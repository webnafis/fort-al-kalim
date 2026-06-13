import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/settings_service.dart';
import '../../social/screens/widgets/notification_bell.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('Leaderboard', style: TextStyle(fontFamily: 'Amiri', color: AppTheme.gold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.gold),
            onPressed: () {
              SettingsNotifier.playSfx('click.mp3');
              context.go(Routes.home);
            },
          ),
          actions: const [
            NotificationBell(),
            SizedBox(width: 8),
          ],
          bottom: const TabBar(
            indicatorColor: AppTheme.gold,
            labelColor: AppTheme.gold,
            unselectedLabelColor: AppTheme.textMuted,
            tabs: [
              Tab(text: 'GLOBAL WARRIORS'),
              Tab(text: 'YOUR LEVEL'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LeaderboardList(isGlobal: true),
            _LeaderboardList(isGlobal: false),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardList extends ConsumerWidget {
  final bool isGlobal;
  const _LeaderboardList({required this.isGlobal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);
    
    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Please log in to view rankings.', style: TextStyle(color: AppTheme.textMuted)));
        }

        Query query = FirebaseFirestore.instance.collection('users');
        
        if (!isGlobal) {
          query = query.where('currentLevel', isEqualTo: user.currentLevel);
        }
        
        query = query.orderBy('lifetimeScore', descending: true).limit(50);

        return StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('Error loading leaderboard: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No warriors found in the desert.', style: TextStyle(color: AppTheme.textMuted)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final rank = index + 1;
                final name = data['displayName'] ?? 'Unknown Warrior';
                final score = data['lifetimeScore'] ?? 0;
                final avatar = data['photoUrl'];

                return Card(
                  color: AppTheme.surfaceDark,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.backgroundDark,
                      backgroundImage: avatar != null && avatar.startsWith('http') ? NetworkImage(avatar) : null,
                      child: avatar == null || !avatar.startsWith('http') ? const Icon(Icons.person, color: AppTheme.textMuted) : null,
                    ),
                    title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Score: $score', style: const TextStyle(color: AppTheme.gold)),
                    trailing: Text('#$rank', style: const TextStyle(color: AppTheme.textMuted, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
      error: (_, __) => const Center(child: Text('Error loading user profile.', style: TextStyle(color: AppTheme.redFort))),
    );
  }
}
