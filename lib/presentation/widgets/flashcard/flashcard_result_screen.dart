import 'dart:async';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/theme/app_colors.dart';
import 'package:til1m/presentation/blocs/flashcard/flashcard_bloc.dart';
import 'package:til1m/presentation/widgets/flashcard/stats_grid.dart';

class FlashcardResultScreen extends StatefulWidget {
  const FlashcardResultScreen({
    required this.state,
    required this.onStudyMore,
    required this.onGoHome,
    super.key,
  });

  final FlashcardSessionComplete state;
  final VoidCallback onStudyMore;
  final VoidCallback onGoHome;

  @override
  State<FlashcardResultScreen> createState() => _FlashcardResultScreenState();
}

class _FlashcardResultScreenState extends State<FlashcardResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1, curve: Curves.easeOut),
      ),
    );
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark
        ? AppColors.successDark
        : AppColors.successLight;

    final accuracyPercent = s.totalAnswered == 0
        ? 0
        : ((s.correctCount / s.totalAnswered) * 100).round();
    final isPerfect = s.incorrectCount == 0 && s.totalAnswered > 0;
    final minutes = s.sessionDuration.inMinutes;
    final seconds = s.sessionDuration.inSeconds % 60;
    final durationLabel = minutes > 0
        ? '$minutes мин $seconds сек'
        : '$seconds сек';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingXXL,
          vertical: AppConstants.paddingM,
        ),
        child: Column(
          children: [
            const Spacer(),

            // Animated icon
            AnimatedBuilder(
              animation: _scale,
              builder: (context, child) => Transform.scale(
                scale: _scale.value,
                child: child,
              ),
              child: Icon(
                isPerfect
                    ? Icons.celebration_rounded
                    : Icons.emoji_events_rounded,
                size: 88,
                color: isDark ? AppColors.warningDark : AppColors.warningLight,
              ),
            ),
            const SizedBox(height: AppConstants.paddingXXL),

            // Title
            AnimatedBuilder(
              animation: _fade,
              builder: (context, child) => Opacity(
                opacity: _fade.value,
                child: child,
              ),
              child: Column(
                children: [
                  Text(
                    isPerfect
                        ? 'Отлично! Так держать! 🎉'
                        : 'Сессия завершена!',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if (s.dailyGoalReached || s.currentStreak > 0) ...[
                    const SizedBox(height: AppConstants.paddingM),
                    _StreakBadge(
                      goalReached: s.dailyGoalReached,
                      streak: s.currentStreak,
                    ),
                  ],

                  const SizedBox(height: AppConstants.paddingSection),

                  StatsGrid(
                    totalAnswered: s.totalAnswered,
                    correctCount: s.correctCount,
                    accuracyPercent: accuracyPercent,
                    newWordsLearned: s.newWordsLearned,
                    wordsReviewed: s.wordsReviewed,
                    durationLabel: durationLabel,
                    successColor: successColor,
                  ),
                ],
              ),
            ),

            const Spacer(),

            AnimatedBuilder(
              animation: _fade,
              builder: (context, child) => Opacity(
                opacity: _fade.value,
                child: child,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: AppConstants.buttonHeight,
                    child: FilledButton.icon(
                      onPressed: widget.onStudyMore,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Учить ещё'),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  SizedBox(
                    width: double.infinity,
                    height: AppConstants.buttonHeight,
                    child: OutlinedButton(
                      onPressed: widget.onGoHome,
                      child: const Text('На главную'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
          ],
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.goalReached, required this.streak});

  final bool goalReached;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warningColor = isDark
        ? AppColors.warningDark
        : AppColors.warningLight;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: warningColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingS,
        ),
        child: Text(
          streak > 0 ? '🔥 Streak: $streak дней!' : '✅ Дневная цель выполнена!',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: warningColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
