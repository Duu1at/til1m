import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/router/app_router.dart';
import 'package:til1m/domain/entities/user_settings.dart';
import 'package:til1m/domain/entities/word.dart';
import 'package:til1m/presentation/presentation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _totalSteps = 3;

  final _pageController = PageController();
  int _currentPage = 0;

  WordLevel? _selectedLevel;

  int? _selectedGoal;
  bool _isCustomGoal = false;
  final _customGoalController = TextEditingController();

  TimeOfDay _studyFrom = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _studyTo = const TimeOfDay(hour: 19, minute: 0);

  @override
  void dispose() {
    _pageController.dispose();
    _customGoalController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 0:
        return _selectedLevel != null;
      case 1:
        if (_isCustomGoal) {
          final val = int.tryParse(_customGoalController.text);
          return val != null && val > 0;
        }
        return _selectedGoal != null;
      case 2:
        return true;
      default:
        return false;
    }
  }

  Future<void> _next() async {
    if (_currentPage < _totalSteps - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      await _saveAndFinish();
    }
  }

  Future<void> _saveAndFinish() async {
    final prefs = await SharedPreferences.getInstance();

    final level = _selectedLevel ?? WordLevel.a1;
    await prefs.setString(AppConstants.keyUserLevel, level.name);

    final goal = _isCustomGoal
        ? (int.tryParse(_customGoalController.text) ?? 5)
        : (_selectedGoal ?? 5);
    await prefs.setInt(AppConstants.keyDailyGoal, goal);

    await prefs.setString(
      AppConstants.keyStudyTimeFrom,
      _formatTime(_studyFrom),
    );
    await prefs.setString(AppConstants.keyStudyTimeTo, _formatTime(_studyTo));

    await prefs.setBool(AppConstants.keyOnboardingDone, true);

    if (!mounted) return;
    final authCubit = context.read<AuthCubit>();

    // ── Path 1: user is already authenticated but had no user_settings ──
    // (direct OAuth sign-up — Google / Apple without WelcomeScreen flow)
    if (authCubit.state is AuthNeedsOnboarding) {
      final uiLangName =
          prefs.getString(AppConstants.keyUiLanguage) ?? UiLanguage.ru.name;
      await authCubit.completeAuthenticatedOnboarding(
        UserSettings(
          dailyGoal: goal,
          englishLevel: level,
          uiLanguage: UiLanguage.values.firstWhere(
            (l) => l.name == uiLangName,
            orElse: () => UiLanguage.ru,
          ),
        ),
      );
      // Router automatically redirects to /home when AuthAuthenticated is emitted.
      return;
    }

    final pendingAuth = prefs.getString(AppConstants.keyPendingAuth);
    await prefs.remove(AppConstants.keyPendingAuth);

    // ── Path 2: WelcomeScreen → onboarding → register (email sign-up) ──
    if (pendingAuth == 'register') {
      if (!mounted) return;
      context.go(AppRoutes.register);
      return;
    }

    // ── Path 3: guest flow ───────────────────────────────────────────────
    await authCubit.continueAsGuest();
    // Router redirects to /home when AuthGuest is emitted on _setupRoutes.
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OnboardingProgressBar(
              currentPage: _currentPage,
              totalSteps: _totalSteps,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  OnboardingLevelStep(
                    selected: _selectedLevel,
                    onSelect: (l) => setState(() => _selectedLevel = l),
                  ),
                  OnboardingGoalStep(
                    selected: _selectedGoal,
                    isCustom: _isCustomGoal,
                    controller: _customGoalController,
                    onSelect: (g) => setState(() {
                      _selectedGoal = g;
                      _isCustomGoal = false;
                    }),
                    onCustomTap: () => setState(() {
                      _selectedGoal = null;
                      _isCustomGoal = true;
                    }),
                    onCustomChanged: (_) => setState(() {}),
                  ),
                  OnboardingTimeStep(
                    from: _studyFrom,
                    to: _studyTo,
                    onFromChanged: (t) => setState(() => _studyFrom = t),
                    onToChanged: (t) => setState(() => _studyTo = t),
                  ),
                ],
              ),
            ),
            OnboardingNextButton(
              isLastStep: _currentPage == _totalSteps - 1,
              enabled: _canProceed,
              onTap: _next,
            ),
          ],
        ),
      ),
    );
  }
}
