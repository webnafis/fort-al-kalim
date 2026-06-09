import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';
import '../services/friend_room_service.dart';

class FriendRoomScreen extends ConsumerStatefulWidget {
  final String? roomCode; // If passed, immediately join
  const FriendRoomScreen({super.key, this.roomCode});

  @override
  ConsumerState<FriendRoomScreen> createState() => _FriendRoomScreenState();
}

class _FriendRoomScreenState extends ConsumerState<FriendRoomScreen> {
  String? _currentRoomCode;
  bool _isHost = false;
  bool _loading = false;
  String? _errorMsg;
  final _codeCtrl = TextEditingController();
  StreamSubscription<DatabaseEvent>? _roomSub;

  @override
  void initState() {
    super.initState();
    if (widget.roomCode != null && widget.roomCode!.isNotEmpty) {
      _joinRoom(widget.roomCode!);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _roomSub?.cancel();
    // If we leave and are host, optionally destroy room here
    if (_isHost && _currentRoomCode != null) {
      ref.read(friendRoomServiceProvider).leaveRoom(_currentRoomCode!);
    }
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() => _loading = true);
    final user = await ref.read(currentUserModelProvider.future);
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    
    try {
      final svc = ref.read(friendRoomServiceProvider);
      final code = await svc.createRoom(user.uid, user.displayName, user.currentLevel);
      setState(() {
        _currentRoomCode = code;
        _isHost = true;
      });
      _listenToRoom(code);
    } catch (e) {
      setState(() { _errorMsg = "Failed to create room."; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _joinRoom(String code) async {
    setState(() => _loading = true);
    final user = await ref.read(currentUserModelProvider.future);
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final svc = ref.read(friendRoomServiceProvider);
      final success = await svc.joinRoom(code, user.uid, user.displayName, user.currentLevel);
      
      if (success) {
        setState(() {
          _currentRoomCode = code.toUpperCase();
          _isHost = false;
        });
        _listenToRoom(_currentRoomCode!);
      } else {
        setState(() { _errorMsg = "Room is full or invalid."; });
      }
    } catch (e) {
      setState(() { _errorMsg = "Error joining room."; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _listenToRoom(String code) {
    _roomSub?.cancel();
    _roomSub = ref.read(friendRoomServiceProvider).watchRoom(code).listen((event) {
      if (event.snapshot.value == null) {
        // Room closed/deleted
        if (mounted) {
          context.pop();
        }
        return;
      }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (data['status'] == 'playing' && data.containsKey('gameId')) {
        // Start game!
        if (mounted) {
          context.go('${Routes.readingPhase}?gameId=${data['gameId']}');
        }
      } else {
        setState(() {}); // Trigger rebuild to show guest info if they joined
      }
    });
  }

  Future<void> _startGame() async {
    if (_currentRoomCode == null) return;
    setState(() { _loading = true; });
    try {
      final gameId = await ref.read(friendRoomServiceProvider).startGame(_currentRoomCode!);
      if (gameId != null && mounted) {
        context.go('${Routes.readingPhase}?gameId=$gameId');
      }
    } catch (e) {
      setState(() { _errorMsg = "Failed to start game."; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Play with Friend', style: TextStyle(fontFamily: 'Amiri', color: AppTheme.gold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _currentRoomCode == null ? _buildSetupUI() : _buildLobbyUI(),
        ),
      ),
    );
  }

  Widget _buildSetupUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMsg != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(_errorMsg!, style: const TextStyle(color: AppTheme.redFort), textAlign: TextAlign.center),
          ),
        
        ElevatedButton(
          onPressed: _loading ? null : _createRoom,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            backgroundColor: AppTheme.gold,
            foregroundColor: AppTheme.backgroundDark,
          ),
          child: _loading 
              ? const CircularProgressIndicator(color: AppTheme.backgroundDark)
              : const Text('CREATE A ROOM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: Text('— OR —', style: TextStyle(color: AppTheme.textMuted))),
        ),

        TextField(
          controller: _codeCtrl,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'ENTER 6-CHAR CODE',
            hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 16, letterSpacing: 1),
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading ? null : () => _joinRoom(_codeCtrl.text.trim()),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            backgroundColor: AppTheme.surfaceDark,
            foregroundColor: AppTheme.textPrimary,
            side: BorderSide(color: AppTheme.gold.withOpacity(0.5)),
          ),
          child: const Text('JOIN ROOM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildLobbyUI() {
    // We can fetch room data synchronously since our stream listener triggers setState anyway
    return StreamBuilder<DatabaseEvent>(
      stream: ref.read(friendRoomServiceProvider).watchRoom(_currentRoomCode!),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
        }

        final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final bool guestJoined = data['status'] == 'ready';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
                _currentRoomCode!,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppTheme.gold),
              ),
            ),
            const SizedBox(height: 48),

            // Players
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPlayerAvatar(data['hostName'], data['hostLevel']),
                const Text('VS', style: TextStyle(color: AppTheme.textMuted, fontSize: 24, fontStyle: FontStyle.italic)),
                if (guestJoined)
                  _buildPlayerAvatar(data['guestName'], data['guestLevel'])
                else
                  _buildWaitingAvatar(),
              ],
            ),
            
            const Spacer(),
            
            if (_isHost)
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
              )
            else
              const Text('Waiting for host to start...', style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
            
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildPlayerAvatar(String name, int level) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppTheme.surfaceDark,
          child: const Icon(Icons.person, size: 40, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text('Level $level', style: const TextStyle(color: AppTheme.gold, fontSize: 12)),
      ],
    );
  }

  Widget _buildWaitingAvatar() {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppTheme.surfaceDark.withOpacity(0.5),
          child: const CircularProgressIndicator(color: AppTheme.gold),
        ),
        const SizedBox(height: 12),
        const Text('Waiting...', style: TextStyle(color: AppTheme.textMuted)),
      ],
    );
  }
}
