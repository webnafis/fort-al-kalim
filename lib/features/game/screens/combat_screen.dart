import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';
import '../services/word_selection_service.dart';
import '../services/lock_timer_service.dart';
import '../flame/combat_game.dart';
import 'widgets/attack_cards.dart';

class CombatScreen extends ConsumerStatefulWidget {
  final String gameId;
  const CombatScreen({super.key, required this.gameId});

  @override
  ConsumerState<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends ConsumerState<CombatScreen> {
  late CombatGame _game;
  bool _isLoading = true;
  Map<String, List<GameWord>>? _words;
  Timer? _aiAttackTimer;

  @override
  void initState() {
    super.initState();
    _game = CombatGame();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await ref.read(currentUserModelProvider.future);
    if (user == null) return;

    final svc = ref.read(wordSelectionServiceProvider);
    final words = await svc.selectWordsForGame(user.uid, user.currentLevel);

    if (mounted) {
      setState(() {
        _words = words;
        _isLoading = false;
      });
      _startAiSimulation();
    }
  }

  void _startAiSimulation() {
    // Just for demo, AI fires a missile every 3-8 seconds
    final rnd = Random();
    _aiAttackTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (rnd.nextBool()) {
        _game.fireMissileAtPlayer('read', 5.0, () {
          _checkGameOver();
        });
        setState(() {}); // refresh HP bar
      }
    });
  }

  @override
  void dispose() {
    _aiAttackTimer?.cancel();
    super.dispose();
  }

  void _checkGameOver() {
    if (_game.playerHp <= 0 || _game.enemyHp <= 0) {
      _aiAttackTimer?.cancel();
      context.go('${Routes.result}?gameId=${widget.gameId}');
    }
    setState(() {}); // force HP bar rebuild
  }

  void _onWordAction(GameWord word, String section, bool correct) {
    if (correct) {
      // Fire missile!
      _game.fireMissileAtEnemy(section, word.baseDamage, () {
        _checkGameOver();
      });
      // In a real app, reduce AP in Firestore here.
    } else {
      // Lock the word
      ref.read(lockTimerServiceProvider).lockWord(word.id);
    }
    setState(() {});
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
        child: Column(
          children: [
            // TOP HALF: FLAME ENGINE
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: Stack(
                children: [
                  GameWidget(game: _game),
                  // HUD Overlay
                  Positioned(
                    top: 8, left: 8, right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHpBar('YOU', _game.playerHp, Colors.blue),
                        _buildHpBar('ENEMY', _game.enemyHp, AppTheme.redFort),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // BOTTOM HALF: FLUTTER TABS
            Expanded(
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    const TabBar(
                      indicatorColor: AppTheme.gold,
                      labelColor: AppTheme.gold,
                      unselectedLabelColor: AppTheme.textMuted,
                      tabs: [
                        Tab(text: 'SEE', icon: Icon(Icons.visibility)),
                        Tab(text: 'LISTEN', icon: Icon(Icons.headphones)),
                        Tab(text: 'WRITE', icon: Icon(Icons.keyboard)),
                        Tab(text: 'SPEAK', icon: Icon(Icons.mic)),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildSectionList('see', _words!['see']!),
                          _buildSectionList('listen', _words!['listen']!),
                          _buildSectionList('write', _words!['write']!),
                          _buildSectionList('speak', _words!['speak']!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHpBar(String label, double hp, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ${hp.toInt()}/200', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: 120,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (hp / 200.0).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionList(String section, List<GameWord> words) {
    if (words.isEmpty) {
      return const Center(child: Text('No words assigned to this section.'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final w = words[index];
        final isLocked = ref.watch(lockTimerServiceProvider).isLocked(w.id);
        
        final onResult = (bool correct) {
          _onWordAction(w, section, correct);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(correct ? 'Attack Successful!' : 'Attack Failed! Word Locked.'),
            backgroundColor: correct ? Colors.green : AppTheme.redFort,
            duration: const Duration(seconds: 1),
          ));
        };

        if (section == 'see') {
          return SeeAttackCard(word: w, pool: words, isLocked: isLocked, onResult: onResult);
        } else if (section == 'listen') {
          return ListenAttackCard(word: w, pool: words, isLocked: isLocked, onResult: onResult);
        } else if (section == 'write') {
          return WriteAttackCard(word: w, isLocked: isLocked, onResult: onResult);
        } else if (section == 'speak') {
          return SpeakAttackCard(word: w, isLocked: isLocked, onResult: onResult);
        }
        return const SizedBox();
      },
    );
  }
}
