import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';
import '../../matchmaking/services/friend_room_service.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  Future<void> _challengeFriend(BuildContext context, WidgetRef ref, String friendId) async {
    final user = await ref.read(currentUserModelProvider.future);
    if (user == null) return;
    
    // Create a room and invite the friend
    final code = await ref.read(friendRoomServiceProvider).createRoom(user.uid, user.displayName, user.currentLevel);
    if (context.mounted) {
      context.go('${Routes.friendRoom}?roomCode=$code');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For demo purposes, we'll just load all users and pretend they are friends.
    Query query = FirebaseFirestore.instance.collection('users').limit(20);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('War Camp (Friends)', style: TextStyle(fontFamily: 'Amiri', color: AppTheme.gold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.gold),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
          }
          
          final docs = snapshot.data?.docs ?? [];
          final currentUserUid = ref.read(currentUserProvider).value?.uid;
          
          final friends = docs.where((doc) => doc.id != currentUserUid).toList();

          if (friends.isEmpty) {
            return const Center(child: Text('No friends found. Invite some!', style: TextStyle(color: AppTheme.textMuted)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final data = friends[index].data() as Map<String, dynamic>;
              final name = data['displayName'] ?? 'Unknown';
              final level = data['currentLevel'] ?? 1;
              final avatar = data['photoUrl'];
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
                  subtitle: Text('Level $level Scholar', style: const TextStyle(color: AppTheme.textMuted)),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOnline ? AppTheme.gold : AppTheme.backgroundDark,
                      foregroundColor: isOnline ? Colors.black : AppTheme.textMuted,
                    ),
                    icon: const Icon(Icons.sports_kabaddi, size: 18),
                    label: const Text('CHALLENGE'),
                    onPressed: isOnline ? () => _challengeFriend(context, ref, friends[index].id) : null,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
