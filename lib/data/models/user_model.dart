import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a Fort Al-Kalim user profile.
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? gpgsPlayerId;     // Google Play Games player ID
  final int currentLevel;
  final double lifetimeScore;     // Total damage dealt across all games
  final int wins;
  final int losses;
  final DateTime createdAt;
  final DateTime lastSeen;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.gpgsPlayerId,
    required this.currentLevel,
    required this.lifetimeScore,
    required this.wins,
    required this.losses,
    required this.createdAt,
    required this.lastSeen,
  });

  /// Win/loss ratio string for display.
  String get wlRecord => '$wins W / $losses L';

  /// Factory from Firestore document.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid:            doc.id,
      displayName:    d['displayName'] ?? '',
      email:          d['email'] ?? '',
      photoUrl:       d['photoUrl'],
      gpgsPlayerId:   d['gpgsPlayerId'],
      currentLevel:   d['currentLevel'] ?? 1,
      lifetimeScore:  (d['lifetimeScore'] ?? 0).toDouble(),
      wins:           d['wins'] ?? 0,
      losses:         d['losses'] ?? 0,
      createdAt:      (d['createdAt'] as Timestamp).toDate(),
      lastSeen:       (d['lastSeen'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore map.
  Map<String, dynamic> toFirestore() => {
    'displayName':  displayName,
    'email':        email,
    'photoUrl':     photoUrl,
    'gpgsPlayerId': gpgsPlayerId,
    'currentLevel': currentLevel,
    'lifetimeScore':lifetimeScore,
    'wins':         wins,
    'losses':       losses,
    'createdAt':    Timestamp.fromDate(createdAt),
    'lastSeen':     Timestamp.fromDate(lastSeen),
  };

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? gpgsPlayerId,
    int? currentLevel,
    double? lifetimeScore,
    int? wins,
    int? losses,
    DateTime? lastSeen,
  }) {
    return UserModel(
      uid:            uid,
      displayName:    displayName    ?? this.displayName,
      email:          email,
      photoUrl:       photoUrl       ?? this.photoUrl,
      gpgsPlayerId:   gpgsPlayerId   ?? this.gpgsPlayerId,
      currentLevel:   currentLevel   ?? this.currentLevel,
      lifetimeScore:  lifetimeScore  ?? this.lifetimeScore,
      wins:           wins           ?? this.wins,
      losses:         losses         ?? this.losses,
      createdAt:      createdAt,
      lastSeen:       lastSeen       ?? this.lastSeen,
    );
  }
}
