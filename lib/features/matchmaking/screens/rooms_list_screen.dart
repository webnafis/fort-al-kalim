import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/settings_service.dart';
import '../services/friend_room_service.dart';

class RoomsListScreen extends ConsumerStatefulWidget {
  const RoomsListScreen({super.key});

  @override
  ConsumerState<RoomsListScreen> createState() => _RoomsListScreenState();
}

class _RoomsListScreenState extends ConsumerState<RoomsListScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    SettingsNotifier.playSfx('click.mp3');
    setState(() { _loading = true; _errorMsg = null; });
    
    final user = ref.read(currentUserProvider).value;
    final userModel = await ref.read(currentUserModelProvider.future);
    
    if (user == null || userModel == null) {
      setState(() => _loading = false);
      return;
    }
    
    try {
      final svc = ref.read(friendRoomServiceProvider);
      final code = await svc.createRoom(user.uid, userModel.displayName, userModel.currentLevel);
      if (mounted) {
        context.push('${Routes.friendRoom}?roomCode=$code');
      }
    } catch (e) {
      if (e.toString().contains('MAX_ROOMS_REACHED')) {
        setState(() => _errorMsg = "You can only host up to 5 rooms at a time.");
      } else {
        setState(() => _errorMsg = "Failed to create room.");
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinRoom(String code) async {
    SettingsNotifier.playSfx('click.mp3');
    if (code.length != 6) {
      setState(() => _errorMsg = "Invalid code.");
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    
    final user = ref.read(currentUserProvider).value;
    final userModel = await ref.read(currentUserModelProvider.future);
    
    if (user == null || userModel == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final svc = ref.read(friendRoomServiceProvider);
      final success = await svc.joinRoom(code, user.uid, userModel.displayName, userModel.currentLevel);
      
      if (success && mounted) {
        context.push('${Routes.friendRoom}?roomCode=$code');
        _codeCtrl.clear();
      } else if (mounted) {
        setState(() => _errorMsg = "Room is full or invalid.");
      }
    } catch (e) {
      if (mounted) setState(() => _errorMsg = "Error joining room.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('War Camp', style: TextStyle(fontFamily: 'Amiri', color: AppTheme.gold)),
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
        child: user == null
            ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
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
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppTheme.backgroundDark, strokeWidth: 2))
                          : const Text('CREATE A NEW ROOM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('— OR JOIN BY CODE —', style: TextStyle(color: AppTheme.textMuted))),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.bold),
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              hintText: 'CODE',
                              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                              counterText: '',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _loading ? null : () => _joinRoom(_codeCtrl.text.trim()),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            backgroundColor: AppTheme.surfaceDark,
                            foregroundColor: AppTheme.gold,
                            side: BorderSide(color: AppTheme.gold.withOpacity(0.5)),
                          ),
                          child: const Text('JOIN'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),
                    
                    _buildRoomsListSection('My Hosted Rooms', true, user.uid),
                    const SizedBox(height: 32),
                    _buildRoomsListSection('Joined Rooms', false, user.uid),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRoomsListSection(String title, bool isHost, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
        const SizedBox(height: 12),
        FutureBuilder<List<DocumentSnapshot>>(
          future: isHost 
              ? ref.read(friendRoomServiceProvider).getMyHostedRooms(uid)
              : ref.read(friendRoomServiceProvider).getMyJoinedRooms(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.gold)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.textMuted.withOpacity(0.2)),
                ),
                child: Text('No rooms found.', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
              );
            }

            final rooms = snapshot.data!;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rooms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final doc = rooms[index];
                final data = doc.data() as Map<String, dynamic>;
                final code = doc.id;
                
                String subtitle = 'Waiting for guest...';
                if (data['guest'] != null) {
                   subtitle = isHost ? 'Vs ${data['guest']['name']}' : 'Vs ${data['host']['name']}';
                }

                return ListTile(
                  tileColor: AppTheme.surfaceDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.gold.withOpacity(0.3)),
                  ),
                  title: Text('Room: $code', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.gold),
                  onTap: () {
                    SettingsNotifier.playSfx('click.mp3');
                    context.push('${Routes.friendRoom}?roomCode=$code');
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
