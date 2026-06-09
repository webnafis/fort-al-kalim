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
  final double currentAp;
  final double baseDamage;

  GameWord({
    required this.id,
    required this.englishText,
    required this.arabicText,
    required this.tiles,
    this.emoji,
    this.audioUrl,
    required this.currentAp,
    required this.baseDamage,
  });
}

class WordSelectionService {
  final _firestore = FirebaseFirestore.instance;

  /// Fetches unmastered words for a specific level and computes the math.
  Future<Map<String, List<GameWord>>> selectWordsForGame(String uid, int level) async {
    // 1. Fetch the 100 level words
    final wordsSnapshot = await _firestore
        .collection('levels')
        .doc('level_$level')
        .collection('words')
        .get();

    // 2. Fetch the user's progress for this level
    // In a real app, this would be stored in users/{uid}/progress/{level}
    // For this simulation, we'll assign default AP if progress doesn't exist.
    final progressSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc('level_$level')
        .get();

    Map<String, dynamic> userProgress = {};
    if (progressSnapshot.exists) {
      userProgress = progressSnapshot.data() ?? {};
    }

    List<Map<String, dynamic>> allWords = [];
    for (var doc in wordsSnapshot.docs) {
      final d = doc.data();
      final wordId = doc.id;
      // Default to 1.0 AP if not started
      final apSee = (userProgress['${wordId}_see'] ?? 1.0).toDouble();
      final apListen = (userProgress['${wordId}_listen'] ?? 1.0).toDouble();
      final apWrite = (userProgress['${wordId}_write'] ?? 1.0).toDouble();
      final apSpeak = (userProgress['${wordId}_speak'] ?? 1.0).toDouble();

      allWords.add({
        'id': wordId,
        'english_text': d['english_text'] ?? '',
        'arabic_text': d['arabic_text'] ?? '',
        'write_tiles': List<String>.from(d['write_tiles'] ?? []),
        'emoji': d['emoji'],
        'audio_url': d['audio_url'],
        'apSee': apSee,
        'apListen': apListen,
        'apWrite': apWrite,
        'apSpeak': apSpeak,
      });
    }

    if (allWords.isEmpty) return {'see': [], 'listen': [], 'write': [], 'speak': []};

    // 3. Sort by highest AP (needs most practice)
    final seePool = List.of(allWords)..sort((a, b) => b['apSee'].compareTo(a['apSee']));
    final listenPool = List.of(allWords)..sort((a, b) => b['apListen'].compareTo(a['apListen']));
    final writePool = List.of(allWords)..sort((a, b) => b['apWrite'].compareTo(a['apWrite']));
    final speakPool = List.of(allWords)..sort((a, b) => b['apSpeak'].compareTo(a['apSpeak']));

    // Select Top N words (Default is 10 words per section)
    int n = min(10, allWords.length);

    // 4. Calculate Base Damage (B) so that Fort HP exactly = 200
    // Multipliers: See=1.0, Listen=1.25, Write=1.5, Speak=1.75. Sum = 5.5
    // B * N * 5.5 = 200  =>  B = 200 / (N * 5.5)
    double baseDamage = 200.0 / (n * 5.5);

    // Helper to map
    List<GameWord> mapToGameWord(List<Map<String, dynamic>> pool, String apKey) {
      return pool.take(n).map((w) {
        return GameWord(
          id: w['id'],
          englishText: w['english_text'],
          arabicText: w['arabic_text'],
          tiles: w['write_tiles'],
          emoji: w['emoji'],
          audioUrl: w['audio_url'],
          currentAp: w[apKey],
          baseDamage: baseDamage,
        );
      }).toList();
    }

    return {
      'see': mapToGameWord(seePool, 'apSee'),
      'listen': mapToGameWord(listenPool, 'apListen'),
      'write': mapToGameWord(writePool, 'apWrite'),
      'speak': mapToGameWord(speakPool, 'apSpeak'),
    };
  }
}
