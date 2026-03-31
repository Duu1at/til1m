import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wordup/core/constants/app_constants.dart';
import 'package:wordup/core/constants/locale_keys.dart';

class OnboardingGoalStep extends StatelessWidget {
  const OnboardingGoalStep({
    required this.selected,
    required this.isCustom,
    required this.controller,
    required this.onSelect,
    required this.onCustomTap,
    required this.onCustomChanged,
    super.key,
  });

  final int? selected;
  final bool isCustom;
  final TextEditingController controller;
  final ValueChanged<int> onSelect;
  final VoidCallback onCustomTap;
  final ValueChanged<String> onCustomChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.onboardingStepGoal.tr(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            LocaleKeys.onboardingStepGoalSubtitle.tr(),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ...AppConstants.dailyGoalOptions.map((count) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GoalOption(
                label: LocaleKeys.onboardingGoalWords
                    .tr(namedArgs: {'count': '$count'}),
                isSelected: !isCustom && selected == count,
                onTap: () => onSelect(count),
              ),
            );
          }),
          _GoalCustomOption(
            isSelected: isCustom,
            controller: controller,
            onTap: onCustomTap,
            onChanged: onCustomChanged,
          ),
        ],
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  const _GoalOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4F46E5);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primary : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _GoalCustomOption extends StatelessWidget {
  const _GoalCustomOption({
    required this.isSelected,
    required this.controller,
    required this.onTap,
    required this.onChanged,
  });

  final bool isSelected;
  final TextEditingController controller;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4F46E5);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primary : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              LocaleKeys.onboardingGoalCustom.tr(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isSelected ? primary : Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            if (isSelected)
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: LocaleKeys.onboardingGoalCustomHint.tr(),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
