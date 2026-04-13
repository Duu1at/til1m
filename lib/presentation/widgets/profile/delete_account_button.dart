import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/presentation/blocs/auth/auth_cubit.dart';

class DeleteAccountButton extends StatelessWidget {
  const DeleteAccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return TextButton.icon(
      onPressed: () => _confirm(context),
      icon: Icon(Icons.delete_forever_rounded, size: 18, color: errorColor),
      label: Text(
        LocaleKeys.profileBtnDeleteAccount.tr(context: context),
        style: TextStyle(color: errorColor, fontSize: 13),
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: colorScheme.error,
          size: 36,
        ),
        title: Text(
          LocaleKeys.profileDeleteAccountTitle.tr(context: dialogCtx),
        ),
        content: Text(
          LocaleKeys.profileDeleteAccountBody.tr(context: dialogCtx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(LocaleKeys.profileBtnCancel.tr(context: dialogCtx)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: Text(
              LocaleKeys.profileDeleteAccountConfirm.tr(context: dialogCtx),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthCubit>().deleteAccount();
    }
  }
}
