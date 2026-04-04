import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/router/app_router.dart';
import 'package:til1m/domain/entities/user_settings.dart';
import 'package:til1m/presentation/presentation.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.settingsTitle.tr(context: context)),
        leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading || state is SettingsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          final settings = state is SettingsLoaded
              ? state.settings
              : const UserSettings();
          return ListView(
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.paddingM,
            ),
            children: [
              SectionHeader(LocaleKeys.homeStreak.tr(context: context)),
              GoalTile(currentGoal: settings.dailyGoal),
              LevelTile(currentLevel: settings.englishLevel),
              const SizedBox(height: AppConstants.paddingS),
              ReminderTile(currentTime: settings.reminderTime),
              const SizedBox(height: AppConstants.paddingS),
              SectionHeader(LocaleKeys.settingsTheme.tr(context: context)),
              ThemeTile(currentTheme: settings.theme),
              const SizedBox(height: AppConstants.paddingS),
              SectionHeader(LocaleKeys.settingsLanguage.tr(context: context)),
              LanguageTile(currentLanguage: settings.uiLanguage),
              const SizedBox(height: AppConstants.paddingS),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  if (authState is! AuthAuthenticated) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        LocaleKeys.settingsAccount.tr(context: context),
                      ),
                      AccountTile(
                        email: context.read<AuthCubit>().currentUserEmail,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppConstants.paddingXXL),
            ],
          );
        },
      ),
    );
  }
}
