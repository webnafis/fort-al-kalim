import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/groq_service.dart';
import '../../../data/services/settings_service.dart';
import '../services/word_selection_service.dart';

class ReadingPhaseScreen extends ConsumerStatefulWidget {
  final String gameId;
  const ReadingPhaseScreen({super.key, required this.gameId});

  @override
  ConsumerState<ReadingPhaseScreen> createState() => _ReadingPhaseScreenState();
}

class _ReadingPhaseScreenState extends ConsumerState<ReadingPhaseScreen> {
  Map<String, List<GameWord>>? _words;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final user = await ref.read(currentUserModelProvider.future);
    if (user == null) return;
    
    final docRef = FirebaseFirestore.instance.collection('games').doc(widget.gameId);
    final gameDoc = await docRef.get();
    final gameData = gameDoc.data() ?? {};
    final p1 = gameData['player1'] ?? user.uid;
    final p2 = gameData['player2'] ?? 'AI_BOT';
    final level = gameData['level'] ?? user.currentLevel;

    // Check if words already exist
    if (gameData.containsKey('words')) {
      final rawWords = gameData['words'] as Map<String, dynamic>;
      final Map<String, List<GameWord>> loadedWords = {};
      rawWords.forEach((key, value) {
        loadedWords[key] = (value as List).map((e) => GameWord.fromJson(e as Map<String, dynamic>)).toList();
      });
      if (mounted) {
        setState(() {
          _words = loadedWords;
          _isLoading = false;
        });
      }
      return;
    }

    // Host Generation
    if (user.uid == p1) {
      final svc = ref.read(wordSelectionServiceProvider);
      final words = await svc.selectWordsForGame(p1, p2, level);
      
      final Map<String, dynamic> wordsJson = {};
      words.forEach((key, list) {
        wordsJson[key] = list.map((w) => w.toJson()).toList();
      });
      await docRef.set({'words': wordsJson}, SetOptions(merge: true));
      
      if (mounted) {
        setState(() {
          _words = words;
          _isLoading = false;
        });
      }
    } else {
      // Client waiting for host
      docRef.snapshots().listen((snapshot) {
        if (!mounted) return;
        final data = snapshot.data();
        if (data != null && data.containsKey('words')) {
          final rawWords = data['words'] as Map<String, dynamic>;
          final Map<String, List<GameWord>> loadedWords = {};
          rawWords.forEach((key, value) {
            loadedWords[key] = (value as List).map((e) => GameWord.fromJson(e as Map<String, dynamic>)).toList();
          });
          setState(() {
            _words = loadedWords;
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Preparation Phase', style: TextStyle(fontFamily: 'Amiri', color: AppTheme.gold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Don't let them back out easily without resigning
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // Flatten words for easy viewing
    final allWords = <GameWord>[];
    _words?.values.forEach(allWords.addAll);
    // Deduplicate
    final uniqueWords = {for (var w in allWords) w.id: w}.values.toList();
    // Sort least used to most used
    uniqueWords.sort((a, b) => a.usageCount.compareTo(b.usageCount));

    return Column(
      children: [
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('games').doc(widget.gameId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            
            final currentUser = ref.read(currentUserModelProvider).value;
            final isP1 = data['player1'] == currentUser?.uid;
            
            final myReady = isP1 ? (data['p1Ready'] ?? false) : (data['p2Ready'] ?? false);
            final opponentReady = isP1 ? (data['p2Ready'] ?? false) : (data['p1Ready'] ?? false);
            final myHp = isP1 ? (data['player1Hp'] ?? 250) : (data['player2Hp'] ?? 250);
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                children: [
                  const Text(
                    'Review your arsenal. Test your pronunciation!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Your Fort: ⚔️ $myHp/250', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      Text(
                        opponentReady ? 'Opponent: READY!' : 'Opponent: Reviewing...', 
                        style: TextStyle(color: opponentReady ? AppTheme.redFort : AppTheme.gold, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: uniqueWords.length,
            itemBuilder: (context, index) {
              return ReviewWordCard(word: uniqueWords[index]);
            },
          ),
        ),

        // Bottom Action
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            border: Border(top: BorderSide(color: AppTheme.gold.withOpacity(0.5), width: 2)),
          ),
          child: ElevatedButton(
            onPressed: () async {
              SettingsNotifier.playSfx('click.mp3');
              // Update ready state in Firestore
              final currentUser = ref.read(currentUserModelProvider).value;
              if (currentUser != null) {
                final doc = await FirebaseFirestore.instance.collection('games').doc(widget.gameId).get();
                final data = doc.data() ?? {};
                final isP1 = data['player1'] == currentUser.uid;
                await FirebaseFirestore.instance.collection('games').doc(widget.gameId).update({
                  if (isP1) 'p1Ready': true else 'p2Ready': true,
                });
              }
              // Start Combat! Pass the gameId
              if (context.mounted) {
                context.go('${Routes.combat}?gameId=${widget.gameId}');
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 60),
              backgroundColor: AppTheme.redFort, // Aggressive color for going into battle
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: AppTheme.redFort.withOpacity(0.5),
            ),
            child: const Text(
              'ENTER THE ARENA',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class ReviewWordCard extends ConsumerStatefulWidget {
  final GameWord word;
  const ReviewWordCard({super.key, required this.word});

  @override
  ConsumerState<ReviewWordCard> createState() => _ReviewWordCardState();
}

class _ReviewWordCardState extends ConsumerState<ReviewWordCard> {
  AudioRecorder? _record;
  bool _isRecording = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _record?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      await SettingsNotifier.pauseBgm();
      _record ??= AudioRecorder();
      if (await _record!.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/review_test.wav';
        await _record!.start(
          const RecordConfig(encoder: AudioEncoder.wav), 
          path: path,
        );
        setState(() => _isRecording = true);
      } else {
        await SettingsNotifier.resumeBgm();
      }
    } catch (e) {
      await SettingsNotifier.resumeBgm();
      debugPrint('Record error: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _record == null) return;
    try {
      final path = await _record!.stop();
      // We can dispose it immediately to free up resources
      _record!.dispose();
      _record = null;
      
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      if (path != null) {
        final groq = ref.read(groqServiceProvider);
        final transcript = await groq.transcribeAudio(path, expectedWord: widget.word.arabicText);
        
        if (transcript != null) {
          final isMatch = await groq.evaluatePronunciation(transcript, widget.word.arabicText);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(isMatch ? 'Perfect! (Match)' : 'Heard: "$transcript"\nExpected: ${widget.word.arabicText}'),
              backgroundColor: isMatch ? Colors.green : AppTheme.redFort,
              duration: const Duration(seconds: 4),
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Stop record error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      await SettingsNotifier.resumeBgm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _isRecording ? AppTheme.redFort.withOpacity(0.2) : AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: _isRecording ? AppTheme.redFort : AppTheme.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.backgroundDark,
          child: Text(widget.word.emoji ?? '📜', style: const TextStyle(fontSize: 20)),
        ),
        title: Text(
          widget.word.arabicText,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 24,
            color: AppTheme.gold,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.right,
        ),
        subtitle: _isProcessing
            ? const Text('Evaluating...', style: TextStyle(color: AppTheme.gold, fontStyle: FontStyle.italic))
            : Text(widget.word.englishText, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? AppTheme.redFort : Colors.transparent,
                ),
                child: _isProcessing 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.gold, strokeWidth: 2))
                    : Icon(
                        _isRecording ? Icons.mic : Icons.mic_none, 
                        color: _isRecording ? Colors.white : AppTheme.gold,
                      ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up, color: AppTheme.gold),
              onPressed: () async {
                SettingsNotifier.playSfx('click.mp3');
                await SettingsNotifier.pauseBgm();
                try {
                  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
                    throw Exception('Bypassing native TTS on Windows');
                  }
                  final tts = FlutterTts();
                  final settings = ref.read(settingsProvider);
                  await tts.awaitSpeakCompletion(true);
                  await tts.setVolume(settings.sfxVolume);
                  await tts.setLanguage('ar');
                  final res = await tts.speak(widget.word.arabicText);
                  if (res == 0) throw Exception('Native TTS failed');
                  await SettingsNotifier.resumeBgm();
                } catch (e) {
                  try {
                    final player = AudioPlayer();
                    
                    player.onPlayerComplete.listen((_) {
                      SettingsNotifier.resumeBgm();
                    });
                    player.onPlayerStateChanged.listen((state) {
                      if (state == PlayerState.stopped || state == PlayerState.disposed) {
                        SettingsNotifier.resumeBgm();
                      }
                    });
                    
                    final settings = ref.read(settingsProvider);
                    await player.setVolume(settings.sfxVolume);
                    final url = 'https://translate.google.com/translate_tts?ie=UTF-8&q=${Uri.encodeComponent(widget.word.arabicText)}&tl=ar&client=tw-ob';
                    await player.play(UrlSource(url));
                  } catch (fallbackErr) {
                    await SettingsNotifier.resumeBgm();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('TTS Error: $fallbackErr')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
