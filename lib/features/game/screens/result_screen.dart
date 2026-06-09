import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    // In a real app, we would query the games/{gameId} node to see who won
    // For this prototype, we'll randomize or assume victory based on a coin flip
    // to simulate the end of a match.
    
    await Future.delayed(const Duration(seconds: 2)); // Simulate network check
    
    if (mounted) {
      setState(() {
        // Just simulating a victory for the showcase
        _isVictory = true; 
        _damageDealt = 200.0; // We destroyed their fort!
        // Simulate a level up 50% of the time on victory
        _showLevelUp = Random().nextBool();
        _isLoading = false;
      });
      
      _updateLifetimeScore();
    }
  }

  Future<void> _updateLifetimeScore() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.update({
        'lifetimeScore': FieldValue.increment(_damageDealt),
        'wins': _isVictory ? FieldValue.increment(1) : FieldValue.increment(0),
        'losses': !_isVictory ? FieldValue.increment(1) : FieldValue.increment(0),
        if (_showLevelUp) 'currentLevel': FieldValue.increment(1),
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
              ElevatedButton.icon(
                onPressed: () {
                  context.go(Routes.home);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  backgroundColor: AppTheme.surfaceDark,
                  foregroundColor: AppTheme.textPrimary,
                  side: BorderSide(color: AppTheme.gold.withOpacity(0.5)),
                ),
                icon: const Icon(Icons.home),
                label: const Text('RETURN TO CAMP', style: TextStyle(fontSize: 18, letterSpacing: 2)),
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
