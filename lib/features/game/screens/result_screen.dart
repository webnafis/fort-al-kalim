import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String gameId;
  const ResultScreen({super.key, required this.gameId});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D1117),
    appBar: AppBar(title: const Text('Result'), backgroundColor: const Color(0xFF0D1117)),
    body: Center(child: Text('Result [$gameId] — Phase 3', style: const TextStyle(color: Colors.white54))),
  );
}
