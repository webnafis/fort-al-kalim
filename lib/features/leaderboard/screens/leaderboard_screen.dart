import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D1117),
    appBar: AppBar(title: const Text('Leaderboard'), backgroundColor: const Color(0xFF0D1117)),
    body: const Center(child: Text('Leaderboard — Phase 4', style: TextStyle(color: Colors.white54))),
  );
}
