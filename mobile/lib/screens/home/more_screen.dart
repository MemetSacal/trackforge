// ── more_screen.dart ────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../raporlar/raporlar_screen.dart';
import '../sosyal/sosyal_screen.dart';
import '../alisveris/alisveris_screen.dart';
import '../profil/profil_screen.dart';
import '../gamification/gamification_screen.dart';
import '../steps/steps_screen.dart';
import '../cycle/cycle_screen.dart';
import '../notifications/notification_screen.dart';

final _genderProvider = FutureProvider.autoDispose<String>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.preferences);
    return response.data['gender'] as String? ?? 'male';
  } catch (_) { return 'male'; }
});

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark   = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg       = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard   = isDark ? const Color(0xFF141620) : Colors.white;
    final bgSoft   = isDark ? const Color(0xFF0F1016) : const Color(0xFFE8EBF2);
    final border   = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text     = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final textSoft = isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);
    final muted    = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent   = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim= isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);

    final gender = ref.watch(_genderProvider).value ?? 'male';

    final sections = <Map<String, dynamic>>[
      {
        'title': 'Analiz',
        'items': [
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
        ],
      },
    ];

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── HEADER ────────────────────────────────
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
                ],
              ),
            ),
          ),

          // ── İÇERİK ────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ...sections.map((section) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Text(
                        section['title'] as String,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted, letterSpacing: 0.5),
                      ),
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
                              decoration: BoxDecoration(
                                color: item.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 22))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                                  const SizedBox(height: 2),
                                  Text(item.desc, style: TextStyle(fontSize: 11, color: muted)),
                                ],
                              ),
                            ),
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