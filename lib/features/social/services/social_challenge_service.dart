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

  /// Accept a challenge safely with a transaction to prevent race conditions
  Future<String?> acceptChallenge(String challengeId, String myUid, String challengerUid, int myLevel) async {
    final challengeRef = _db.collection('challenges').doc(challengeId);
    String? finalGameId;

    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(challengeRef);
        if (!snapshot.exists) throw Exception('Challenge not found');

        final data = snapshot.data() as Map<String, dynamic>;
        
        if (data['status'] != 'pending') {
          throw Exception('Challenge is no longer pending (status: ${data['status']})');
        }

        finalGameId = const Uuid().v4();
        final gameRef = _db.collection('games').doc(finalGameId);
        
        transaction.set(gameRef, {
          'player1': challengerUid, // host
          'player2': myUid,         // guest
          'level': myLevel,
          'status': 'reading_phase',
          'isFriendMatch': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(challengeRef, {
          'status': 'accepted',
          'gameId': finalGameId,
        });
      });
      return finalGameId;
    } catch (e) {
      // Transaction failed or challenge wasn't pending
      return null;
    }
  }

  /// Decline a challenge
  Future<void> declineChallenge(String challengeId) async {
    await _db.collection('challenges').doc(challengeId).update({
      'status': 'declined',
    });
  }

  /// Cancel an outgoing challenge
  Future<void> cancelChallenge(String challengeId) async {
    await _db.collection('challenges').doc(challengeId).update({
      'status': 'cancelled',
    });
  }
}
