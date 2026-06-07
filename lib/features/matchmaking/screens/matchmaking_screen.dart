import 'package:flutter/material.dart';

class MatchmakingScreen extends StatelessWidget {
  const MatchmakingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D1117),
    appBar: AppBar(title: const Text('Find Opponent'), backgroundColor: const Color(0xFF0D1117)),
    body: const Center(child: Text('Matchmaking — Phase 2', style: TextStyle(color: Colors.white54))),
  );
}
