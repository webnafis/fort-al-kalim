import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/settings_service.dart';
import '../../matchmaking/services/friend_room_service.dart';
import '../services/social_challenge_service.dart';
import '../../../data/services/presence_service.dart';
import 'widgets/notification_bell.dart';

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

final socialPlayersProvider = FutureProvider.autoDispose<List<SocialPlayer>>((ref) async {
  final currentUserUid = ref.watch(currentUserProvider).value?.uid;
  if (currentUserUid == null) return [];

  final db = FirebaseFirestore.instance;
  Map<String, int> opponentCounts = {};

  final p1Games = await db.collection('games').where('player1', isEqualTo: currentUserUid).get();
  for (var doc in p1Games.docs) {
    final p2 = doc.data()['player2'] as String?;
    if (p2 != null && p2 != 'AI_BOT') {
      opponentCounts[p2] = (opponentCounts[p2] ?? 0) + 1;
    }
  }

  final p2Games = await db.collection('games').where('player2', isEqualTo: currentUserUid).get();
  for (var doc in p2Games.docs) {
    final p1 = doc.data()['player1'] as String?;
    if (p1 != null && p1 != 'AI_BOT') {
      opponentCounts[p1] = (opponentCounts[p1] ?? 0) + 1;
    }
  }

  var sortedOpponents = opponentCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
    
  final pastUids = sortedOpponents.map((e) => e.key).take(20).toList();
  List<SocialPlayer> players = [];
  
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
});

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  Future<void> _challengeFriend(String friendId) async {
    SettingsNotifier.playSfx('click.mp3');
    final user = ref.read(currentUserModelProvider).value;
    if (user == null) return;

    final svc = ref.read(socialChallengeServiceProvider);
    
    // First, send the challenge
    final challengeId = await svc.sendChallenge(
      fromUid: user.uid,
      fromName: user.displayName,
      fromLevel: user.currentLevel,
      toUid: friendId,
    );

    // Show waiting dialog with Cancel option
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: AppTheme.gold),
            SizedBox(height: 16),
            Text('Waiting for opponent...', style: TextStyle(color: AppTheme.gold)),
            SizedBox(height: 8),
            Text('Timeout in 60s', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Cancel challenge and close dialog
              svc.cancelChallenge(challengeId);
              Navigator.of(context).pop();
            },
            child: const Text('Cancel', style: TextStyle(color: AppTheme.redFort)),
          )
        ],
      ),
    );

    // Wait for them to accept, or for us to cancel
    StreamSubscription<DocumentSnapshot>? sub;
    sub = svc.watchChallenge(challengeId).listen((doc) {
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'];
      
      if (status == 'accepted') {
        sub?.cancel();
        final gameId = data['gameId'];
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // close waiting dialog
          context.go('${Routes.readingPhase}?gameId=$gameId');
        }
      } else if (status == 'declined' || status == 'cancelled') {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // close waiting dialog
          if (status == 'declined') {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Challenge Declined')));
          }
        }
      }
    });

    // Timeout max wait time: 60 seconds
    Future.delayed(const Duration(seconds: 60), () {
      sub?.cancel();
      // Only close if dialog is still open
      if (mounted) {
        svc.cancelChallenge(challengeId); // auto-cancel if they never responded
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(socialPlayersProvider);

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
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.gold),
            onPressed: () {
              SettingsNotifier.playSfx('click.mp3');
              // invalidate provider to force a fresh pull!
              ref.invalidate(socialPlayersProvider);
            },
          ),
        ],
      ),
      body: playersAsync.when(
        data: (players) {
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
                ...pastOpponents.map((p) => _PlayerCard(player: p, onChallenge: () => _challengeFriend(p.uid))),
                const SizedBox(height: 16),
              ],
              if (globalPlayers.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('🌍 Global Players', style: TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
                ),
                ...globalPlayers.map((p) => _PlayerCard(player: p, onChallenge: () => _challengeFriend(p.uid))),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
        error: (e, st) => Center(child: Text(e.toString(), style: const TextStyle(color: AppTheme.redFort))),
      ),
    );
  }
}

class _PlayerCard extends ConsumerWidget {
  final SocialPlayer player;
  final VoidCallback onChallenge;

  const _PlayerCard({required this.player, required this.onChallenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = player.data['displayName'] ?? 'Unknown';
    final level = player.data['currentLevel'] ?? 1;
    final avatar = player.data['photoUrl'];
    
    // Watch real-time true presence status
    final isOnlineAsync = ref.watch(onlineStatusProvider(player.uid));
    final isOnline = isOnlineAsync.value ?? false;

    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.backgroundDark,
              backgroundImage: avatar != null && avatar.startsWith('http') ? NetworkImage(avatar) : null,
              child: avatar == null || !avatar.startsWith('http') ? const Icon(Icons.person, color: AppTheme.textMuted) : null,
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
          onPressed: isOnline ? onChallenge : null,
        ),
      ),
    );
  }
}
