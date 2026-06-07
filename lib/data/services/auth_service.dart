import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

// ── Providers ────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserModelProvider = FutureProvider<UserModel?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  return ref.read(authServiceProvider).getUserModel(user.uid);
});

// ── Service ───────────────────────────────────────────────────────
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google account.
  Future<UserModel?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // Check if this is a new user — create Firestore profile if so
      final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNew) {
        return await _createUserProfile(user);
      } else {
        // Update lastSeen
        await _db.collection(AppConstants.colUsers).doc(user.uid).update({
          'lastSeen': Timestamp.now(),
        });
        return await getUserModel(user.uid);
      }
    } catch (e) {
      throw AuthException('Google Sign-In failed: $e');
    }
  }

  /// Sign in with email + password.
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email, password: password,
      );
      await _db.collection(AppConstants.colUsers)
               .doc(credential.user!.uid)
               .update({'lastSeen': Timestamp.now()});
      return await getUserModel(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  /// Register a new user with email + password.
  Future<UserModel?> registerWithEmail(
      String email, String password, String displayName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await credential.user!.updateDisplayName(displayName);
      return await _createUserProfile(credential.user!, displayName: displayName);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  /// Sign out from Firebase and Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Get a user's profile from Firestore.
  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Create a new user profile in Firestore.
  Future<UserModel> _createUserProfile(User user, {String? displayName}) async {
    final now = DateTime.now();
    final model = UserModel(
      uid:            user.uid,
      displayName:    displayName ?? user.displayName ?? 'Warrior',
      email:          user.email ?? '',
      photoUrl:       user.photoURL,
      currentLevel:   1,
      lifetimeScore:  0,
      wins:           0,
      losses:         0,
      createdAt:      now,
      lastSeen:       now,
    );

    await _db.collection(AppConstants.colUsers)
             .doc(user.uid)
             .set(model.toFirestore());
    return model;
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':      return 'No account found with that email.';
      case 'wrong-password':      return 'Incorrect password.';
      case 'email-already-in-use':return 'An account with that email already exists.';
      case 'weak-password':       return 'Password must be at least 6 characters.';
      case 'invalid-email':       return 'Please enter a valid email address.';
      default:                    return 'Authentication error: ${e.message}';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override String toString() => message;
}
