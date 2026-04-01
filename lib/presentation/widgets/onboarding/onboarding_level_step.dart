import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wordup/core/constants/app_constants.dart';
import 'package:wordup/core/constants/locale_keys.dart';
import 'package:wordup/domain/entities/word.dart';
import 'package:wordup/presentation/presentation.dart';

class OnboardingLevelStep extends StatelessWidget {
  const OnboardingLevelStep({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final WordLevel? selected;
  final ValueChanged<WordLevel> onSelect;

  static const List<({WordLevel level, String label, String desc})> _levels = [
    (level: WordLevel.a1, label: 'A1', desc: 'Beginner'),
    (level: WordLevel.a2, label: 'A2', desc: 'Elementary'),
    (level: WordLevel.b1, label: 'B1', desc: 'Intermediate'),
    (level: WordLevel.b2, label: 'B2', desc: 'Upper-Intermediate'),
    (level: WordLevel.c1, label: 'C1', desc: 'Advanced'),
    (level: WordLevel.c2, label: 'C2', desc: 'Proficient'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingXXL,
        AppConstants.paddingSection,
        AppConstants.paddingXXL,
        AppConstants.paddingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.onboardingStepLevel.tr(context: context),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingXS),
          Text(
            LocaleKeys.onboardingStepLevelSubtitle.tr(context: context),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSection),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: AppConstants.paddingM,
              crossAxisSpacing: AppConstants.paddingM,
              childAspectRatio: 2.2,
              children: _levels.map((item) {
                return OnboardingLevelCard(
                  label: item.label,
                  desc: item.desc,
                  isSelected: selected == item.level,
                  onTap: () => onSelect(item.level),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
