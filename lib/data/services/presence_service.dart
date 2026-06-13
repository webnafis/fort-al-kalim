import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

/// Service to handle RTDB-based True Presence.
final presenceServiceProvider = Provider<PresenceService>((ref) {
  final service = PresenceService();
  
  ref.listen(currentUserModelProvider, (previous, next) {
    final user = next.value;
    if (user == null) {
      service.goOffline();
      service.clearUser();
    } else {
      service.updateUser(user.uid, user.shareOnlineStatus);
    }
  });
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

final onlineStatusProvider = StreamProvider.autoDispose.family<bool, String>((ref, uid) {
  return FirebaseDatabase.instance.ref('users/$uid/isOnline').onValue.map((event) {
    final val = event.snapshot.value;
    return val == true;
  });
});

class PresenceService with WidgetsBindingObserver {
  String? _currentUid;
  bool _currentShareStatus = false;

  PresenceService() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    goOffline();
  }

  void updateUser(String uid, bool shareOnlineStatus) {
    _currentUid = uid;
    _currentShareStatus = shareOnlineStatus;
    
    if (shareOnlineStatus) {
      goOnline();
    } else {
      goOffline();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUid == null || !_currentShareStatus) return;

    if (state == AppLifecycleState.resumed) {
      goOnline();
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.detached || 
               state == AppLifecycleState.inactive) {
      goOffline();
    }
  }

  void goOnline() {
    if (_currentUid != null && _currentShareStatus) {
      final ref = FirebaseDatabase.instance.ref('users/$_currentUid');
      ref.onDisconnect().update({'isOnline': false});
      ref.update({'isOnline': true});
    }
  }

  void goOffline() {
    if (_currentUid != null) {
      final ref = FirebaseDatabase.instance.ref('users/$_currentUid');
      ref.onDisconnect().cancel();
      ref.update({'isOnline': false});
    }
  }

  void clearUser() {
    _currentUid = null;
    _currentShareStatus = false;
  }
}
