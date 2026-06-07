import 'package:flutter/material.dart';

class FriendRoomScreen extends StatelessWidget {
  final String? roomCode;
  const FriendRoomScreen({super.key, this.roomCode});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D1117),
    appBar: AppBar(title: const Text('Friend Room'), backgroundColor: const Color(0xFF0D1117)),
    body: Center(child: Text('Friend Room${roomCode != null ? ": $roomCode" : ""} — Phase 2', style: const TextStyle(color: Colors.white54))),
  );
}
