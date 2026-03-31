import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _currentSlide = 0;

  final List<_SlideData> _slides = const [
    _SlideData(
      icon: Icons.style,
      title: 'Карточки с изображениями',
      subtitle: 'Изучай слова с картинками, транскрипцией и аудио',
    ),
    _SlideData(
      icon: Icons.edit,
      title: 'Режим написания слов',
      subtitle: 'Проверяй правописание и закрепляй знания',
    ),
    _SlideData(
      icon: Icons.bar_chart,
      title: 'Отслеживай свой прогресс',
      subtitle: 'Streak, статистика и алгоритм повторения SM-2',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true;
    if (!isFirst && mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsFirstLaunch, false);
  }

  Future<void> _navigate(String route) async {
    await _markSeen();
    if (!mounted) return;
    context.go(route);
  }

  Future<void> _continueAsGuest() async {
    await _markSeen();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyGuestMode, true);
    if (!mounted) return;
    context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.school, size: 72, color: Color(0xFF4F46E5)),
              const SizedBox(height: 16),
              Text('WordUp', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
              const SizedBox(height: 8),
              Text('Изучай английские слова\nс переводом на русский и кыргызский', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 40),
              SizedBox(
                height: 160,
                child: PageView.builder(
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _currentSlide = i),
                  itemBuilder: (context, i) => _SlideCard(data: _slides[i]),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentSlide ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i == _currentSlide ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                  ),
                )),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _navigate(AppRoutes.register),
                child: const Text('Создать аккаунт'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _continueAsGuest,
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                child: const Text('Продолжить без аккаунта'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _navigate(AppRoutes.login),
                child: const Text('Уже есть аккаунт? Войти'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SlideData({required this.icon, required this.title, required this.subtitle});
}

class _SlideCard extends StatelessWidget {
  final _SlideData data;
  const _SlideCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(data.icon, size: 48, color: const Color(0xFF4F46E5)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(data.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(data.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
