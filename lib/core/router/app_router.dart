import 'package:go_router/go_router.dart';
import 'package:til1m/core/shell/main_shell.dart';
import 'package:til1m/core/utils/go_router_refresh_stream.dart';
import 'package:til1m/presentation/blocs/auth/auth_cubit.dart';
import 'package:til1m/presentation/screens/auth/forgot_password_screen.dart';
import 'package:til1m/presentation/screens/auth/login_screen.dart';
import 'package:til1m/presentation/screens/auth/register_screen.dart';
import 'package:til1m/presentation/screens/dictionary/dictionary_screen.dart';
import 'package:til1m/presentation/screens/favorites/favorites_screen.dart';
import 'package:til1m/presentation/screens/flashcards/flashcards_screen.dart';
import 'package:til1m/presentation/screens/home/home_screen.dart';
import 'package:til1m/presentation/screens/onboarding/language_select_screen.dart';
import 'package:til1m/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:til1m/presentation/screens/onboarding/welcome_screen.dart';
import 'package:til1m/presentation/screens/profile/profile_screen.dart';
import 'package:til1m/presentation/screens/settings/settings_screen.dart';
import 'package:til1m/presentation/screens/spelling/spelling_screen.dart';
import 'package:til1m/presentation/screens/statistics/statistics_screen.dart';
import 'package:til1m/presentation/screens/word_detail/word_detail_screen.dart';

final class AppRoutes {
  static const String languageSelect = '/language-select';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
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

// Setup screens that make no sense once the user is onboarded.
const Set<String> _setupRoutes = {
  AppRoutes.languageSelect,
  AppRoutes.welcome,
  AppRoutes.onboarding,
};

// Auth screens that logged-in / guest users should never land on.
const Set<String> _authOnlyRoutes = {
  AppRoutes.login,
  AppRoutes.register,
};

// All routes that are openly accessible without any session.
const Set<String> _publicRoutes = {
  AppRoutes.languageSelect,
  AppRoutes.welcome,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
};

GoRouter createRouter(AuthCubit authCubit) => GoRouter(
  initialLocation: AppRoutes.languageSelect,
  refreshListenable: GoRouterRefreshStream(authCubit.stream),
  redirect: (context, state) {
    final authState = authCubit.state;
    if (authState is AuthInitial) return null;

    final isAuthenticated = authState is AuthAuthenticated;
    final isGuest = authState is AuthGuest;
    final isUnauthenticated = authState is AuthUnauthenticated;
    final needsOnboarding = authState is AuthNeedsOnboarding;
    final location = state.matchedLocation;

    // User who needs onboarding is funneled exclusively to /onboarding until
    // completeAuthenticatedOnboarding() emits AuthAuthenticated.
    if (needsOnboarding && location != AppRoutes.onboarding) {
      return AppRoutes.onboarding;
    }

    // Authenticated / explicit-guest users skip the setup flow.
    if ((isAuthenticated || isGuest) && _setupRoutes.contains(location)) {
      return AppRoutes.home;
    }

    // Authenticated / guest users have no reason to be on login/register.
    if ((isAuthenticated || isGuest) && _authOnlyRoutes.contains(location)) {
      return AppRoutes.home;
    }

    // Unauthenticated (logged-out) users cannot access protected routes.
    // They are sent to login; the welcome/onboarding slides are NOT shown.
    if (isUnauthenticated && !_publicRoutes.contains(location)) {
      return AppRoutes.login;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.languageSelect,
      builder: (context, state) => const LanguageSelectScreen(),
    ),
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
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
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
