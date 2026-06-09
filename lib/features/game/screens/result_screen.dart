import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flame_audio/flame_audio.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final String gameId;
  const ResultScreen({super.key, required this.gameId});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _isLoading = true;
  bool _isVictory = false;
  double _damageDealt = 0;
  bool _showLevelUp = false;

  @override
  void initState() {
    super.initState();
    _processResult();
  }

  Future<void> _processResult() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network check
    
    bool leveledUp = false;
    double damage = 200.0; // Simulated
    bool victory = true;   // Simulated

    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      try {
        final gameDoc = await FirebaseFirestore.instance.collection('games').doc(widget.gameId).get();
        final level = gameDoc.data()?['level'] ?? user.currentLevel;

        if (user.currentLevel == level) {
          final wordsSnapshot = await FirebaseFirestore.instance.collection('levels').doc('level_$level').collection('words').get();
          final progressSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('progress').doc('level_$level').get();
          
          if (progressSnapshot.exists && wordsSnapshot.docs.isNotEmpty) {
            final progress = progressSnapshot.data()!;
            bool allMastered = true;
            
            for (var wordDoc in wordsSnapshot.docs) {
              final id = wordDoc.id;
              final see = progress['${id}_see_usage'] ?? 0;
              final listen = progress['${id}_listen_usage'] ?? 0;
              final write = progress['${id}_write_usage'] ?? 0;
              final speak = progress['${id}_speak_usage'] ?? 0;
              
              if (see < 4 || listen < 4 || write < 4 || speak < 4) {
                allMastered = false;
                break;
              }
            }
            
            if (allMastered) leveledUp = true;
          }
        }
      } catch (e) {
        debugPrint("Error checking level up: $e");
      }
    }
    
    if (mounted) {
      setState(() {
        _isVictory = victory; 
        _damageDealt = damage;
        _showLevelUp = leveledUp;
        _isLoading = false;
      });
      
      _updateLifetimeScore(leveledUp);
    }
  }

  Future<void> _updateLifetimeScore(bool leveledUp) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.update({
        'lifetimeScore': FieldValue.increment(_damageDealt),
        'wins': _isVictory ? FieldValue.increment(1) : FieldValue.increment(0),
        'losses': !_isVictory ? FieldValue.increment(1) : FieldValue.increment(0),
        if (leveledUp) 'currentLevel': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint("Failed to update score: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.gold)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isVictory ? 'VICTORY' : 'DEFEAT',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: _isVictory ? AppTheme.gold : AppTheme.redFort,
                ),
              ),
              const SizedBox(height: 20),
              
              const Text('DAMAGE DEALT', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
              Text(
                '+${_damageDealt.toInt()}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              
              const SizedBox(height: 60),

              // Achievement Unlock Stub
              if (_isVictory)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.gold),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.emoji_events, color: AppTheme.gold, size: 40),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Achievement Unlocked!', style: TextStyle(color: AppTheme.gold, fontSize: 12)),
                            Text('First Blood', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () {
                  FlameAudio.play('click.mp3');
                  context.go(Routes.home);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.backgroundDark,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Return to Base', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              if (_showLevelUp) ...[
                const SizedBox(height: 40),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 2),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.gold, width: 4),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.upgrade, size: 64, color: AppTheme.gold),
                            Text('LEVEL UP!', style: TextStyle(color: AppTheme.gold, fontSize: 32, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
