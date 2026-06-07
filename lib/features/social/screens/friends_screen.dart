import 'package:flutter/material.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D1117),
    appBar: AppBar(title: const Text('Friends'), backgroundColor: const Color(0xFF0D1117)),
    body: const Center(child: Text('Friends — Phase 4', style: TextStyle(color: Colors.white54))),
  );
}
