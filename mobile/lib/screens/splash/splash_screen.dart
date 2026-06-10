import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _imgScale;
  late Animation<double> _imgOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _barWidth;

  static const _bg     = Color(0xFF0C0D10);
  static const _accent = Color(0xFFFFB020);
  static const _sub    = Color(0xFF8A88A8);
  static const _track  = Color(0xFF1E2030);

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Görsel: 0.0 → 0.5 arası scale + opacity
    _imgScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _imgOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Metin + bar: 0.5 → 1.0 arası
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 0.85, curve: Curves.easeIn),
      ),
    );

    // Bar genişliği 0 → 1 (progress simülasyonu)
    _barWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.55, 1.0, curve: Curves.easeInOut),
      ),
    );

    _ctrl.forward();
    _navigate();
  }

 Future<void> _navigate() async {
   await Future.delayed(const Duration(milliseconds: 3400));
   if (!mounted) return;
   SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

   final prefs = await SharedPreferences.getInstance();
   final sessionOnly = prefs.getBool('session_only') ?? false;
   if (sessionOnly) {
     await TokenManager.clearTokens();
     await prefs.remove('session_only');
     if (!mounted) return;
     context.go('/login');
     return;
   }

   final isLoggedIn = await TokenManager.isLoggedIn();
   if (!mounted) return;
   if (isLoggedIn) {
     context.go('/home');
   } else {
     context.go('/login');
   }
 }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [

          // ── 1. SPLASH GÖRSELİ ────────────────────────────────────────────
          Positioned(
            top: sh * 0.06,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Opacity(
                opacity: _imgOpacity.value,
                child: Transform.scale(
                  scale: _imgScale.value,
                  child: SizedBox(
                    height: sh * 0.75,
                    child: Image.asset(
                      'assets/images/splash_bg.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 2. ALT İÇERİK (metin + bar) ─────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Opacity(
                opacity: _textOpacity.value,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    sw * 0.10, 24, sw * 0.10, sh * 0.06),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0xDD0C0D10),
                        Color(0xFF0C0D10),
                      ],
                      stops: [0.0, 0.3, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // APP ADI
                      const Text(
                        'TrackForge',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: _accent,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // SLOGAN
                      const Text(
                        'Unlock Your Performance.\nAI-Powered Personal Health.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: _sub,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // PROGRESS BAR
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: SizedBox(
                          height: 3,
                          child: Stack(
                            children: [
                              // track
                              Container(color: _track),
                              // fill
                              FractionallySizedBox(
                                widthFactor: _barWidth.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _accent,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // LOADING YAZI
                      const Text(
                        'Initializing Your Health Journey...',
                        style: TextStyle(
                          fontSize: 11,
                          color: _sub,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}