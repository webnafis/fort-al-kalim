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
  final List<String> unlockedAchievements;
  final int lives;
  final int currentStreak;
  final DateTime? lastMatchDate;
  final DateTime? unlimitedLivesUntil;
  final DateTime? lastLifeRefillTime;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool shareOnlineStatus;
  final bool hasPromptedForStatus;

  bool get hasUnlimitedLives => unlimitedLivesUntil != null && unlimitedLivesUntil!.isAfter(DateTime.now());

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
    this.unlockedAchievements = const [],
    this.lives = 5,
    this.currentStreak = 0,
    this.lastMatchDate,
    this.unlimitedLivesUntil,
    this.lastLifeRefillTime,
    required this.createdAt,
    required this.lastSeen,
    this.shareOnlineStatus = false,
    this.hasPromptedForStatus = false,
  });

  /// Dynamically calculate current lives based on 30 min refill.
  int get currentLives {
    if (lives >= 5 || lastLifeRefillTime == null) return lives;
    final minutesPassed = DateTime.now().difference(lastLifeRefillTime!).inMinutes;
    final earned = minutesPassed ~/ 30;
    return (lives + earned).clamp(0, 5);
  }

  /// Time remaining until next life refills (null if full).
  Duration? get timeUntilNextLife {
    if (currentLives >= 5 || lastLifeRefillTime == null) return null;
    final minutesPassed = DateTime.now().difference(lastLifeRefillTime!).inMinutes;
    final remainder = minutesPassed % 30;
    return Duration(minutes: 30 - remainder);
  }

  /// Win/loss record
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
      unlockedAchievements: List<String>.from(d['unlockedAchievements'] ?? []),
      lives:          d['lives'] ?? 5,
      currentStreak:  d['currentStreak'] ?? 0,
      lastMatchDate:  d['lastMatchDate'] != null ? (d['lastMatchDate'] as Timestamp).toDate() : null,
      unlimitedLivesUntil: d['unlimitedLivesUntil'] != null ? (d['unlimitedLivesUntil'] as Timestamp).toDate() : null,
      lastLifeRefillTime: d['lastLifeRefillTime'] != null ? (d['lastLifeRefillTime'] as Timestamp).toDate() : null,
      createdAt:      (d['createdAt'] as Timestamp).toDate(),
      lastSeen:       (d['lastSeen'] as Timestamp).toDate(),
      shareOnlineStatus: d['shareOnlineStatus'] ?? false,
      hasPromptedForStatus: d['hasPromptedForStatus'] ?? false,
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
    'unlockedAchievements': unlockedAchievements,
    'lives':        lives,
    'currentStreak': currentStreak,
    'lastMatchDate': lastMatchDate != null ? Timestamp.fromDate(lastMatchDate!) : null,
    'unlimitedLivesUntil': unlimitedLivesUntil != null ? Timestamp.fromDate(unlimitedLivesUntil!) : null,
    'lastLifeRefillTime': lastLifeRefillTime != null ? Timestamp.fromDate(lastLifeRefillTime!) : null,
    'createdAt':    Timestamp.fromDate(createdAt),
    'lastSeen':     Timestamp.fromDate(lastSeen),
    'shareOnlineStatus': shareOnlineStatus,
    'hasPromptedForStatus': hasPromptedForStatus,
  };

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? gpgsPlayerId,
    int? currentLevel,
    double? lifetimeScore,
    int? wins,
    int? losses,
    List<String>? unlockedAchievements,
    int? currentStreak,
    DateTime? lastMatchDate,
    DateTime? unlimitedLivesUntil,
    DateTime? lastSeen,
    bool? shareOnlineStatus,
    bool? hasPromptedForStatus,
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
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      lives:          lives,
      currentStreak:  currentStreak ?? this.currentStreak,
      lastMatchDate:  lastMatchDate ?? this.lastMatchDate,
      unlimitedLivesUntil: unlimitedLivesUntil ?? this.unlimitedLivesUntil,
      lastLifeRefillTime: lastLifeRefillTime,
      createdAt:      createdAt,
      lastSeen:       lastSeen       ?? this.lastSeen,
      shareOnlineStatus: shareOnlineStatus ?? this.shareOnlineStatus,
      hasPromptedForStatus: hasPromptedForStatus ?? this.hasPromptedForStatus,
    );
  }
}
