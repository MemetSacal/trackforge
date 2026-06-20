import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';
import 'wrapped_screen.dart';
import '../health/insights_card.dart';
import '../../app.dart';

final weeklyReportDetailProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiClient.instance.get(
    Endpoints.reportsWeekly,
    queryParameters: {'reference_date': TFDateUtils.today()},
  );
  return Map<String, dynamic>.from(response.data);
});

final weeklyLogsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final response = await ApiClient.instance.get(
      '${Endpoints.reportsWeekly}/logs',
      queryParameters: {'reference_date': TFDateUtils.today()},
    );
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return {};
  }
});

final monthlyReportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final now = DateTime.now();
  final response = await ApiClient.instance.get(
    Endpoints.reportsMonthly,
    queryParameters: {'year': now.year.toString(), 'month': now.month.toString()},
  );
  return Map<String, dynamic>.from(response.data);
});

class _RC {
  static const bg       = Color(0xFF0C0D10);
  static const bgCard   = Color(0xFF141620);
  static const bgSoft   = Color(0xFF0F1016);
  static const border   = Color(0x12FFFFFF);
  static const text     = Color(0xFFF0EEF8);
  static const textSoft = Color(0xFF8A88A8);
  static const textMuted= Color(0xFF4A4860);
  static const accent   = Color(0xFFFFB020);
  static const accentDim= Color(0x1FFFB020);
  static const positive = Color(0xFF34D399);
  static const danger   = Color(0xFFFF5555);
  static const warning  = Color(0xFFFFB020);
  static const lBg      = Color(0xFFF0F2F6);
  static const lBgCard  = Color(0xFFFFFFFF);
  static const lBgSoft  = Color(0xFFE8EBF2);
  static const lBorder  = Color(0x12000000);
  static const lText    = Color(0xFF111318);
  static const lTextSoft= Color(0xFF5A6078);
  static const lTextMuted=Color(0xFF9AA0B8);
  static const lAccent  = Color(0xFFFF6B2B);
  static const lAccentDim=Color(0x1AFF6B2B);
  static const lPositive= Color(0xFF059669);
  static const lDanger  = Color(0xFFDC2626);
  static const lWarning = Color(0xFFD97706);
}

class RaporlarScreen extends ConsumerStatefulWidget {
  const RaporlarScreen({super.key});
  @override
  ConsumerState<RaporlarScreen> createState() => _RaporlarScreenState();
}

class _RaporlarScreenState extends ConsumerState<RaporlarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _months = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Context sızıntısını önlemek için context parametresi kaldırıldı, mounted kontrolü eklendi
  Future<void> _downloadHealthPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🩺 Rapor hazırlanıyor...')));
    try {
      final res = await ApiClient.instance.get(
        Endpoints.reportsHealthPdf,
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/trackforge_saglik_raporu.pdf');
      await file.writeAsBytes(res.data as List<int>);

      if (!mounted) return;
      await OpenFilex.open(file.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rapor indirilemedi, tekrar dene')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg       = isDark ? _RC.bg       : _RC.lBg;
    final bgCard   = isDark ? _RC.bgCard   : _RC.lBgCard;
    final bgSoft   = isDark ? _RC.bgSoft   : _RC.lBgSoft;
    final border   = isDark ? _RC.border   : _RC.lBorder;
    final text     = isDark ? _RC.text     : _RC.lText;
    final textSoft = isDark ? _RC.textSoft : _RC.lTextSoft;
    final muted    = isDark ? _RC.textMuted: _RC.lTextMuted;
    final accent   = isDark ? _RC.accent   : _RC.lAccent;
    final accentDim= isDark ? _RC.accentDim: _RC.lAccentDim;
    final positive = isDark ? _RC.positive : _RC.lPositive;
    final danger   = isDark ? _RC.danger   : _RC.lDanger;
    final warning  = isDark ? _RC.warning  : _RC.lWarning;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Container(
            color: bg,
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: textSoft),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Raporlar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5))),
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
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(14)),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)]),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: accent,
                    unselectedLabelColor: muted,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    tabs: const [Tab(text: 'Haftalık'), Tab(text: 'Aylık')],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _WeeklyTab(
                  bg: bg, bgCard: bgCard, bgSoft: bgSoft, border: border,
                  text: text, textSoft: textSoft, muted: muted, accent: accent,
                  accentDim: accentDim, positive: positive, danger: danger, warning: warning,
                  isDark: isDark, onPdfTap: _downloadHealthPdf,
                ),
                _MonthlyTab(bg: bg, bgCard: bgCard, bgSoft: bgSoft, border: border,
                  text: text, textSoft: textSoft, muted: muted, accent: accent,
                  accentDim: accentDim, positive: positive, danger: danger, warning: warning,
                  months: _months),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyTab extends ConsumerWidget {
  final Color bg, bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim, positive, danger, warning;
  final bool isDark;
  final VoidCallback onPdfTap;

  const _WeeklyTab({
    required this.bg, required this.bgCard, required this.bgSoft,
    required this.border, required this.text, required this.textSoft, required this.muted,
    required this.accent, required this.accentDim, required this.positive,
    required this.danger, required this.warning, required this.isDark,
    required this.onPdfTap,
  });

  static const _shortMonths = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(weeklyReportDetailProvider);

    return reportAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: accent)),
      error: (_, __) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Veri yüklenemedi', style: TextStyle(color: text)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => ref.refresh(weeklyReportDetailProvider), child: const Text('Yenile')),
        ]),
      ),
      data: (data) {
        final logs = ref.watch(weeklyLogsProvider).value ?? {};
        final water    = data['water']    != null ? Map<String, dynamic>.from(data['water'])    : <String, dynamic>{};
        final sleep    = data['sleep']    != null ? Map<String, dynamic>.from(data['sleep'])    : <String, dynamic>{};
        final exercise = data['exercise'] != null ? Map<String, dynamic>.from(data['exercise']) : <String, dynamic>{};
        final meas     = data['measurements'] != null ? Map<String, dynamic>.from(data['measurements']) : <String, dynamic>{};
        final meal     = data['meal_compliance'] != null ? Map<String, dynamic>.from(data['meal_compliance']) : <String, dynamic>{};
        final measLogs  = logs['measurements'] as List? ?? [];
        final waterLogs = logs['water_logs']   as List? ?? [];
        final sleepLogs = logs['sleep_logs']   as List? ?? [];

        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd   = weekStart.add(const Duration(days: 6));
        final dateLabel = '${weekStart.day}–${weekEnd.day} ${_shortMonths[weekStart.month]} ${weekStart.year}';

        // Güvenli cast işlemleriyle stats listesi oluşturuldu
        final stats = [
          ['Kilo Değişimi',  meas['weight_change'] != null ? '${(meas['weight_change'] as num) < 0 ? "" : "+"}${meas['weight_change']} kg' : '-', meas['weight_change'] != null && (meas['weight_change'] as num) <= 0],
          ['Diyet Uyumu',    meal['compliance_rate'] != null ? '%${(meal['compliance_rate'] as num).toStringAsFixed(0)}' : '-', meal['compliance_rate'] != null && (meal['compliance_rate'] as num) >= 70],
          ['Egzersiz',       exercise['total_sessions'] != null ? '${exercise['total_sessions']} seans' : '-', exercise['total_sessions'] != null && (exercise['total_sessions'] as num) >= 3],
          ['Ort. Uyku',      sleep['avg_hours'] != null ? '${(sleep['avg_hours'] as num).toStringAsFixed(1)}s' : '-', sleep['avg_hours'] != null && (sleep['avg_hours'] as num) >= 7],
          ['Su Ort.',        water['avg_daily_ml'] != null ? '${((water['avg_daily_ml'] as num) / 1000).toStringAsFixed(1)}L' : '-', water['avg_daily_ml'] != null && (water['avg_daily_ml'] as num) >= 2000],
          ['Kalori Ort.',    meal['avg_calories'] != null ? '${(meal['avg_calories'] as num).toInt()} kcal' : '-', true],
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            children: [
              const InsightsCard(),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WrappedScreen())),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFFB020), Color(0xFFFF6B2B)],
                        begin: Alignment.centerLeft, end: Alignment.centerRight),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    const Text('🏆', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('TrackForge Wrapped hazır! 🎁', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1208))),
                      SizedBox(height: 2),
                      Text('Yılının özetini gör, arkadaşlarına göster', style: TextStyle(fontSize: 12, color: Color(0xB31A1208))),
                    ])),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF1A1208)),
                  ]),
                ),
              ),
              GestureDetector(
                onTap: onPdfTap,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                  ),
                  child: Row(children: [
                    const Text('🩺', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Sağlık Raporu (PDF)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                      const SizedBox(height: 2),
                      Text('Doktoruna/diyetisyenine götür — son 4 haftanın özeti', style: TextStyle(fontSize: 11, color: muted)),
                    ])),
                    Icon(Icons.download_rounded, size: 18, color: accent),
                  ]),
                ),
              ),
              Container(
                decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(dateLabel, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                    ]),
                    const SizedBox(height: 14),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.8,
                      children: stats.map((s) {
                        final isTarget = s[2] as bool? ?? false; // Null-safe koruma
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(s[0] as String, style: TextStyle(fontSize: 10, color: muted, overflow: TextOverflow.ellipsis)),
                              const SizedBox(height: 2),
                              Text(s[1] as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: text, overflow: TextOverflow.ellipsis)),
                              Text(isTarget ? '✔ hedefte' : '⚠ düşük',
                                style: TextStyle(fontSize: 10, color: isTarget ? positive : warning, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: bgCard.withOpacity(0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: accent.withOpacity(0.3))),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Yorumu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                    const SizedBox(height: 10),
                    Text(_buildAiComment(water, sleep, exercise, meas), style: TextStyle(fontSize: 13, color: text, height: 1.6)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (measLogs.isNotEmpty) ...[
                _ChartCard(title: '⚖️ Kilo Trendi', bgCard: bgCard, border: border, text: text,
                  child: _WeightChart(measurements: measLogs, accent: accent, bgSoft: bgSoft)),
                const SizedBox(height: 12),
              ],
              if (waterLogs.isNotEmpty) ...[
                _ChartCard(title: '💧 Su Tüketimi', bgCard: bgCard, border: border, text: text,
                  child: _WaterChart(waterLogs: waterLogs, accent: accent)),
                const SizedBox(height: 12),
              ],
              if (sleepLogs.isNotEmpty) ...[
                _ChartCard(title: '😴 Uyku Süresi', bgCard: bgCard, border: border, text: text,
                  child: _SleepChart(sleepLogs: sleepLogs, accent: accent, bgSoft: bgSoft)),
              ],
              if (measLogs.isEmpty && waterLogs.isEmpty && sleepLogs.isEmpty)
                Container(
                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(children: [
                    const Text('📊', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('Henüz grafik verisi yok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
                    const SizedBox(height: 4),
                    Text('Ölçüm, su ve uyku kaydet', style: TextStyle(fontSize: 12, color: muted)),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }

  String _buildAiComment(Map water, Map sleep, Map exercise, Map meas) {
    final parts = <String>[];
    final wChange = (meas['weight_change'] as num?)?.toDouble();
    if (wChange != null) parts.add(wChange < 0 ? 'Kilo trendin olumlu (${wChange.toStringAsFixed(1)} kg).' : 'Kilo biraz arttı (+${wChange.toStringAsFixed(1)} kg), dikkat et.');
    final avgSleep = (sleep['avg_hours'] as num?)?.toDouble();
    if (avgSleep != null) parts.add(avgSleep >= 7 ? 'Uyku düzenin iyi.' : 'Uyku süren yetersiz, artırmayı dene.');
    final totalSess = (exercise['total_sessions'] as num?)?.toInt();
    if (totalSess != null) parts.add(totalSess >= 3 ? '$totalSess antrenmanla güçlü bir hafta geçirdin.' : 'Antrenman sayısını artırmaya çalış.');
    if (parts.isEmpty) return 'Veri girdikçe kişisel AI yorumun burada görünecek.';
    return parts.join(' ');
  }
}

class _MonthlyTab extends ConsumerWidget {
  final Color bg, bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim, positive, danger, warning;
  final List<String> months;
  const _MonthlyTab({required this.bg, required this.bgCard, required this.bgSoft,
    required this.border, required this.text, required this.textSoft, required this.muted,
    required this.accent, required this.accentDim, required this.positive,
    required this.danger, required this.warning, required this.months});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(monthlyReportProvider);

    return reportAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: accent)),
      error: (_, __) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Veri yüklenemedi', style: TextStyle(color: text)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => ref.refresh(monthlyReportProvider), child: const Text('Yenile')),
        ]),
      ),
      data: (data) {
        final water    = data['water']    != null ? Map<String, dynamic>.from(data['water'])    : <String, dynamic>{};
        final sleep    = data['sleep']    != null ? Map<String, dynamic>.from(data['sleep'])    : <String, dynamic>{};
        final exercise = data['exercise'] != null ? Map<String, dynamic>.from(data['exercise']) : <String, dynamic>{};
        final meas     = data['measurements'] != null ? Map<String, dynamic>.from(data['measurements']) : <String, dynamic>{};
        final meal     = data['meal_compliance'] != null ? Map<String, dynamic>.from(data['meal_compliance']) : <String, dynamic>{};

        final now = DateTime.now();
        final rows = [
          ['Toplam Antrenman', exercise['total_sessions'] != null ? '${exercise['total_sessions']} seans' : '-', exercise['total_sessions'] != null && (exercise['total_sessions'] as num) >= 12],
          ['Ort. Su',          water['avg_daily_ml']    != null ? '${((water['avg_daily_ml'] as num) / 1000).toStringAsFixed(1)} L/gün' : '-', water['avg_daily_ml'] != null && (water['avg_daily_ml'] as num) >= 2000],
          ['Ort. Uyku',        sleep['avg_hours']       != null ? '${(sleep['avg_hours'] as num).toStringAsFixed(1)} saat' : '-', sleep['avg_hours'] != null && (sleep['avg_hours'] as num) >= 7],
          ['Diyet Uyumu',      meal['compliance_rate']  != null ? '%${(meal['compliance_rate'] as num).toStringAsFixed(0)}' : '-', meal['compliance_rate'] != null && (meal['compliance_rate'] as num) >= 70],
          ['Son Kilo',         meas['weight_kg']        != null ? '${meas['weight_kg']} kg' : '-', true],
          ['Kilo Değişimi',    meas['weight_change']    != null ? '${meas['weight_change']} kg' : '-', meas['weight_change'] != null && (meas['weight_change'] as num) <= 0],
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${months[now.month]} ${now.year}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                    const SizedBox(height: 14),
                    ...rows.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r[0] as String, style: TextStyle(fontSize: 13, color: textSoft)),
                          Row(children: [
                            Text(r[1] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: text)),
                            const SizedBox(width: 8),
                            Text((r[2] as bool) ? '✔' : '⚠', style: TextStyle(color: (r[2] as bool) ? positive : warning, fontSize: 12)),
                          ]),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color bgCard, border, text;
  const _ChartCard({required this.title, required this.child, required this.bgCard, required this.border, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
          const SizedBox(height: 16),
          SizedBox(height: 180, child: child),
        ],
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List measurements;
  final Color accent, bgSoft;
  const _WeightChart({required this.measurements, required this.accent, required this.bgSoft});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < measurements.length; i++) {
      final m = Map<String, dynamic>.from(measurements[i]);
      final w = (m['weight_kg'] as num?)?.toDouble();
      if (w != null) spots.add(FlSpot(i.toDouble(), w));
    }
    if (spots.isEmpty) return Center(child: Text('Kilo verisi yok', style: TextStyle(color: accent.withOpacity(0.5))));
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(LineChartData(
      minY: minY, maxY: maxY,
      gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: bgSoft, strokeWidth: 1)),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
          getTitlesWidget: (v, _) => Text('${v.toInt()}', style: TextStyle(fontSize: 9, color: accent.withOpacity(0.6))))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
          getTitlesWidget: (v, _) => Text('${v.toInt() + 1}', style: TextStyle(fontSize: 9, color: accent.withOpacity(0.6))))),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(
        spots: spots, isCurved: true, color: accent, barWidth: 3,
        dotData: FlDotData(getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: accent, strokeWidth: 0, strokeColor: Colors.transparent)),
        belowBarData: BarAreaData(show: true, color: accent.withOpacity(0.1)),
      )],
    ));
  }
}

class _WaterChart extends StatelessWidget {
  final List waterLogs;
  final Color accent;
  const _WaterChart({required this.waterLogs, required this.accent});

  @override
  Widget build(BuildContext context) {
    final bars = <BarChartGroupData>[];
    for (var i = 0; i < waterLogs.length; i++) {
      final w = Map<String, dynamic>.from(waterLogs[i]);
      final amount = ((w['amount_ml'] as num?)?.toDouble() ?? 0) / 1000;
      bars.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: amount, color: const Color(0xFF22D3EE), width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
      ]));
    }
    return BarChart(BarChartData(
      barGroups: bars,
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
          getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}L', style: TextStyle(fontSize: 9, color: accent.withOpacity(0.6))))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
          getTitlesWidget: (v, _) => Text('${v.toInt() + 1}', style: TextStyle(fontSize: 9, color: accent.withOpacity(0.6))))),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
    ));
  }
}

class _SleepChart extends StatelessWidget {
  final List sleepLogs;
  final Color accent, bgSoft;
  const _SleepChart({required this.sleepLogs, required this.accent, required this.bgSoft});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < sleepLogs.length; i++) {
      final s = Map<String, dynamic>.from(sleepLogs[i]);
      final h = (s['duration_hours'] as num?)?.toDouble();
      if (h != null) spots.add(FlSpot(i.toDouble(), h));
    }
    if (spots.isEmpty) return Center(child: Text('Uyku verisi yok', style: TextStyle(color: accent.withOpacity(0.5))));

    return LineChart(LineChartData(
      minY: 0, maxY: 12,
      gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: bgSoft, strokeWidth: 1)),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32,
          getTitlesWidget: (v, _) => Text('${v.toInt()}s', style: TextStyle(fontSize: 9, color: accent.withOpacity(0.6))))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
          getTitlesWidget: (v, _) => Text('${v.toInt() + 1}', style: TextStyle(fontSize: 9, color: accent.withOpacity(0.6))))),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(
        spots: spots, isCurved: true, color: const Color(0xFFA78BFA), barWidth: 3,
        dotData: FlDotData(getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: const Color(0xFFA78BFA), strokeWidth: 0, strokeColor: Colors.transparent)),
        belowBarData: BarAreaData(show: true, color: const Color(0xFFA78BFA).withOpacity(0.1)),
      )],
    ));
  }
}