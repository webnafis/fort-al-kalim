import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/word_model.dart';

/// Represents one game session between two players.
class GameSession {
  final String gameId;
  final String player1Id;
  final String player2Id;
  final String player1Name;
  final String player2Name;
  final int player1Level;
  final int player2Level;
  final double player1FortHp;   // Remaining HP of player 1's fort
  final double player2FortHp;   // Remaining HP of player 2's fort
  final GameStatus status;
  final String? winnerId;       // null until game ends
  final bool isFriendMatch;     // true if via room code / friend invite
  final DateTime startedAt;
  final DateTime? endedAt;

  const GameSession({
    required this.gameId,
    required this.player1Id,
    required this.player2Id,
    required this.player1Name,
    required this.player2Name,
    required this.player1Level,
    required this.player2Level,
    required this.player1FortHp,
    required this.player2FortHp,
    required this.status,
    this.winnerId,
    required this.isFriendMatch,
    required this.startedAt,
    this.endedAt,
  });

  bool get isActive     => status == GameStatus.combat;
  bool get isFinished   => status == GameStatus.finished;
  bool get isInReading  => status == GameStatus.reading;

  factory GameSession.fromMap(String id, Map<dynamic, dynamic> data) {
    return GameSession(
      gameId:         id,
      player1Id:      data['player1Id'] ?? '',
      player2Id:      data['player2Id'] ?? '',
      player1Name:    data['player1Name'] ?? '',
      player2Name:    data['player2Name'] ?? '',
      player1Level:   data['player1Level'] ?? 1,
      player2Level:   data['player2Level'] ?? 1,
      player1FortHp:  (data['player1FortHp'] ?? 200).toDouble(),
      player2FortHp:  (data['player2FortHp'] ?? 200).toDouble(),
      status:         GameStatus.values.firstWhere(
                        (e) => e.name == (data['status'] ?? 'reading'),
                        orElse: () => GameStatus.reading,
                      ),
      winnerId:       data['winnerId'],
      isFriendMatch:  data['isFriendMatch'] ?? false,
      startedAt:      DateTime.fromMillisecondsSinceEpoch(data['startedAt'] ?? 0),
      endedAt:        data['endedAt'] != null
                        ? DateTime.fromMillisecondsSinceEpoch(data['endedAt'])
                        : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'player1Id':    player1Id,
    'player2Id':    player2Id,
    'player1Name':  player1Name,
    'player2Name':  player2Name,
    'player1Level': player1Level,
    'player2Level': player2Level,
    'player1FortHp':player1FortHp,
    'player2FortHp':player2FortHp,
    'status':       status.name,
    'winnerId':     winnerId,
    'isFriendMatch':isFriendMatch,
    'startedAt':    startedAt.millisecondsSinceEpoch,
    'endedAt':      endedAt?.millisecondsSinceEpoch,
  };

  GameSession copyWith({
    double? player1FortHp,
    double? player2FortHp,
    GameStatus? status,
    String? winnerId,
    DateTime? endedAt,
  }) {
    return GameSession(
      gameId:         gameId,
      player1Id:      player1Id,
      player2Id:      player2Id,
      player1Name:    player1Name,
      player2Name:    player2Name,
      player1Level:   player1Level,
      player2Level:   player2Level,
      player1FortHp:  player1FortHp  ?? this.player1FortHp,
      player2FortHp:  player2FortHp  ?? this.player2FortHp,
      status:         status         ?? this.status,
      winnerId:       winnerId       ?? this.winnerId,
      isFriendMatch:  isFriendMatch,
      startedAt:      startedAt,
      endedAt:        endedAt        ?? this.endedAt,
    );
  }
}

enum GameStatus {
  waiting,   // Matched, setting up words
  reading,   // Reading phase (pre-combat)
  combat,    // Active combat
  finished,  // Game over
}

/// Holds the word assignments for ONE player in ONE game.
/// Contains 4 lists (one per section) sorted by current AP descending.
class PlayerGameWords {
  final String playerId;
  final String gameId;
  // Maps section name → list of (word, progress) sorted by AP desc
  final Map<String, List<GameWord>> sections;

  const PlayerGameWords({
    required this.playerId,
    required this.gameId,
    required this.sections,
  });

  List<GameWord> wordsForSection(String section) =>
      sections[section] ?? [];
}

/// A word with its current progress, used during a game session.
class GameWord {
  final WordModel word;
  WordProgress progress;

  GameWord({required this.word, required this.progress});

  bool get isAvailable => !progress.isLocked && !progress.isExhausted;
  double get currentAp  => progress.currentAp;
  double get baseAp     => progress.baseAp;
}
