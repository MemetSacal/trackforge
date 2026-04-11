// ── raporlar_screen.dart ────────────────────────────────
// Haftalık ve aylık raporlar ekranı.
// GET /reports/weekly → haftalık özet
// GET /reports/monthly → aylık özet
// fl_chart ile kilo, su, uyku grafikleri gösterilir.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';

// ── PROVIDER'LAR ────────────────────────────────────────
final weeklyReportDetailProvider =
FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiClient.instance.get(
    Endpoints.reportsWeekly,
    queryParameters: {'reference_date': TFDateUtils.today()},
  );
  return Map<String, dynamic>.from(response.data);
});

final monthlyReportProvider =
FutureProvider<Map<String, dynamic>>((ref) async {
  final now = DateTime.now();
  final response = await ApiClient.instance.get(
    Endpoints.reportsMonthly,
    queryParameters: {
      'year': now.year.toString(),
      'month': now.month.toString(),
    },
  );
  return Map<String, dynamic>.from(response.data);
});

// ── RAPORLAR SCREEN ─────────────────────────────────────
class RaporlarScreen extends ConsumerStatefulWidget {
  const RaporlarScreen({super.key});

  @override
  ConsumerState<RaporlarScreen> createState() => _RaporlarScreenState();
}

class _RaporlarScreenState extends ConsumerState<RaporlarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Haftalık'),
            Tab(text: 'Aylık'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WeeklyTab(),
          _MonthlyTab(),
        ],
      ),
    );
  }
}

// ── HAFTALIK TAB ────────────────────────────────────────
class _WeeklyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(weeklyReportDetailProvider);

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Veri yüklenemedi')),
      data: (data) {
        // Backend nested objeler döndürüyor
        final water = data['water'] != null
            ? Map<String, dynamic>.from(data['water'])
            : <String, dynamic>{};
        final sleep = data['sleep'] != null
            ? Map<String, dynamic>.from(data['sleep'])
            : <String, dynamic>{};
        final exercise = data['exercise'] != null
            ? Map<String, dynamic>.from(data['exercise'])
            : <String, dynamic>{};

        // Grafik için ham listeler — backend bunları döndürmüyor,
        // özet objelerden hesaplıyoruz
        final rawMeasurements = data['measurements'];
        final measurements = rawMeasurements is List
            ? rawMeasurements
            : <dynamic>[];
        final rawWaterLogs = data['water_logs'];
        final waterLogs = rawWaterLogs is List
            ? rawWaterLogs
            : <dynamic>[];
        final rawSleepLogs = data['sleep_logs'];
        final sleepLogs = rawSleepLogs is List
            ? rawSleepLogs
            : <dynamic>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── ÖZET KARTLAR ──────────────────────────
              Row(
                children: [
                  _SummaryCard(
                    icon: '💧',
                    label: 'Ort. Su',
                    value: water.isNotEmpty
                        ? '${((water['avg_daily_ml'] as num? ?? 0) / 1000).toStringAsFixed(1)}L'
                        : '-',
                  ),
                  const SizedBox(width: 8),
                  _SummaryCard(
                    icon: '🏋️',
                    label: 'Antrenman',
                    value: exercise.isNotEmpty
                        ? '${exercise['total_sessions'] ?? 0}'
                        : '-',
                  ),
                  const SizedBox(width: 8),
                  _SummaryCard(
                    icon: '😴',
                    label: 'Ort. Uyku',
                    value: sleep.isNotEmpty
                        ? '${(sleep['avg_hours'] as num? ?? 0).toStringAsFixed(1)}s'
                        : '-',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── KİLO GRAFİĞİ ──────────────────────────
              if (measurements.isNotEmpty) ...[
                _ChartCard(
                  title: '⚖️ Kilo Trendi',
                  child: _WeightChart(measurements: measurements),
                ),
                const SizedBox(height: 16),
              ],

              // ── SU GRAFİĞİ ────────────────────────────
              if (waterLogs.isNotEmpty) ...[
                _ChartCard(
                  title: '💧 Su Tüketimi',
                  child: _WaterChart(waterLogs: waterLogs),
                ),
                const SizedBox(height: 16),
              ],

              // ── UYKU GRAFİĞİ ──────────────────────────
              if (sleepLogs.isNotEmpty) ...[
                _ChartCard(
                  title: '😴 Uyku Süresi',
                  child: _SleepChart(sleepLogs: sleepLogs),
                ),
                const SizedBox(height: 16),
              ],

              // Grafik verisi yoksa mesaj göster
              if (measurements.isEmpty &&
                  waterLogs.isEmpty &&
                  sleepLogs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Text('📊',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        const Text(
                          'Bu hafta henüz grafik verisi yok',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ölçüm, su ve uyku kaydet',
                          style:
                          Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

// ── AYLIK TAB ───────────────────────────────────────────
class _MonthlyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(monthlyReportProvider);

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Veri yüklenemedi')),
      data: (data) {
        // Backend nested objeler döndürüyor — summary değil ayrı field'lar
        final water = data['water'] != null
            ? Map<String, dynamic>.from(data['water'])
            : <String, dynamic>{};
        final sleep = data['sleep'] != null
            ? Map<String, dynamic>.from(data['sleep'])
            : <String, dynamic>{};
        final exercise = data['exercise'] != null
            ? Map<String, dynamic>.from(data['exercise'])
            : <String, dynamic>{};
        final measurements = data['measurements'] != null
            ? Map<String, dynamic>.from(data['measurements'])
            : <String, dynamic>{};
        final mealCompliance = data['meal_compliance'] != null
            ? Map<String, dynamic>.from(data['meal_compliance'])
            : <String, dynamic>{};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateTime.now().year} — ${_monthName(DateTime.now().month)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                        label: 'Toplam Antrenman',
                        value: exercise.isNotEmpty
                            ? '${exercise['total_sessions'] ?? 0} seans'
                            : '-',
                      ),
                      _InfoRow(
                        label: 'Ort. Su',
                        value: water.isNotEmpty
                            ? '${((water['avg_daily_ml'] as num? ?? 0) / 1000).toStringAsFixed(1)} L/gün'
                            : '-',
                      ),
                      _InfoRow(
                        label: 'Ort. Uyku',
                        value: sleep.isNotEmpty
                            ? '${(sleep['avg_hours'] as num? ?? 0).toStringAsFixed(1)} saat'
                            : '-',
                      ),
                      _InfoRow(
                        label: 'Diyet Uyum',
                        value: mealCompliance.isNotEmpty
                            ? '%${(mealCompliance['compliance_rate'] as num? ?? 0).toStringAsFixed(0)}'
                            : '-',
                      ),
                      if (measurements.isNotEmpty &&
                          measurements['weight_kg'] != null)
                        _InfoRow(
                          label: 'Son Kilo',
                          value: '${measurements['weight_kg']} kg',
                        ),
                      if (measurements.isNotEmpty &&
                          measurements['weight_change'] != null)
                        _InfoRow(
                          label: 'Kilo Değişimi',
                          value: '${measurements['weight_change']} kg',
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return months[month];
  }
}

// ── KİLO GRAFİĞİ ────────────────────────────────────────
class _WeightChart extends StatelessWidget {
  final List measurements;
  const _WeightChart({required this.measurements});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < measurements.length; i++) {
      final m = Map<String, dynamic>.from(measurements[i]);
      final weight = (m['weight_kg'] as num?)?.toDouble();
      if (weight != null) {
        spots.add(FlSpot(i.toDouble(), weight));
      }
    }

    if (spots.isEmpty) {
      return const Center(child: Text('Kilo verisi yok'));
    }

    final minY =
        spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
    final maxY =
        spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt() + 1}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color:
              Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SU GRAFİĞİ ──────────────────────────────────────────
class _WaterChart extends StatelessWidget {
  final List waterLogs;
  const _WaterChart({required this.waterLogs});

  @override
  Widget build(BuildContext context) {
    final bars = <BarChartGroupData>[];
    for (var i = 0; i < waterLogs.length; i++) {
      final w = Map<String, dynamic>.from(waterLogs[i]);
      final amount =
          ((w['amount_ml'] as num?)?.toDouble() ?? 0) / 1000;
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: Theme.of(context).primaryColor,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: bars,
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                '${value.toStringAsFixed(1)}L',
                style: const TextStyle(fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt() + 1}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

// ── UYKU GRAFİĞİ ────────────────────────────────────────
class _SleepChart extends StatelessWidget {
  final List sleepLogs;
  const _SleepChart({required this.sleepLogs});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < sleepLogs.length; i++) {
      final s = Map<String, dynamic>.from(sleepLogs[i]);
      final hours = (s['duration_hours'] as num?)?.toDouble();
      if (hours != null) {
        spots.add(FlSpot(i.toDouble(), hours));
      }
    }

    if (spots.isEmpty) {
      return const Center(child: Text('Uyku verisi yok'));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 12,
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}s',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt() + 1}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.indigo,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.indigo.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

// ── YARDIMCI WIDGET'LAR ──────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 180, child: child),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}