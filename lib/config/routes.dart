import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/home_screen.dart';
import '../screens/download_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/media_library_screen.dart';
import '../screens/browser_screen.dart';
import '../screens/pro_screen.dart';
import '../screens/app_lock_screen.dart';
import '../screens/conversion_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String download = '/download';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String library = '/library';
  static const String browser = '/browser';
  static const String pro = '/pro';
  static const String lock = '/lock';
  static const String conversion = '/conversion';

  static Route<dynamic> _pageTransition(
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
    Offset begin = const Offset(0.0, 1.0),
  }) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: duration,
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween(begin: begin, end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic))
            .animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SplashScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        );
      case '/onboarding':
        return _pageTransition(const OnboardingScreen(), duration: const Duration(milliseconds: 500));
      case '/home':
        return _pageTransition(const HomeScreen());
      case '/download':
        final args = settings.arguments as Map<String, dynamic>?;
        return _pageTransition(DownloadScreen(url: args?['url'] ?? ''));
      case '/history':
        return _pageTransition(const HistoryScreen(),
          begin: const Offset(1.0, 0.0));
      case '/settings':
        return _pageTransition(const SettingsScreen(),
          begin: const Offset(1.0, 0.0));
      case '/library':
        return _pageTransition(const MediaLibraryScreen());
      case '/browser':
        return _pageTransition(const BrowserScreen(), duration: const Duration(milliseconds: 300));
      case '/pro':
        return _pageTransition(const ProScreen());
      case '/lock':
        return PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AppLockScreen(),
          transitionDuration: Duration.zero,
        );
      case '/conversion':
        final args = settings.arguments as Map<String, dynamic>?;
        return _pageTransition(ConversionScreen(
          task: args?['task'],
          filePath: args?['filePath'],
        ));
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}