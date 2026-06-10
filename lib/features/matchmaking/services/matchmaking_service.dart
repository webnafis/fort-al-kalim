import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final matchmakingServiceProvider = Provider((ref) => MatchmakingService());

class MatchmakingService {
  final _db = FirebaseFirestore.instance;

  /// Starts searching for a match. Returns a Stream of the Game ID when matched.
  Stream<String> findMatch({
    required String uid,
    required String displayName,
    required int level,
    required double lifetimeScore,
  }) {
    final controller = StreamController<String>();
    bool matched = false;

    final myEntryRef = _db.collection('matchmaking_queue').doc(uid);

    // 1. Enter the queue
    myEntryRef.set({
      'uid': uid,
      'displayName': displayName,
      'level': level,
      'lifetimeScore': lifetimeScore,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Listen to my entry in case someone else matches with me
    final sub = myEntryRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('matchedGameId')) {
          matched = true;
          controller.add(data['matchedGameId'] as String);
        }
      }
    });

    // 3. Search for others
    _searchForMatch(uid, level, lifetimeScore).then((gameId) {
      if (gameId != null && !matched) {
        matched = true;
        controller.add(gameId);
      }
    });

    // 4. 15-Second Hard Cap for AI Fallback
    Timer(const Duration(seconds: 15), () {
      if (!matched) {
        matched = true;
        myEntryRef.delete(); // Leave queue
        final aiGameId = createAiMatch(uid, level);
        controller.add(aiGameId);
      }
    });

    controller.onCancel = () {
      if (!matched) myEntryRef.delete();
      sub.cancel();
    };

    return controller.stream;
  }

  Future<String?> _searchForMatch(String myUid, int myLevel, double myLifetimeScore) async {
    final queueRef = _db.collection('matchmaking_queue');
    final snapshot = await queueRef.get();

    if (snapshot.docs.isEmpty) return null;

    // Filter out self and people already matched
    final candidates = snapshot.docs.where((doc) {
      if (doc.id == myUid) return false;
      final data = doc.data();
      return !data.containsKey('matchedGameId');
    }).toList();

    if (candidates.isEmpty) return null;

    // Rule 1: Same Level Exact
    final sameLevel = candidates.where((doc) {
      final data = doc.data();
      return data['level'] == myLevel;
    }).toList();

    if (sameLevel.isEmpty) return null; // We only match exact levels now

    // Rule 2: Nearest Rank (lifetimeScore), then most waited
    sameLevel.sort((a, b) {
      final dataA = a.data();
      final dataB = b.data();
      
      final scoreA = (dataA['lifetimeScore'] as num).toDouble();
      final scoreB = (dataB['lifetimeScore'] as num).toDouble();
      
      final diffA = (scoreA - myLifetimeScore).abs();
      final diffB = (scoreB - myLifetimeScore).abs();
      
      if (diffA != diffB) {
        return diffA.compareTo(diffB); // Nearest rank first
      } else {
        // Tie breaker: most waited (oldest timestamp first)
        final timeA = (dataA['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final timeB = (dataB['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return timeA.compareTo(timeB);
      }
    });

    final bestMatch = sameLevel.first;
    final opponentUid = bestMatch.id;
    final gameId = const Uuid().v4();

    // Transactionally attempt to claim this opponent
    bool success = false;
    try {
      await _db.runTransaction((transaction) async {
        final opponentDoc = await transaction.get(queueRef.doc(opponentUid));
        if (!opponentDoc.exists) throw Exception("Opponent left queue");
        final data = opponentDoc.data()!;
        if (data.containsKey('matchedGameId')) throw Exception("Opponent already matched");

        transaction.update(queueRef.doc(opponentUid), {'matchedGameId': gameId});
      });
      success = true;
    } catch (e) {
      return null;
    }

    if (success) {
      // Claimed successfully! Create the game node.
      await _db.collection('games').doc(gameId).set({
        'player1': myUid,
        'player2': opponentUid,
        'level': myLevel,
        'status': 'reading_phase',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update my own node
      await queueRef.doc(myUid).update({'matchedGameId': gameId});
      return gameId;
    }

    return null;
  }

  String createAiMatch(String myUid, int level) {
    final gameId = 'ai_${const Uuid().v4()}';
    _db.collection('games').doc(gameId).set({
      'player1': myUid,
      'player2': 'AI_BOT',
      'level': level,
      'status': 'reading_phase',
      'createdAt': FieldValue.serverTimestamp(),
      'isAiGame': true,
    });
    return gameId;
  }
}
