// ── more_screen.dart ────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart'; // FIX: GoRouter importu eklendi
import '../../app.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/auth/token_manager.dart';
import '../../core/utils/rate_limiter.dart';
import '../home/dashboard_screen.dart'; // notificationsProvider için
import '../home/home_screen.dart'; // bottomNavIndexProvider için
import '../raporlar/raporlar_screen.dart';
import '../sosyal/sosyal_screen.dart';
import '../alisveris/alisveris_screen.dart';
import '../profil/profil_screen.dart';
import '../gamification/gamification_screen.dart';
import '../steps/steps_screen.dart';
import '../cycle/cycle_screen.dart';
import '../notifications/notification_screen.dart';
import '../ai/chat_screen.dart';
import '../health/blood_values_screen.dart';
import '../health/progress_photos_screen.dart';

final _genderProvider = FutureProvider.autoDispose<String>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.preferences);
    return response.data['gender'] as String? ?? 'male';
  } catch (_) { return 'male'; }
});

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});
  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkmak istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try { await ApiClient.instance.post(Endpoints.authLogout); } catch (_) {}
    await RateLimiter.clearUserLimits();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FcmService.deactivateTokenOnBackend();
    await TokenManager.clearTokens();
    if (!mounted) return;
    ref.read(bottomNavIndexProvider.notifier).state = 0;
    context.go('/login');
  }

  void _showNotifications(BuildContext context, bool isDark,
      Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final notifsAsync = ref.watch(notificationsProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(99)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('🔔 Bildirimler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
                    GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('in_app_notifications');
                        ref.invalidate(notificationsProvider);
                      },
                      child: Text('Temizle', style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 300,
                child: notifsAsync.when(
                  loading: () => Center(child: CircularProgressIndicator(color: accent)),
                  error:   (_, __) => Center(child: Text('Yüklenemedi', style: TextStyle(color: text))),
                  data: (notifs) {
                    if (notifs.isEmpty) {
                      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('🔕', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text('Henüz bildirim yok', style: TextStyle(fontSize: 14, color: text)),
                        const SizedBox(height: 4),
                        Text('Hatırlatıcılar burada görünecek', style: TextStyle(fontSize: 12, color: muted)),
                      ]);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: notifs.length,
                      itemBuilder: (ctx, i) {
                        final n = notifs[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                          child: Row(children: [
                            const Text('🔔', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(n['title'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: text)),
                              const SizedBox(height: 2),
                              Text(n['body'] as String, style: TextStyle(fontSize: 11, color: textSoft)),
                              if ((n['time'] as String).isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(n['time'] as String, style: TextStyle(fontSize: 10, color: muted)),
                              ],
                            ])),
                          ]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) { // FIX: "WidgetRef ref" parametresi kaldırıldı
    final isDark   = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg       = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard   = isDark ? const Color(0xFF141620) : Colors.white;
    final bgSoft   = isDark ? const Color(0xFF0F1016) : const Color(0xFFE8EBF2);
    final border   = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text     = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final textSoft = isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);
    final muted    = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent   = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);

    final gender = ref.watch(_genderProvider).value ?? 'male';

    final sections = <Map<String, dynamic>>[
      {
        'title': 'Analiz',
        'items': [
          _Item('💬', 'Koçunla Konuş', 'Verilerini bilen AI asistan', const Color(0xFFFFB020), () => _push(context, const ChatScreen())),
          _Item('🩸', 'Kan Değerleri', 'Tahlil takibi ve trend', const Color(0xFFEF4444), () => _push(context, const BloodValuesScreen())),
          _Item('📸', 'İlerleme Fotoğrafları', 'Değişimini yan yana gör', const Color(0xFFA78BFA), () => _push(context, const ProgressPhotosScreen())),
          _Item('📊', 'Raporlar',       'Haftalık ve aylık grafikler', const Color(0xFF22D3EE),  () => _push(context, const RaporlarScreen())),
          _Item('🏆', 'Gamification',   'XP, rozetler, seviye',        const Color(0xFFFFB020),  () => _push(context, const GamificationScreen())),
          _Item('👟', 'Adım Sayar',     'Günlük adım takibi',          const Color(0xFF34D399),  () => _push(context, const StepsScreen())),
        ],
      },
      {
        'title': 'Sosyal',
        'items': [
          _Item('👥', 'Arkadaşlar & Liderlik', 'Arkadaşlarınla yarış', const Color(0xFFA78BFA), () => _push(context, const SosyalScreen())),
        ],
      },
      {
        'title': 'Alışveriş',
        'items': [
          _Item('🛒', 'Alışveriş Listesi', 'Barkod tarayıcı dahil', const Color(0xFFFFB020), () => _push(context, const AlisverisScreen())),
        ],
      },
      if (gender == 'female')
        {
          'title': 'Sağlık',
          'items': [
            _Item('🌸', 'Regl Takvimi', 'Döngü takibi ve faz analizi', const Color(0xFFFF69B4), () => _push(context, const CycleScreen())),
          ],
        },
      {
        'title': 'Hesap',
        'items': [
          _Item('👤', 'Profil', 'Sağlık bilgileri ve tercihler', const Color(0xFF34D399), () => _push(context, const ProfilScreen())),
          _Item('🔔', 'Bildirimler', 'Hatırlatıcı ayarları', const Color(0xFFFFB020), () => _push(context, const NotificationScreen())),
          _Item('🚪', 'Çıkış Yap', 'Hesabından güvenli çıkış yap', const Color(0xFFEF4444), _logout),
        ],
      },
    ];

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: bg,
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
                        Text('Daha Fazla', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                      child: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round, size: 15, color: textSoft),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showNotifications(context, isDark, bgCard, bgSoft, border, text, textSoft, muted, accent),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                      child: Icon(Icons.notifications_none_rounded, size: 15, color: textSoft),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ...sections.map((section) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Text(section['title'] as String,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted, letterSpacing: 0.5)),
                    ),
                    ...(section['items'] as List<_Item>).map((item) => GestureDetector(
                      onTap: item.onTap,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: item.color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                              child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 22))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                              const SizedBox(height: 2),
                              Text(item.desc, style: TextStyle(fontSize: 11, color: muted)),
                            ])),
                            Icon(Icons.chevron_right, size: 16, color: muted),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 8),
                  ],
                )),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

class _Item {
  final String emoji, title, desc;
  final Color color;
  final VoidCallback onTap;
  const _Item(this.emoji, this.title, this.desc, this.color, this.onTap);
}