import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// Contact card showing developer social links.
class ContactCard extends StatelessWidget {
  const ContactCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor =
        theme.cardTheme.color ?? theme.colorScheme.surfaceContainerHighest;

    const items = [
      _ContactItem(
        icon: Icons.telegram,
        iconColor: Color(0xFF29B6F6),
        label: 'Telegram',
        value: '+996 702 313 611',
        url: 'https://t.me/+996702313611',
      ),
      _ContactItem(
        icon: Icons.chat_rounded,
        iconColor: Color(0xFF25D366),
        label: 'WhatsApp',
        value: '+996 702 313 611',
        url: 'https://wa.me/996702313611',
      ),

      _ContactItem(
        icon: Icons.mail_outline_rounded,
        iconColor: Color(0xFF4F46E5),
        label: 'Email',
        value: 'dbolsunbekuulu@gmail.com',
        url: 'dbolsunbekuulu@gmail.com',
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _ContactRow(
              item: items[i],
              isFirst: i == 0,
              isLast: i == items.length - 1,
            ),
            if (i < items.length - 1)
              Divider(
                height: AppConstants.dividerThickness,
                thickness: AppConstants.dividerThickness,
                indent: AppConstants.paddingXXL + 22 + AppConstants.paddingM,
                color: theme.dividerColor,
              ),
          ],
        ],
      ),
    );
  }
}

final class _ContactItem {
  const _ContactItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.url,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String url;
}

final class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  final _ContactItem item;
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
        onTap: () => _open(item.url),
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingXXL,
            vertical: AppConstants.paddingM,
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 22, color: item.iconColor),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      item.value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
