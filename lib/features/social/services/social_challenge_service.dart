import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final socialChallengeServiceProvider = Provider((ref) => SocialChallengeService());

class SocialChallengeService {
  final _db = FirebaseFirestore.instance;

  /// Sends a direct challenge to another user.
  Future<String> sendChallenge({
    required String fromUid,
    required String fromName,
    required int fromLevel,
    required String toUid,
  }) async {
    final challengeId = const Uuid().v4();
    await _db.collection('challenges').doc(challengeId).set({
      'fromUid': fromUid,
      'fromName': fromName,
      'fromLevel': fromLevel,
      'toUid': toUid,
      'status': 'pending', // pending, accepted, declined
      'gameId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return challengeId;
  }

  /// Listen to a specific challenge you sent to see if it gets accepted
  Stream<DocumentSnapshot> watchChallenge(String challengeId) {
    return _db.collection('challenges').doc(challengeId).snapshots();
  }

  /// Listen to incoming challenges
  Stream<QuerySnapshot> watchIncomingChallenges(String myUid) {
    return _db.collection('challenges')
        .where('toUid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Accept a challenge
  Future<String?> acceptChallenge(String challengeId, String myUid, String challengerUid, int myLevel) async {
    final gameId = const Uuid().v4();
    
    // Create the game node
    await _db.collection('games').doc(gameId).set({
      'player1': challengerUid, // host
      'player2': myUid,         // guest
      'level': myLevel,
      'status': 'reading_phase',
      'isFriendMatch': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update challenge status
    await _db.collection('challenges').doc(challengeId).update({
      'status': 'accepted',
      'gameId': gameId,
    });

    return gameId;
  }

  /// Decline a challenge
  Future<void> declineChallenge(String challengeId) async {
    await _db.collection('challenges').doc(challengeId).update({
      'status': 'declined',
    });
  }
}
