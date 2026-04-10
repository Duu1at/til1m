import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/domain/repositories/auth_repository.dart';

enum SoftAuthTrigger {
  /// Shown after the first completed flashcard session and every 5th session.
  sessionComplete,

  /// Shown when a guest taps the Favorites action.
  favorites,
}

/// A non-blocking registration nudge shown as a modal bottom sheet.
///
/// Rules:
///   - Only shown to guests (`AuthRepository.isGuest == true`).
///   - Shown at most once per app lifecycle (static flag).
///   - For [SoftAuthTrigger.sessionComplete]: shown on the 1st session and
///     every 5th session thereafter (counter persisted in SharedPreferences).
abstract final class SoftAuthPrompt {
  SoftAuthPrompt._();

  // ─── Public API ───────────────────────────────────────────────────────────────

  /// Shows the bottom sheet if the conditions are met.
  ///
  /// Returns immediately if the user is authenticated, the prompt has already
  /// been shown this app session, or the session-count threshold is not met.
  static Future<void> showIfNeeded(
    BuildContext context, {
    required AuthRepository authRepo,
    required SoftAuthTrigger trigger,
  }) async {
    if (!authRepo.isGuest) return;
    if (_shownThisSession) return;
    if (!context.mounted) return;

    if (trigger == SoftAuthTrigger.sessionComplete) {
      final shouldShow = await _checkSessionThreshold();
      if (!shouldShow) return;
    }

    if (!context.mounted) return;

    _shownThisSession = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusXXL)),
      ),
      builder: (_) => _content(trigger),
    );
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  static bool _shownThisSession = false;

  /// Increments the guest session counter.
  /// Returns true if the prompt should be displayed for this count.
  static Future<bool> _checkSessionThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(AppConstants.keyGuestSessionCount) ?? 0) + 1;
    await prefs.setInt(AppConstants.keyGuestSessionCount, count);
    return count == 1 || count % 5 == 0;
  }

  static Widget _content(SoftAuthTrigger trigger) {
    return switch (trigger) {
      SoftAuthTrigger.sessionComplete => const _SoftAuthSheet(
        icon: Icons.cloud_upload_outlined,
        title: 'Сохрани свой прогресс',
        subtitle: 'Создай аккаунт, чтобы прогресс не пропал при удалении приложения',
      ),
      SoftAuthTrigger.favorites => const _SoftAuthSheet(
        icon: Icons.favorite_border_rounded,
        title: 'Войди, чтобы сохранять слова',
        subtitle: 'Избранное доступно только зарегистрированным пользователям',
      ),
    };
  }
}

// ─── Bottom Sheet content ─────────────────────────────────────────────────────

class _SoftAuthSheet extends StatelessWidget {
  const _SoftAuthSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.paddingXXL,
          AppConstants.paddingXXL,
          AppConstants.paddingXXL,
          AppConstants.paddingL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            SizedBox(
              width: 40,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingXXL),

            // Icon
            SizedBox(
              width: AppConstants.logoBoxSize,
              height: AppConstants.logoBoxSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, size: 36, color: colorScheme.onPrimaryContainer),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),

            // Title
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingS),

            // Subtitle
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingSection),

            // Primary CTA
            FilledButton(
              onPressed: () {
                context.pop();
                unawaited(context.push('/register'));
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
              ),
              child: const Text('Создать аккаунт'),
            ),
            const SizedBox(height: AppConstants.paddingS),

            // Dismiss
            TextButton(
              onPressed: () => context.pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
              ),
              child: Text(
                'Позже',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
