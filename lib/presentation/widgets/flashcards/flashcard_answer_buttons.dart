import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/theme/app_colors.dart';

class FlashcardAnswerButtons extends StatelessWidget {
  const FlashcardAnswerButtons({
    required this.onKnew,
    required this.onDidntKnow,
    super.key,
  });

  final VoidCallback onKnew;
  final VoidCallback onDidntKnow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final successColor =
        isDark ? AppColors.successDark : AppColors.successLight;
    final failColor = theme.colorScheme.error;

    return Row(
      children: [
        Expanded(
          child: _AnswerButton(
            label: LocaleKeys.wordBtnDontKnow.tr(context: context),
            icon: Icons.close_rounded,
            color: failColor,
            onTap: onDidntKnow,
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: _AnswerButton(
            label: LocaleKeys.wordBtnKnow.tr(context: context),
            icon: Icons.check_rounded,
            color: successColor,
            onTap: onKnew,
          ),
        ),
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: AppConstants.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          ),
          backgroundColor: color.withValues(alpha: 0.06),
        ),
      ),
    );
  }
}
