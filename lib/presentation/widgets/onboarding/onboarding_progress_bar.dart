import 'package:flutter/material.dart';
import 'package:wordup/core/constants/app_constants.dart';

class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    required this.currentPage,
    required this.totalSteps,
    super.key,
  });

  final int currentPage;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingXXL,
        AppConstants.paddingXL,
        AppConstants.paddingXXL,
        0,
      ),
      child: Row(
        children: List.generate(totalSteps, (i) {
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              margin: EdgeInsets.only(
                right: i < totalSteps - 1 ? AppConstants.paddingS : 0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.radiusXS),
                color: i <= currentPage
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
          );
        }),
      ),
    );
  }
}
