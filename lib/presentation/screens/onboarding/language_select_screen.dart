import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/core/router/app_router.dart';
import 'package:til1m/presentation/presentation.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_checkAlreadySelected());
  }

  Future<void> _checkAlreadySelected() async {
    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getBool(AppConstants.keyLanguageSelected) ?? false;
    if (!selected || !mounted) return;

    final onboardingDone =
        prefs.getBool(AppConstants.keyOnboardingDone) ?? false;
    if (onboardingDone) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  Future<void> _selectLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUiLanguage, langCode);
    await prefs.setBool(AppConstants.keyLanguageSelected, true);
    if (!mounted) return;
    await context.setLocale(Locale(langCode));
    if (!mounted) return;
    context.go(AppRoutes.welcome);
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
                  'Выберите язык · Тилди тандаңыз',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingS),
              Center(
                child: Text(
                  'На каком языке учить английский?\nАнглисчени кайсы тилде үйрөнөсүз?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              LangCard(
                flag: '🇷🇺',
                title: 'Русский',
                subtitle: 'Изучать английский на русском',
                onTap: () => unawaited(_selectLanguage('ru')),
              ),
              const SizedBox(height: AppConstants.paddingL),
              LangCard(
                flag: '🇰🇬',
                title: 'Кыргызча',
                subtitle: 'Англисчени кыргызча үйрөнүү',
                onTap: () => unawaited(_selectLanguage('ky')),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
