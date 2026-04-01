import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordup/core/constants/app_constants.dart';
import 'package:wordup/core/constants/locale_keys.dart';
import 'package:wordup/core/router/app_router.dart';
import 'package:wordup/presentation/presentation.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_checkFirstLaunch());
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true;
    if (!isFirst && mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _go(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsFirstLaunch, false);
    if (!mounted) return;
    context.go(route);
  }

  Future<void> _continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsFirstLaunch, false);
    await prefs.setBool(AppConstants.keyGuestMode, true);
    if (!mounted) return;
    context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingWide,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusXXL),
                  ),
                  child: SizedBox.square(
                    dimension: AppConstants.logoBoxSize,
                    child: Center(
                      child: Icon(
                        Icons.school_rounded,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingXL),
              Center(
                child: Text(
                  LocaleKeys.welcomeTitle.tr(context: context),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingS),
              Center(
                child: Text(
                  LocaleKeys.welcomeSubtitle.tr(context: context),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingLarge),
              WelcomeFeatureRow(
                icon: Icons.chat_bubble_outline_rounded,
                text: LocaleKeys.welcomeFeature1.tr(context: context),
              ),
              const SizedBox(height: AppConstants.paddingL),
              WelcomeFeatureRow(
                icon: Icons.verified_outlined,
                text: LocaleKeys.welcomeFeature2.tr(context: context),
              ),
              const SizedBox(height: AppConstants.paddingL),
              WelcomeFeatureRow(
                icon: Icons.loop_rounded,
                text: LocaleKeys.welcomeFeature3.tr(context: context),
              ),
              const Spacer(flex: 3),
              ElevatedButton(
                onPressed: () => unawaited(_go(AppRoutes.register)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(
                    double.infinity,
                    AppConstants.buttonHeight,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  LocaleKeys.welcomeBtnRegister.tr(context: context),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
              OutlinedButton(
                onPressed: () => unawaited(_go(AppRoutes.login)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(
                    double.infinity,
                    AppConstants.buttonHeight,
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  ),
                ),
                child: Text(
                  LocaleKeys.welcomeBtnLogin.tr(context: context),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingL),
              Center(
                child: TextButton(
                  onPressed: () => unawaited(_continueAsGuest()),
                  child: Text(
                    LocaleKeys.welcomeBtnGuest.tr(context: context),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingM),
            ],
          ),
        ),
      ),
    );
  }
}
