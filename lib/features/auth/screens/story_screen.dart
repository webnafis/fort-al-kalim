import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/settings_service.dart';

class StoryScreen extends ConsumerWidget {
  const StoryScreen({super.key});

  void _finishStory(BuildContext context, WidgetRef ref) {
    SettingsNotifier.playSfx('click.mp3');
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      // Already logged in -> go straight to Home
      context.go(Routes.home);
    } else {
      // Not logged in -> go to Login
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_main.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Dark Overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.75),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar with Skip Button
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => _finishStory(context, ref),
                    child: const Text(
                      'SKIP ⏭',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Scrolling Story Text
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
                    child: Column(
                      children: [
                        const Text(
                          'THE LEGEND OF\nFORT AL-KALIM',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildStoryParagraph(
                          'Long ago, in an age when scholars were the mightiest warriors and ink was worth more than blood, there existed an ancient fortress unlike anything the world had ever seen.',
                        ),
                        _buildStoryParagraph(
                          'Fort Al-Kalim — قلعة الكليم — The Fortress of the Word.',
                        ),
                        _buildStoryParagraph(
                          'It was not built with stone or iron. Its walls were raised from thousand-year-old manuscripts, its towers carved from scrolls of Arabic poetry, and its gates sealed shut by the sacred weight of language itself.',
                        ),
                        _buildStoryParagraph(
                          'No sword could breach it. No army could conquer it. Only one force in the world had the power to bring those walls down... A word, spoken correctly.',
                        ),
                        _buildStoryParagraph(
                          'The ancient Keepers declared a sacred law:\n\n"Weapons of steel shall not open these gates.\nOnly the warrior who masters our words\nshall ever break our walls.\nFor a word understood is a fortress fallen.\nA word forgotten is a wall rebuilt."',
                        ),
                        _buildStoryParagraph(
                          'And so the War of Words began. Champions entered the arena armed not with arrows, but with vocabulary. Not with shields, but with memory. They hurled missiles of meaning at each other\'s forts: each correct translation a direct hit, each mastered word a crack in the enemy wall.',
                        ),
                        _buildStoryParagraph(
                          'Today, you step into the arena. Your words are your only weapons.',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Will you break their walls before they break yours?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // Bottom Continue Button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ElevatedButton(
                    onPressed: () => _finishStory(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.backgroundDark,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'BEGIN YOUR JOURNEY',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          height: 1.6,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
