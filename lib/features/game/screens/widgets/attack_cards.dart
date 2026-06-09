import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/groq_service.dart';
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
class SeeAttackCard extends StatelessWidget {
  final GameWord word;
  final List<GameWord> pool;
  final bool isLocked;
  final void Function(bool) onResult;

  const SeeAttackCard({super.key, required this.word, required this.pool, required this.isLocked, required this.onResult});

  @override
  Widget build(BuildContext context) {
    if (isLocked) return _buildLocked(word);

    final options = _getOptions(word, pool, true);

    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(word.emoji ?? '❓', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: options.map((opt) => ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.backgroundDark, foregroundColor: AppTheme.gold),
                onPressed: () => onResult(opt == word.arabicText),
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
class ListenAttackCard extends StatelessWidget {
  final GameWord word;
  final List<GameWord> pool;
  final bool isLocked;
  final void Function(bool) onResult;

  const ListenAttackCard({super.key, required this.word, required this.pool, required this.isLocked, required this.onResult});

  @override
  Widget build(BuildContext context) {
    if (isLocked) return _buildLocked(word);

    final options = _getOptions(word, pool, false);

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
                final tts = FlutterTts();
                await tts.setLanguage('ar');
                await tts.speak(word.arabicText);
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: options.map((opt) => ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.backgroundDark, foregroundColor: Colors.white),
                onPressed: () => onResult(opt == word.englishText),
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
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.backgroundDark, foregroundColor: AppTheme.gold),
              onPressed: () {
                widget.onResult(_currentTiles.join() == widget.word.tiles.join());
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
  final void Function(bool) onResult;

  const SpeakAttackCard({super.key, required this.word, required this.isLocked, required this.onResult});

  @override
  ConsumerState<SpeakAttackCard> createState() => _SpeakAttackCardState();
}

class _SpeakAttackCardState extends ConsumerState<SpeakAttackCard> {
  late AudioRecorder _record;
  bool _isListening = false;
  bool _isProcessing = false;
  String _statusText = 'Hold to Speak Arabic';

  @override
  void initState() {
    super.initState();
    _record = AudioRecorder();
  }

  @override
  void dispose() {
    _record.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _record.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/audio_temp.m4a';

        await _record.start(
          const RecordConfig(encoder: AudioEncoder.aacLc), 
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
    if (!_isListening) return;

    try {
      final path = await _record.stop();
      setState(() {
        _isListening = false;
        _isProcessing = true;
        _statusText = 'Transcribing with Groq...';
      });

      if (path != null) {
        final groq = ref.read(groqServiceProvider);
        
        final transcript = await groq.transcribeAudio(path);
        
        if (transcript != null) {
          setState(() => _statusText = 'Heard: "$transcript". Evaluating...');
          
          final isCorrect = await groq.evaluatePronunciation(transcript, widget.word.arabicText);
          
          setState(() {
            _statusText = isCorrect ? 'Match! Excellent.' : 'Mismatched. Word Locked.';
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
            const SizedBox(height: 12),
            
            if (_isProcessing)
              const CircularProgressIndicator(color: AppTheme.gold)
            else ...[
              GestureDetector(
                onLongPressStart: (_) => _startRecording(),
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
