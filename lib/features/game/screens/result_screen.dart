import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flame_audio/flame_audio.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/achievements.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/settings_service.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final String gameId;
  final bool didQuit;
  final bool victory;
  const ResultScreen({super.key, required this.gameId, this.didQuit = false, this.victory = false});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _isLoading = true;
  bool _isVictory = false;
  double _damageDealt = 0;
  bool _showLevelUp = false;
  List<Achievement> _newUnlocked = [];

  @override
  void initState() {
    super.initState();
    _processResult();
  }

  Future<void> _processResult() async {
    final user = await ref.read(currentUserModelProvider.future);
    if (user == null) return;
    
    bool leveledUp = false;
    double totalDamage = 0.0;

    try {
      // 1. Calculate Damage Dealt
      final missilesSnap = await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .collection('missiles')
          .where('from', isEqualTo: user.uid)
          .get();

      for (var doc in missilesSnap.docs) {
        totalDamage += (doc.data()['damage'] as num).toDouble();
      }
      
      // If we quit, we still keep the damage we successfully dealt as score!
      // But if we quit without firing, it's 0.
    } catch (e) {
      debugPrint("Error fetching missiles: $e");
    }

    // 2. Check Victory Condition
    bool victory = widget.victory;
    if (widget.didQuit) {
      victory = false;
    }

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
    
    if (mounted) {
      setState(() {
        _isVictory = victory; 
        _damageDealt = totalDamage;
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
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;
        
        final d = snapshot.data()!;
        int dbLives = d['lives'] ?? 5;
        int currentLevel = d['currentLevel'] ?? 1;
        double currentScore = (d['lifetimeScore'] ?? 0).toDouble();
        int currentWins = d['wins'] ?? 0;
        int currentLosses = d['losses'] ?? 0;
        List<String> unlockedIds = List<String>.from(d['unlockedAchievements'] ?? []);
        Timestamp? lastRefillTs = d['lastLifeRefillTime'];
        DateTime? lastRefill = lastRefillTs?.toDate();

        int currentStreak = d['currentStreak'] ?? 0;
        Timestamp? lastMatchTs = d['lastMatchDate'];
        DateTime? lastMatchDate = lastMatchTs?.toDate();
        Timestamp? unlimitedUntilTs = d['unlimitedLivesUntil'];
        DateTime? unlimitedLivesUntil = unlimitedUntilTs?.toDate();
        
        int currentLives = dbLives;
        if (lastRefill != null && dbLives < 5) {
           final minutesPassed = DateTime.now().difference(lastRefill).inMinutes;
           final earned = minutesPassed ~/ 30;
           currentLives = (dbLives + earned).clamp(0, 5);
           
           if (currentLives < 5) {
              lastRefill = lastRefill.add(Duration(minutes: 30 * earned));
           } else {
              lastRefill = null;
           }
        }

        bool hasUnlimitedLives = unlimitedLivesUntil != null && unlimitedLivesUntil.isAfter(DateTime.now());

        if (!_isVictory && currentLives > 0 && !hasUnlimitedLives) {
            if (currentLives == 5) {
                lastRefill = DateTime.now();
            }
            currentLives -= 1;
        }

        // Streak Evaluation
        DateTime now = DateTime.now();
        DateTime todayMidnight = DateTime(now.year, now.month, now.day);
        
        int newStreak = currentStreak;
        if (lastMatchDate == null) {
          newStreak = 1;
        } else {
          DateTime lastMidnight = DateTime(lastMatchDate.year, lastMatchDate.month, lastMatchDate.day);
          int diffDays = todayMidnight.difference(lastMidnight).inDays;
          
          if (diffDays == 1) {
            newStreak += 1; // consecutive day
          } else if (diffDays > 1) {
            newStreak = 1; // missed a day, reset
          }
          // if diffDays == 0, same day, do nothing
        }

        // Reward Evaluation
        DateTime? newUnlimitedUntil = unlimitedLivesUntil;
        if (newStreak > currentStreak && newStreak > 0 && newStreak % 7 == 0) {
          // Grant 24 hours of unlimited lives
          newUnlimitedUntil = now.add(const Duration(days: 1));
        }

        // Evaluate achievements with new stats
        final newWins = _isVictory ? currentWins + 1 : currentWins;
        final newLosses = !_isVictory ? currentLosses + 1 : currentLosses;
        final newScore = currentScore + _damageDealt;
        final newLevel = leveledUp ? currentLevel + 1 : currentLevel;

        final evaluated = evaluateAchievements(
          currentLevel: newLevel,
          lifetimeScore: newScore,
          wins: newWins,
          losses: newLosses,
        );

        // Find which are newly unlocked this game
        List<String> newlyUnlockedIds = [];
        for (var id in evaluated) {
          if (!unlockedIds.contains(id)) {
            newlyUnlockedIds.add(id);
            unlockedIds.add(id);
          }
        }
        
        transaction.update(userRef, {
           'lifetimeScore': FieldValue.increment(_damageDealt),
           'wins': _isVictory ? FieldValue.increment(1) : FieldValue.increment(0),
           'losses': !_isVictory ? FieldValue.increment(1) : FieldValue.increment(0),
           'lives': currentLives,
           'unlockedAchievements': unlockedIds,
           'currentStreak': newStreak,
           'lastMatchDate': Timestamp.fromDate(now),
           'unlimitedLivesUntil': newUnlimitedUntil != null ? Timestamp.fromDate(newUnlimitedUntil) : null,
           'lastLifeRefillTime': lastRefill != null ? Timestamp.fromDate(lastRefill) : null,
           if (leveledUp) 'currentLevel': FieldValue.increment(1),
        });

        // Map IDs back to objects for the UI
        if (newlyUnlockedIds.isNotEmpty && mounted) {
           setState(() {
              _newUnlocked = kAllAchievements.where((a) => newlyUnlockedIds.contains(a.id)).toList();
           });
        }
      });
    } catch (e) {
      debugPrint("Failed to update score and lives: $e");
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

              // Achievement Banners
              if (_newUnlocked.isNotEmpty)
                Column(
                  children: _newUnlocked.map((achievement) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.gold),
                      ),
                      child: Row(
                        children: [
                          Image.asset(achievement.imagePath, width: 48, height: 48),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Achievement Unlocked!', style: TextStyle(color: AppTheme.gold, fontSize: 12)),
                                Text(achievement.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: () {
                  SettingsNotifier.playSfx('click.mp3');
                  context.go(Routes.home);
                },
                icon: const Icon(Icons.home, size: 28),
                label: const Text('Return to Base', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.backgroundDark,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
