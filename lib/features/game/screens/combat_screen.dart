import 'package:flutter/material.dart';

class CombatScreen extends StatelessWidget {
  final String gameId;
  const CombatScreen({super.key, required this.gameId});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D1117),
    appBar: AppBar(title: const Text('Combat'), backgroundColor: const Color(0xFF0D1117)),
    body: Center(child: Text('Combat [$gameId] — Phase 3', style: const TextStyle(color: Colors.white54))),
  );
}
