import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';

final achievementServiceProvider = Provider<AchievementService>((_) => AchievementService());

/// Handles unlocking and querying achievements purely in Firebase Firestore
/// (Cross-Platform replacement for GPGS Achievements)
class AchievementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Unlock an achievement for the user
  Future<void> unlockAchievement(String userId, String achievementId) async {
    try {
      final docRef = _db
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection('achievements')
          .doc(achievementId);
          
      // Use set with merge to avoid overwriting the unlock date if they already earned it
      await docRef.set({
        'id': achievementId,
        'unlockedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
    } catch (e) {
      // Swallow error silently so gameplay isn't interrupted
      print('Failed to unlock achievement in Firestore: $e');
    }
  }

  /// Get a list of all unlocked achievement IDs for a user
  Future<List<String>> getUnlockedAchievements(String userId) async {
    try {
      final snapshot = await _db
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection('achievements')
          .orderBy('unlockedAt', descending: true)
          .get();
          
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Failed to fetch achievements: $e');
      return [];
    }
  }
}
