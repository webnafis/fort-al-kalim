import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../data/services/auth_service.dart';
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
    
    // Fetch game details to know players and level
    final gameDoc = await FirebaseFirestore.instance.collection('games').doc(widget.gameId).get();
    final gameData = gameDoc.data() ?? {};
    final p1 = gameData['player1'] ?? user.uid;
    final p2 = gameData['player2'] ?? 'AI_BOT';
    final level = gameData['level'] ?? user.currentLevel;

    final svc = ref.read(wordSelectionServiceProvider);
    final words = await svc.selectWordsForGame(p1, p2, level);
    
    if (mounted) {
      setState(() {
        _words = words;
        _isLoading = false;
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

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Text(
            'Review your arsenal. Your opponent might be ready before you are!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: uniqueWords.length,
            itemBuilder: (context, index) {
              final w = uniqueWords[index];
              return Card(
                color: AppTheme.surfaceDark,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.backgroundDark,
                    child: Text(w.emoji ?? '📜', style: const TextStyle(fontSize: 20)),
                  ),
                  title: Text(
                    w.arabicText,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 24,
                      color: AppTheme.gold,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  subtitle: Text(
                    w.englishText,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.volume_up, color: AppTheme.textSecondary),
                    onPressed: () async {
                      final tts = FlutterTts();
                      await tts.setLanguage('ar');
                      await tts.speak(w.arabicText);
                    },
                  ),
                ),
              );
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
            onPressed: () {
              // Start Combat! Pass the gameId
              context.go('${Routes.combat}?gameId=${widget.gameId}');
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
