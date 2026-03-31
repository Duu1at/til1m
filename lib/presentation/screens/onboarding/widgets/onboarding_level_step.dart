import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wordup/core/constants/locale_keys.dart';
import 'package:wordup/domain/entities/word.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.onboardingStepLevel.tr(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            LocaleKeys.onboardingStepLevelSubtitle.tr(),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: _levels.map((item) {
                return _LevelCard(
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

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.label,
    required this.desc,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String desc;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4F46E5);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primary : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              desc,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white70 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
