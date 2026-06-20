// ── dashboard_screen.dart ───────────────────────────────
import 'package:dio/dio.dart';
import '../health/weekly_checkin_card.dart';
import '../../core/widgets/pulse_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/offline_cache.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';
import '../../app.dart';
import '../takip/takip_screen.dart';
import '../ai/workout_plan_screen.dart';
import 'home_screen.dart';

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

// ── v4: TEK İSTEK DASHBOARD ──
// ESKİ: Açılışta 6 ayrı GET (me, gamification, weekly, ölçüm, öğün, su+uyku)
// → 6 round-trip, yavaş açılış, pil, sunucuda 6 kat istek.
// YENİ: Tek agregat istek; eski provider'lar bu yanıtın DİLİMLERİNİ döndürür.
// Alt nesne şekilleri tekil endpoint'lerle birebir aynı olduğundan
// UI kodu hiç değişmeden çalışır.
final dashSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  // v7: offline cache — internet yokken son bilinen dashboard görünür
  return OfflineCache.getJson(Endpoints.reportsDashboardSummary);
});

final dashUserProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final summary = await ref.watch(dashSummaryProvider.future);
  final u = summary['user'];
  if (u is Map) return Map<String, dynamic>.from(u);
  // Agregat'ta yoksa eski yola düş (geriye uyum)
  final res = await ApiClient.instance.get(Endpoints.me);
  return Map<String, dynamic>.from(res.data);
});

final dashGamificationProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final summary = await ref.watch(dashSummaryProvider.future); // v4: agregat dilimi
  final g = summary['gamification'];
  if (g is Map) return Map<String, dynamic>.from(g);
  final res = await ApiClient.instance.get(Endpoints.gamificationSummary);
  return Map<String, dynamic>.from(res.data);
});

final dashWeeklyProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final summary = await ref.watch(dashSummaryProvider.future); // v4: agregat dilimi
  final w = summary['weekly'];
  if (w is Map) return Map<String, dynamic>.from(w);
  final res = await ApiClient.instance.get(
    Endpoints.reportsWeekly,
    queryParameters: {'reference_date': TFDateUtils.today()},
  );
  return Map<String, dynamic>.from(res.data);
});

// ── Son vücut ölçümü (ağırlık için) ─────────────────────
final dashLatestMeasurementProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final summary = await ref.watch(dashSummaryProvider.future); // v4: agregat dilimi
    final m = summary['latest_measurement'];
    if (m is Map) return Map<String, dynamic>.from(m);
    if (summary.containsKey('latest_measurement')) return null; // agregat "yok" dedi
    final to   = TFDateUtils.today();
    final from = DateTime.now().subtract(const Duration(days: 90));
    final fromStr = '${from.year}-${from.month.toString().padLeft(2,'0')}-${from.day.toString().padLeft(2,'0')}';
    final res = await ApiClient.instance.get(Endpoints.measurements, queryParameters: {'from': fromStr, 'to': to});
    final list = res.data as List?;
    if (list == null || list.isEmpty) return null;
    return Map<String, dynamic>.from(list.last);
  } catch (_) { return null; }
});

// ── Bugünkü kalori bankası verisi ───────────────────────
final dashMealProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final summary = await ref.watch(dashSummaryProvider.future); // v4: agregat dilimi
    final v = summary['meal_today'];
    if (v is Map) return Map<String, dynamic>.from(v);
    if (summary.containsKey('meal_today')) return null; // agregat "bugün kayıt yok" dedi
    final res = await ApiClient.instance.get('${Endpoints.mealCompliance}/date/${TFDateUtils.today()}');
    return Map<String, dynamic>.from(res.data);
  } catch (_) { return null; }
});

// ── Bugünkü su verisi ────────────────────────────────────
final dashWaterTodayProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final summary = await ref.watch(dashSummaryProvider.future); // v4: agregat dilimi
    final v = summary['water_today'];
    if (v is Map) return Map<String, dynamic>.from(v);
    if (summary.containsKey('water_today')) return null; // agregat "bugün kayıt yok" dedi
    final res = await ApiClient.instance.get('${Endpoints.water}/date/${TFDateUtils.today()}');
    return Map<String, dynamic>.from(res.data);
  } catch (_) { return null; }
});

// ── Bugünkü uyku verisi ──────────────────────────────────
final dashSleepTodayProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final summary = await ref.watch(dashSummaryProvider.future); // v4: agregat dilimi
    final v = summary['sleep_today'];
    if (v is Map) return Map<String, dynamic>.from(v);
    if (summary.containsKey('sleep_today')) return null; // agregat "bugün kayıt yok" dedi
    final res = await ApiClient.instance.get('${Endpoints.sleep}/date/${TFDateUtils.today()}');
    return Map<String, dynamic>.from(res.data);
  } catch (_) { return null; }
});

// ── Bildirim listesi provider ────────────────────────────
final notificationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw   = prefs.getStringList('in_app_notifications') ?? [];
  return raw.map((e) {
    final parts = e.split('||');
    return {
      'title': parts.isNotEmpty ? parts[0] : '',
      'body':  parts.length > 1 ? parts[1] : '',
      'time':  parts.length > 2 ? parts[2] : '',
    };
  }).toList().reversed.toList();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showNotifications(BuildContext context, WidgetRef ref, _Theme t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: t.bgCard,
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
                decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(99)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('🔔 Bildirimler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text)),
                    GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('in_app_notifications');
                        ref.invalidate(notificationsProvider);
                      },
                      child: Text('Temizle', style: TextStyle(fontSize: 12, color: t.accent, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 300,
                child: notifsAsync.when(
                  loading: () => Center(child: CircularProgressIndicator(color: t.accent)),
                  error:   (_, __) => Center(child: Text('Yüklenemedi', style: TextStyle(color: t.text))),
                  data: (notifs) {
                    if (notifs.isEmpty) {
                      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('🔕', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text('Henüz bildirim yok', style: TextStyle(fontSize: 14, color: t.text)),
                        const SizedBox(height: 4),
                        Text('Hatırlatıcılar burada görünecek', style: TextStyle(fontSize: 12, color: t.textMuted)),
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
                          decoration: BoxDecoration(
                            color: t.bgSoft,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: t.border),
                          ),
                          child: Row(children: [
                            const Text('🔔', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(n['title'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text)),
                              const SizedBox(height: 2),
                              Text(n['body']  as String, style: TextStyle(fontSize: 11, color: t.textSoft)),
                              if ((n['time'] as String).isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(n['time'] as String, style: TextStyle(fontSize: 10, color: t.textMuted)),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final t = _Theme(isDark);

    final userAsync      = ref.watch(dashUserProvider);
    final gamiAsync      = ref.watch(dashGamificationProvider);
    final weeklyAsync    = ref.watch(dashWeeklyProvider);
    final mealAsync      = ref.watch(dashMealProvider);
    final waterToday     = ref.watch(dashWaterTodayProvider).value;
    final sleepToday     = ref.watch(dashSleepTodayProvider).value;
    final latestMeas     = ref.watch(dashLatestMeasurementProvider).value;

    return Scaffold(
      backgroundColor: t.bg,
      body: RefreshIndicator(
        color: t.accent,
        backgroundColor: t.bgCard,
        onRefresh: () async {
          ref.invalidate(dashUserProvider);
          ref.invalidate(dashGamificationProvider);
          ref.invalidate(dashWeeklyProvider);
          ref.invalidate(dashMealProvider);
          ref.invalidate(dashWaterTodayProvider);
          ref.invalidate(dashSleepTodayProvider);
          ref.invalidate(dashLatestMeasurementProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: t.textMuted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          userAsync.when(
                            data: (u) => Text(
                              'Merhaba, ${u['full_name'].toString().split(' ')[0]} 👋',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: t.text, letterSpacing: -0.5),
                            ),
                            loading: () => Text('Ana Sayfa', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: t.text)),
                            error: (_, __) => Text('Ana Sayfa', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: t.text)),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: t.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: t.border)),
                        child: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round, size: 15, color: t.textSoft),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showNotifications(context, ref, t),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: t.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: t.border)),
                        child: Icon(Icons.notifications_none_rounded, size: 15, color: t.textSoft),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // v1.1: hafta sonu check-in hatırlatması (sadece Cmt/Paz, yapılmadıysa)
                  const WeeklyCheckinCard(),
                  gamiAsync.when(
                    data: (gami) => weeklyAsync.when(
                      data: (weekly) => _HeroCard(t: t, gami: gami, weekly: weekly, waterToday: waterToday, sleepToday: sleepToday, mealToday: mealAsync.value),
                      loading: () => _HeroCard(t: t, gami: gami, weekly: {}, waterToday: waterToday, sleepToday: sleepToday, mealToday: mealAsync.value),
                      error: (_, __) => _HeroCard(t: t, gami: gami, weekly: {}, waterToday: waterToday, sleepToday: sleepToday, mealToday: mealAsync.value),
                    ),
                    loading: () => _shimmer(t, 180),
                    error: (_, __) => _HeroCard(t: t, gami: {}, weekly: {}),
                  ),
                  const SizedBox(height: 12),
                  mealAsync.when(
                    data: (meal) => meal != null ? _CalorieBankNote(t: t, meal: meal) : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  mealAsync.when(
                    data: (meal) => meal != null ? const SizedBox(height: 12) : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  weeklyAsync.when(
                    data: (w) => _StatGrid(t: t, weekly: w, latestWeight: latestMeas?['weight_kg'] as double?),
                    loading: () => _shimmer(t, 160),
                    error: (_, __) => _StatGrid(t: t, weekly: {}, latestWeight: null),
                  ),
                  const SizedBox(height: 12),
                  weeklyAsync.when(
                    data: (w) => _WaterSleepRow(t: t, weekly: w),
                    loading: () => _shimmer(t, 110),
                    error: (_, __) => _WaterSleepRow(t: t, weekly: {}),
                  ),
                  const SizedBox(height: 12),
                  gamiAsync.when(
                    data: (gami) => _StreaksCard(t: t, gami: gami),
                    loading: () => _shimmer(t, 100),
                    error: (_, __) => _StreaksCard(t: t, gami: {}),
                  ),
                  const SizedBox(height: 12),
                  weeklyAsync.when(
                    data: (w) => _DietChartCard(t: t, weekly: w),
                    loading: () => _shimmer(t, 120),
                    error: (_, __) => _DietChartCard(t: t, weekly: {}),
                  ),
                  const SizedBox(height: 12),
                  _QuickActions(t: t),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmer(_Theme t, double h) => PulseSkeleton(
        height: h,
        radius: BorderRadius.circular(20),
      );
}

// ── KALORİ BANKASI NOTU ──────────────────────────────────
class _CalorieBankNote extends ConsumerWidget {
  final _Theme t;
  final Map<String, dynamic> meal;
  const _CalorieBankNote({required this.t, required this.meal});

  void _showBankAdvice(BuildContext context, _Theme t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: t.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => BankAdviceSheetPublic(isDark: t.isDark),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consumed    = (meal['calories_consumed']   as num?)?.toDouble() ?? 0;
    final target = (meal['calories_target'] as num?)?.toDouble() ?? 0;
    // target 0 ise gösterme — veri henüz yok demektir
    if (target == 0 && consumed == 0) return const SizedBox.shrink();
    final bankBalance = (meal['weekly_bank_balance'] as num?)?.toDouble() ?? 0;
    final bankMessage = meal['bank_message'] as String?;
    final isOver      = consumed > target && target > 0;
    final progress    = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () {
        ref.read(takipTabIndexProvider.notifier).state  = 1;
        ref.read(bottomNavIndexProvider.notifier).state = 1;
      },
      child: Container(
        decoration: BoxDecoration(
          color: t.accentDim,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.accent),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('💳 Bugünkü Kalori Bankası', style: TextStyle(fontSize: 11, color: t.accent, fontWeight: FontWeight.w600)),
                Text('Diyet Planı →', style: TextStyle(fontSize: 11, color: t.accent, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                RichText(text: TextSpan(
                  text: '${consumed.toInt()}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isOver ? t.danger : t.accent),
                  children: [TextSpan(
                    text: ' / ${target.toInt()} kcal',
                    style: TextStyle(fontSize: 12, color: t.textSoft, fontWeight: FontWeight.w400),
                  )],
                )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (bankBalance >= 0 ? t.positive : t.danger).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Hafta: ${bankBalance >= 0 ? "+" : ""}${bankBalance.toInt()} kcal',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: bankBalance >= 0 ? t.positive : t.danger),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: t.accent.withOpacity(0.15),
                color: isOver ? t.danger : t.accent,
              ),
            ),
            if (bankMessage != null) ...[
              const SizedBox(height: 8),
              Text(bankMessage, style: TextStyle(fontSize: 11, color: t.textSoft, height: 1.4)),
            ],
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showBankAdvice(context, t),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: t.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.accent.withOpacity(0.4)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.auto_awesome, size: 14, color: t.accent),
                  const SizedBox(width: 6),
                  Text('AI Kalori Analizi Al', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.accent)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HERO CARD ───────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final _Theme t;
  final Map<String, dynamic> gami;
  final Map<String, dynamic> weekly;
  final Map<String, dynamic>? waterToday;
  final Map<String, dynamic>? sleepToday;
  final Map<String, dynamic>? mealToday;
  const _HeroCard({required this.t, required this.gami, required this.weekly, this.waterToday, this.sleepToday, this.mealToday});

  @override
  Widget build(BuildContext context) {
    final level   = gami['level'] != null ? Map<String, dynamic>.from(gami['level']) : <String, dynamic>{};
    final rawStr  = gami['streaks'];
    final streaks = rawStr is List ? rawStr.map((s) => Map<String, dynamic>.from(s)).toList() : <Map<String, dynamic>>[];

    int maxStreak = 0;
    for (final s in streaks) {
      final cur = (s['current_streak'] as num?)?.toInt() ?? 0;
      if (cur > maxStreak) maxStreak = cur;
    }

    final measurements  = weekly['measurements'] != null ? Map<String, dynamic>.from(weekly['measurements']) : <String, dynamic>{};
    final weightChange  = (measurements['weight_change'] as num?)?.toDouble();
    final avgMl         = (weekly['water'] as Map?)?['avg_daily_ml'];
    final totalSess     = (weekly['exercise'] as Map?)?['total_sessions'];
    final avgSleep      = (weekly['sleep'] as Map?)?['avg_hours'];

    final missions = [
      ['💧 2L su iç',      avgMl    != null && (avgMl    as num) >= 2000],
      ['🏋️ Antrenman yap', totalSess != null && (totalSess as num) > 0],
      ['😴 7+ saat uyu',   avgSleep  != null && (avgSleep  as num) >= 7],
      ['🎯 Kalori hedefi',  false],
    ];

    final gradient = t.isDark
        ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1a1400), Color(0xFF2a1f00), Color(0xFF1a1200)])
        : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B2B), Color(0xFFFF9A5C)]);

    final heroText = t.isDark ? _C.accent : Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: t.accent.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          Positioned(
            top: -30, right: -30,
            child: Container(width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08))),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI KOÇ · GÜNLÜK ANALİZ',
                style: TextStyle(fontSize: 10, letterSpacing: 3, color: heroText.withOpacity(0.7), fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: Text(
                    maxStreak > 0 ? '🔥 $maxStreak günlük seri!' : '🚀 Hadi başlayalım!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: heroText, height: 1.2),
                  )),
                  if (level.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: Column(children: [
                        Text('Lv.${level['level'] ?? 1}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: heroText)),
                        Text('${level['xp'] ?? 0} XP', style: TextStyle(fontSize: 9, color: heroText.withOpacity(0.7))),
                      ]),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _buildDailyMessage(weightChange),
                style: TextStyle(fontSize: 12, color: heroText.withOpacity(0.82), height: 1.5),
              ),
              const SizedBox(height: 14),
              ...missions.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(m[0] as String, style: TextStyle(fontSize: 12, color: heroText)),
                      Text((m[1] as bool) ? '✔' : '✖',
                        style: TextStyle(fontWeight: FontWeight.w700,
                          color: (m[1] as bool) ? Colors.white : Colors.white.withOpacity(0.5))),
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

  String _buildDailyMessage(double? weightChange) {
    final messages = <String>[];
    final amountMl = (waterToday?['amount_ml'] as num?)?.toDouble();
    final targetMl = (waterToday?['target_ml'] as num?)?.toDouble() ?? 2000;
    if (amountMl != null && amountMl < targetMl * 0.5) {
      messages.add('💧 Bugün su içmeyi unutuyorsun!');
    }
    final sleepHours = (sleepToday?['duration_hours'] as num?)?.toDouble();
    if (sleepHours != null && sleepHours < 6) {
      messages.add('😴 Dün az uyudun (${sleepHours.toStringAsFixed(1)} saat).');
    }
    final consumed = (mealToday?['calories_consumed'] as num?)?.toDouble();
    final target   = (mealToday?['calories_target']   as num?)?.toDouble();
    if (consumed != null && target != null && consumed > target * 1.2) {
      messages.add('🍽️ Bugün kalori hedefini aştın.');
    }
    if (weightChange != null) {
      messages.add(weightChange < 0
          ? 'Kilo trendin düşüyor (${weightChange.toStringAsFixed(1)} kg). Harika!'
          : 'Kilo biraz arttı (+${weightChange.toStringAsFixed(1)} kg), dikkat et.');
    }
    if (messages.isEmpty) return 'Verilerini girerek kişisel AI analizini aktifleştir.';
    return messages.join(' ');
  }
}

// ── STAT GRID ───────────────────────────────────────────
class _StatGrid extends StatelessWidget {
  final _Theme t;
  final Map<String, dynamic> weekly;
  final double? latestWeight;
  const _StatGrid({required this.t, required this.weekly, this.latestWeight});

  @override
  Widget build(BuildContext context) {
    final water    = weekly['water']        != null ? Map<String, dynamic>.from(weekly['water'])        : <String, dynamic>{};
    final sleep    = weekly['sleep']        != null ? Map<String, dynamic>.from(weekly['sleep'])        : <String, dynamic>{};
    final exercise = weekly['exercise']     != null ? Map<String, dynamic>.from(weekly['exercise'])     : <String, dynamic>{};
    final meas     = weekly['measurements'] != null ? Map<String, dynamic>.from(weekly['measurements']) : <String, dynamic>{};

    final weightKg     = latestWeight ?? (meas['weight_kg'] as num?)?.toDouble();
    final weightChange = (meas['weight_change']      as num?)?.toDouble();
    final avgSleep     = (sleep['avg_hours']         as num?)?.toDouble();
    final totalSess    = (exercise['total_sessions'] as num?)?.toInt();
    final avgWater     = (water['avg_daily_ml']      as num?)?.toDouble();

    final items = [
      _StatItem(label: 'Ağırlık', value: weightKg != null ? weightKg.toStringAsFixed(1) : '--', unit: 'kg',
        delta: weightChange != null ? '${weightChange < 0 ? "↓" : "↑"} ${weightChange.abs().toStringAsFixed(1)} kg' : null,
        positive: weightChange != null && weightChange <= 0,
        bars: weightKg != null ? [20, 30, 45, 55, 70, (weightKg.clamp(30, 150) / 150 * 100).toInt()] : [0,0,0,0,0,0]),
      _StatItem(label: 'Ortalama Su', value: avgWater != null ? (avgWater / 1000).toStringAsFixed(1) : '--', unit: 'L/gün',
        delta: avgWater != null ? (avgWater >= 2000 ? '✓ hedefte' : '⚠ düşük') : null,
        positive: avgWater != null && avgWater >= 2000,
        bars: avgWater != null ? [10, 20, 35, 50, 65, (avgWater / 3000 * 100).clamp(0, 100).toInt()] : [0,0,0,0,0,0]),
      _StatItem(label: 'Egzersiz', value: totalSess != null ? '$totalSess' : '--', unit: 'seans',
        delta: totalSess != null ? (totalSess >= 3 ? '✓ iyi' : '⚠ az') : null,
        positive: totalSess != null && totalSess >= 3,
        bars: totalSess != null ? [0, 10, 25, 40, 60, (totalSess.clamp(0, 7) / 7 * 100).toInt()] : [0,0,0,0,0,0]),
      _StatItem(label: 'Ort. Uyku', value: avgSleep != null ? avgSleep.toStringAsFixed(1) : '--', unit: 'saat',
        delta: avgSleep != null ? (avgSleep >= 7 ? '✓ iyi' : '⚠ az') : null,
        positive: avgSleep != null && avgSleep >= 7,
        bars: avgSleep != null ? [10, 25, 40, 55, 70, (avgSleep.clamp(0, 10) / 10 * 100).toInt()] : [0,0,0,0,0,0]),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      // FIX (taşma): 1.5 kartları kısa bırakıp 6-7px dikey overflow'a yol açıyordu.
      // 1.35 ile kart yüksekliği içeriğe (başlık+değer+delta+bar) yetiyor.
      childAspectRatio: 1.35,
      children: items.map((item) => _StatMiniCard(t: t, item: item)).toList(),
    );
  }
}

class _StatItem {
  final String label, value, unit;
  final String? delta;
  final bool positive;
  final List<int> bars;
  const _StatItem({required this.label, required this.value, required this.unit,
    this.delta, this.positive = true, required this.bars});
}

class _StatMiniCard extends StatelessWidget {
  final _Theme t;
  final _StatItem item;
  const _StatMiniCard({required this.t, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: t.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: t.border)),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(alignment: Alignment.topCenter,
            child: Container(height: 2,
              decoration: BoxDecoration(color: t.accent.withOpacity(0.6), borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 6),
          Text(item.label, style: TextStyle(fontSize: 10, color: t.textMuted)),
          const SizedBox(height: 4),
          RichText(text: TextSpan(
            text: item.value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: t.text, height: 1),
            children: [TextSpan(text: ' ${item.unit}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: t.textSoft))],
          )),
          if (item.delta != null) ...[
            const SizedBox(height: 3),
            Text(item.delta!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: item.positive ? t.positive : t.danger)),
          ],
          const Spacer(),
          SizedBox(
            height: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: item.bars.asMap().entries.map((e) {
                final opacity = 0.15 + (e.key / item.bars.length) * 0.85;
                return Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: FractionallySizedBox(
                    heightFactor: e.value / 100,
                    alignment: Alignment.bottomCenter,
                    child: Container(decoration: BoxDecoration(
                      color: t.accent.withOpacity(opacity),
                      borderRadius: BorderRadius.circular(2))),
                  ),
                ));
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
    final water    = weekly['water'] != null ? Map<String, dynamic>.from(weekly['water']) : <String, dynamic>{};
    final sleep    = weekly['sleep'] != null ? Map<String, dynamic>.from(weekly['sleep']) : <String, dynamic>{};
    final avgMl    = (water['avg_daily_ml'] as num?)?.toDouble() ?? 0;
    final avgHours = (sleep['avg_hours']    as num?)?.toDouble() ?? 0;
    final waterPct = (avgMl    / 2000).clamp(0.0, 1.0);
    final sleepPct = (avgHours / 8   ).clamp(0.0, 1.0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: t.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: t.border)),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💧 Su', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.text)),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [0.0, 0.3, 0.6, waterPct, 0.0].map((h) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(color: t.bgSoft, borderRadius: BorderRadius.circular(5)),
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: h.clamp(0.05, 1.0),
                            child: Container(decoration: BoxDecoration(color: _C.cyan, borderRadius: BorderRadius.circular(4))),
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  RichText(text: TextSpan(
                    text: avgMl > 0 ? '${(avgMl / 1000).toStringAsFixed(1)}L' : '--',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.text),
                    children: [TextSpan(text: ' / 2L',
                      style: TextStyle(fontSize: 11, color: t.textSoft, fontWeight: FontWeight.w400))],
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: t.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: t.border)),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('😴 Uyku', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.text)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: CustomPaint(
                      painter: _SleepGaugePainter(progress: sleepPct, trackColor: t.bgSoft, fillColor: t.accent),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(avgHours > 0 ? '${avgHours.toStringAsFixed(1)} saat' : '--',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.text)),
                  Text(avgHours >= 7 ? 'iyi kalite' : 'yetersiz',
                    style: TextStyle(fontSize: 11, color: avgHours >= 7 ? t.positive : t.danger)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepGaugePainter extends CustomPainter {
  final double progress;
  final Color trackColor, fillColor;
  const _SleepGaugePainter({required this.progress, required this.trackColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx     = size.width / 2;
    final radius = size.width * 0.38;
    final cy     = size.height * 0.95;
    final rect   = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final p      = Paint()..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 3.14159, 3.14159, false, p..color = trackColor);
    canvas.drawArc(rect, 3.14159, 3.14159 * progress, false, p..color = fillColor);
  }

  @override
  bool shouldRepaint(_SleepGaugePainter old) =>
      old.progress != progress || old.trackColor != trackColor || old.fillColor != fillColor;
}

// ── SERİLER KARTI ───────────────────────────────────────
class _StreaksCard extends ConsumerWidget {
  final _Theme t;
  final Map<String, dynamic> gami;
  const _StreaksCard({required this.t, required this.gami});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawStreaks = gami['streaks'];
    final streaks = rawStreaks is List
        ? rawStreaks.map((s) => Map<String, dynamic>.from(s)).toList()
        : <Map<String, dynamic>>[];

    final streakMeta = {
      'water':    ('💧', 'Su'),
      'exercise': ('🏋️', 'Gym'),
      'sleep':    ('😴', 'Uyku'),
    };

    final displayStreaks = streaks.isNotEmpty ? streaks.take(4).toList() : [
      {'streak_type': 'water',    'current_streak': 0},
      {'streak_type': 'exercise', 'current_streak': 0},
      {'streak_type': 'sleep',    'current_streak': 0},
    ];

    return Container(
      decoration: BoxDecoration(color: t.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: t.border)),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('🏆 Seriler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text)),
            GestureDetector(
              onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 4,
              child: Text('Tümü', style: TextStyle(fontSize: 13, color: t.accent, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 14),
          Row(
            children: displayStreaks.map((s) {
              final type  = s['streak_type'] as String? ?? 'water';
              final count = (s['current_streak'] as num?)?.toInt() ?? 0;
              final meta  = streakMeta[type] ?? ('🔥', type);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: t.bgSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: t.border)),
                  child: Column(children: [
                    Text(meta.$1, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 2),
                    Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: t.accent)),
                    Text(meta.$2, style: TextStyle(fontSize: 9, color: t.textMuted)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── DİYET UYUMU BAR CHART ────────────────────────────────
class _DietChartCard extends StatelessWidget {
  final _Theme t;
  final Map<String, dynamic> weekly;
  const _DietChartCard({required this.t, required this.weekly});

  @override
  Widget build(BuildContext context) {
    final diet        = weekly['meal_compliance'] != null
        ? Map<String, dynamic>.from(weekly['meal_compliance'])
        : <String, dynamic>{};
    final avgRate      = (diet['compliance_rate'] as num?)?.toDouble();
    final compliedDays = (diet['complied_days']   as num?)?.toInt() ?? 0;
    final totalDays    = (diet['total_days']       as num?)?.toInt() ?? 0;

    final values = List.generate(7, (i) {
      if (totalDays == 0) return 0.0;
      if (i >= totalDays) return 0.0;
      return i < compliedDays ? 10.0 : 3.0;
    });
    final days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return Container(
      decoration: BoxDecoration(color: t.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: t.border)),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('📊 Diyet Uyumu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text)),
            if (avgRate != null)
              Text('%${avgRate.toInt()}', style: TextStyle(fontSize: 13, color: t.accent, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          if (totalDays == 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Henüz diyet verisi yok', style: TextStyle(fontSize: 13, color: t.textMuted)),
              ),
            ),
          ] else SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final v = values[i];
                Color barColor;
                double opacity;
                if (v >= 8)      { barColor = t.accent; opacity = 1.0; }
                else if (v >= 5) { barColor = _C.cyan;  opacity = 0.65; }
                else             { barColor = t.danger; opacity = 0.65; }

                return Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Expanded(child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: (v / 10).clamp(0.05, 1.0),
                        child: Container(decoration: BoxDecoration(
                          color: barColor.withOpacity(opacity),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        )),
                      ),
                    )),
                    const SizedBox(height: 4),
                    Text(days[i], style: TextStyle(fontSize: 9, color: t.textMuted)),
                  ]),
                ));
              }),
            ),
          ),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Haftalık ort.', style: TextStyle(fontSize: 12, color: t.textSoft)),
            Text(
              avgRate != null ? '%${avgRate.toInt()} uyum' : '-- veri yok',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: t.accent),
            ),
          ]),
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
      decoration: BoxDecoration(color: t.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: t.border)),
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
              child: Column(children: [
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
              ]),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── KALORI BANKASI SHEET ─────────────────────────────────
class BankAdviceSheetPublic extends StatefulWidget {
  final bool isDark;
  const BankAdviceSheetPublic({required this.isDark});
  @override
  State<BankAdviceSheetPublic> createState() => _BankAdviceSheetState();
}

class _BankAdviceSheetState extends State<BankAdviceSheetPublic> {
  Map<String, dynamic>? _advice;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final response = await ApiClient.instance.post(Endpoints.aiCalorieBankAdvice, data: {});
      setState(() { _advice = Map<String, dynamic>.from(response.data); _isLoading = false; });
    } on DioException catch (e) {
      // v2: calorie-bank-advice artık kotalı — kota mesajını aynen göster
      final q = QuotaException.fromDioError(e);
      setState(() { _error = q?.message ?? 'Analiz alınamadı'; _isLoading = false; });
    } catch (_) {
      setState(() { _error = 'Analiz alınamadı'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _Theme(widget.isDark);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 16),
          Text('🤖 AI Kalori Analizi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text)),
          const SizedBox(height: 16),
          if (_isLoading)
            Center(child: Padding(padding: const EdgeInsets.all(32), child: CircularProgressIndicator(color: t.accent)))
          else if (_error != null)
            Text(_error!, style: TextStyle(color: t.danger))
          else if (_advice != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: t.accentDim, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.accent)),
                        child: Text(
                          (_advice!['short_message'] as String?)?.isNotEmpty == true
                              ? _advice!['short_message'] as String
                              : 'Bugün iyi gidiyorsun!',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.accent),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if ((_advice!['detailed_advice'] as String?)?.isNotEmpty == true)
                        Text(_advice!['detailed_advice'] as String,
                          style: TextStyle(fontSize: 13, color: t.text, height: 1.5)),
                      const SizedBox(height: 12),
                      if ((_advice!['tomorrow_suggestion'] as String?)?.isNotEmpty == true) ...[
                        Text('Yarın için öneri:', style: TextStyle(fontSize: 12, color: t.textMuted, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(_advice!['tomorrow_suggestion'] as String,
                          style: TextStyle(fontSize: 13, color: t.text, height: 1.4)),
                      ],
                      if ((_advice!['weekly_outlook'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        Text('Haftalık değerlendirme:', style: TextStyle(fontSize: 12, color: t.textMuted, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(_advice!['weekly_outlook'] as String,
                          style: TextStyle(fontSize: 13, color: t.text, height: 1.4)),
                      ],
                      if ((_advice!['telafi_options'] as List?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        Text('Telafi seçenekleri:', style: TextStyle(fontSize: 12, color: t.textMuted, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        ...(_advice!['telafi_options'] as List).map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [
                            Icon(Icons.check_circle_outline, size: 14, color: t.accent),
                            const SizedBox(width: 8),
                            Expanded(child: Text(o.toString(), style: TextStyle(fontSize: 12, color: t.text))),
                          ]),
                        )),
                      ],
                      if ((_advice!['estimated_goal_date'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: t.accentDim, borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            Icon(Icons.flag_outlined, size: 14, color: t.accent),
                            const SizedBox(width: 8),
                            Text('Tahmini hedef: ${_advice!['estimated_goal_date']}',
                              style: TextStyle(fontSize: 12, color: t.accent, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ],
                      // FIX (UX): koç metni "antrenman planına git" diyordu ama tıklanamıyordu.
                      // Artık net bir CTA: sheet'i kapat, doğrudan Antrenman Planı ekranına götür.
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final nav = Navigator.of(context);
                            nav.pop(); // koç sheet'ini kapat
                            nav.push(MaterialPageRoute(builder: (_) => const WorkoutPlanScreen()));
                          },
                          icon: const Icon(Icons.fitness_center, size: 18),
                          label: const Text('Antrenman Planına Git'),
                        ),
                      ),
                    ],
        ],
      ),
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