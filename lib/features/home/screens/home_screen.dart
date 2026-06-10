import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../leaderboard/screens/leaderboard_screen.dart';
import '../../social/screens/friends_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../dictionary/screens/dictionary_home_screen.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/settings_service.dart';
import '../../matchmaking/services/matchmaking_service.dart';

import 'package:flame_audio/flame_audio.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _PlayTab(),
    const DictionaryHomeScreen(),
    const FriendsScreen(),
    const LeaderboardScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _startMenuMusic();
  }

  Future<void> _startMenuMusic() async {
    try {
      await SettingsNotifier.playBgm('bgm_menu.mp3');
    } catch (e) {
      debugPrint('Error playing menu bgm: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.surfaceDark,
        selectedItemColor: AppTheme.gold,
        unselectedItemColor: AppTheme.textMuted,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.play_arrow), label: 'Play'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Social'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Ranks'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _PlayTab extends ConsumerStatefulWidget {
  const _PlayTab();

  @override
  ConsumerState<_PlayTab> createState() => _PlayTabState();
}

class _PlayTabState extends ConsumerState<_PlayTab> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update UI every second if there's a countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkLivesAndProceed(BuildContext context, dynamic user, VoidCallback onProceed) {
    if (user.hasUnlimitedLives || user.currentLives > 0) {
      onProceed();
    } else {
      SettingsNotifier.playSfx('error.mp3');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Row(
            children: [
              Icon(Icons.favorite_border, color: AppTheme.redFort),
              SizedBox(width: 8),
              Text('Out of Lives', style: TextStyle(color: AppTheme.redFort, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'You have no lives left.\nPlease wait for them to refill to continue playing.',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: AppTheme.gold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserModelProvider);
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Center(
          child: userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox();
              return Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'FORT AL-KALIM',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Defend your fortress with Arabic words.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 60),
                        _buildPlayButton(
                          context,
                          'QUICK MATCH',
                          Icons.bolt,
                          () => _checkLivesAndProceed(context, user, () => _showLevelSelection(context, user.currentLevel, false)),
                        ),
                        const SizedBox(height: 24),
                        _buildPlayButton(
                          context,
                          'PLAY WITH AI',
                          Icons.smart_toy,
                          () => _checkLivesAndProceed(context, user, () => _showLevelSelection(context, user.currentLevel, true)),
                        ),
                        const SizedBox(height: 24),
                        _buildPlayButton(
                          context,
                          'WAR CAMP (FRIENDS)',
                          Icons.group,
                          () => _checkLivesAndProceed(context, user, () => context.push(Routes.roomsList)), 
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      children: [
                        if (user.currentStreak > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Row(
                              children: [
                                const Text('🔥 ', style: TextStyle(fontSize: 18)),
                                Text(
                                  '${user.currentStreak}',
                                  style: const TextStyle(color: AppTheme.gold, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        if (!user.hasUnlimitedLives && user.currentLives < 5 && user.timeUntilNextLife != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '${user.timeUntilNextLife!.inMinutes.toString().padLeft(2, '0')}:${(user.timeUntilNextLife!.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: user.hasUnlimitedLives ? AppTheme.gold : AppTheme.redFort.withOpacity(0.5)
                            ),
                            boxShadow: user.hasUnlimitedLives ? [
                              BoxShadow(color: AppTheme.gold.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)
                            ] : [],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                user.hasUnlimitedLives ? Icons.all_inclusive : Icons.favorite, 
                                color: user.hasUnlimitedLives ? AppTheme.gold : AppTheme.redFort, 
                                size: 20
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user.hasUnlimitedLives ? '∞' : '${user.currentLives}/5',
                                style: TextStyle(
                                  color: user.hasUnlimitedLives ? AppTheme.gold : Colors.white, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(color: AppTheme.gold),
            error: (_, __) => const Text('Error loading user data', style: TextStyle(color: AppTheme.redFort)),
          ),
        ),
      ),
    );
  }

  void _showLevelSelection(BuildContext context, int currentLevel, bool isAi) {
    const totalLevels = 45; // Match dictionary total levels
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAi ? 'Select Level (Vs AI)' : 'Select Level (PvP)',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.gold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: totalLevels,
                  itemBuilder: (context, index) {
                    final level = index + 1;
                    final isUnlocked = level <= currentLevel;
                    
                    return ListTile(
                      title: Text(
                        'Level $level', 
                        style: TextStyle(
                          color: isUnlocked ? AppTheme.textPrimary : AppTheme.textMuted, 
                          fontSize: 18,
                        )
                      ),
                      trailing: Icon(
                        isUnlocked ? Icons.play_arrow : Icons.lock, 
                        color: isUnlocked ? AppTheme.gold : AppTheme.textMuted
                      ),
                      onTap: () {
                        if (!isUnlocked) {
                          // Show locked info instead
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppTheme.surfaceDark,
                              title: const Text('Level Locked', style: TextStyle(color: AppTheme.redFort, fontWeight: FontWeight.bold)),
                              content: Text(
                                'You must complete Level $currentLevel and reach Level $level to play this stage.\n\nKeep playing matches and defeating enemies to level up!',
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    SettingsNotifier.playSfx('click.mp3');
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK', style: TextStyle(color: AppTheme.gold)),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        
                        context.pop(); // close bottom sheet
                        if (isAi) {
                          final uid = ref.read(currentUserProvider).value?.uid;
                          if (uid != null) {
                            final gameId = ref.read(matchmakingServiceProvider).createAiMatch(uid, level);
                            context.push('${Routes.readingPhase}?gameId=$gameId');
                          }
                        } else {
                          context.push('${Routes.matchmaking}?level=$level');
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayButton(BuildContext context, String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: () {
        SettingsNotifier.playSfx('click.mp3');
        onTap();
      },
      icon: Icon(icon, size: 28),
      label: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.gold,
        foregroundColor: AppTheme.backgroundDark,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        minimumSize: const Size(300, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
