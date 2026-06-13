import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gamePresenceServiceProvider = Provider((ref) => GamePresenceService());

class GamePresenceService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Joins a match by setting a presence node in RTDB.
  /// If the player's connection drops, the server will instantly write 'offline' to this node.
  void joinMatch(String gameId, String uid) {
    final ref = _db.ref('matches/$gameId/players/$uid');
    
    // Set up the disconnect trigger first
    ref.onDisconnect().update({'status': 'offline'});
    
    // Then set the actual status
    ref.update({'status': 'online'});
  }

  /// Leaves a match gracefully, cleaning up the RTDB node.
  void leaveMatch(String gameId, String uid) {
    final ref = _db.ref('matches/$gameId/players/$uid');
    
    // Cancel the disconnect trigger so it doesn't fire later
    ref.onDisconnect().cancel();
    
    // We can just remove the node entirely when they leave properly
    ref.remove();
  }

  /// Watches an opponent's presence in a specific match.
  Stream<String> watchOpponentPresence(String gameId, String opponentUid) {
    return _db.ref('matches/$gameId/players/$opponentUid/status').onValue.map((event) {
      final val = event.snapshot.value;
      if (val == null) return 'unknown';
      return val as String;
    });
  }
}
