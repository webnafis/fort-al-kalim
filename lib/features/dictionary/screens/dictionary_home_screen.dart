import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/settings_service.dart';
import '../../social/screens/widgets/notification_bell.dart';

class DictionaryHomeScreen extends ConsumerWidget {
  const DictionaryHomeScreen({super.key});

  static const int totalLevels = 45; 

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Library', style: TextStyle(fontFamily: 'Amiri', color: AppTheme.gold)),
        backgroundColor: AppTheme.backgroundDark,
        actions: const [
          NotificationBell(),
          SizedBox(width: 8),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox();
          final currentLevel = user.currentLevel;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: totalLevels,
            itemBuilder: (context, index) {
              final level = index + 1;
              final isUnlocked = level <= currentLevel;

              return Card(
                color: isUnlocked ? AppTheme.surfaceDark : AppTheme.surfaceDark.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isUnlocked ? AppTheme.gold.withOpacity(0.5) : AppTheme.textMuted.withOpacity(0.2),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    SettingsNotifier.playSfx('click.mp3');
                    if (isUnlocked) {
                      context.push('${Routes.dictionaryLevel}?level=$level');
                    } else {
                      _showLockedDialog(context, level, currentLevel);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isUnlocked ? Icons.book : Icons.lock,
                          color: isUnlocked ? AppTheme.gold : AppTheme.textMuted,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Level $level',
                          style: TextStyle(
                            color: isUnlocked ? Colors.white : AppTheme.textMuted,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
        error: (_, __) => const Center(child: Text('Error loading library.', style: TextStyle(color: AppTheme.redFort))),
      ),
    );
  }

  void _showLockedDialog(BuildContext context, int lockedLevel, int currentLevel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('Level Locked', style: TextStyle(color: AppTheme.redFort, fontWeight: FontWeight.bold)),
          content: Text(
            'You must complete Level $currentLevel and reach Level $lockedLevel to unlock this dictionary section.\n\nKeep playing matches and defeating enemies to level up!',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                SettingsNotifier.playSfx('click.mp3');
                context.pop();
              },
              child: const Text('OK', style: TextStyle(color: AppTheme.gold)),
            ),
          ],
        );
      },
    );
  }
}
