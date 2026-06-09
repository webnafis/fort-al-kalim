import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../leaderboard/screens/leaderboard_screen.dart';
import '../../social/screens/friends_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../data/services/auth_service.dart';

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
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play('bgm_menu.mp3');
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
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Social'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Ranks'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _PlayTab extends ConsumerWidget {
  const _PlayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Center(
          child: userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox();
              return Column(
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
                    () => _showLevelSelection(context, user.currentLevel),
                  ),
                  const SizedBox(height: 24),
                  _buildPlayButton(
                    context,
                    'PLAY WITH FRIEND',
                    Icons.group,
                    () => context.push(Routes.friendRoom),
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

  void _showLevelSelection(BuildContext context, int maxLevel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Level',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.gold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: maxLevel,
                  itemBuilder: (context, index) {
                    final level = index + 1;
                    return ListTile(
                      title: Text('Level $level', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
                      trailing: const Icon(Icons.play_arrow, color: AppTheme.gold),
                      onTap: () {
                        context.pop(); // close bottom sheet
                        context.push('${Routes.matchmaking}?level=$level');
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
        FlameAudio.play('click.mp3');
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
