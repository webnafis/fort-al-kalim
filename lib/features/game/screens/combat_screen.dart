import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flame_audio/flame_audio.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/settings_dialog.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/settings_service.dart';
import '../services/word_selection_service.dart';
import '../services/lock_timer_service.dart';

import '../flame/combat_game.dart';
import '../services/game_presence_service.dart';
import 'widgets/attack_cards.dart';

class CombatScreen extends ConsumerStatefulWidget {
  final String gameId;
  const CombatScreen({super.key, required this.gameId});

  @override
  ConsumerState<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends ConsumerState<CombatScreen> with WidgetsBindingObserver {
  late CombatGame _game;
  bool _isLoading = true;
  bool _isPaused = false;
  Map<String, List<GameWord>>? _words;
  Timer? _aiAttackTimer;
  final Map<String, int> _matchWordUsage = {};

  StreamSubscription? _missileSub;
  StreamSubscription? _gameSub;
  StreamSubscription<String>? _presenceSub;
  final Set<String> _processedMissiles = {};
  String? _myUid;
  String? _enemyUid;
  bool _isP1 = true;
  bool _gameOverTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = CombatGame();
    _loadData();
    _startBattleMusic();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // User left the app mid-game
      if (!_gameOverTriggered && _myUid != null) {
        FirebaseFirestore.instance.collection('games').doc(widget.gameId).update({
          'surrender': _myUid,
        });
      }
    }
  }

  Future<void> _startBattleMusic() async {
    try {
      await SettingsNotifier.playBgm('bgm_battle.mp3');
    } catch (e) {
      debugPrint('Error playing battle bgm: $e');
    }
  }

  Future<void> _loadData() async {
    final user = await ref.read(currentUserModelProvider.future);
    if (user == null) return;
    _myUid = user.uid;

    final gameDoc = await FirebaseFirestore.instance.collection('games').doc(widget.gameId).get();
    final gameData = gameDoc.data() ?? {};
    
    final p1 = gameData['player1'] ?? user.uid;
    final p2 = gameData['player2'] ?? 'AI_BOT';
    _isP1 = (user.uid == p1);
    _enemyUid = _isP1 ? p2 : p1;

    Map<String, List<GameWord>> words = {};
    if (gameData.containsKey('words')) {
      final rawWords = gameData['words'] as Map<String, dynamic>;
      rawWords.forEach((key, value) {
        words[key] = (value as List).map((e) => GameWord.fromJson(e as Map<String, dynamic>)).toList();
      });
    } else {
      final level = gameData['level'] ?? user.currentLevel;
      final svc = ref.read(wordSelectionServiceProvider);
      words = await svc.selectWordsForGame(p1, p2, level);
    }

    if (mounted) {
      setState(() {
        _words = words;
        _isLoading = false;
      });
      
      // Listen to the main game doc for surrenders
      _gameSub = FirebaseFirestore.instance.collection('games').doc(widget.gameId).snapshots().listen((doc) {
        if (!mounted || _gameOverTriggered) return;
        final data = doc.data() ?? {};
        if (data.containsKey('surrender')) {
          final surrenderUid = data['surrender'];
          if (surrenderUid == _myUid) {
            _game.playerHp = 0; // I surrendered
          } else {
            _game.enemyHp = 0; // Enemy surrendered
          }
          _checkGameOver();
        }
      });

      if (_enemyUid == 'AI_BOT') {
        _startAiSimulation();
      } else {
        _startMultiplayerListener();
        ref.read(gamePresenceServiceProvider).joinMatch(widget.gameId, _myUid!);
        _presenceSub = ref.read(gamePresenceServiceProvider).watchOpponentPresence(widget.gameId, _enemyUid!).listen((status) {
          if (!mounted || _gameOverTriggered) return;
          if (status == 'offline') {
            _game.enemyHp = 0; // Enemy crashed out
            _checkGameOver();
          }
        });
      }
    }
  }

  void _startMultiplayerListener() {
    _missileSub = FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .collection('missiles')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || _isPaused || _gameOverTriggered) return;
      
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final doc = change.doc;
          if (_processedMissiles.contains(doc.id)) continue;
          _processedMissiles.add(doc.id);
          
          final data = doc.data()!;
          final from = data['from'] as String;
          final type = data['type'] as String;
          final damage = (data['damage'] as num).toDouble();
          
          if (from == _myUid) {
            _game.fireMissileAtEnemy(type, damage, () {
              if (mounted) setState(() {});
              _checkGameOver();
            });
          } else {
            _game.fireMissileAtPlayer(type, damage, () {
              if (mounted) setState(() {});
              _checkGameOver();
            });
          }
        }
      }
    });
  }

  void _startAiSimulation() {
    final rnd = Random();
    _aiAttackTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _isPaused || _gameOverTriggered) return;
      if (rnd.nextBool()) {
        _game.fireMissileAtPlayer('read', 15.0, () {
          if (mounted) setState(() {});
          _checkGameOver();
        });
        setState(() {}); // refresh HP bar
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_myUid != null && _enemyUid != 'AI_BOT') {
      ref.read(gamePresenceServiceProvider).leaveMatch(widget.gameId, _myUid!);
    }
    _aiAttackTimer?.cancel();
    _presenceSub?.cancel();
    _missileSub?.cancel();
    _gameSub?.cancel();
    super.dispose();
  }

  void _checkGameOver() async {
    if (_gameOverTriggered) return;
    if (_game.playerHp <= 0 || _game.enemyHp <= 0) {
      _gameOverTriggered = true;
      // DO NOT cancel streams here. Let dispose() do it gracefully.
      _game.pauseEngine(); 
      FlameAudio.bgm.stop();
      
      bool isVictory = _game.playerHp > 0 && _game.enemyHp <= 0;
      
      // CRITICAL WINDOWS FIX: Delay navigation so Firestore background GRPC threads
      // can flush any pending snapshot updates before the screen is disposed and 
      // the channels are destroyed. Prevents native C++ segfault.
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        context.go('${Routes.result}?gameId=${widget.gameId}&victory=$isVictory');
      }
    }
    if (mounted) setState(() {});
  }

  void _onWordAction(GameWord word, String section, bool correct) {
    if (_gameOverTriggered) return;
    if (correct) {
      _matchWordUsage['${word.id}_$section'] = (_matchWordUsage['${word.id}_$section'] ?? 0) + 1;
      
      double damage = 10.0;
      if (section == 'see') damage = 5.0;
      if (section == 'listen') damage = 10.0;
      if (section == 'write') damage = 15.0;
      if (section == 'speak') damage = 25.0;

      if (_enemyUid == 'AI_BOT') {
        _game.fireMissileAtEnemy(section, damage, () {
          if (mounted) setState(() {});
          _checkGameOver();
        });
        
        // Also write the player's missile to Firestore so we can score it later
        FirebaseFirestore.instance
            .collection('games')
            .doc(widget.gameId)
            .collection('missiles')
            .add({
          'from': _myUid,
          'type': section,
          'damage': damage,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        final targetField = _isP1 ? 'player2Hp' : 'player1Hp';
        FirebaseFirestore.instance.collection('games').doc(widget.gameId).update({
          targetField: FieldValue.increment(-damage),
        });

        FirebaseFirestore.instance
            .collection('games')
            .doc(widget.gameId)
            .collection('missiles')
            .add({
          'from': _myUid,
          'type': section,
          'damage': damage,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      final user = ref.read(currentUserModelProvider).value;
      if (user != null) {
        FirebaseFirestore.instance.collection('games').doc(widget.gameId).get().then((doc) {
          final level = doc.data()?['level'] ?? user.currentLevel;
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('progress')
              .doc('level_$level')
              .set({
            '${word.id}_${section}_usage': FieldValue.increment(1),
          }, SetOptions(merge: true));
        });
      }
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
              height: MediaQuery.of(context).size.height * 0.45,
              child: Stack(
                children: [
                  GameWidget(game: _game),
                  // HUD Overlay
                  Positioned(
                    top: 8, left: 8, right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHpBar('YOU', _game.playerHp, Colors.blue),
                        IconButton(
                          icon: const Icon(Icons.pause, color: AppTheme.gold, size: 32),
                          onPressed: _showPauseMenu,
                        ),
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
                        Tab(text: 'SEE (⚔️5)', icon: Icon(Icons.visibility)),
                        Tab(text: 'LISTEN (⚔️10)', icon: Icon(Icons.headphones)),
                        Tab(text: 'WRITE (⚔️15)', icon: Icon(Icons.keyboard)),
                        Tab(text: 'SPEAK (⚔️25)', icon: Icon(Icons.mic)),
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

  void _showPauseMenu() {
    setState(() => _isPaused = true);
    SettingsNotifier.playSfx('click.mp3');

    final isAi = _enemyUid == 'AI_BOT';
    if (isAi) {
      _game.pauseEngine();
      FlameAudio.bgm.pause();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('GAME MENU', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPauseMenuButton('Resume', Icons.play_arrow, () {
                SettingsNotifier.playSfx('click.mp3');
                dialogContext.pop();
                setState(() => _isPaused = false);
                if (isAi) {
                  _game.resumeEngine();
                  FlameAudio.bgm.resume();
                  FlameAudio.bgm.audioPlayer?.setVolume(SettingsNotifier.currentMusicVolume);
                }
              }),
              const SizedBox(height: 12),
              _buildPauseMenuButton('Settings', Icons.settings, () async {
                dialogContext.pop();
                await showDialog(context: context, builder: (_) => const SettingsDialog());
                if (mounted && _isPaused) {
                  _showPauseMenu();
                }
              }),
              const SizedBox(height: 12),
              _buildPauseMenuButton('Restart', Icons.refresh, () {
                dialogContext.pop();
                Future.delayed(const Duration(milliseconds: 100), () => FlameAudio.bgm.stop());
                if (mounted) context.pushReplacement('${Routes.combat}?gameId=${widget.gameId}');
              }),
              const SizedBox(height: 12),
              _buildPauseMenuButton('Quit', Icons.exit_to_app, () async {
                dialogContext.pop();
                _gameOverTriggered = true;
                FlameAudio.bgm.stop();
                _game.playerHp = 0; // Force HP to 0 so damage calc knows we lost
                if (_myUid != null) {
                  FirebaseFirestore.instance.collection('games').doc(widget.gameId).update({
                    'surrender': _myUid,
                  });
                }
                
                // CRITICAL WINDOWS FIX: Delay navigation after Firestore write.
                await Future.delayed(const Duration(milliseconds: 400));
                if (mounted) {
                  context.go('${Routes.result}?gameId=${widget.gameId}&didQuit=true&victory=false');
                }
              }, isDanger: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPauseMenuButton(String text, IconData icon, VoidCallback onPressed, {bool isDanger = false}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: isDanger ? Colors.white : AppTheme.backgroundDark),
      label: Text(text, style: TextStyle(color: isDanger ? Colors.white : AppTheme.backgroundDark, fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDanger ? AppTheme.redFort : AppTheme.gold,
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildHpBar(String label, double hp, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ${hp.toInt()}/250', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            widthFactor: (hp / 250.0).clamp(0.0, 1.0),
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
        final usage = _matchWordUsage['${w.id}_$section'] ?? 0;
        
        if (usage >= 4) {
          return Card(
            color: AppTheme.surfaceDark.withOpacity(0.5),
            margin: const EdgeInsets.only(bottom: 12),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppTheme.gold, size: 32),
                  SizedBox(width: 16),
                  Text('MASTERED\n(Max Uses Reached)', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          );
        }

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
