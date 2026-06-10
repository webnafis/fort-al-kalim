import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wordSelectionServiceProvider = Provider((ref) => WordSelectionService());

class GameWord {
  final String id;
  final String englishText;
  final String arabicText;
  final List<String> tiles;
  final String? emoji;
  final String? audioUrl;
  final int usageCount;

  GameWord({
    required this.id,
    required this.englishText,
    required this.arabicText,
    required this.tiles,
    this.emoji,
    this.audioUrl,
    required this.usageCount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'englishText': englishText,
    'arabicText': arabicText,
    'tiles': tiles,
    'emoji': emoji,
    'audioUrl': audioUrl,
    'usageCount': usageCount,
  };

  factory GameWord.fromJson(Map<String, dynamic> json) => GameWord(
    id: json['id'] ?? '',
    englishText: json['englishText'] ?? '',
    arabicText: json['arabicText'] ?? '',
    tiles: List<String>.from(json['tiles'] ?? []),
    emoji: json['emoji'],
    audioUrl: json['audioUrl'],
    usageCount: json['usageCount'] ?? 0,
  );
}

class WordSelectionService {
  final _firestore = FirebaseFirestore.instance;

  /// Fetches lowest used words for both players and combines them.
  Future<Map<String, List<GameWord>>> selectWordsForGame(
      String player1Uid, String player2Uid, int level) async {
    // 1. Fetch the 100 level words
    final wordsSnapshot = await _firestore
        .collection('levels')
        .doc('level_$level')
        .collection('words')
        .get();

    // 2. Fetch progress for both players
    final p1ProgressSnapshot = await _firestore
        .collection('users')
        .doc(player1Uid)
        .collection('progress')
        .doc('level_$level')
        .get();

    Map<String, dynamic> p1Progress =
        p1ProgressSnapshot.exists ? (p1ProgressSnapshot.data() ?? {}) : {};

    Map<String, dynamic> p2Progress = {};
    if (player2Uid != 'AI_BOT') {
      final p2ProgressSnapshot = await _firestore
          .collection('users')
          .doc(player2Uid)
          .collection('progress')
          .doc('level_$level')
          .get();
      p2Progress = p2ProgressSnapshot.exists ? (p2ProgressSnapshot.data() ?? {}) : {};
    }

    List<Map<String, dynamic>> allWords = [];
    for (var doc in wordsSnapshot.docs) {
      final d = doc.data();
      final wordId = doc.id;

      // Usage starts at 0. Max 4.
      allWords.add({
        'id': wordId,
        'english_text': d['english_text'] ?? '',
        'arabic_text': d['arabic_text'] ?? '',
        'write_tiles': List<String>.from(d['write_tiles'] ?? []),
        'emoji': d['emoji'],
        'audio_url': d['audio_url'],
        'p1_see': p1Progress['${wordId}_see_usage'] ?? 0,
        'p1_listen': p1Progress['${wordId}_listen_usage'] ?? 0,
        'p1_write': p1Progress['${wordId}_write_usage'] ?? 0,
        'p1_speak': p1Progress['${wordId}_speak_usage'] ?? 0,
        'p2_see': p2Progress['${wordId}_see_usage'] ?? 0,
        'p2_listen': p2Progress['${wordId}_listen_usage'] ?? 0,
        'p2_write': p2Progress['${wordId}_write_usage'] ?? 0,
        'p2_speak': p2Progress['${wordId}_speak_usage'] ?? 0,
      });
    }

    if (allWords.isEmpty) return {'see': [], 'listen': [], 'write': [], 'speak': []};

    List<GameWord> pick10Words(String p1Key, String p2Key) {
      // Exclude words that have reached 4 usages for BOTH players?
      // For now, we just pick the lowest used words regardless, since if all are 4, level is mastered.
      
      var p1Sorted = List.of(allWords)..sort((a, b) => (a[p1Key] as int).compareTo(b[p1Key] as int));
      var p2Sorted = List.of(allWords)..sort((a, b) => (a[p2Key] as int).compareTo(b[p2Key] as int));

      List<Map<String, dynamic>> selected = [];
      Set<String> selectedIds = {};

      // Take 5 from Player 1
      for (var w in p1Sorted) {
        if (selected.length >= 5) break;
        selected.add(w);
        selectedIds.add(w['id']);
      }

      // Take 5 from Player 2, skipping duplicates
      int p2Count = 0;
      for (var w in p2Sorted) {
        if (p2Count >= 5) break;
        if (!selectedIds.contains(w['id'])) {
          selected.add(w);
          selectedIds.add(w['id']);
          p2Count++;
        }
      }

      // If we didn't get 10 words total (because of overlaps or small word pool), pad with remaining
      if (selected.length < 10) {
        for (var w in p1Sorted) {
          if (selected.length >= 10) break;
          if (!selectedIds.contains(w['id'])) {
            selected.add(w);
            selectedIds.add(w['id']);
          }
        }
      }

      // Sort the 10 words from least used to most used
      selected.sort((a, b) => (a[p1Key] as int).compareTo(b[p1Key] as int));

      return selected.map((w) {
        // We pass the highest usage count among the two players, or just average it?
        // Since it's UI representation, we just take P1's usage since the device is P1.
        return GameWord(
          id: w['id'],
          englishText: w['english_text'],
          arabicText: w['arabic_text'],
          tiles: w['write_tiles'],
          emoji: w['emoji'],
          audioUrl: w['audio_url'],
          usageCount: w[p1Key],
        );
      }).toList();
    }

    return {
      'see': pick10Words('p1_see', 'p2_see'),
      'listen': pick10Words('p1_listen', 'p2_listen'),
      'write': pick10Words('p1_write', 'p2_write'),
      'speak': pick10Words('p1_speak', 'p2_speak'),
    };
  }
}
