import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:til1m/core/constants/locale_keys.dart';
import 'package:til1m/core/router/app_router.dart';

final class MainShell extends StatelessWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.home)) {
      return 0;
    }
    if (location.startsWith(AppRoutes.flashcards) ||
        location.startsWith(AppRoutes.spelling)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.dictionary) ||
        location.startsWith(AppRoutes.favorites)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.profile) ||
        location.startsWith(AppRoutes.statistics) ||
        location.startsWith(AppRoutes.settings)) {
      return 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
            case 1:
              context.go(AppRoutes.flashcards);
            case 2:
              context.go(AppRoutes.dictionary);
            case 3:
              context.go(AppRoutes.profile);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: LocaleKeys.navHome.tr(context: context),
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school),
            label: LocaleKeys.navLearn.tr(context: context),
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: LocaleKeys.navDictionary.tr(context: context),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person),
            label: LocaleKeys.navProfile.tr(context: context),
          ),
        ],
      ),
    );
  }
}
