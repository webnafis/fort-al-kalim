import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/achievements.dart';
import '../../../core/widgets/settings_dialog.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/database_seeder.dart';
import '../../matchmaking/services/friend_room_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/settings_service.dart';
import '../../social/screens/widgets/notification_bell.dart';

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
        actions: const [
          NotificationBell(),
          SizedBox(width: 8),
        ],
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
                    child: user.photoUrl != null && user.photoUrl!.startsWith('http')
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
                const SizedBox(height: 24),
                
                // Battle Dossier
                _buildBattleDossier(context, ref, user),
                const SizedBox(height: 40),

                // Achievements Section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Achievements',
                    style: TextStyle(fontFamily: 'Amiri', color: AppTheme.gold, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                _buildAchievementsGrid(user.unlockedAchievements),
                const SizedBox(height: 48),

                // Actions
                ElevatedButton.icon(
                  onPressed: () {
                    SettingsNotifier.playSfx('click.mp3');
                    _showTipsDialog(context);
                  },
                  icon: const Icon(Icons.lightbulb),
                  label: const Text('Tips for Battle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceDark,
                    foregroundColor: AppTheme.gold,
                    side: BorderSide(color: AppTheme.gold.withOpacity(0.5)),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    SettingsNotifier.playSfx('click.mp3');
                    showDialog(context: context, builder: (_) => const SettingsDialog());
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceDark,
                    foregroundColor: AppTheme.gold,
                    side: BorderSide(color: AppTheme.gold.withOpacity(0.5)),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    SettingsNotifier.playSfx('click.mp3');
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
                    SettingsNotifier.playSfx('click.mp3');
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

  Widget _buildAchievementsGrid(List<String> unlockedIds) {
    const ColorFilter greyscale = ColorFilter.matrix(<double>[
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0,      0,      0,      1, 0,
    ]);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
        childAspectRatio: 0.7,
      ),
      itemCount: kAllAchievements.length,
      itemBuilder: (context, index) {
        final ach = kAllAchievements[index];
        final isUnlocked = unlockedIds.contains(ach.id);
        return GestureDetector(
          onTap: () {
            SettingsNotifier.playSfx('click.mp3');
            _showAchievementDetails(context, ach, isUnlocked);
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUnlocked ? AppTheme.gold.withOpacity(0.1) : AppTheme.surfaceDark.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlocked ? AppTheme.gold : AppTheme.textMuted.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: isUnlocked
                    ? Image.asset(ach.imagePath, width: 48, height: 48)
                    : ColorFiltered(
                        colorFilter: greyscale,
                        child: Opacity(
                          opacity: 0.3,
                          child: Image.asset(ach.imagePath, width: 48, height: 48),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                ach.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? Colors.white : AppTheme.textMuted.withOpacity(0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAchievementDetails(BuildContext context, Achievement ach, bool isUnlocked) {
    const ColorFilter greyscale = ColorFilter.matrix(<double>[
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0,      0,      0,      1, 0,
    ]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isUnlocked ? AppTheme.gold : AppTheme.textMuted.withOpacity(0.3), 
            width: 2
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isUnlocked ? AppTheme.gold.withOpacity(0.1) : AppTheme.backgroundDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked ? AppTheme.gold : AppTheme.textMuted.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isUnlocked
                  ? Image.asset(ach.imagePath, width: 80, height: 80)
                  : ColorFiltered(
                      colorFilter: greyscale,
                      child: Opacity(
                        opacity: 0.3,
                        child: Image.asset(ach.imagePath, width: 80, height: 80),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            Text(
              ach.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? AppTheme.gold : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ach.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isUnlocked ? 'Unlocked!' : 'Locked',
                style: TextStyle(
                  color: isUnlocked ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: AppTheme.gold)),
          ),
        ],
      ),
    );
  }

  void _showTipsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.gold, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: AppTheme.gold),
            SizedBox(width: 8),
            Text('Tips for Battle', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Study the Library', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Before jumping into battle, visit the Library tab to memorize the Arabic words for your current level. Enemies will attack with these meanings.', style: TextStyle(color: AppTheme.textSecondary)),
              SizedBox(height: 12),
              Text('2. Keep Your Streak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Play at least one match a day to maintain your streak. If you hit a 7-day streak, you get 24 hours of unlimited lives!', style: TextStyle(color: AppTheme.textSecondary)),
              SizedBox(height: 12),
              Text('3. Manage Your Stamina', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('You lose 1 life every time you are defeated. Lives regenerate every 30 minutes, so take a break to study if you run out!', style: TextStyle(color: AppTheme.textSecondary)),
              SizedBox(height: 12),
              Text('4. Play with Friends', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Use the "War Camp" to create rooms and invite friends using a 6-digit code. Playing against a friend is a great way to practice.', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Understood', style: TextStyle(color: AppTheme.gold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleDossier(BuildContext context, WidgetRef ref, UserModel user) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        ref.read(friendRoomServiceProvider).getMyHostedRooms(user.uid),
        ref.read(friendRoomServiceProvider).getMyJoinedRooms(user.uid),
      ]),
      builder: (context, snapshot) {
        int hostedCount = 0;
        int joinedCount = 0;
        if (snapshot.hasData) {
          hostedCount = snapshot.data![0].length;
          joinedCount = snapshot.data![1].length;
        }
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Text('BATTLE DOSSIER', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 18)),
              const Divider(color: AppTheme.gold, height: 32),
              Row(
                children: [
                  Expanded(child: _buildDossierItem('Score', user.lifetimeScore.toInt().toString(), Icons.emoji_events)),
                  Expanded(child: _buildDossierItem('Level', user.currentLevel.toString(), Icons.star)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildDossierItem('Matches', (user.wins + user.losses).toString(), Icons.gamepad)),
                  Expanded(child: _buildDossierItem('Streak', '${user.currentStreak} 🔥', Icons.local_fire_department)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildDossierItem('Wins', user.wins.toString(), Icons.thumb_up)),
                  Expanded(child: _buildDossierItem('Losses', user.losses.toString(), Icons.thumb_down)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildDossierItem('Hosted Rooms', hostedCount.toString(), Icons.home)),
                  Expanded(child: _buildDossierItem('Joined Rooms', joinedCount.toString(), Icons.login)),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDossierItem(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppTheme.gold, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
      ],
    );
  }
}
