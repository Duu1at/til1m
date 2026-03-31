import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordup/core/constants/app_constants.dart';
import 'package:wordup/core/constants/locale_keys.dart';
import 'package:wordup/core/router/app_router.dart';
import 'package:wordup/domain/entities/word.dart';
import 'package:wordup/presentation/screens/onboarding/widgets/onboarding_goal_step.dart';
import 'package:wordup/presentation/screens/onboarding/widgets/onboarding_level_step.dart';
import 'package:wordup/presentation/screens/onboarding/widgets/onboarding_time_step.dart';

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

    await prefs.setString(
      AppConstants.keyUserLevel,
      (_selectedLevel ?? WordLevel.a1).name,
    );

    final goal = _isCustomGoal
        ? (int.tryParse(_customGoalController.text) ?? 5)
        : (_selectedGoal ?? 5);
    await prefs.setInt(AppConstants.keyDailyGoal, goal);

    await prefs.setString(
      AppConstants.keyStudyTimeFrom,
      _formatTime(_studyFrom),
    );
    await prefs.setString(
      AppConstants.keyStudyTimeTo,
      _formatTime(_studyTo),
    );

    await prefs.setBool(AppConstants.keyOnboardingDone, true);

    if (!mounted) return;
    context.go(AppRoutes.home);
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
            _OnboardingProgressBar(
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
            _OnboardingNextButton(
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

class _OnboardingProgressBar extends StatelessWidget {
  const _OnboardingProgressBar({
    required this.currentPage,
    required this.totalSteps,
  });

  final int currentPage;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: List.generate(totalSteps, (i) {
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              margin: EdgeInsets.only(right: i < totalSteps - 1 ? 8 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i <= currentPage
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _OnboardingNextButton extends StatelessWidget {
  const _OnboardingNextButton({
    required this.isLastStep,
    required this.enabled,
    required this.onTap,
  });

  final bool isLastStep;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          disabledForegroundColor: Colors.grey,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          isLastStep
              ? LocaleKeys.onboardingBtnFinish.tr()
              : LocaleKeys.onboardingBtnNext.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
