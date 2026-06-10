import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/story_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/matchmaking/screens/matchmaking_screen.dart';
import '../../features/matchmaking/screens/friend_room_screen.dart';
import '../../features/matchmaking/screens/rooms_list_screen.dart';
import '../../features/game/screens/reading_phase_screen.dart';
import '../../features/game/screens/combat_screen.dart';
import '../../features/game/screens/result_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/social/screens/friends_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/dictionary/screens/dictionary_home_screen.dart';
import '../../features/dictionary/screens/level_dictionary_screen.dart';
import '../../features/dictionary/screens/dictionary_practice_screen.dart';

// Route names as constants
class Routes {
  static const splash       = '/';
  static const story        = '/story';
  static const login        = '/login';
  static const home         = '/home';
  static const matchmaking  = '/matchmaking';
  static const roomsList    = '/rooms';
  static const friendRoom   = '/friend-room';
  static const readingPhase = '/game/reading';
  static const combat       = '/game/combat';
  static const result       = '/game/result';
  static const leaderboard  = '/leaderboard';
  static const friends      = '/friends';
  static const profile      = '/profile';
  static const dictionary   = '/dictionary';
  static const dictionaryLevel = '/dictionary/level';
  static const dictionaryPractice = '/dictionary/practice';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.story,
        builder: (context, state) => const StoryScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.matchmaking,
        builder: (context, state) {
          final levelStr = state.uri.queryParameters['level'];
          final level = levelStr != null ? int.tryParse(levelStr) ?? 1 : 1;
          return MatchmakingScreen(level: level);
        },
      ),
      GoRoute(
        path: Routes.roomsList,
        builder: (context, state) => const RoomsListScreen(),
      ),
      GoRoute(
        path: Routes.friendRoom,
        builder: (context, state) {
          final roomCode = state.uri.queryParameters['roomCode'];
          return FriendRoomScreen(roomCode: roomCode);
        },
      ),
      GoRoute(
        path: Routes.readingPhase,
        builder: (context, state) {
          final gameId = state.uri.queryParameters['gameId']!;
          return ReadingPhaseScreen(gameId: gameId);
        },
      ),
      GoRoute(
        path: Routes.combat,
        builder: (context, state) {
          final gameId = state.uri.queryParameters['gameId']!;
          return CombatScreen(gameId: gameId);
        },
      ),
      GoRoute(
        path: Routes.result,
        builder: (context, state) {
          final gameId = state.uri.queryParameters['gameId'] ?? '';
          final didQuit = state.uri.queryParameters['didQuit'] == 'true';
          final victoryStr = state.uri.queryParameters['victory'];
          final victory = victoryStr == 'true';
          return ResultScreen(gameId: gameId, didQuit: didQuit, victory: victory);
        },
      ),
      GoRoute(
        path: Routes.leaderboard,
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: Routes.friends,
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.dictionary,
        builder: (context, state) => const DictionaryHomeScreen(),
      ),
      GoRoute(
        path: Routes.dictionaryLevel,
        builder: (context, state) {
          final levelStr = state.uri.queryParameters['level'] ?? '1';
          return LevelDictionaryScreen(level: int.parse(levelStr));
        },
      ),
      GoRoute(
        path: Routes.dictionaryPractice,
        builder: (context, state) {
          final levelStr = state.uri.queryParameters['level'] ?? '1';
          final type = state.uri.queryParameters['type'] ?? 'see';
          return DictionaryPracticeScreen(level: int.parse(levelStr), practiceType: type);
        },
      ),
    ],
  );
});
