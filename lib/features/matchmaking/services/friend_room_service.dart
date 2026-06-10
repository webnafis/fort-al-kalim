import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final friendRoomServiceProvider = Provider((ref) => FriendRoomService());

class FriendRoomService {
  final _firestore = FirebaseFirestore.instance;

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<String> createRoom(String hostUid, String hostName, int level) async {
    // Check constraint: Host can have max 5 rooms at a time.
    final myRooms = await _firestore.collection('rooms')
        .where('host.uid', isEqualTo: hostUid)
        .get();
        
    if (myRooms.docs.length >= 5) {
      throw Exception('MAX_ROOMS_REACHED');
    }

    final code = _generateRoomCode();
    await _firestore.collection('rooms').doc(code).set({
      'host': {
        'uid': hostUid,
        'name': hostName,
        'level': level,
      },
      'guest': null,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  Future<bool> joinRoom(String code, String guestUid, String guestName, int level) async {
    code = code.toUpperCase();
    final roomRef = _firestore.collection('rooms').doc(code);
    
    // Use transaction to ensure strict 2-player limit
    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return false;
      
      final data = snapshot.data()!;
      
      if (data['guest'] != null) {
        return false; // Room is full
      }
      
      if (data['status'] != 'waiting') {
        return false; // Game already started or invalid
      }

      transaction.update(roomRef, {
        'guest': {
          'uid': guestUid,
          'name': guestName,
          'level': level,
        }
      });
      return true;
    });
  }

  Stream<DocumentSnapshot> watchRoom(String code) {
    return _firestore.collection('rooms').doc(code).snapshots();
  }

  Future<String?> startGame(String code) async {
    code = code.toUpperCase();
    final roomRef = _firestore.collection('rooms').doc(code);
    final snapshot = await roomRef.get();
    
    if (!snapshot.exists) return null;
    final data = snapshot.data()!;
    
    if (data['guest'] == null) return null; // Cannot start without guest
    
    final String actualGameId = const Uuid().v4();
    
    final hostUid = data['host']['uid'];
    final guestUid = data['guest']['uid'];
    final level = data['host']['level'];

    await _firestore.collection('games').doc(actualGameId).set({
      'player1': hostUid, // host
      'player2': guestUid, // guest
      'level': level,
      'status': 'reading_phase',
      'isFriendMatch': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await roomRef.update({
      'status': 'playing',
      'gameId': actualGameId,
    });
    
    return actualGameId;
  }

  Future<void> deleteRoom(String code) async {
    await _firestore.collection('rooms').doc(code.toUpperCase()).delete();
  }

  // Helper to fetch rooms for the RoomsListScreen
  Future<List<DocumentSnapshot>> getMyHostedRooms(String uid) async {
    final snap = await _firestore.collection('rooms')
        .where('host.uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs;
  }

  Future<List<DocumentSnapshot>> getMyJoinedRooms(String uid) async {
    final snap = await _firestore.collection('rooms')
        .where('guest.uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs;
  }
}
