import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';

class AccountTile extends StatelessWidget {
  const AccountTile({required this.email, super.key});

  final String? email;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingXXL,
      ),
      leading: const Icon(Icons.email_outlined),
      title: Text(email ?? '—'),
      subtitle: Text(LocaleKeys.authEmail.tr(context: context)),
    );
  }
}
