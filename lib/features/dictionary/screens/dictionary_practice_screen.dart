import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/settings_service.dart';
import '../services/dictionary_service.dart';
import '../../game/services/word_selection_service.dart' show GameWord;
import '../../game/screens/widgets/attack_cards.dart';

final dictionaryWordsStreamProvider = StreamProvider.autoDispose.family<List<GameWord>, ({String uid, int level, String practiceType})>((ref, args) {
  return ref.read(dictionaryServiceProvider)
      .streamWordsForLevel(args.uid, args.level)
      .map((dictWords) {
        int getUsage(DictionaryWord w) {
          switch (args.practiceType) {
            case 'listen': return w.listenUsage;
            case 'write': return w.writeUsage;
            case 'speak': return w.speakUsage;
            case 'see':
            default: return w.seeUsage;
          }
        }
        
        final mutableDictWords = List<DictionaryWord>.from(dictWords);
        mutableDictWords.sort((a, b) => getUsage(a).compareTo(getUsage(b)));
        return mutableDictWords.map((dw) => dw.toGameWord(getUsage(dw))).toList();
      });
});

class DictionaryPracticeScreen extends ConsumerStatefulWidget {
  final int level;
  final String practiceType; // 'see', 'listen', 'write', 'speak'
  final String? targetWordId;

  const DictionaryPracticeScreen({super.key, required this.level, required this.practiceType, this.targetWordId});

  @override
  ConsumerState<DictionaryPracticeScreen> createState() => _DictionaryPracticeScreenState();
}

class _DictionaryPracticeScreenState extends ConsumerState<DictionaryPracticeScreen> {
  int _currentIndex = 0;
  bool _showFeedback = false;
  bool _lastResultCorrect = false;
  bool _initializedSingleWord = false;

  void _onResult(bool correct, int poolLength) {
    setState(() {
      _showFeedback = true;
      _lastResultCorrect = correct;
    });

    // Automatically move to next word after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _showFeedback = false;
        if (correct && widget.targetWordId != null) {
          if (context.canPop()) context.pop();
        } else {
          if (widget.targetWordId == null) {
            _currentIndex = (_currentIndex + 1) % poolLength;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text('Practice: ${widget.practiceType.toUpperCase()}', style: const TextStyle(fontFamily: 'Amiri', color: AppTheme.gold)),
        backgroundColor: AppTheme.backgroundDark,
        iconTheme: const IconThemeData(color: AppTheme.gold),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final userAsync = ref.watch(currentUserModelProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) return const Center(child: Text("Not logged in", style: TextStyle(color: AppTheme.redFort)));
        
        final wordsAsync = ref.watch(dictionaryWordsStreamProvider((uid: user.uid, level: widget.level, practiceType: widget.practiceType)));
        
        return wordsAsync.when(
          data: (pool) {
            if (pool.isEmpty) {
              return const Center(child: Text('No words to practice.', style: TextStyle(color: AppTheme.textMuted)));
            }
            
            if (widget.targetWordId != null && !_initializedSingleWord) {
              final idx = pool.indexWhere((w) => w.id == widget.targetWordId);
              if (idx != -1) {
                _currentIndex = idx;
              }
              _initializedSingleWord = true;
            }

            // Ensure currentIndex is valid if pool size changes
            if (_currentIndex >= pool.length) {
              _currentIndex = 0;
            }

            final currentWord = pool[_currentIndex];

            return Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Card ${_currentIndex + 1} of ${pool.length}',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 400,
                          width: double.infinity,
                          child: _buildAttackCard(currentWord, pool),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (_showFeedback)
                  Container(
                    color: _lastResultCorrect ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8),
                    child: Center(
                      child: Icon(
                        _lastResultCorrect ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 100,
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
          error: (e, st) => Center(child: Text(e.toString(), style: const TextStyle(color: AppTheme.redFort))),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
      error: (e, st) => Center(child: Text(e.toString(), style: const TextStyle(color: AppTheme.redFort))),
    );
  }

  Widget _buildAttackCard(GameWord word, List<GameWord> pool) {
    void handleResult(bool correct) => _onResult(correct, pool.length);
    final wordKey = ValueKey('${word.arabicText}_${word.englishText}');

    switch (widget.practiceType) {
      case 'listen':
        return ListenAttackCard(key: wordKey, word: word, pool: pool, isLocked: false, onResult: handleResult);
      case 'write':
        return WriteAttackCard(key: wordKey, word: word, isLocked: false, onResult: handleResult);
      case 'speak':
        return SpeakAttackCard(key: wordKey, word: word, isLocked: false, isPracticeMode: true, onResult: handleResult);
      case 'see':
      default:
        return SeeAttackCard(key: wordKey, word: word, pool: pool, isLocked: false, onResult: handleResult);
    }
  }


}
