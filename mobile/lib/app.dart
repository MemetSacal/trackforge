// ── app.dart ────────────────────────────────────────────
// Uygulamanın kök widget'ı.
// GoRouter (navigation) ve MaterialApp burada kurulur.
// Tema sistemi buraya bağlanır.
// Kullanıcı giriş yapmış mı? → Dashboard'a git
// Yapmamış mı? → Login'e git

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/auth/token_manager.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

// ── ROUTER TANIMI ─────────────────────────────────────────
// GoRouter uygulamanın tüm sayfalarını ve geçişlerini yönetir.
// Java'daki intent/navigation gibi düşün ama daha merkezi.
final _router = GoRouter(
  // Uygulama açılınca önce buraya gider, token kontrolü yapar
  initialLocation: '/splash',

  routes: [
    // Splash — token kontrolü için geçici ekran
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Auth ekranları
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // Onboarding — ilk kurulum (4 adım)
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Ana uygulama — bottom navigation burada
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);

// ── APP WIDGET ────────────────────────────────────────────
// ConsumerWidget — Riverpod provider'larına erişebilen widget türü.
// StatelessWidget'tan farkı: ref parametresi ile provider okuyabilir.
class TrackForgeApp extends ConsumerWidget {
  const TrackForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'TrackForge',
      debugShowCheckedModeBanner: false, // Sağ üstteki "DEBUG" yazısını kaldır

      // Tema sistemi — app_theme.dart'tan geliyor
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // Telefon ayarına göre otomatik

      // GoRouter'ı MaterialApp'e bağla
      routerConfig: _router,
    );
  }
}

// ── SPLASH SCREEN ─────────────────────────────────────────
// Uygulama açılınca 1-2 saniye gösterilen ekran.
// Bu sürede token kontrolü yapılır:
// Token var → /home
// Token yok → /login
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Widget ekrana yerleşince token kontrolünü başlat
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Kısa bir bekleme — logo/splash görseli için
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return; // Widget hâlâ ekranda mı kontrol et

    final isLoggedIn = await TokenManager.isLoggedIn();

    if (isLoggedIn) {
      // Token var → ana sayfaya git
      context.go('/home');
    } else {
      // Token yok → login'e git
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Basit splash ekranı — logo + yükleniyor animasyonu
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder — ileride gerçek logo gelecek
            Text(
              '⚡ TrackForge',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24), // Boşluk
            const CircularProgressIndicator(), // Yükleniyor animasyonu
          ],
        ),
      ),
    );
  }
}