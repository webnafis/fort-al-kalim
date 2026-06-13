import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/groq_service.dart';
import '../../../../data/services/settings_service.dart';
import '../../services/word_selection_service.dart';

// Helper to generate 3 wrong options from the pool of words
List<String> _getOptions(GameWord target, List<GameWord> pool, bool isArabic) {
  final options = {isArabic ? target.arabicText : target.englishText};
  final rnd = Random();
  while (options.length < 4 && options.length < pool.length) {
    final w = pool[rnd.nextInt(pool.length)];
    options.add(isArabic ? w.arabicText : w.englishText);
  }
  final out = options.toList();
  out.shuffle();
  return out;
}

// ---------------------------------------------------------
// SEE SECTION (Image -> 4 Arabic Words)
// ---------------------------------------------------------
class SeeAttackCard extends StatefulWidget {
  final GameWord word;
  final List<GameWord> pool;
  final bool isLocked;
  final void Function(bool) onResult;

  const SeeAttackCard({super.key, required this.word, required this.pool, required this.isLocked, required this.onResult});

  @override
  State<SeeAttackCard> createState() => _SeeAttackCardState();
}

class _SeeAttackCardState extends State<SeeAttackCard> {
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _options = _getOptions(widget.word, widget.pool, true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLocked) return _buildLocked(widget.word);

    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(widget.word.emoji ?? '❓', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _options.map((opt) => ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.backgroundDark, foregroundColor: AppTheme.gold),
                onPressed: () {
                  SettingsNotifier.playSfx('click.mp3');
                  final correct = opt == widget.word.arabicText;
                  widget.onResult(correct);
                  setState(() { _options.shuffle(); });
                },
                child: Text(opt, style: const TextStyle(fontFamily: 'Amiri', fontSize: 20)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// LISTEN SECTION (Audio -> 4 English Words)
// ---------------------------------------------------------
class ListenAttackCard extends ConsumerStatefulWidget {
  final GameWord word;
  final List<GameWord> pool;
  final bool isLocked;
  final void Function(bool) onResult;

  const ListenAttackCard({super.key, required this.word, required this.pool, required this.isLocked, required this.onResult});

  @override
  ConsumerState<ListenAttackCard> createState() => _ListenAttackCardState();
}

class _ListenAttackCardState extends ConsumerState<ListenAttackCard> {
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _options = _getOptions(widget.word, widget.pool, false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLocked) return _buildLocked(widget.word);

    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            IconButton(
              iconSize: 48,
              icon: const Icon(Icons.play_circle_fill, color: AppTheme.gold),
              onPressed: () async {
                SettingsNotifier.playSfx('click.mp3');
                try {
                  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
                    throw Exception('Bypassing native TTS on Windows to force Google Translate');
                  }
                  
                  final tts = FlutterTts();
                  final settings = ref.read(settingsProvider);
                  await tts.setVolume(settings.sfxVolume);
                  await tts.setLanguage('ar');
                  final result = await tts.speak(widget.word.arabicText);
                  if (result == 0) throw Exception('Native TTS failed');
                } catch (e) {
                  debugPrint('>>> TTS TRIGGER: $e');
                  try {
                    final player = AudioPlayer();
                    
                    player.onPlayerStateChanged.listen((state) {
                      debugPrint('>>> AudioPlayer State Changed: $state');
                    });
                    
                    final settings = ref.read(settingsProvider);
                    await player.setVolume(settings.sfxVolume);
                    
                    final url = 'https://translate.google.com/translate_tts?ie=UTF-8&q=${Uri.encodeComponent(widget.word.arabicText)}&tl=ar&client=tw-ob';
                    debugPrint('>>> Requesting Google Translate URL: $url');
                    
                    await player.play(UrlSource(url));
                  } catch (fallbackErr) {
                    debugPrint('>>> TTS FALLBACK CATCH BLOCK: $fallbackErr');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('TTS Fallback Error: $fallbackErr')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _options.map((opt) => ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.backgroundDark, foregroundColor: Colors.white),
                onPressed: () {
                  SettingsNotifier.playSfx('click.mp3');
                  final correct = opt == widget.word.englishText;
                  widget.onResult(correct);
                  setState(() { _options.shuffle(); });
                },
                child: Text(opt),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// WRITE SECTION (Draggable Tiles)
// ---------------------------------------------------------
class WriteAttackCard extends StatefulWidget {
  final GameWord word;
  final bool isLocked;
  final void Function(bool) onResult;

  const WriteAttackCard({super.key, required this.word, required this.isLocked, required this.onResult});

  @override
  State<WriteAttackCard> createState() => _WriteAttackCardState();
}

class _WriteAttackCardState extends State<WriteAttackCard> {
  late List<String> _currentTiles;
  
  @override
  void initState() {
    super.initState();
    _currentTiles = List.from(widget.word.tiles);
    _currentTiles.shuffle();
  }

  void _checkOrder() {
    final correct = widget.word.tiles.join() == _currentTiles.join();
    if (correct) {
      widget.onResult(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLocked) return _buildLocked(widget.word);

    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(widget.word.englishText, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ReorderableListView(
                  scrollDirection: Axis.horizontal,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _currentTiles.removeAt(oldIndex);
                    _currentTiles.insert(newIndex, item);
                  });
                },
                children: [
                  for (int i = 0; i < _currentTiles.length; i++)
                    Card(
                      key: ValueKey('$_currentTiles[$i]_$i'),
                      color: AppTheme.gold,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_currentTiles[i], style: const TextStyle(fontFamily: 'Amiri', fontSize: 24, color: Colors.black)),
                      ),
                    ),
                ],
              ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.backgroundDark, foregroundColor: AppTheme.gold),
              onPressed: () {
                SettingsNotifier.playSfx('click.mp3');
                final correct = _currentTiles.join() == widget.word.tiles.join();
                widget.onResult(correct);
                setState(() { _currentTiles.shuffle(); });
              },
              child: const Text('SUBMIT'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// SPEAK SECTION (Microphone with Groq API)
// ---------------------------------------------------------
class SpeakAttackCard extends ConsumerStatefulWidget {
  final GameWord word;
  final bool isLocked;
  final bool isPracticeMode;
  final void Function(bool) onResult;

  const SpeakAttackCard({super.key, required this.word, required this.isLocked, this.isPracticeMode = false, required this.onResult});

  @override
  ConsumerState<SpeakAttackCard> createState() => _SpeakAttackCardState();
}

class _SpeakAttackCardState extends ConsumerState<SpeakAttackCard> {
  AudioRecorder? _record;
  bool _isListening = false;
  bool _isProcessing = false;
  String _statusText = 'Hold mic and say the Arabic word';

  @override
  void dispose() {
    _record?.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      _record ??= AudioRecorder();
      if (await _record!.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/audio_temp.wav';

        await _record!.start(
          const RecordConfig(encoder: AudioEncoder.wav), 
          path: path
        );
        setState(() {
          _isListening = true;
          _statusText = 'Recording...';
        });
      } else {
        setState(() => _statusText = 'Microphone permission denied.');
      }
    } catch (e) {
      print('Record error: $e');
      setState(() => _statusText = 'Recording error.');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isListening || _record == null) return;

    try {
      final path = await _record!.stop();
      _record!.dispose();
      _record = null;
      
      setState(() {
        _isListening = false;
        _isProcessing = true;
        _statusText = 'Transcribing with Groq...';
      });

      if (path != null) {
        final groq = ref.read(groqServiceProvider);
        
        final transcript = await groq.transcribeAudio(path, expectedWord: widget.word.arabicText);
        
        if (transcript != null) {
          setState(() => _statusText = 'Heard: "$transcript"\nEvaluating...');
          
          final isCorrect = await groq.evaluatePronunciation(transcript, widget.word.arabicText);
          
          setState(() {
            _statusText = 'Heard: "$transcript"\nResult: ${isCorrect ? 'Match! Excellent.' : 'Mismatched. Word Locked.'}';
            _isProcessing = false;
          });

          widget.onResult(isCorrect);
        } else {
          setState(() {
            _statusText = 'Transcription failed.';
            _isProcessing = false;
          });
          widget.onResult(false);
        }
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      print('Stop record error: $e');
      setState(() {
        _isProcessing = false;
        _statusText = 'Error stopping recording.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLocked) return _buildLocked(widget.word);

    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(widget.word.englishText, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
            if (widget.isPracticeMode)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.word.arabicText, style: const TextStyle(fontSize: 32, color: AppTheme.gold, fontFamily: 'Amiri')),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: AppTheme.gold),
                      onPressed: () async {
                        SettingsNotifier.playSfx('click.mp3');
                        try {
                          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
                            throw Exception('Bypassing native TTS on Windows to force Google Translate');
                          }
                          final tts = FlutterTts();
                          final settings = ref.read(settingsProvider);
                          await tts.setVolume(settings.sfxVolume);
                          await tts.setLanguage('ar');
                          final result = await tts.speak(widget.word.arabicText);
                          if (result == 0) throw Exception('Native TTS failed');
                        } catch (e) {
                          try {
                            final player = AudioPlayer();
                            final settings = ref.read(settingsProvider);
                            await player.setVolume(settings.sfxVolume);
                            final url = 'https://translate.google.com/translate_tts?ie=UTF-8&q=${Uri.encodeComponent(widget.word.arabicText)}&tl=ar&client=tw-ob';
                            await player.play(UrlSource(url));
                          } catch (fallbackErr) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('TTS Error: $fallbackErr')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            
            if (_isProcessing)
              const CircularProgressIndicator(color: AppTheme.gold)
            else ...[
              GestureDetector(
                onLongPressStart: (_) {
                  SettingsNotifier.playSfx('click.mp3');
                  _startRecording();
                },
                onLongPressEnd: (_) => _stopRecording(),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: _isListening ? AppTheme.redFort : AppTheme.gold,
                  child: Icon(Icons.mic, size: 30, color: _isListening ? Colors.white : Colors.black),
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(_statusText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontFamily: 'Amiri')),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// LOCKED OVERLAY
// ---------------------------------------------------------
Widget _buildLocked(GameWord word) {
  return Card(
    color: AppTheme.surfaceDark.withOpacity(0.5),
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, color: AppTheme.redFort, size: 32),
          const SizedBox(width: 16),
          Text('${word.englishText}\nLOCKED (30s)', style: const TextStyle(color: AppTheme.redFort, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    ),
  );
}
