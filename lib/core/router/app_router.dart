import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/matchmaking/screens/matchmaking_screen.dart';
import '../../features/matchmaking/screens/friend_room_screen.dart';
import '../../features/game/screens/reading_phase_screen.dart';
import '../../features/game/screens/combat_screen.dart';
import '../../features/game/screens/result_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/social/screens/friends_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

// Route names as constants
class Routes {
  static const splash       = '/';
  static const login        = '/login';
  static const home         = '/home';
  static const matchmaking  = '/matchmaking';
  static const friendRoom   = '/friend-room';
  static const readingPhase = '/game/reading';
  static const combat       = '/game/combat';
  static const result       = '/game/result';
  static const leaderboard  = '/leaderboard';
  static const friends      = '/friends';
  static const profile      = '/profile';
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
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.matchmaking,
        builder: (context, state) => const MatchmakingScreen(),
      ),
      GoRoute(
        path: Routes.friendRoom,
        builder: (context, state) {
          final roomCode = state.uri.queryParameters['code'];
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
          final gameId = state.uri.queryParameters['gameId']!;
          return ResultScreen(gameId: gameId);
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
    ],
  );
});
