import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';

class MenuItem extends StatelessWidget {
  const MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = AppConstants.radiusXL;
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(radius) : Radius.zero,
      bottom: isLast ? const Radius.circular(radius) : Radius.zero,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingXXL,
            vertical: AppConstants.paddingM,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
