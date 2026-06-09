import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final matchmakingServiceProvider = Provider((ref) => MatchmakingService());

class MatchmakingService {
  final _db = FirebaseDatabase.instance;

  /// Starts searching for a match. Returns a Stream of the Game ID when matched.
  Stream<String> findMatch({
    required String uid,
    required String displayName,
    required int level,
    required double remainingAP,
  }) {
    final controller = StreamController<String>();
    bool matched = false;

    final queueRef = _db.ref('matchmaking/queue');
    final myEntryRef = queueRef.child(uid);

    // 1. Enter the queue
    myEntryRef.set({
      'uid': uid,
      'displayName': displayName,
      'level': level,
      'remainingAP': remainingAP,
      'timestamp': ServerValue.timestamp,
    });

    // 2. Listen to my entry in case someone else matches with me
    final sub = myEntryRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (data.containsKey('matchedGameId')) {
          matched = true;
          controller.add(data['matchedGameId'] as String);
        }
      }
    });

    // 3. Search for others
    _searchForMatch(uid, level, remainingAP).then((gameId) {
      if (gameId != null && !matched) {
        matched = true;
        controller.add(gameId);
      }
    });

    // 4. 15-Second Hard Cap for AI Fallback
    Timer(const Duration(seconds: 15), () {
      if (!matched) {
        matched = true;
        myEntryRef.remove(); // Leave queue
        final aiGameId = _createAiMatch(uid, level, remainingAP);
        controller.add(aiGameId);
      }
    });

    controller.onCancel = () {
      if (!matched) myEntryRef.remove();
      sub.cancel();
    };

    return controller.stream;
  }

  Future<String?> _searchForMatch(String myUid, int myLevel, double myAp) async {
    final queueRef = _db.ref('matchmaking/queue');
    final snapshot = await queueRef.get();

    if (!snapshot.exists) return null;

    final entries = Map<String, dynamic>.from(snapshot.value as Map);
    
    // Filter out self and people already matched
    final candidates = entries.entries.where((e) {
      if (e.key == myUid) return false;
      final data = Map<String, dynamic>.from(e.value as Map);
      return !data.containsKey('matchedGameId');
    }).toList();

    if (candidates.isEmpty) return null;

    // Rule 1: Same Level First
    final sameLevel = candidates.where((e) {
      final data = Map<String, dynamic>.from(e.value as Map);
      return data['level'] == myLevel;
    }).toList();

    MapEntry<String, dynamic>? bestMatch;

    if (sameLevel.isNotEmpty) {
      // Find smallest AP difference
      sameLevel.sort((a, b) {
        final apA = (Map<String, dynamic>.from(a.value as Map)['remainingAP'] as num).toDouble();
        final apB = (Map<String, dynamic>.from(b.value as Map)['remainingAP'] as num).toDouble();
        return (apA - myAp).abs().compareTo((apB - myAp).abs());
      });
      bestMatch = sameLevel.first;
    } else {
      // Rule 2: Cross-Level match (smallest AP diff)
      candidates.sort((a, b) {
        final apA = (Map<String, dynamic>.from(a.value as Map)['remainingAP'] as num).toDouble();
        final apB = (Map<String, dynamic>.from(b.value as Map)['remainingAP'] as num).toDouble();
        return (apA - myAp).abs().compareTo((apB - myAp).abs());
      });
      bestMatch = candidates.first;
    }

    if (bestMatch != null) {
      final opponentUid = bestMatch.key;
      final gameId = const Uuid().v4();

      // Transactionally attempt to claim this opponent
      final result = await queueRef.child(opponentUid).runTransaction((obj) {
        if (obj == null) return Transaction.abort();
        final data = Map<String, dynamic>.from(obj as Map);
        if (data.containsKey('matchedGameId')) return Transaction.abort(); // already claimed
        
        data['matchedGameId'] = gameId;
        return Transaction.success(data);
      });

      if (result.committed) {
        // Claimed successfully! Create the game node.
        await _db.ref('games/$gameId').set({
          'player1': myUid,
          'player2': opponentUid,
          'status': 'reading_phase',
          'createdAt': ServerValue.timestamp,
        });
        
        // Update my own node
        await queueRef.child(myUid).update({'matchedGameId': gameId});
        return gameId;
      }
    }

    return null;
  }

  String _createAiMatch(String myUid, int level, double ap) {
    final gameId = 'ai_${const Uuid().v4()}';
    _db.ref('games/$gameId').set({
      'player1': myUid,
      'player2': 'AI_BOT',
      'status': 'reading_phase',
      'createdAt': ServerValue.timestamp,
      'isAiGame': true,
    });
    return gameId;
  }
}
