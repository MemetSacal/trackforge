// ── wrapped_screen.dart (v5) ─────────────────────────────
// "TrackForge Wrapped" — Spotify Wrapped mantığıyla yıl özeti.
// GET /reports/wrapped'tan gelen saf agregasyon verisi (AI yok,
// kota yok) kaydırmalı gurur kartlarına dönüşür. Paylaşım metni
// panoya kopyalanır → Instagram/WhatsApp'a yapıştır = organik tanıtım.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';

final wrappedProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiClient.instance.get(Endpoints.reportsWrapped);
  return Map<String, dynamic>.from(res.data);
});

class WrappedScreen extends ConsumerStatefulWidget {
  const WrappedScreen({super.key});
  @override
  ConsumerState<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends ConsumerState<WrappedScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _fmt(num? n) {
    if (n == null) return '0';
    final s = n.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  void _share(Map<String, dynamic> d) {
    final year = d['year'];
    final lines = <String>[
      '🏆 TrackForge Wrapped $year',
      '',
      '💪 ${_fmt(d['total_sessions'])} antrenman seansı',
      '👟 ${_fmt(d['total_steps'])} adım (${d['total_distance_km']} km)',
      '🔥 ${_fmt(d['total_workout_calories'])} kcal yakıldı',
      if (d['weight_change_kg'] != null)
        '⚖️ ${(d['weight_change_kg'] as num) <= 0 ? '' : '+'}${d['weight_change_kg']} kg yolculuk',
      '🏅 ${d['badges_earned']} rozet · 🔥 ${d['longest_streak']} gün seri',
      '',
      '#TrackForge ile takip ettim 📱',
    ];
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('📋 Özet panoya kopyalandı — istediğin yere yapıştır!'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final wrappedAsync = ref.watch(wrappedProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0C0D10),
      body: wrappedAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFB020))),
        error: (_, __) => Center(
          child: Text('Özet yüklenemedi',
              style: TextStyle(color: Colors.white.withOpacity(0.7)))),
        data: (d) {
          final cards = _buildCards(d);
          return SafeArea(
            child: Column(children: [
              // ── Üst bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: Colors.white54),
                  ),
                  const Spacer(),
                  Text('TRACKFORGE WRAPPED ${d['year']}',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11,
                          fontWeight: FontWeight.w800, letterSpacing: 3)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _share(d),
                    child: const Icon(Icons.ios_share_rounded,
                        color: Color(0xFFFFB020), size: 20),
                  ),
                ]),
              ),
              // ── Kartlar ──
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: cards,
                ),
              ),
              // ── Sayfa noktaları ──
              Padding(
                padding: const EdgeInsets.only(bottom: 18, top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(cards.length, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _page ? 20 : 7, height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _page ? const Color(0xFFFFB020) : Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  )),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  List<Widget> _buildCards(Map<String, dynamic> d) {
    final cards = <Widget>[
      _card(
        gradient: const [Color(0xFF1A1D2B), Color(0xFF2D1B4E)],
        emoji: '🏋️',
        big: _fmt(d['total_sessions']),
        title: 'antrenman seansı',
        sub: '${_fmt(d['total_workout_minutes'])} dakika ter döktün,\n'
             '${_fmt(d['total_workout_calories'])} kcal yaktın 🔥',
      ),
      _card(
        gradient: const [Color(0xFF0E2A1E), Color(0xFF143524)],
        emoji: '👟',
        big: _fmt(d['total_steps']),
        title: 'adım attın',
        sub: 'Tam ${d['total_distance_km']} km —\n'
             '${_kmContext((d['total_distance_km'] as num?)?.toDouble() ?? 0)}',
      ),
    ];

    if (d['favorite_exercise'] != null) {
      cards.add(_card(
        gradient: const [Color(0xFF2B1A1A), Color(0xFF4E1B2D)],
        emoji: '❤️',
        big: d['favorite_exercise'].toString(),
        bigSize: 34,
        title: 'favori hareketin',
        sub: 'Bu yıl tam ${d['favorite_exercise_count']} kez yaptın.\n'
             'Aranızda özel bir bağ var belli ki 😄',
      ));
    }

    if (d['weight_change_kg'] != null) {
      final ch = (d['weight_change_kg'] as num).toDouble();
      cards.add(_card(
        gradient: const [Color(0xFF1A2530), Color(0xFF1B3A4E)],
        emoji: '⚖️',
        big: '${ch <= 0 ? '' : '+'}${ch.toStringAsFixed(1)} kg',
        title: 'kilo yolculuğun',
        sub: '${d['weight_start_kg']} kg → ${d['weight_end_kg']} kg\n'
             '${ch < 0 ? 'Disiplinin konuştu 👏' : ch > 0 ? 'Yolculuk devam ediyor 💪' : 'Dengede kaldın ⚖️'}',
      ));
    }

    cards.add(_card(
      gradient: const [Color(0xFF1A2B2B), Color(0xFF1B4E4A)],
      emoji: '💧',
      big: '${d['total_water_liters']} L',
      title: 'su içtin',
      sub: '${d['tracked_days']} gün beslenme takibi yaptın,\n'
           '${d['complied_days']} gününde hedefi tutturdun ✅',
    ));

    cards.add(_card(
      gradient: const [Color(0xFF2B271A), Color(0xFF4E3D1B)],
      emoji: '🏅',
      big: '${d['badges_earned']}',
      title: 'rozet kazandın',
      sub: 'En uzun serin ${d['longest_streak']} gün sürdü 🔥\n'
           'Bunu kimse senden alamaz.',
    ));

    cards.add(Builder(builder: (context) => GestureDetector(
      onTap: () => _share(d),
      child: _card(
        gradient: const [Color(0xFFFFB020), Color(0xFFFF6B2B)],
        emoji: '🏆',
        big: '${d['year']}',
        title: 'senin yılındı',
        dark: true,
        sub: 'Her adımı, her seti, her damlayı saydık.\n'
             'Dokun → panoya kopyala → arkadaşlarına göster 📲',
      ),
    )));

    return cards;
  }

  String _kmContext(double km) {
    if (km >= 565) return 'Samsun→İstanbul arası gittin resmen 🚗';
    if (km >= 100) return 'şehirler arası mesafe bu, helal 👏';
    if (km >= 42) return 'bir maratondan fazlası 🏃';
    return 'her kilometre senin eserin 💪';
  }

  Widget _card({
    required List<Color> gradient,
    required String emoji,
    required String big,
    required String title,
    required String sub,
    double bigSize = 56,
    bool dark = false,
  }) {
    final fg = dark ? const Color(0xFF1A1208) : Colors.white;
    final fgSoft = dark ? const Color(0xB31A1208) : Colors.white70;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 24),
            Text(big,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: bigSize, fontWeight: FontWeight.w900,
                    color: fg, letterSpacing: -1, height: 1.05)),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: fg)),
            const SizedBox(height: 18),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.55, color: fgSoft)),
          ],
        ),
      ),
    );
  }
}
