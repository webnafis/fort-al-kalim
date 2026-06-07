import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single Arabic-English word in a level.
class WordModel {
  final String id;
  final int level;
  final String arabicText;      // Full Arabic word (with harakat)
  final String englishText;     // English translation
  final String audioUrl;        // Firebase Storage URL for Arabic audio
  final String imageUrl;        // Firebase Storage URL for SEE section image
  final List<String> writeTiles;// Pre-split tiles (concat = arabicText)

  const WordModel({
    required this.id,
    required this.level,
    required this.arabicText,
    required this.englishText,
    required this.audioUrl,
    required this.imageUrl,
    required this.writeTiles,
  });

  factory WordModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WordModel(
      id:          doc.id,
      level:       d['level'] ?? 1,
      arabicText:  d['arabicText'] ?? '',
      englishText: d['englishText'] ?? '',
      audioUrl:    d['audioUrl'] ?? '',
      imageUrl:    d['imageUrl'] ?? '',
      writeTiles:  List<String>.from(d['writeTiles'] ?? []),
    );
  }

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id:          json['id'] ?? '',
      level:       json['level'] ?? 1,
      arabicText:  json['arabicText'] ?? '',
      englishText: json['englishText'] ?? '',
      audioUrl:    json['audioUrl'] ?? '',
      imageUrl:    json['imageUrl'] ?? '',
      writeTiles:  List<String>.from(json['writeTiles'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'level':       level,
    'arabicText':  arabicText,
    'englishText': englishText,
    'audioUrl':    audioUrl,
    'imageUrl':    imageUrl,
    'writeTiles':  writeTiles,
  };
}

/// Tracks a user's mastery of ONE word in ONE section.
/// Stored per user, per word, per section (4 records per word per user).
class WordProgress {
  final String userId;
  final String wordId;
  final String section;         // 'see' | 'listen' | 'write' | 'speak'
  final double baseAp;          // Base attack power (never changes)
  final double currentAp;       // Current remaining attack power
  final DateTime? lockUntil;    // Null if not locked; timestamp if locked
  final bool isBonusWord;       // True if already mastered (bonus reward)

  const WordProgress({
    required this.userId,
    required this.wordId,
    required this.section,
    required this.baseAp,
    required this.currentAp,
    this.lockUntil,
    this.isBonusWord = false,
  });

  /// Whether this word is currently locked (failed attempt cooldown).
  bool get isLocked {
    if (lockUntil == null) return false;
    return DateTime.now().isBefore(lockUntil!);
  }

  /// Whether this word is fully exhausted (AP = 0).
  bool get isExhausted => currentAp <= 0;

  /// Seconds remaining on lock timer (0 if not locked).
  int get lockSecondsRemaining {
    if (!isLocked) return 0;
    return lockUntil!.difference(DateTime.now()).inSeconds;
  }

  factory WordProgress.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WordProgress(
      userId:       d['userId'] ?? '',
      wordId:       d['wordId'] ?? '',
      section:      d['section'] ?? '',
      baseAp:       (d['baseAp'] ?? 0).toDouble(),
      currentAp:    (d['currentAp'] ?? 0).toDouble(),
      lockUntil:    d['lockUntil'] != null
                      ? (d['lockUntil'] as Timestamp).toDate()
                      : null,
      isBonusWord:  d['isBonusWord'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId':      userId,
    'wordId':      wordId,
    'section':     section,
    'baseAp':      baseAp,
    'currentAp':   currentAp,
    'lockUntil':   lockUntil != null ? Timestamp.fromDate(lockUntil!) : null,
    'isBonusWord': isBonusWord,
  };

  WordProgress copyWith({
    double? currentAp,
    DateTime? lockUntil,
    bool clearLock = false,
  }) {
    return WordProgress(
      userId:       userId,
      wordId:       wordId,
      section:      section,
      baseAp:       baseAp,
      currentAp:    currentAp ?? this.currentAp,
      lockUntil:    clearLock ? null : (lockUntil ?? this.lockUntil),
      isBonusWord:  isBonusWord,
    );
  }
}
