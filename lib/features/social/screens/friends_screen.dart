import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/settings_service.dart';
import '../../matchmaking/services/friend_room_service.dart';
import '../services/social_challenge_service.dart';

class SocialPlayer {
  final String uid;
  final Map<String, dynamic> data;
  final bool isPastOpponent;
  final int matchCount;

  SocialPlayer({
    required this.uid,
    required this.data,
    this.isPastOpponent = false,
    this.matchCount = 0,
  });
}

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  StreamSubscription? _incomingSub;
  final Set<String> _handledChallenges = {};
  int _refreshKey = 0;
  bool _isChallenging = false;

  @override
  void initState() {
    super.initState();
    _listenForChallenges();
  }

  void _listenForChallenges() async {
    final user = await ref.read(currentUserModelProvider.future);
    if (user == null) return;

    final svc = ref.read(socialChallengeServiceProvider);
    _incomingSub = svc.watchIncomingChallenges(user.uid).listen((snapshot) {
      if (!mounted) return;
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final doc = change.doc;
          if (_handledChallenges.contains(doc.id)) continue;
          _handledChallenges.add(doc.id);

          final data = doc.data() as Map<String, dynamic>;
          _showIncomingChallengeDialog(doc.id, data);
        }
      }
    });
  }

  void _showIncomingChallengeDialog(String challengeId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Incoming Challenge!', style: TextStyle(color: AppTheme.gold)),
        content: Text('${data['fromName']} (Level ${data['fromLevel']}) has challenged you to a battle!', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(socialChallengeServiceProvider).declineChallenge(challengeId);
              context.pop();
            },
            child: const Text('Decline', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
            onPressed: () async {
              SettingsNotifier.playSfx('click.mp3');
              context.pop();
              final user = ref.read(currentUserModelProvider).value;
              if (user == null) return;
              
              final gameId = await ref.read(socialChallengeServiceProvider).acceptChallenge(
                challengeId, 
                user.uid, 
                data['fromUid'], 
                user.currentLevel,
              );
              if (gameId != null && mounted) {
                context.go('${Routes.readingPhase}?gameId=$gameId');
              }
            },
            child: const Text('ACCEPT'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    super.dispose();
  }

  Future<void> _challengeFriend(String friendId) async {
    SettingsNotifier.playSfx('click.mp3');
    final user = ref.read(currentUserModelProvider).value;
    if (user == null) return;

    // Show waiting dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.gold),
            SizedBox(height: 16),
            Text('Sending Challenge...', style: TextStyle(color: AppTheme.gold)),
          ],
        ),
      ),
    );

    setState(() { _isChallenging = true; });

    final svc = ref.read(socialChallengeServiceProvider);
    final challengeId = await svc.sendChallenge(
      fromUid: user.uid,
      fromName: user.displayName,
      fromLevel: user.currentLevel,
      toUid: friendId,
    );

    // Wait for them to accept
    final sub = svc.watchChallenge(challengeId).listen((doc) {
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'];
      
      if (status == 'accepted') {
        final gameId = data['gameId'];
        if (mounted) {
          context.pop(); // close waiting dialog
          context.go('${Routes.readingPhase}?gameId=$gameId');
        }
      } else if (status == 'declined') {
        if (mounted) {
          context.pop(); // close waiting dialog
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Challenge Declined')));
        }
      }
    });

    // Cleanup listener if dialog is somehow dismissed
    Future.delayed(const Duration(seconds: 30), () {
      sub.cancel();
    });
  }

  Future<List<SocialPlayer>> _loadSocialData() async {
    final currentUserUid = ref.read(currentUserProvider).value?.uid;
    if (currentUserUid == null) return [];

    final db = FirebaseFirestore.instance;
    Map<String, int> opponentCounts = {};

    // Fetch games where I was player 1
    final p1Games = await db.collection('games').where('player1', isEqualTo: currentUserUid).get();
    for (var doc in p1Games.docs) {
      final p2 = doc.data()['player2'] as String?;
      if (p2 != null && p2 != 'AI_BOT') {
        opponentCounts[p2] = (opponentCounts[p2] ?? 0) + 1;
      }
    }

    // Fetch games where I was player 2
    final p2Games = await db.collection('games').where('player2', isEqualTo: currentUserUid).get();
    for (var doc in p2Games.docs) {
      final p1 = doc.data()['player1'] as String?;
      if (p1 != null && p1 != 'AI_BOT') {
        opponentCounts[p1] = (opponentCounts[p1] ?? 0) + 1;
      }
    }

    // Sort opponents by match count descending
    var sortedOpponents = opponentCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    // Cap past opponents
    final pastUids = sortedOpponents.map((e) => e.key).take(20).toList();
    
    List<SocialPlayer> players = [];
    
    // Fetch past opponents data
    if (pastUids.isNotEmpty) {
      final futures = pastUids.map((uid) => db.collection('users').doc(uid).get());
      final docs = await Future.wait(futures);
      for (int i=0; i<docs.length; i++) {
        if (docs[i].exists) {
          players.add(SocialPlayer(
            uid: docs[i].id,
            data: docs[i].data() as Map<String, dynamic>,
            isPastOpponent: true,
            matchCount: opponentCounts[docs[i].id] ?? 0,
          ));
        }
      }
    }
    
    // If we have less than 20 players, fetch global ones to fill
    int remaining = 20 - players.length;
    if (remaining > 0) {
      final globalDocs = await db.collection('users').limit(remaining + players.length + 1).get();
      for (var doc in globalDocs.docs) {
        if (players.length >= 20) break;
        if (doc.id == currentUserUid) continue;
        if (pastUids.contains(doc.id)) continue;
        
        players.add(SocialPlayer(
          uid: doc.id,
          data: doc.data(),
          isPastOpponent: false,
          matchCount: 0,
        ));
      }
    }
    
    return players;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Social Hub', style: TextStyle(fontFamily: 'Amiri', color: AppTheme.gold)),
        backgroundColor: AppTheme.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.gold),
          onPressed: () {
            SettingsNotifier.playSfx('click.mp3');
            context.go(Routes.home);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.gold),
            onPressed: () {
              SettingsNotifier.playSfx('click.mp3');
              setState(() => _refreshKey++);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<SocialPlayer>>(
        key: ValueKey(_refreshKey),
        future: _loadSocialData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
          }
          
          final players = snapshot.data ?? [];

          if (players.isEmpty) {
            return const Center(child: Text('No players found.', style: TextStyle(color: AppTheme.textMuted)));
          }

          final pastOpponents = players.where((p) => p.isPastOpponent).toList();
          final globalPlayers = players.where((p) => !p.isPastOpponent).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pastOpponents.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('⚔️ Past Opponents', style: TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
                ),
                ...pastOpponents.map((p) => _buildPlayerCard(p)),
                const SizedBox(height: 16),
              ],
              if (globalPlayers.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('🌍 Global Players', style: TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
                ),
                ...globalPlayers.map((p) => _buildPlayerCard(p)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerCard(SocialPlayer player) {
    final name = player.data['displayName'] ?? 'Unknown';
    final level = player.data['currentLevel'] ?? 1;
    final avatar = player.data['photoUrl'];
    final isOnline = Random().nextBool(); // Demo: Randomly show online status

    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.backgroundDark,
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              child: avatar == null ? const Icon(Icons.person, color: AppTheme.textMuted) : null,
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surfaceDark, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          player.isPastOpponent 
            ? 'Level $level • ${player.matchCount} Match${player.matchCount > 1 ? 'es' : ''} Played'
            : 'Level $level Scholar', 
          style: TextStyle(color: player.isPastOpponent ? AppTheme.gold : AppTheme.textMuted, fontSize: 12)
        ),
        trailing: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isOnline ? AppTheme.gold : AppTheme.backgroundDark,
            foregroundColor: isOnline ? Colors.black : AppTheme.textMuted,
          ),
          icon: const Icon(Icons.sports_kabaddi, size: 18),
          label: const Text('CHALLENGE'),
          onPressed: isOnline ? () => _challengeFriend(player.uid) : null,
        ),
      ),
    );
  }
}
