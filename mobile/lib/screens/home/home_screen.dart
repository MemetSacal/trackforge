// ── home_screen.dart ────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../takip/takip_screen.dart';
import '../egzersiz/egzersiz_screen.dart';
import '../ai/ai_screen.dart';
import 'dashboard_screen.dart';
import 'more_screen.dart';
import '../../app.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/auth/token_manager.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const List<Widget> _screens = [
    DashboardScreen(), TakipScreen(), EgzersizScreen(), AiScreen(), MoreScreen(),
  ];

  bool _emailVerified = true;
  bool _bannerDismissed = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();
  }

  Future<void> _checkEmailVerified() async {
    final verified = await TokenManager.isEmailVerified();
    if (!verified && mounted) setState(() => _emailVerified = false);
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ApiClient.instance.post(Endpoints.authResendVerification);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✉️ Doğrulama emaili gönderildi!')));
        setState(() => _bannerDismissed = true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gönderilemedi, lütfen tekrar dene.')));
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    final bg       = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard   = isDark ? const Color(0xFF141620) : Colors.white;
    final border   = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final accent   = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final muted    = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final textSoft = isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);

    final showBanner = !_emailVerified && !_bannerDismissed;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Email doğrulama banner'ı ───────────────────────────────
          if (showBanner)
            Material(
              color: const Color(0xFFD97706),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(children: [
                    const Icon(Icons.mail_outline, size: 16, color: Colors.black),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'E-postanı doğrula — gelen kutuna bak.',
                        style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600),
                      ),
                    ),
                    GestureDetector(
                      onTap: _resending ? null : _resend,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _resending
                            ? const SizedBox(width: 12, height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Text('Tekrar Gönder',
                                style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _bannerDismissed = true),
                      child: const Icon(Icons.close, size: 16, color: Colors.black),
                    ),
                  ]),
                ),
              ),
            ),
          Expanded(child: _screens[currentIndex]),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: bgCard, border: Border(top: BorderSide(color: border))),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(children: [
              _NavItem(icon: Icons.home_outlined,          activeIcon: Icons.home,            label: 'Ana Sayfa', index: 0, current: currentIndex, accent: accent, muted: muted, textSoft: textSoft),
              _NavItem(icon: Icons.track_changes_outlined, activeIcon: Icons.track_changes,   label: 'Takip',    index: 1, current: currentIndex, accent: accent, muted: muted, textSoft: textSoft),
              _NavItem(icon: Icons.fitness_center_outlined,activeIcon: Icons.fitness_center,  label: 'Egzersiz', index: 2, current: currentIndex, accent: accent, muted: muted, textSoft: textSoft),
              _NavItem(icon: Icons.auto_awesome_outlined,  activeIcon: Icons.auto_awesome,    label: 'AI Koç',   index: 3, current: currentIndex, accent: accent, muted: muted, textSoft: textSoft),
              _NavItem(icon: Icons.more_horiz,             activeIcon: Icons.more_horiz,      label: 'Daha',     index: 4, current: currentIndex, accent: accent, muted: muted, textSoft: textSoft),
            ]),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends ConsumerWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final Color accent, muted, textSoft;

  const _NavItem({
    required this.icon, required this.activeIcon, required this.label,
    required this.index, required this.current,
    required this.accent, required this.muted, required this.textSoft,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(bottomNavIndexProvider.notifier).state = index,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon,
                size: 22, color: isActive ? accent : muted),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? accent : textSoft,
                )),
          ],
        ),
      ),
    );
  }
}