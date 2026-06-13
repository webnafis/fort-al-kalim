import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final matchmakingServiceProvider = Provider((ref) => MatchmakingService());

class MatchmakingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  /// Starts searching for a match. Returns a Stream of the Game ID when matched.
  Stream<String> findMatch({
    required String uid,
    required String displayName,
    required int level,
    required double lifetimeScore,
  }) {
    final controller = StreamController<String>();
    bool matched = false;

    final myEntryRef = _rtdb.ref('matchmaking_queue/$uid');

    // 1. Set up disconnect handler and enter the queue
    myEntryRef.onDisconnect().remove();
    myEntryRef.set({
      'uid': uid,
      'displayName': displayName,
      'level': level,
      'lifetimeScore': lifetimeScore,
      'timestamp': ServerValue.timestamp,
    });

    // 2. Listen to my entry in case someone else matches with me
    final sub = myEntryRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
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
        myEntryRef.onDisconnect().cancel();
        myEntryRef.remove(); // Leave queue
        final aiGameId = createAiMatch(uid, level);
        controller.add(aiGameId);
      }
    });

    controller.onCancel = () {
      if (!matched) {
        myEntryRef.onDisconnect().cancel();
        myEntryRef.remove();
      }
      sub.cancel();
    };

    return controller.stream;
  }

  Future<String?> _searchForMatch(String myUid, int myLevel, double myLifetimeScore) async {
    final queueRef = _rtdb.ref('matchmaking_queue');
    final snapshot = await queueRef.get();

    if (!snapshot.exists) return null;

    final map = Map<String, dynamic>.from(snapshot.value as Map);
    
    // Filter out self and people already matched
    final candidates = <MapEntry<String, Map<String, dynamic>>>[];
    map.forEach((key, value) {
      if (key == myUid) return;
      final data = Map<String, dynamic>.from(value as Map);
      if (!data.containsKey('matchedGameId')) {
        candidates.add(MapEntry(key, data));
      }
    });

    if (candidates.isEmpty) return null;

    // Rule 1: Same Level Exact
    final sameLevel = candidates.where((entry) {
      final data = entry.value;
      return data['level'] == myLevel;
    }).toList();

    if (sameLevel.isEmpty) return null;

    // Rule 2: Nearest Rank (lifetimeScore), then most waited
    sameLevel.sort((a, b) {
      final dataA = a.value;
      final dataB = b.value;
      
      final scoreA = (dataA['lifetimeScore'] as num).toDouble();
      final scoreB = (dataB['lifetimeScore'] as num).toDouble();
      
      final diffA = (scoreA - myLifetimeScore).abs();
      final diffB = (scoreB - myLifetimeScore).abs();
      
      if (diffA != diffB) {
        return diffA.compareTo(diffB); // Nearest rank first
      } else {
        // Tie breaker: most waited (oldest timestamp first)
        final timeA = (dataA['timestamp'] as num?)?.toInt() ?? 0;
        final timeB = (dataB['timestamp'] as num?)?.toInt() ?? 0;
        return timeA.compareTo(timeB);
      }
    });

    final bestMatch = sameLevel.first;
    final opponentUid = bestMatch.key;
    final gameId = const Uuid().v4();

    // Transactionally attempt to claim this opponent in RTDB
    bool success = false;
    try {
      final result = await queueRef.child(opponentUid).runTransaction((Object? currentData) {
        if (currentData == null) {
          return Transaction.abort(); // Opponent left queue
        }
        Map<String, dynamic> data = Map<String, dynamic>.from(currentData as Map);
        if (data.containsKey('matchedGameId')) {
          return Transaction.abort(); // Opponent already matched
        }
        
        data['matchedGameId'] = gameId;
        return Transaction.success(data);
      });
      success = result.committed;
    } catch (e) {
      return null;
    }

    if (success) {
      // Claimed successfully! Create the game node in Firestore.
      await _db.collection('games').doc(gameId).set({
        'player1': myUid,
        'player2': opponentUid,
        'level': myLevel,
        'status': 'reading_phase',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update my own node so I trigger my own listener
      await queueRef.child(myUid).update({'matchedGameId': gameId});
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
