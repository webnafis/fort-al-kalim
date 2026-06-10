import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/services/word_selection_service.dart' show GameWord;

class DictionaryWord {
  final String id;
  final String englishText;
  final String arabicText;
  final List<String> tiles;
  final String? emoji;
  final String? audioUrl;
  final int seeUsage;
  final int listenUsage;
  final int writeUsage;
  final int speakUsage;

  DictionaryWord({
    required this.id,
    required this.englishText,
    required this.arabicText,
    required this.tiles,
    this.emoji,
    this.audioUrl,
    required this.seeUsage,
    required this.listenUsage,
    required this.writeUsage,
    required this.speakUsage,
  });
  
  // Converts to GameWord for reusing AttackCards
  GameWord toGameWord(int usageType) {
    return GameWord(
      id: id,
      englishText: englishText,
      arabicText: arabicText,
      tiles: tiles,
      emoji: emoji,
      audioUrl: audioUrl,
      usageCount: usageType,
    );
  }
}

final dictionaryServiceProvider = Provider<DictionaryService>((ref) => DictionaryService());

class DictionaryService {
  final _firestore = FirebaseFirestore.instance;

  Future<List<DictionaryWord>> getWordsForLevel(String uid, int level) async {
    // 1. Fetch level words
    final wordsSnapshot = await _firestore
        .collection('levels')
        .doc('level_$level')
        .collection('words')
        .get();

    // 2. Fetch user progress
    final progressSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc('level_$level')
        .get();

    final progress = progressSnapshot.exists ? (progressSnapshot.data() ?? {}) : {};

    List<DictionaryWord> words = [];
    for (var doc in wordsSnapshot.docs) {
      final d = doc.data();
      final wordId = doc.id;

      words.add(DictionaryWord(
        id: wordId,
        englishText: d['english_text'] ?? '',
        arabicText: d['arabic_text'] ?? '',
        tiles: List<String>.from(d['write_tiles'] ?? []),
        emoji: d['emoji'],
        audioUrl: d['audio_url'],
        seeUsage: progress['${wordId}_see_usage'] ?? 0,
        listenUsage: progress['${wordId}_listen_usage'] ?? 0,
        writeUsage: progress['${wordId}_write_usage'] ?? 0,
        speakUsage: progress['${wordId}_speak_usage'] ?? 0,
      ));
    }
    return words;
  }
}
