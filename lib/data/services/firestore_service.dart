import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../models/word_model.dart';

final firestoreServiceProvider = Provider<FirestoreService>((_) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch all words for a specific level from Firestore
  Future<List<WordModel>> fetchWordsForLevel(int level) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.colWords)
          .where('level', isEqualTo: level)
          .get();

      return snapshot.docs.map((doc) => WordModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch words from Firestore: $e');
    }
  }

  /// Sync a batch of local word progress to Firestore
  Future<void> syncProgressToCloud(String userId, List<WordProgress> progressList) async {
    try {
      final batch = _db.batch();
      final progressRef = _db
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection('progress');

      for (final progress in progressList) {
        final docRef = progressRef.doc('${progress.wordId}_${progress.section}');
        batch.set(docRef, progress.toFirestore(), SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to sync progress to cloud: $e');
    }
  }

  /// Fetch user progress from Firestore
  Future<List<WordProgress>> fetchUserProgress(String userId) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection('progress')
          .get();

      return snapshot.docs.map((doc) => WordProgress.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user progress: $e');
    }
  }
}
