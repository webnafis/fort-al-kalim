import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../leaderboard/screens/leaderboard_screen.dart';
import '../../social/screens/friends_screen.dart';
import '../../profile/screens/profile_screen.dart';

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

class _PlayTab extends StatelessWidget {
  const _PlayTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Center(
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
                () => context.push(Routes.matchmaking),
              ),
              const SizedBox(height: 24),
              _buildPlayButton(
                context,
                'PLAY WITH FRIEND',
                Icons.group,
                () => context.push(Routes.friendRoom),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context, String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
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
