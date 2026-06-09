import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;

  Achievement({required this.id, required this.title, required this.description, required this.icon, required this.isUnlocked});
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Hardcoded demo achievements list.
    // In a real app, 'isUnlocked' would be checked against Firestore users/{uid}/achievements array.
    final achievements = [
      Achievement(id: 'a1', title: 'First Blood', description: 'Win your first battle.', icon: Icons.whatshot, isUnlocked: true),
      Achievement(id: 'a2', title: 'Scholar', description: 'Reach Level 2.', icon: Icons.menu_book, isUnlocked: true),
      Achievement(id: 'a3', title: 'Sharpshooter', description: 'Answer 5 questions correctly in a row.', icon: Icons.track_changes, isUnlocked: false),
      Achievement(id: 'a4', title: 'Polyglot', description: 'Successfully use all 4 attack types in one game.', icon: Icons.record_voice_over, isUnlocked: false),
      Achievement(id: 'a5', title: 'Untouchable', description: 'Win a battle without taking any damage.', icon: Icons.shield, isUnlocked: false),
      Achievement(id: 'a6', title: 'Desert Fox', description: 'Win 10 battles.', icon: Icons.pets, isUnlocked: false),
      Achievement(id: 'a7', title: 'Calligrapher', description: 'Solve 20 WRITE challenges.', icon: Icons.draw, isUnlocked: false),
      Achievement(id: 'a8', title: 'Golden Tongue', description: 'Solve 20 SPEAK challenges.', icon: Icons.mic, isUnlocked: false),
      Achievement(id: 'a9', title: 'Eagle Eye', description: 'Solve 20 SEE challenges.', icon: Icons.visibility, isUnlocked: false),
      Achievement(id: 'a10', title: 'Fortress Commander', description: 'Reach Level 10.', icon: Icons.castle, isUnlocked: false),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Achievements', style: TextStyle(fontFamily: 'Amiri', color: AppTheme.gold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.gold),
          onPressed: () => context.go(Routes.profile),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final a = achievements[index];
          return Card(
            color: a.isUnlocked ? AppTheme.surfaceDark : AppTheme.backgroundDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: a.isUnlocked ? AppTheme.gold : AppTheme.textMuted.withOpacity(0.3), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    a.isUnlocked ? a.icon : Icons.lock,
                    size: 48,
                    color: a.isUnlocked ? AppTheme.gold : AppTheme.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    a.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: a.isUnlocked ? Colors.white : AppTheme.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontStyle: a.isUnlocked ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
