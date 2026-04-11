// ── dashboard_screen.dart ───────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';
import 'home_screen.dart';
import '../takip/takip_screen.dart';

// ── PROVIDER'LAR ────────────────────────────────────────
final userProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiClient.instance.get(Endpoints.me);
  return Map<String, dynamic>.from(response.data);
});

final gamificationProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiClient.instance.get(Endpoints.gamificationSummary);
  return Map<String, dynamic>.from(response.data);
});

final weeklyReportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiClient.instance.get(
    Endpoints.reportsWeekly,
    queryParameters: {'reference_date': TFDateUtils.today()},
  );
  return Map<String, dynamic>.from(response.data);
});

// ── DASHBOARD SCREEN ────────────────────────────────────
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final gamificationAsync = ref.watch(gamificationProvider);
    final weeklyAsync = ref.watch(weeklyReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: userAsync.when(
          data: (user) => Text(
              'Merhaba, ${user['full_name'].toString().split(' ')[0]} 👋'),
          loading: () => const Text('TrackForge'),
          error: (_, __) => const Text('TrackForge'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userProvider);
              ref.invalidate(gamificationProvider);
              ref.invalidate(weeklyReportProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProvider);
          ref.invalidate(gamificationProvider);
          ref.invalidate(weeklyReportProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              gamificationAsync.when(
                data: (data) => _GamificationCard(data: data),
                loading: () => const _LoadingCard(height: 120),
                error: (e, _) => const _ErrorCard(),
              ),
              const SizedBox(height: 16),
              weeklyAsync.when(
                data: (data) => _WeeklyCard(data: data),
                loading: () => const _LoadingCard(height: 200),
                error: (e, _) => const _ErrorCard(),
              ),
              const SizedBox(height: 16),
              const _QuickActionsCard(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ── GAMİFİCATİON KARTI ──────────────────────────────────
class _GamificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _GamificationCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final level = data['level'] != null
        ? Map<String, dynamic>.from(data['level'])
        : <String, dynamic>{};

    final rawStreaks = data['streaks'];
    final streaks = rawStreaks is List
        ? rawStreaks.map((s) => Map<String, dynamic>.from(s)).toList()
        : <Map<String, dynamic>>[];

    int maxStreak = 0;
    for (final s in streaks) {
      final current = s['current_streak'] as int? ?? 0;
      if (current > maxStreak) maxStreak = current;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${level['level'] ?? 1}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${level['level_title'] ?? 'Beginner'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _xpProgress(level),
                    backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.15),
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${level['xp'] ?? 0} XP',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 24)),
                Text(
                  '$maxStreak',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text('gün', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _xpProgress(Map<String, dynamic> level) {
    final xp = (level['xp'] as num?)?.toInt() ?? 0;
    final lvl = (level['level'] as num?)?.toInt() ?? 1;
    const thresholds = [0, 500, 1500, 3000, 6000];
    if (lvl >= thresholds.length) return 1.0;
    final current = thresholds[lvl - 1];
    final next = thresholds[lvl];
    return ((xp - current) / (next - current)).clamp(0.0, 1.0);
  }
}

// ── HAFTALIK ÖZET KARTI ─────────────────────────────────
class _WeeklyCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _WeeklyCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // Backend nested objeler döndürüyor — her birini ayrı parse et
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu Hafta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatBox(
                  icon: '💧',
                  label: 'Ortalama Su',
                  value: water.isNotEmpty
                      ? '${((water['avg_daily_ml'] as num? ?? 0) / 1000).toStringAsFixed(1)}L'
                      : '-',
                ),
                const SizedBox(width: 12),
                _StatBox(
                  icon: '🏋️',
                  label: 'Antrenman',
                  value: exercise.isNotEmpty
                      ? '${exercise['total_sessions'] ?? 0} seans'
                      : '-',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatBox(
                  icon: '😴',
                  label: 'Ortalama Uyku',
                  value: sleep.isNotEmpty
                      ? '${((sleep['avg_hours'] as num? ?? 0).toStringAsFixed(1))}s'
                      : '-',
                ),
                const SizedBox(width: 12),
                _StatBox(
                  icon: '⚖️',
                  label: 'Son Kilo',
                  value: measurements.isNotEmpty && measurements['weight_kg'] != null
                      ? '${measurements['weight_kg']} kg'
                      : '-',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ── HIZLI ERİŞİM ────────────────────────────────────────
class _QuickActionsCard extends ConsumerWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hızlı Erişim',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickAction(
                  icon: '💧',
                  label: 'Su Ekle',
                  onTap: () {
                    ref.read(takipTabIndexProvider.notifier).state = 2; // Su tab
                    ref.read(bottomNavIndexProvider.notifier).state = 1; // Takip
                  },
                ),
                _QuickAction(
                  icon: '🏋️',
                  label: 'Antrenman',
                  onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 2,
                ),
                _QuickAction(
                  icon: '🍽️',
                  label: 'Öğün',
                  onTap: () {
                    ref.read(takipTabIndexProvider.notifier).state = 1; // Diyet tab
                    ref.read(bottomNavIndexProvider.notifier).state = 1; // Takip
                  },
                ),
                _QuickAction(
                  icon: '😴',
                  label: 'Uyku',
                  onTap: () {
                    ref.read(takipTabIndexProvider.notifier).state = 3; // Uyku tab
                    ref.read(bottomNavIndexProvider.notifier).state = 1; // Takip
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// ── YARDIMCI WIDGET'LAR ──────────────────────────────────
class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text(
              'Veri yüklenemedi',
              style:
              TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }
}