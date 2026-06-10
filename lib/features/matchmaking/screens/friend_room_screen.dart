import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/settings_service.dart';
import '../services/friend_room_service.dart';

class FriendRoomScreen extends ConsumerStatefulWidget {
  final String? roomCode; 
  const FriendRoomScreen({super.key, required this.roomCode});

  @override
  ConsumerState<FriendRoomScreen> createState() => _FriendRoomScreenState();
}

class _FriendRoomScreenState extends ConsumerState<FriendRoomScreen> {
  bool _loading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    if (widget.roomCode == null || widget.roomCode!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pop();
      });
    }
  }

  Future<void> _startGame() async {
    SettingsNotifier.playSfx('click.mp3');
    if (widget.roomCode == null) return;
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final gameId = await ref.read(friendRoomServiceProvider).startGame(widget.roomCode!);
      if (gameId != null && mounted) {
        context.go('${Routes.readingPhase}?gameId=$gameId');
      } else if (mounted) {
        setState(() { _errorMsg = "Cannot start game right now."; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMsg = "Failed to start game."; _loading = false; });
    }
  }

  Future<void> _deleteRoom() async {
    SettingsNotifier.playSfx('click.mp3');
    if (widget.roomCode == null) return;
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await ref.read(friendRoomServiceProvider).deleteRoom(widget.roomCode!);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() { _errorMsg = "Failed to delete room."; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.roomCode == null) return const Scaffold(backgroundColor: AppTheme.backgroundDark);

    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('War Camp Lobby', style: TextStyle(fontFamily: 'Amiri', color: AppTheme.gold)),
        backgroundColor: AppTheme.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.gold),
          onPressed: () {
            SettingsNotifier.playSfx('click.mp3');
            context.go(Routes.home);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: user == null
              ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
              : StreamBuilder<DocumentSnapshot>(
                  stream: ref.read(friendRoomServiceProvider).watchRoom(widget.roomCode!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(child: Text('Room closed or deleted.', style: TextStyle(color: AppTheme.redFort)));
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    
                    // Route immediately if game started
                    if (data['status'] == 'playing' && data.containsKey('gameId')) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                         if (mounted) context.go('${Routes.readingPhase}?gameId=${data['gameId']}');
                      });
                      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
                    }

                    final bool guestJoined = data['guest'] != null;
                    final bool isHost = data['host']['uid'] == user.uid;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_errorMsg != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(_errorMsg!, style: const TextStyle(color: AppTheme.redFort)),
                          ),
                        const Spacer(),
                        const Text('ROOM CODE', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.gold, width: 2),
                          ),
                          child: Text(
                            widget.roomCode!,
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppTheme.gold),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Players
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildPlayerAvatar(data['host']['name'], data['host']['level']),
                            const Text('VS', style: TextStyle(color: AppTheme.textMuted, fontSize: 24, fontStyle: FontStyle.italic)),
                            if (guestJoined)
                              _buildPlayerAvatar(data['guest']['name'], data['guest']['level'])
                            else
                              _buildWaitingAvatar(),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        if (isHost) ...[
                          ElevatedButton(
                            onPressed: guestJoined && !_loading ? _startGame : null,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 64),
                              backgroundColor: AppTheme.gold,
                              foregroundColor: AppTheme.backgroundDark,
                            ),
                            child: _loading 
                                ? const CircularProgressIndicator(color: AppTheme.backgroundDark)
                                : const Text('START DUEL', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _loading ? null : _deleteRoom,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              foregroundColor: AppTheme.redFort,
                              side: const BorderSide(color: AppTheme.redFort),
                            ),
                            child: const Text('DELETE ROOM'),
                          ),
                        ] else ...[
                          const Text('Waiting for host to start...', style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                        ],
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar(String name, int level) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundColor: AppTheme.surfaceDark,
          child: Icon(Icons.person, size: 40, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        Text('Lv. $level', style: const TextStyle(color: AppTheme.gold, fontSize: 14)),
      ],
    );
  }

  Widget _buildWaitingAvatar() {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppTheme.surfaceDark.withOpacity(0.5),
          child: const CircularProgressIndicator(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 12),
        const Text('Waiting...', style: TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
      ],
    );
  }
}
