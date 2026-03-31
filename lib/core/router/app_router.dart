import 'package:go_router/go_router.dart';
import '../../presentation/screens/onboarding/welcome_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/word_detail/word_detail_screen.dart';
import '../../presentation/screens/flashcards/flashcards_screen.dart';
import '../../presentation/screens/spelling/spelling_screen.dart';
import '../../presentation/screens/dictionary/dictionary_screen.dart';
import '../../presentation/screens/favorites/favorites_screen.dart';
import '../../presentation/screens/statistics/statistics_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../shell/main_shell.dart';

class AppRoutes {
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String wordDetail = '/word/:id';
  static const String flashcards = '/flashcards';
  static const String spelling = '/spelling';
  static const String dictionary = '/dictionary';
  static const String favorites = '/favorites';
  static const String statistics = '/statistics';
  static const String settings = '/settings';
  static const String profile = '/profile';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.welcome,
  routes: [
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.wordDetail,
      builder: (context, state) {
        final wordId = state.pathParameters['id']!;
        return WordDetailScreen(wordId: wordId);
      },
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.flashcards,
          builder: (context, state) => const FlashcardsScreen(),
        ),
        GoRoute(
          path: AppRoutes.spelling,
          builder: (context, state) => const SpellingScreen(),
        ),
        GoRoute(
          path: AppRoutes.dictionary,
          builder: (context, state) => const DictionaryScreen(),
        ),
        GoRoute(
          path: AppRoutes.favorites,
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: AppRoutes.statistics,
          builder: (context, state) => const StatisticsScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
