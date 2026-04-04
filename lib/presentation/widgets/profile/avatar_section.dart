import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/presentation/presentation.dart';

class AvatarSection extends StatelessWidget {
  const AvatarSection({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.isGuest,
    super.key,
  });

  final String? name;
  final String? email;
  final String? avatarUrl;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = isGuest
        ? LocaleKeys.profileGuest.tr(context: context)
        : (name ?? email ?? '—');
    final initials = _initials(name, email, isGuest);

    return Column(
      children: [
        Avatar(avatarUrl: avatarUrl, initials: initials, isGuest: isGuest),
        const SizedBox(height: AppConstants.paddingM),
        Text(
          displayName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        if (!isGuest && email != null && name != null) ...[
          const SizedBox(height: AppConstants.paddingXS),
          Text(
            email!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppConstants.paddingM),
        BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state is! SettingsLoaded) return const SizedBox.shrink();
            return LevelBadge(
              level: state.settings.englishLevel.name.toUpperCase(),
            );
          },
        ),
      ],
    );
  }

  String _initials(String? name, String? email, bool isGuest) {
    if (isGuest) return '?';
    final source = name ?? email ?? '?';
    return source.isNotEmpty ? source[0].toUpperCase() : '?';
  }
}
