import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../models/word_model.dart';
import 'local_db_service.dart';

final wordServiceProvider = Provider<WordService>((ref) {
  return WordService(localDb: ref.read(localDbServiceProvider));
});

/// Handles fetching words, tracking progress, and the
/// attack-power balance formula for game word selection.
class WordService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalDbService localDb;

  WordService({required this.localDb});

  // ── Fetch all words for a level ──────────────────────────────────
  Future<List<WordModel>> getWordsForLevel(int level) async {
    // Try local cache first
    final cached = await localDb.getWordsForLevel(level);
    if (cached.isNotEmpty) return cached;

    // Fetch from Firestore and cache locally
    final snap = await _db
        .collection(AppConstants.colWords)
        .where('level', isEqualTo: level)
        .get();
    final words = snap.docs.map(WordModel.fromFirestore).toList();
    await localDb.cacheWords(words);
    return words;
  }

  // ── Fetch/init progress for a user's word in a section ───────────
  Future<WordProgress> getOrCreateProgress({
    required String userId,
    required String wordId,
    required String section,
    required double baseAp,
  }) async {
    final docId = '${userId}_${wordId}_$section';
    final ref   = _db.collection(AppConstants.colProgress).doc(docId);
    final snap  = await ref.get();

    if (snap.exists) return WordProgress.fromFirestore(snap);

    // First time — create fresh progress record
    final progress = WordProgress(
      userId:    userId,
      wordId:    wordId,
      section:   section,
      baseAp:    baseAp,
      currentAp: baseAp,
    );
    await ref.set(progress.toFirestore());
    return progress;
  }

  // ── Record a successful attack ───────────────────────────────────
  /// Degrades AP by 25% of base and returns updated progress + damage dealt.
  Future<({WordProgress updated, double damage})> recordSuccess({
    required WordProgress progress,
    required String section,
  }) async {
    final multiplier = AppConstants.sectionMultipliers[section] ?? 1.0;
    final degradation = progress.baseAp * AppConstants.apDegradationRate;
    final damage      = degradation * multiplier;
    final newAp       = (progress.currentAp - degradation).clamp(0.0, double.infinity);

    final updated = progress.copyWith(currentAp: newAp, clearLock: true);
    await _updateProgress(updated);
    return (updated: updated, damage: damage);
  }

  // ── Record a failed attack ────────────────────────────────────────
  /// Locks the word for 30 seconds — no AP change.
  Future<WordProgress> recordFailure(WordProgress progress) async {
    final lockUntil = DateTime.now().add(
      const Duration(seconds: AppConstants.lockDurationSeconds),
    );
    final updated = progress.copyWith(lockUntil: lockUntil);
    await _updateProgress(updated);
    return updated;
  }

  Future<void> _updateProgress(WordProgress p) async {
    final docId = '${p.userId}_${p.wordId}_${p.section}';
    await _db.collection(AppConstants.colProgress)
             .doc(docId)
             .set(p.toFirestore(), SetOptions(merge: true));
  }

  // ── Word Selection Algorithm ─────────────────────────────────────
  /// Selects words for a player for one game session.
  /// Returns a map of section → list of GameWord sorted by currentAp desc.
  ///
  /// Formula: total attack potential across all sections = fortHp (200)
  ///   B = fortHp / (N × sumOfMultipliers)
  ///   where N = target words per section
  Future<Map<String, List<GameWord>>> selectWordsForPlayer({
    required String userId,
    required int level,
  }) async {
    final allWords = await getWordsForLevel(level);
    final sections = AppConstants.sectionMultipliers.keys.toList();

    // ── Step 1: For each section, fetch all word progress sorted by AP desc ─
    final Map<String, List<WordProgress>> sectionProgress = {};

    for (final section in sections) {
      final multiplier = AppConstants.sectionMultipliers[section]!;

      // Temporary base AP (will be recalculated after word count is known)
      const tempBase = 1.0;

      final progList = await Future.wait(
        allWords.map((w) => getOrCreateProgress(
          userId:  userId,
          wordId:  w.id,
          section: section,
          baseAp:  tempBase * multiplier,
        )),
      );

      // Sort by currentAp descending (least known = highest AP first)
      progList.sort((a, b) => b.currentAp.compareTo(a.currentAp));
      sectionProgress[section] = progList;
    }

    // ── Step 2: Determine word count per section ──────────────────────────
    // Try for equal N per section. If a section has fewer available words,
    // reduce N for that section and compensate in others.
    int targetN = AppConstants.wordsPerSection; // default 10
    final Map<String, int> wordCounts = {};
    for (final section in sections) {
      final available = sectionProgress[section]!
          .where((p) => p.currentAp > 0)
          .length;
      wordCounts[section] = available < targetN ? available : targetN;
    }

    // ── Step 3: Calculate base AP so total = fortHp ──────────────────────
    // total = B × sum(count[s] × multiplier[s])
    // B = fortHp / sum(count[s] × multiplier[s])
    double weightedSum = 0;
    for (final section in sections) {
      weightedSum += wordCounts[section]! *
                     AppConstants.sectionMultipliers[section]!;
    }
    // Avoid division by zero
    final double baseAp = weightedSum > 0
        ? AppConstants.fortHp / weightedSum
        : 1.0;

    // ── Step 4: Build GameWord lists per section ─────────────────────────
    final Map<String, List<GameWord>> result = {};

    for (final section in sections) {
      final multiplier = AppConstants.sectionMultipliers[section]!;
      final count      = wordCounts[section]!;
      final progList   = sectionProgress[section]!;

      // Select top `count` words by current AP
      // If not enough unmastered, pad with bonus (mastered) words
      final selected = <GameWord>[];
      final unmastered = progList.where((p) => p.currentAp > 0).take(count).toList();
      selected.addAll(unmastered.map((p) {
        final word = allWords.firstWhere((w) => w.id == p.wordId);
        // Rescale progress to use the newly calculated baseAp
        final rescaled = WordProgress(
          userId:      p.userId,
          wordId:      p.wordId,
          section:     section,
          baseAp:      baseAp * multiplier,
          currentAp:   p.currentAp > 0 ? p.currentAp : baseAp * multiplier,
          lockUntil:   p.lockUntil,
          isBonusWord: false,
        );
        return GameWord(word: word, progress: rescaled);
      }));

      // If short of target, fill with bonus (mastered) words
      if (selected.length < count) {
        final mastered = progList
            .where((p) => p.currentAp <= 0)
            .take(count - selected.length);
        for (final p in mastered) {
          final word = allWords.firstWhere((w) => w.id == p.wordId);
          final bonusProgress = WordProgress(
            userId:      p.userId,
            wordId:      p.wordId,
            section:     section,
            baseAp:      baseAp * multiplier,
            currentAp:   baseAp * multiplier, // reset to full as reward
            isBonusWord: true,
          );
          selected.add(GameWord(word: word, progress: bonusProgress));
        }
      }

      // Sort: non-bonus first, then by current AP desc
      selected.sort((a, b) {
        if (a.progress.isBonusWord != b.progress.isBonusWord) {
          return a.progress.isBonusWord ? 1 : -1;
        }
        return b.currentAp.compareTo(a.currentAp);
      });

      result[section] = selected;
    }

    return result;
  }

  // ── Check if player has levelled up ─────────────────────────────
  /// Returns true if ALL words in ALL 4 sections are exhausted (AP = 0)
  Future<bool> checkLevelComplete({
    required String userId,
    required int level,
  }) async {
    final words = await getWordsForLevel(level);
    final sections = AppConstants.sectionMultipliers.keys.toList();

    for (final word in words) {
      for (final section in sections) {
        final docId = '${userId}_${word.id}_$section';
        final snap  = await _db.collection(AppConstants.colProgress).doc(docId).get();
        if (!snap.exists) return false;
        final progress = WordProgress.fromFirestore(snap);
        if (progress.currentAp > 0) return false;
      }
    }
    return true;
  }
}
