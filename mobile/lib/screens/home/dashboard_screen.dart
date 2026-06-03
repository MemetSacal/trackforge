// ── dashboard_screen.dart ───────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';
import '../../app.dart';
import '../takip/takip_screen.dart';
import 'home_screen.dart';

// ── RENKLER (React mockup ile birebir) ──────────────────
class _C {
  static const bg         = Color(0xFF0C0D10);
  static const bgCard     = Color(0xFF141620);
  static const bgSoft     = Color(0xFF0F1016);
  static const border     = Color(0x12FFFFFF);
  static const text       = Color(0xFFF0EEF8);
  static const textSoft   = Color(0xFF8A88A8);
  static const textMuted  = Color(0xFF4A4860);
  static const accent     = Color(0xFFFFB020);
  static const accentDim  = Color(0x1FFFB020);
  static const positive   = Color(0xFF34D399);
  static const danger     = Color(0xFFFF5555);
  static const cyan       = Color(0xFF22D3EE);

  // Light mode
  static const lBg        = Color(0xFFF0F2F6);
  static const lBgCard    = Color(0xFFFFFFFF);
  static const lBgSoft    = Color(0xFFE8EBF2);
  static const lBorder    = Color(0x12000000);
  static const lText      = Color(0xFF111318);
  static const lTextSoft  = Color(0xFF5A6078);
  static const lTextMuted = Color(0xFF9AA0B8);
  static const lAccent    = Color(0xFFFF6B2B);
  static const lAccentDim = Color(0x1AFF6B2B);
  static const lPositive  = Color(0xFF059669);
  static const lDanger    = Color(0xFFDC2626);
}

// ── PROVIDERS ───────────────────────────────────────────
final dashUserProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiClient.instance.get(Endpoints.me);
  return Map<String, dynamic>.from(res.data);
});

final dashGamificationProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiClient.instance.get(Endpoints.gamificationSummary);
  return Map<String, dynamic>.from(res.data);
});

final dashWeeklyProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiClient.instance.get(
    Endpoints.reportsWeekly,
    queryParameters: {'reference_date': TFDateUtils.today()},
  );
  return Map<String, dynamic>.from(res.data);
});

// ── MAIN SCREEN ─────────────────────────────────────────
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final t = _Theme(isDark);

    final userAsync   = ref.watch(dashUserProvider);
    final gamiAsync   = ref.watch(dashGamificationProvider);
    final weeklyAsync = ref.watch(dashWeeklyProvider);

    return Scaffold(
      backgroundColor: t.bg,
      body: RefreshIndicator(
        color: t.accent,
        backgroundColor: t.bgCard,
        onRefresh: () async {
          ref.invalidate(dashUserProvider);
          ref.invalidate(dashGamificationProvider);
          ref.invalidate(dashWeeklyProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── APP BAR ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TRACKFORGE',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 3,
                              color: t.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          userAsync.when(
                            data: (u) => Text(
                              'Merhaba, ${u['full_name'].toString().split(' ')[0]} 👋',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: t.text,
                                letterSpacing: -0.5,
                              ),
                            ),
                            loading: () => Text(
                              'Ana Sayfa',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: t.text,
                              ),
                            ),
                            error: (_, __) => Text(
                              'Ana Sayfa',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: t.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Dark mode toggle
                    GestureDetector(
                      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: t.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: t.border),
                        ),
                        child: Icon(
                          isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                          size: 15,
                          color: t.textSoft,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: t.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.border),
                      ),
                      child: Icon(Icons.notifications_none_rounded, size: 15, color: t.textSoft),
                    ),
                  ],
                ),
              ),
            ),

            // ── İÇERİK ──────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // 1) HERO CARD
                  gamiAsync.when(
                    data: (gami) => weeklyAsync.when(
                      data: (weekly) => _HeroCard(t: t, gami: gami, weekly: weekly),
                      loading: () => _HeroCard(t: t, gami: gami, weekly: {}),
                      error: (_, __) => _HeroCard(t: t, gami: gami, weekly: {}),
                    ),
                    loading: () => _shimmer(t, 180),
                    error: (_, __) => _HeroCard(t: t, gami: {}, weekly: {}),
                  ),
                  const SizedBox(height: 12),

                  // 2) STAT GRID (2x2)
                  weeklyAsync.when(
                    data: (w) => _StatGrid(t: t, weekly: w),
                    loading: () => _shimmer(t, 160),
                    error: (_, __) => _StatGrid(t: t, weekly: {}),
                  ),
                  const SizedBox(height: 12),

                  // 3) SU + UYKU
                  weeklyAsync.when(
                    data: (w) => _WaterSleepRow(t: t, weekly: w),
                    loading: () => _shimmer(t, 110),
                    error: (_, __) => _WaterSleepRow(t: t, weekly: {}),
                  ),
                  const SizedBox(height: 12),

                  // 4) SERİLER
                  gamiAsync.when(
                    data: (gami) => _StreaksCard(t: t, gami: gami),
                    loading: () => _shimmer(t, 100),
                    error: (_, __) => _StreaksCard(t: t, gami: {}),
                  ),
                  const SizedBox(height: 12),

                  // 5) DİYET UYUMU BARL CHART
                  _DietChartCard(t: t),
                  const SizedBox(height: 12),

                  // 6) HIZLI ERİŞİM
                  _QuickActions(t: t),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmer(_Theme t, double h) => Container(
    height: h,
    decoration: BoxDecoration(
      color: t.bgCard,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: t.border),
    ),
    child: Center(child: CircularProgressIndicator(color: t.accent, strokeWidth: 2)),
  );
}

// ── HERO CARD ───────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final _Theme t;
  final Map<String, dynamic> gami;
  final Map<String, dynamic> weekly;
  const _HeroCard({required this.t, required this.gami, required this.weekly});

  @override
  Widget build(BuildContext context) {
    final level  = gami['level']  != null ? Map<String, dynamic>.from(gami['level'])  : <String, dynamic>{};
    final rawStr = gami['streaks'];
    final streaks = rawStr is List
        ? rawStr.map((s) => Map<String, dynamic>.from(s)).toList()
        : <Map<String, dynamic>>[];

    int maxStreak = 0;
    String streakType = 'gün';
    for (final s in streaks) {
      final cur = (s['current_streak'] as num?)?.toInt() ?? 0;
      if (cur > maxStreak) { maxStreak = cur; streakType = 'gün'; }
    }

    final measurements = weekly['measurements'] != null
        ? Map<String, dynamic>.from(weekly['measurements'])
        : <String, dynamic>{};
    final weightChange = (measurements['weight_change'] as num?)?.toDouble();

    // Görevler (mock — ilerleyen polish'te gerçek veriye bağlanır)

    final avgMl = (weekly['water'] as Map?)?['avg_daily_ml'];
    final totalSess = (weekly['exercise'] as Map?)?['total_sessions'];
    final avgSleep = (weekly['sleep'] as Map?)?['avg_hours'];

    final missions = [
      ['💧 2L su iç',      avgMl != null && (avgMl as num) >= 2000],
      ['🏋️ Antrenman yap', totalSess != null && (totalSess as num) > 0],
      ['😴 7+ saat uyu',   avgSleep != null && (avgSleep as num) >= 7],
      ['🎯 Kalori hedefi',  false],
    ];

    final gradient = t.isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1400), Color(0xFF2a1f00), Color(0xFF1a1200)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B2B), Color(0xFFFF9A5C)],
          );

    final heroText = t.isDark ? _C.accent : Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: t.accent.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          // Dekoratif daire
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI KOÇ · GÜNLÜK ANALİZ',
                style: TextStyle(
                  fontSize: 10, letterSpacing: 3,
                  color: heroText.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      maxStreak > 0 ? '🔥 $maxStreak günlük seri!' : '🚀 Hadi başlayalım!',
                      style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        color: heroText, height: 1.2,
                      ),
                    ),
                  ),
                  // Seviye badge
                  if (level.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Lv.${level['level'] ?? 1}',
                            style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800,
                              color: heroText,
                            ),
                          ),
                          Text(
                            '${level['xp'] ?? 0} XP',
                            style: TextStyle(fontSize: 9, color: heroText.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                weightChange != null
                    ? 'Kilo trendin ${weightChange < 0 ? "düşüyor (${weightChange.toStringAsFixed(1)} kg)" : "yükseliyor (+${weightChange.toStringAsFixed(1)} kg)"}. Harika gidiyorsun!'
                    : 'Verilerini girerek kişisel AI analizini aktifleştir.',
                style: TextStyle(
                  fontSize: 12, color: heroText.withOpacity(0.82), height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              // Görev listesi
              ...missions.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(m[0] as String, style: TextStyle(fontSize: 12, color: heroText)),
                      Text(
                        (m[1] as bool) ? '✔' : '✖',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: (m[1] as bool) ? Colors.white : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

// ── STAT GRID ───────────────────────────────────────────
class _StatGrid extends StatelessWidget {
  final _Theme t;
  final Map<String, dynamic> weekly;
  const _StatGrid({required this.t, required this.weekly});

  @override
  Widget build(BuildContext context) {
    final water   = weekly['water']        != null ? Map<String, dynamic>.from(weekly['water'])        : <String, dynamic>{};
    final sleep   = weekly['sleep']        != null ? Map<String, dynamic>.from(weekly['sleep'])        : <String, dynamic>{};
    final exercise= weekly['exercise']     != null ? Map<String, dynamic>.from(weekly['exercise'])     : <String, dynamic>{};
    final meas    = weekly['measurements'] != null ? Map<String, dynamic>.from(weekly['measurements']) : <String, dynamic>{};

    final weightKg    = (meas['weight_kg']     as num?)?.toDouble();
    final weightChange= (meas['weight_change'] as num?)?.toDouble();
    final avgSleep    = (sleep['avg_hours']     as num?)?.toDouble();
    final totalSess   = (exercise['total_sessions'] as num?)?.toInt();
    final avgWater    = (water['avg_daily_ml']  as num?)?.toDouble();

    final items = [
      _StatItem(
        label: 'Ağırlık',
        value: weightKg != null ? '${weightKg.toStringAsFixed(1)}' : '--',
        unit: 'kg',
        delta: weightChange != null ? '${weightChange < 0 ? "↓" : "↑"} ${weightChange.abs().toStringAsFixed(1)} kg' : null,
        positive: weightChange != null && weightChange <= 0,
        bars: const [42, 55, 65, 72, 80, 92],
      ),
      _StatItem(
        label: 'Ortalama Su',
        value: avgWater != null ? (avgWater / 1000).toStringAsFixed(1) : '--',
        unit: 'L/gün',
        delta: avgWater != null ? (avgWater >= 2000 ? '✓ hedefte' : '⚠ düşük') : null,
        positive: avgWater != null && avgWater >= 2000,
        bars: const [50, 60, 45, 70, 80, 65],
      ),
      _StatItem(
        label: 'Egzersiz',
        value: totalSess != null ? '$totalSess' : '--',
        unit: 'seans',
        delta: totalSess != null ? '${totalSess >= 3 ? "✓ iyi" : "⚠ az"}' : null,
        positive: totalSess != null && totalSess >= 3,
        bars: const [55, 70, 45, 88, 75, 100],
      ),
      _StatItem(
        label: 'Ort. Uyku',
        value: avgSleep != null ? avgSleep.toStringAsFixed(1) : '--',
        unit: 'saat',
        delta: avgSleep != null ? (avgSleep >= 7 ? '✓ iyi' : '⚠ az') : null,
        positive: avgSleep != null && avgSleep >= 7,
        bars: const [60, 72, 55, 80, 68, 85],
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.5,
      children: items.map((item) => _StatMiniCard(t: t, item: item)).toList(),
    );
  }
}

class _StatItem {
  final String label, value, unit;
  final String? delta;
  final bool positive;
  final List<int> bars;
  const _StatItem({
    required this.label, required this.value, required this.unit,
    this.delta, this.positive = true, required this.bars,
  });
}

class _StatMiniCard extends StatelessWidget {
  final _Theme t;
  final _StatItem item;
  const _StatMiniCard({required this.t, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst accent çizgi
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: t.accent.withOpacity(0.6),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(item.label, style: TextStyle(fontSize: 10, color: t.textMuted)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              text: item.value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: t.text, height: 1),
              children: [
                TextSpan(
                  text: ' ${item.unit}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: t.textSoft),
                ),
              ],
            ),
          ),
          if (item.delta != null) ...[
            const SizedBox(height: 3),
            Text(
              item.delta!,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: item.positive ? t.positive : t.danger,
              ),
            ),
          ],
          const Spacer(),
          // Mini bar chart
          SizedBox(
            height: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: item.bars.asMap().entries.map((e) {
                final opacity = 0.15 + (e.key / item.bars.length) * 0.85;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: FractionallySizedBox(
                      heightFactor: e.value / 100,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: t.accent.withOpacity(opacity),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SU + UYKU SATIRI ────────────────────────────────────
class _WaterSleepRow extends StatelessWidget {
  final _Theme t;
  final Map<String, dynamic> weekly;
  const _WaterSleepRow({required this.t, required this.weekly});

  @override
  Widget build(BuildContext context) {
    final water = weekly['water'] != null ? Map<String, dynamic>.from(weekly['water']) : <String, dynamic>{};
    final sleep = weekly['sleep'] != null ? Map<String, dynamic>.from(weekly['sleep']) : <String, dynamic>{};

    final avgMl   = (water['avg_daily_ml'] as num?)?.toDouble() ?? 0;
    final targetMl = 2000.0;
    final waterPct = (avgMl / targetMl).clamp(0.0, 1.0);

    final avgHours = (sleep['avg_hours'] as num?)?.toDouble() ?? 0;
    final sleepPct = (avgHours / 8).clamp(0.0, 1.0);

    return Row(
      children: [
        // Su kartı
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: t.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.border),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💧 Su', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.text)),
                const SizedBox(height: 10),
                // Bar'lar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [0.0, 0.3, 0.6, waterPct, 0.0].map((h) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: t.bgSoft,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: h.clamp(0.05, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _C.cyan,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    text: avgMl > 0 ? '${(avgMl / 1000).toStringAsFixed(1)}L' : '--',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.text),
                    children: [
                      TextSpan(
                        text: ' / 2L',
                        style: TextStyle(fontSize: 11, color: t.textSoft, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Uyku kartı
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: t.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.border),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('😴 Uyku', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.text)),
                const SizedBox(height: 8),
                // Yarım daire gauge
                SizedBox(
                  height: 50,
                  child: CustomPaint(
                    painter: _SleepGaugePainter(
                      progress: sleepPct,
                      trackColor: t.bgSoft,
                      fillColor: t.accent,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  avgHours > 0 ? '${avgHours.toStringAsFixed(1)} saat' : '--',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.text),
                ),
                Text(
                  avgHours >= 7 ? 'iyi kalite' : 'yetersiz',
                  style: TextStyle(
                    fontSize: 11,
                    color: avgHours >= 7 ? t.positive : t.danger,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Yarım daire painter
class _SleepGaugePainter extends CustomPainter {
  final double progress;
  final Color trackColor, fillColor;
  const _SleepGaugePainter({required this.progress, required this.trackColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // cy'yi sabit yüksekliğe bağla, size'a değil
    final radius = (size.width * 0.42).clamp(0.0, size.height - 4);
    final cy = size.height - 4.0; // alt kenara dayalı
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 3.14159, 3.14159, false, trackPaint);
    canvas.drawArc(rect, 3.14159, 3.14159 * progress, false, fillPaint);
  }

  @override
  bool shouldRepaint(_SleepGaugePainter old) => old.progress != progress;
}

// ── SERİLER KARTI ───────────────────────────────────────
class _StreaksCard extends StatelessWidget {
  final _Theme t;
  final Map<String, dynamic> gami;
  const _StreaksCard({required this.t, required this.gami});

  @override
  Widget build(BuildContext context) {
    final rawStreaks = gami['streaks'];
    final streaks = rawStreaks is List
        ? rawStreaks.map((s) => Map<String, dynamic>.from(s)).toList()
        : <Map<String, dynamic>>[];

    // Streak type → emoji + label map
    final streakMeta = {
      'water':    ('💧', 'Su'),
      'exercise': ('🏋️', 'Gym'),
      'sleep':    ('😴', 'Uyku'),
    };

    // Veri yoksa mock göster
    final displayStreaks = streaks.isNotEmpty
        ? streaks.take(4).toList()
        : [
            {'streak_type': 'water',    'current_streak': 0},
            {'streak_type': 'exercise', 'current_streak': 0},
            {'streak_type': 'sleep',    'current_streak': 0},
          ];

    return Container(
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🏆 Seriler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text)),
              Text('Tümü', style: TextStyle(fontSize: 13, color: t.accent, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: displayStreaks.map((s) {
              final type = s['streak_type'] as String? ?? 'water';
              final count = (s['current_streak'] as num?)?.toInt() ?? 0;
              final meta = streakMeta[type] ?? ('🔥', type);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: t.bgSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.border),
                  ),
                  child: Column(
                    children: [
                      Text(meta.$1, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 2),
                      Text(
                        '$count',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: t.accent),
                      ),
                      Text(meta.$2, style: TextStyle(fontSize: 9, color: t.textMuted)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── DİYET UYUMU BAR CHART ───────────────────────────────
class _DietChartCard extends StatelessWidget {
  final _Theme t;
  const _DietChartCard({required this.t});

  @override
  Widget build(BuildContext context) {
    // Mock haftalık diyet uyumu (0-10 arası) — ilerleyen polish'te API'ye bağlanır
    const values = [9, 6, 8, 8, 7, 5, 8];
    const days = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];

    return Container(
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('📊 Diyet Uyumu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final v = values[i];
                Color barColor;
                double opacity;
                if (v >= 8) { barColor = t.accent; opacity = 1.0; }
                else if (v >= 7) { barColor = _C.cyan; opacity = 0.65; }
                else { barColor = t.danger; opacity = 0.65; }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: v / 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: barColor.withOpacity(opacity),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(days[i], style: TextStyle(fontSize: 9, color: t.textMuted)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Haftalık ort.', style: TextStyle(fontSize: 12, color: t.textSoft)),
              Text('7.3 / 10', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: t.accent)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── HIZLI ERİŞİM ────────────────────────────────────────
class _QuickActions extends ConsumerWidget {
  final _Theme t;
  const _QuickActions({required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      ('💧', 'Su Ekle',    () { ref.read(takipTabIndexProvider.notifier).state = 2; ref.read(bottomNavIndexProvider.notifier).state = 1; }),
      ('🏋️', 'Antrenman', () { ref.read(bottomNavIndexProvider.notifier).state = 2; }),
      ('🍽️', 'Öğün',      () { ref.read(takipTabIndexProvider.notifier).state = 1; ref.read(bottomNavIndexProvider.notifier).state = 1; }),
      ('😴', 'Uyku',       () { ref.read(takipTabIndexProvider.notifier).state = 3; ref.read(bottomNavIndexProvider.notifier).state = 1; }),
    ];

    return Container(
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚡ Hızlı Erişim', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: actions.map((a) => GestureDetector(
              onTap: a.$3,
              child: Column(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: t.accentDim,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.accent.withOpacity(0.3)),
                    ),
                    child: Center(child: Text(a.$1, style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(height: 6),
                  Text(a.$2, style: TextStyle(fontSize: 11, color: t.textSoft)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── TEMA YARDIMCISI ─────────────────────────────────────
class _Theme {
  final bool isDark;
  const _Theme(this.isDark);

  Color get bg        => isDark ? _C.bg        : _C.lBg;
  Color get bgCard    => isDark ? _C.bgCard    : _C.lBgCard;
  Color get bgSoft    => isDark ? _C.bgSoft    : _C.lBgSoft;
  Color get border    => isDark ? _C.border    : _C.lBorder;
  Color get text      => isDark ? _C.text      : _C.lText;
  Color get textSoft  => isDark ? _C.textSoft  : _C.lTextSoft;
  Color get textMuted => isDark ? _C.textMuted : _C.lTextMuted;
  Color get accent    => isDark ? _C.accent    : _C.lAccent;
  Color get accentDim => isDark ? _C.accentDim : _C.lAccentDim;
  Color get positive  => isDark ? _C.positive  : _C.lPositive;
  Color get danger    => isDark ? _C.danger    : _C.lDanger;
}