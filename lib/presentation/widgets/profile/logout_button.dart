import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/presentation/presentation.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({required this.isGuest, super.key});

  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return OutlinedButton.icon(
      onPressed: () => _confirmLogout(context),
      icon: const Icon(Icons.logout),
      label: Text(LocaleKeys.profileBtnLogout.tr()),
      style: OutlinedButton.styleFrom(
        foregroundColor: errorColor,
        side: BorderSide(color: errorColor.withValues(alpha: 0.5)),
        minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(LocaleKeys.profileBtnLogoutConfirm.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(LocaleKeys.profileBtnCancel.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(LocaleKeys.profileBtnConfirm.tr()),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<AuthCubit>().signOut();
    }
  }
}
