// ── app.dart ────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/auth/token_manager.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/splash/splash_screen.dart';

// ── THEME PROVIDER ────────────────────────────────────────
// ThemeMode state'ini tutan provider.
// shared_preferences'a kaydedilir — uygulama kapanınca kaybolmaz.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  // Başlangıçta system — shared_prefs'ten yüklenir
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  // Kaydedilen tercihi yükle
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode') ?? 'system';
    state = _fromString(saved);
  }

  // Dark/light arasında toggle
  Future<void> toggle() async {
    final next =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _toString(next));
  }

  // Direkt set et
  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _toString(mode));
  }

  String _toString(ThemeMode m) {
    switch (m) {
      case ThemeMode.dark: return 'dark';
      case ThemeMode.light: return 'light';
      default: return 'system';
    }
  }

  ThemeMode _fromString(String s) {
    switch (s) {
      case 'dark': return ThemeMode.dark;
      case 'light': return ThemeMode.light;
      default: return ThemeMode.system;
    }
  }
}

// ── ROUTER ────────────────────────────────────────────────
final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
  ],
);

// ── APP WIDGET ────────────────────────────────────────────
class TrackForgeApp extends ConsumerWidget {
  const TrackForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // themeModeProvider'ı izle — değişince rebuild olur
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'TrackForge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
      // FIX #8: responsive overflow guard.
      // Chrome device mode %75 zoom gibi "sanal küçük ekranlarda" sistem
      // textScaleFactor'ü 1.0'ın üstüne çıkarıyor → sabit boyutlu Card/Row
      // taşıyor. Burada 1.15 tavanı koyuyoruz: erişilebilirliği bozmaz ama
      // layout'u korur. Ayrıca visualDensity.compact padding/spacing'i
      // ~8px daraltır; küçük ekranda kart içi nefes alanı açar.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
