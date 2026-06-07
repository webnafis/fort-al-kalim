import 'package:flutter/material.dart';

class ReadingPhaseScreen extends StatelessWidget {
  final String gameId;
  const ReadingPhaseScreen({super.key, required this.gameId});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D1117),
    appBar: AppBar(title: const Text('Reading Phase'), backgroundColor: const Color(0xFF0D1117)),
    body: Center(child: Text('Reading Phase [$gameId] — Phase 3', style: const TextStyle(color: Colors.white54))),
  );
}
