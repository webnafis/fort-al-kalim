import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/database_seeder.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Warrior Profile', style: TextStyle(fontFamily: 'Amiri')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not logged in.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.gold, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user.photoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(color: AppTheme.gold),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.person,
                              size: 60,
                              color: AppTheme.gold,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 60,
                            color: AppTheme.gold,
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Name & Email
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),

                // Stats Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('Level', user.currentLevel.toString()),
                    _buildStatCard('Score', user.lifetimeScore.toInt().toString()),
                    _buildStatCard('Record', user.wlRecord),
                  ],
                ),
                const SizedBox(height: 60),

                // Actions
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) {
                      context.go(Routes.splash);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Leave Fort'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceDark,
                    foregroundColor: AppTheme.redFort,
                    side: BorderSide(color: AppTheme.redFort.withOpacity(0.5)),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Admin Area
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: 12),
                const Text('Admin Tools', style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeding Database...')));
                    try {
                      await DatabaseSeeder.seedLevel1();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database seeded successfully!')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('Seed Level 1 Words'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceDark,
                    foregroundColor: AppTheme.gold,
                    side: BorderSide(color: AppTheme.gold.withOpacity(0.5)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.gold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
