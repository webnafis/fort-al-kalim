// ══════════════════════════════════════════════════════
//  App-wide constants for Fort Al-Kalim
// ══════════════════════════════════════════════════════

class AppConstants {
  AppConstants._();

  // ── Game Balance ────────────────────────────────────
  /// HP of each player's fort. Fixed for all levels.
  static const int fortHp = 200;

  /// Seconds a word is locked after a failed attack attempt.
  static const int lockDurationSeconds = 30;

  /// Number of uses before a word is fully exhausted.
  static const int wordMaxUses = 4;

  /// Percentage of base AP lost per successful use (25%).
  static const double apDegradationRate = 0.25;

  /// Target number of words per section per player per game.
  static const int wordsPerSection = 10;

  /// Multipliers for each attack section.
  static const Map<String, double> sectionMultipliers = {
    'see':    1.00,
    'listen': 1.25,
    'write':  1.50,
    'speak':  1.75,
  };

  /// Sum of all section multipliers (for AP formula).
  static const double multiplierSum = 5.5; // 1.0+1.25+1.5+1.75

  // ── Matchmaking ─────────────────────────────────────
  /// Maximum seconds a player waits before forced match or AI.
  static const int matchmakingTimeoutSeconds = 15;

  // ── Friend Match (Room Codes) ────────────────────────
  /// Characters used for room code generation.
  static const String roomCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Length of generated room codes.
  static const int roomCodeLength = 6;

  /// Minutes before an unclaimed room code expires.
  static const int roomCodeExpiryMinutes = 5;

  /// Minutes before an unaccepted friend invite expires.
  static const int friendInviteExpiryMinutes = 2;

  // ── Words & Levels ───────────────────────────────────
  /// Number of words in each level.
  static const int wordsPerLevel = 100;

  // ── Score & Leaderboard ──────────────────────────────
  /// Number of top entries shown in leaderboard.
  static const int leaderboardTopN = 100;

  // ── Firebase Collection Names ────────────────────────
  static const String colUsers        = 'users';
  static const String colWords        = 'words';
  static const String colProgress     = 'progress';
  static const String colGames        = 'games';
  static const String colRooms        = 'rooms';
  static const String colInvites      = 'invites';
  static const String colLeaderboard  = 'leaderboard';

  // ── Realtime DB Paths ────────────────────────────────
  static const String rtdbMatchmaking = 'matchmaking';
  static const String rtdbRooms       = 'rooms';
  static const String rtdbGameSessions= 'game_sessions';
}
