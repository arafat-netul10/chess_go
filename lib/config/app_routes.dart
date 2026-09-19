import 'package:go_router/go_router.dart';
import '../ui/features/splash/splash_screen.dart';
import '../ui/features/home/home_screen.dart';
import '../ui/features/game/views/game_screen.dart';
import '../ui/features/lobby/online_lobby_screen.dart';
import '../ui/features/leaderboard/leaderboard_screen.dart';
import '../ui/features/profile/profile_screen.dart';

/// Declarative GoRouter configuration for cross-platform navigation
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) => const GameScreen(),
    ),
    GoRoute(
      path: '/lobby',
      builder: (context, state) => const OnlineLobbyScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
