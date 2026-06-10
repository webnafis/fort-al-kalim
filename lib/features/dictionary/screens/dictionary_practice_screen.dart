import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/settings_service.dart';
import '../services/dictionary_service.dart';
import '../../game/services/word_selection_service.dart' show GameWord;
import '../../game/screens/widgets/attack_cards.dart';

class DictionaryPracticeScreen extends ConsumerStatefulWidget {
  final int level;
  final String practiceType; // 'see', 'listen', 'write', 'speak'

  const DictionaryPracticeScreen({super.key, required this.level, required this.practiceType});

  @override
  ConsumerState<DictionaryPracticeScreen> createState() => _DictionaryPracticeScreenState();
}

class _DictionaryPracticeScreenState extends ConsumerState<DictionaryPracticeScreen> {
  List<GameWord>? _pool;
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;
  
  bool _showFeedback = false;
  bool _lastResultCorrect = false;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    try {
      final user = await ref.read(currentUserModelProvider.future);
      if (user == null) {
        setState(() => _error = "Not logged in");
        return;
      }
      final dictWords = await ref.read(dictionaryServiceProvider).getWordsForLevel(user.uid, widget.level);
      
      // Convert DictionaryWord to GameWord and sort by the specific usage
      int getUsage(DictionaryWord w) {
        switch (widget.practiceType) {
          case 'listen': return w.listenUsage;
          case 'write': return w.writeUsage;
          case 'speak': return w.speakUsage;
          case 'see':
          default: return w.seeUsage;
        }
      }
      
      dictWords.sort((a, b) => getUsage(a).compareTo(getUsage(b)));
      
      // Convert to GameWord so AttackCards can use them
      final gameWords = dictWords.map((dw) => dw.toGameWord(getUsage(dw))).toList();
      
      if (mounted) {
        setState(() {
          _pool = gameWords;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onResult(bool correct) {
    setState(() {
      _showFeedback = true;
      _lastResultCorrect = correct;
    });

    // Automatically move to next word after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _showFeedback = false;
        // Loop back to start if at end
        _currentIndex = (_currentIndex + 1) % _pool!.length;
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: AppTheme.redFort)));
    }
    if (_pool == null || _pool!.isEmpty) {
      return const Center(child: Text('No words to practice.', style: TextStyle(color: AppTheme.textMuted)));
    }

    final currentWord = _pool![_currentIndex];

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Card ${_currentIndex + 1} of ${_pool!.length}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
                ),
                const SizedBox(height: 24),
                // Wrap the AttackCard in a fixed height container or let it expand
                SizedBox(
                  height: 400,
                  width: double.infinity,
                  child: _buildAttackCard(currentWord),
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
  }

  Widget _buildAttackCard(GameWord word) {
    switch (widget.practiceType) {
      case 'listen':
        return ListenAttackCard(word: word, pool: _pool!, isLocked: false, onResult: _onResult);
      case 'write':
        return WriteAttackCard(word: word, isLocked: false, onResult: _onResult);
      case 'speak':
        return SpeakAttackCard(word: word, isLocked: false, onResult: _onResult);
      case 'see':
      default:
        return SeeAttackCard(word: word, pool: _pool!, isLocked: false, onResult: _onResult);
    }
  }
}
