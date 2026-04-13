import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/router/app_router.dart';
import 'package:til1m/presentation/presentation.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (_, current) => current is AuthUnauthenticated,
      listener: (ctx, _) => ctx.go(AppRoutes.welcome),
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocaleKeys.profileTitle.tr(context: context)),
        ),
        body: Builder(
          builder: (context) {
            final authCubit = context.read<AuthCubit>();
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingXXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AvatarSection(
                    name: authCubit.currentUserName,
                    email: authCubit.currentUserEmail,
                    avatarUrl: authCubit.currentUserAvatarUrl,
                  ),
                  const SizedBox(height: AppConstants.paddingSection),
                  const QuickStatsRow(),
                  const SizedBox(height: AppConstants.paddingSection),
                  const MenuCard(),
                  const SizedBox(height: AppConstants.paddingSection),
                  SectionHeader(
                    LocaleKeys.profileContactSection.tr(context: context),
                  ),
                  const ContactCard(),
                  const SizedBox(height: AppConstants.paddingLarge),
                  const LogoutButton(),
                  const SizedBox(height: AppConstants.paddingS),
                  const Center(child: DeleteAccountButton()),
                  const SizedBox(height: AppConstants.paddingXXL),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
