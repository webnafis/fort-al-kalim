import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

/// Service to handle Firestore-based True Presence.
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
  return FirebaseFirestore.instance.collection('users').doc(uid).snapshots().map((doc) {
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>;
    return data['isOnline'] == true;
  });
});

class PresenceService with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
      _firestore.collection('users').doc(_currentUid).set({'isOnline': true}, SetOptions(merge: true));
    }
  }

  void goOffline() {
    if (_currentUid != null) {
      _firestore.collection('users').doc(_currentUid).set({'isOnline': false}, SetOptions(merge: true));
    }
  }

  void clearUser() {
    _currentUid = null;
    _currentShareStatus = false;
  }
}
