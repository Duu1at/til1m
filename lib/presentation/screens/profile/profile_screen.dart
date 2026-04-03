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
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final isGuest = authState is AuthGuest;
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
                    isGuest: isGuest,
                  ),
                  const SizedBox(height: AppConstants.paddingSection),
                  const QuickStatsRow(),
                  if (isGuest) ...[
                    const SizedBox(height: AppConstants.paddingXXL),
                    const GuestCallToAction(),
                  ],
                  const SizedBox(height: AppConstants.paddingSection),
                  const MenuCard(),
                  const SizedBox(height: AppConstants.paddingLarge),
                  LogoutButton(isGuest: isGuest),
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
