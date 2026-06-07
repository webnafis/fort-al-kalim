import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';

final matchmakingServiceProvider = Provider<MatchmakingService>(
  (_) => MatchmakingService(),
);

/// Handles algorithmic matchmaking and friend room codes.
class MatchmakingService {
  final FirebaseDatabase  _rtdb = FirebaseDatabase.instance;
  final FirebaseFirestore _db   = FirebaseFirestore.instance;

  // ── ALGORITHMIC MATCHMAKING ──────────────────────────────────────

  /// Add this player to the matchmaking queue.
  Future<void> joinQueue(UserModel player, double totalRemainingAp) async {
    await _rtdb.ref('${AppConstants.rtdbMatchmaking}/${player.uid}').set({
      'uid':             player.uid,
      'displayName':     player.displayName,
      'level':           player.currentLevel,
      'totalRemainingAp':totalRemainingAp,
      'joinedAt':        ServerValue.timestamp,
      'status':          'waiting',
    });
  }

  /// Remove this player from the queue (on cancel or match found).
  Future<void> leaveQueue(String uid) async {
    await _rtdb.ref('${AppConstants.rtdbMatchmaking}/$uid').remove();
  }

  /// Listen for a match being assigned to this player.
  Stream<String?> listenForMatch(String uid) {
    return _rtdb
        .ref('${AppConstants.rtdbMatchmaking}/$uid/matchedGameId')
        .onValue
        .map((event) => event.snapshot.value as String?);
  }

  /// [Server-side logic placeholder]
  /// In production, a Cloud Function runs this logic.
  /// For prototype: client-side matching triggered by queue changes.
  ///
  /// Matching priority:
  ///   1. Same level (ALWAYS match if 2+ same-level players available)
  ///      Tiebreak among same-level: smallest AP gap
  ///      Tiebreak equal AP gap: longest wait time
  ///   2. Cross-level (only if player is alone at their level)
  ///      Pick nearest level, then smallest AP gap
  ///   3. After 15 seconds: force-match with best available or offer AI
  Future<String?> findBestMatch(UserModel player, double myAp) async {
    final snap = await _rtdb.ref(AppConstants.rtdbMatchmaking).get();
    if (!snap.exists) return null;

    final queue = <Map<String, dynamic>>[];
    for (final child in snap.children) {
      final data = Map<String, dynamic>.from(child.value as Map);
      if (data['uid'] != player.uid && data['status'] == 'waiting') {
        queue.add(data);
      }
    }
    if (queue.isEmpty) return null;

    // Same-level candidates
    final sameLevelCandidates = queue
        .where((p) => p['level'] == player.currentLevel)
        .toList();

    if (sameLevelCandidates.isNotEmpty) {
      // Sort by AP gap asc, then wait time desc (longest wait = older joinedAt)
      sameLevelCandidates.sort((a, b) {
        final apGapA = ((a['totalRemainingAp'] as num) - myAp).abs();
        final apGapB = ((b['totalRemainingAp'] as num) - myAp).abs();
        if (apGapA != apGapB) return apGapA.compareTo(apGapB);
        // Older joinedAt = longer wait = higher priority
        return (a['joinedAt'] as int).compareTo(b['joinedAt'] as int);
      });
      return sameLevelCandidates.first['uid'] as String;
    }

    // Cross-level: find nearest level with smallest AP gap
    queue.sort((a, b) {
      final levelDiffA = ((a['level'] as int) - player.currentLevel).abs();
      final levelDiffB = ((b['level'] as int) - player.currentLevel).abs();
      if (levelDiffA != levelDiffB) return levelDiffA.compareTo(levelDiffB);
      final apGapA = ((a['totalRemainingAp'] as num) - myAp).abs();
      final apGapB = ((b['totalRemainingAp'] as num) - myAp).abs();
      return apGapA.compareTo(apGapB);
    });
    return queue.first['uid'] as String;
  }

  // ── FRIEND ROOM CODE SYSTEM ──────────────────────────────────────

  /// Generate a unique 6-character room code and create the room.
  Future<String> createFriendRoom(UserModel host) async {
    final code    = _generateRoomCode();
    final expiry  = DateTime.now()
        .add(const Duration(minutes: AppConstants.roomCodeExpiryMinutes));

    await _rtdb.ref('${AppConstants.rtdbRooms}/$code').set({
      'code':       code,
      'hostId':     host.uid,
      'hostName':   host.displayName,
      'hostLevel':  host.currentLevel,
      'guestId':    null,
      'status':     'waiting',      // waiting | ready | started
      'expiresAt':  expiry.millisecondsSinceEpoch,
      'createdAt':  ServerValue.timestamp,
    });

    return code;
  }

  /// Join an existing room by code. Returns false if invalid/expired.
  Future<bool> joinFriendRoom(String code, UserModel guest) async {
    final ref  = _rtdb.ref('${AppConstants.rtdbRooms}/$code');
    final snap = await ref.get();

    if (!snap.exists) return false;
    final data = Map<String, dynamic>.from(snap.value as Map);

    // Check expiry
    final expiresAt = data['expiresAt'] as int;
    if (DateTime.now().millisecondsSinceEpoch > expiresAt) return false;

    // Check not already taken
    if (data['guestId'] != null) return false;

    await ref.update({
      'guestId':   guest.uid,
      'guestName': guest.displayName,
      'status':    'ready',
    });
    return true;
  }

  /// Stream room state (host listens for guest joining).
  Stream<Map<String, dynamic>?> listenToRoom(String code) {
    return _rtdb.ref('${AppConstants.rtdbRooms}/$code').onValue.map((event) {
      if (!event.snapshot.exists) return null;
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  /// Cancel and delete a room.
  Future<void> cancelRoom(String code) async {
    await _rtdb.ref('${AppConstants.rtdbRooms}/$code').remove();
  }

  // ── FRIEND INVITE (FCM-based) ────────────────────────────────────

  /// Send a challenge invite to a friend (stored in Firestore, FCM notif sent).
  Future<void> sendFriendInvite({
    required String fromUid,
    required String fromName,
    required String toUid,
    required String roomCode,
  }) async {
    final expiry = DateTime.now()
        .add(const Duration(minutes: AppConstants.friendInviteExpiryMinutes));

    await _db
        .collection(AppConstants.colInvites)
        .doc(toUid)
        .collection('received')
        .add({
      'fromUid':   fromUid,
      'fromName':  fromName,
      'roomCode':  roomCode,
      'expiresAt': Timestamp.fromDate(expiry),
      'status':    'pending',
      'createdAt': Timestamp.now(),
    });
    // Note: FCM push notification is triggered by a Firestore Cloud Function
    // (the function listens for new docs in invites/{uid}/received)
  }

  /// Listen for incoming friend invites for a user.
  Stream<List<Map<String, dynamic>>> listenForInvites(String uid) {
    final now = Timestamp.now();
    return _db
        .collection(AppConstants.colInvites)
        .doc(uid)
        .collection('received')
        .where('status', isEqualTo: 'pending')
        .where('expiresAt', isGreaterThan: now)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  // ── Helpers ──────────────────────────────────────────────────────

  String _generateRoomCode() {
    final rng  = Random.secure();
    final chars = AppConstants.roomCodeChars;
    return List.generate(
      AppConstants.roomCodeLength,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
  }
}
