import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/router/app_router.dart';
import 'package:til1m/presentation/blocs/home/home_cubit.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({required this.data, super.key});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.style_rounded,
            title: LocaleKeys.flashcardsTitle.tr(context: context),
            subtitle: LocaleKeys.dictionaryWordsCount.tr(
              namedArgs: {'count': '${data.dueCount}'},
            ),
            onTap: () => context.go(AppRoutes.flashcards),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: _ActionCard(
            icon: Icons.edit_rounded,
            title: LocaleKeys.spellingTitle.tr(context: context),
            subtitle: LocaleKeys.homeReviewToday.tr(context: context),
            onTap: () => context.go(AppRoutes.spelling),
          ),
        ),
      ],
    );
  }
}

final class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppConstants.radiusXL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.onPrimaryContainer, size: 28),
              const SizedBox(height: AppConstants.paddingS),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
