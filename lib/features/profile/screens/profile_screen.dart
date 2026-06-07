import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D1117),
    appBar: AppBar(title: const Text('Profile'), backgroundColor: const Color(0xFF0D1117)),
    body: const Center(child: Text('Profile — Phase 4', style: TextStyle(color: Colors.white54))),
  );
}
