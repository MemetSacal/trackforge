// ── steps_screen.dart ───────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ← YENİ
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';
import '../../app.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/widgets/count_up_text.dart';
import '../../core/widgets/pulse_skeleton.dart';

// v8: son 7 günün adımları — mini grafik için
final weekStepsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.steps);
    final list = (response.data as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e)).toList();
    list.sort((a, b) => (a['date'] ?? '').toString().compareTo((b['date'] ?? '').toString()));
    return list.length > 7 ? list.sublist(list.length - 7) : list;
  } catch (_) { return []; }
});

final todayStepsProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.instance.get('${Endpoints.steps}/date/${TFDateUtils.today()}');
    return Map<String, dynamic>.from(response.data);
  } catch (_) { return null; }
});

class StepsScreen extends ConsumerStatefulWidget {
  const StepsScreen({super.key});
  @override
  ConsumerState<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends ConsumerState<StepsScreen> {
  final _stepsController = TextEditingController();
  final _goalController  = TextEditingController(text: '10000');
  bool _isLoading = false;

  // ── Pedometer ──────────────────────────────────────────
  StreamSubscription<StepCount>?    _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;
  int  _liveSteps     = 0;
  bool _isPedActive   = false;
  bool _isWalking     = false;

  // Persist için kullanılan alanlar
  // _sessionStart  → cihaz boot'undan itibaren toplam adım sayısı
  //                  (pedometer her boot'ta sıfırlanır, bunu saklarız)
  // _savedToday    → bugün için daha önce persist ettiğimiz adım sayısı
  //                  (uygulama kapanıp açılınca buradan devam ederiz)
  int  _sessionStart  = 0;
  int  _savedToday    = 0;
  bool _sessionActive = false;
  int  _lastRawSteps    = 0;     // son pedometer raw değeri
  int  _pendingSteps    = 0;     // birikmiş ama henüz onaylanmamış adımlar
  DateTime? _lastStepTime;       // son adım zamanı
  static const int _minStepDelta    = 3;    // tek seferde en az 3 adım artışı kabul et
  static const int _minIntervalMs   = 400;  // adımlar arası minimum 400ms

  // SharedPreferences key'leri
  // 'ped_session_start' → pedometer'dan okunan başlangıç değeri
  // 'ped_saved_date'    → hangi gün için kayıt tutulduğu (YYYY-MM-DD)
  // 'ped_saved_steps'   → o gün için kaydedilen toplam adım
  static const _kStart = 'ped_session_start';
  static const _kDate  = 'ped_saved_date';
  static const _kSteps = 'ped_saved_steps';

  @override
  void initState() {
    super.initState();
    _loadAndStart(); // Önce persist'ten yükle, sonra pedometer'ı başlat
  }

  // ── PERSIST'TEN YÜKLE ─────────────────────────────────
  // Uygulama açılırken SharedPreferences'tan bugünkü adım verisini çeker.
  // Eğer kayıt başka bir güne aitse sıfırlar (yeni gün = sıfırdan başla).
  Future<void> _loadAndStart() async {
    final prefs   = await SharedPreferences.getInstance();
    final today   = TFDateUtils.today(); // "YYYY-MM-DD"
    final savedDate = prefs.getString(_kDate);

    if (savedDate == today) {
      // Bugün için kayıt var — kaldığı yerden devam et
      _savedToday   = prefs.getInt(_kSteps) ?? 0;
      _sessionStart = prefs.getInt(_kStart) ?? 0;
      setState(() => _liveSteps = _savedToday);
    } else {
      // Yeni gün — her şeyi sıfırla
      await prefs.setString(_kDate,  today);
      await prefs.setInt(_kSteps, 0);
      await prefs.setInt(_kStart, 0);
      _savedToday   = 0;
      _sessionStart = 0;
    }

    // İzin al ve pedometer'ı başlat
    final actStatus = await Permission.activityRecognition.request();
    final senStatus = await Permission.sensors.request();
    if (actStatus.isGranted || senStatus.isGranted) {
      _startPedometer();
    } else {
      setState(() => _isPedActive = false);
    }
  }

  // ── PEDOMETER BAŞLAT ──────────────────────────────────
  void _startPedometer() {
    _stepSub = Pedometer.stepCountStream.listen(
      (event) async {
        if (!_sessionActive) {
          if (_sessionStart == 0) {
            _sessionStart = event.steps;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt(_kStart, _sessionStart);
          }
          _lastRawSteps  = event.steps;
          _sessionActive = true;
          setState(() => _isPedActive = true);
          return;
        }

        final now      = DateTime.now();
        final rawDelta = event.steps - _lastRawSteps;

        // ── Threshold kontrolleri ──
        // 1. Çok az artış → titreşim/gürültü, yoksay
        if (rawDelta < _minStepDelta) return;

        // 2. Çok hızlı geldi → fiziksel olarak imkânsız, yoksay
        if (_lastStepTime != null) {
          final elapsed = now.difference(_lastStepTime!).inMilliseconds;
          if (elapsed < _minIntervalMs) return;
        }

        // Geçti — gerçek adım olarak kabul et
        _lastRawSteps = event.steps;
        _lastStepTime = now;

        final thisSession = event.steps - _sessionStart;
        final total       = (_savedToday + thisSession).clamp(0, 100000);

        setState(() => _liveSteps = total);
        _stepsController.text = total.toString();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_kSteps, total);
      },
      onError: (_) => setState(() => _isPedActive = false),
    );

    _statusSub = Pedometer.pedestrianStatusStream.listen(
      (event) => setState(() => _isWalking = event.status == 'walking'),
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    _stepsController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  // ── KAYDET / GÜNCELLE ─────────────────────────────────
  Future<void> _save(Map<String, dynamic>? existing) async {
    final stepsText = _stepsController.text.trim();
    if (stepsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adım sayısı zorunludur')));
      return;
    }
    final steps = int.tryParse(stepsText);
    if (steps == null || steps < 0 || steps > 100000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adım 0–100.000 arasında olmalı')));
      return;
    }
    final goalText = _goalController.text.trim();
    if (goalText.isNotEmpty) {
      final goal = int.tryParse(goalText);
      if (goal == null || goal < 1000 || goal > 50000) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hedef 1.000–50.000 arasında olmalı')));
        return;
      }
    }
    setState(() => _isLoading = true);
    try {
      if (existing != null) {
        await ApiClient.instance.put('${Endpoints.steps}/${existing['id']}', data: {
          'step_count': steps,
          'goal': int.tryParse(_goalController.text) ?? 10000,
        });
      } else {
        await ApiClient.instance.post(Endpoints.steps, data: {
          'date':       TFDateUtils.today(),
          'step_count': steps,
          'goal':       int.tryParse(_goalController.text) ?? 10000,
        });
      }
      ref.invalidate(todayStepsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adım kaydedildi ✅')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt sırasında hata oluştu')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // build() metodu tamamen aynı kalıyor — hiçbir şeye dokunmana gerek yok
  @override
  Widget build(BuildContext context) {
    // ... (mevcut build kodu değişmiyor)
    // Buraya mevcut build() metodunu kopyalayıp yapıştır
    final isDark    = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg        = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard    = isDark ? const Color(0xFF141620) : Colors.white;
    final bgSoft    = isDark ? const Color(0xFF0F1016) : const Color(0xFFE8EBF2);
    final border    = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text      = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final textSoft  = isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);
    final muted     = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent    = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim = isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);
    final positive  = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);

    final stepsAsync = ref.watch(todayStepsProvider);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Container(
            color: bg,
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: textSoft),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
                  Text('Adım Sayar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5)),
                ])),
                if (_isPedActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (_isWalking ? positive : accent).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: (_isWalking ? positive : accent).withOpacity(0.4)),
                    ),
                    child: Text(
                      _isWalking ? '🚶 Yürüyor' : '⏸ Durdu',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _isWalking ? positive : accent),
                    ),
                  ),
                const SizedBox(width: 8),
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
          Expanded(
            child: stepsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: accent)),
              error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
              data: (stepsData) {
                final savedSteps = (stepsData?['step_count'] as num?)?.toInt() ?? 0;
                final goal       = (stepsData?['goal']       as num?)?.toInt() ?? 10000;
                if (stepsData != null) _goalController.text = goal.toString();

                final displaySteps = _isPedActive ? _liveSteps : savedSteps;
                final progress     = goal > 0 ? (displaySteps / goal).clamp(0.0, 1.0) : 0.0;
                final distance     = (displaySteps * 0.000762).toStringAsFixed(2);
                final calories     = (displaySteps * 0.04).toInt();

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: border)),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 160, height: 160,
                                  child: CircularProgressIndicator(
                                    value: progress, strokeWidth: 12,
                                    backgroundColor: accent.withOpacity(0.15),
                                    color: progress >= 1.0 ? positive : accent,
                                  ),
                                ),
                                Column(children: [
                                  Text(_isPedActive && _isWalking ? '🚶' : '👟', style: const TextStyle(fontSize: 32)),
                                  CountUpText(
                                    value: displaySteps,
                                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: accent),
                                  ),
                                  Text('adım', style: TextStyle(fontSize: 12, color: muted)),
                                ]),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              progress >= 1.0
                                  ? '🎉 Günlük hedefe ulaştın!'
                                  : 'Hedef: $goal adım — ${((1 - progress) * goal).toInt()} adım kaldı',
                              style: TextStyle(fontSize: 13, color: progress >= 1.0 ? positive : textSoft),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _StatChip('🏃 $distance km', 'Mesafe',  bgSoft, border, text, muted)),
                                const SizedBox(width: 8),
                                Expanded(child: _StatChip('🔥 $calories kcal', 'Kalori', bgSoft, border, text, muted)),
                                const SizedBox(width: 8),
                                Expanded(child: _StatChip('🎯 $goal', 'Hedef', bgSoft, border, text, muted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── v8: Son 7 gün mini grafik ──
                      _WeekStepsCard(
                        bgCard: bgCard, border: border, text: text,
                        muted: muted, accent: accent, goal: goal,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: _isPedActive ? positive.withOpacity(0.08) : bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _isPedActive ? positive.withOpacity(0.3) : border),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          Icon(_isPedActive ? Icons.sensors : Icons.sensors_off, color: _isPedActive ? positive : muted, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isPedActive
                                  ? 'Pedometer aktif — adımların canlı sayılıyor'
                                  : 'Pedometer kapalı — manuel giriş yapabilirsin',
                              style: TextStyle(fontSize: 12, color: _isPedActive ? positive : muted),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stepsData != null ? 'Güncelle' : 'Adım Gir', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                            const SizedBox(height: 6),
                            Text(
                              _isPedActive ? 'Pedometer aktif — adımlar otomatik dolduruluyor' : 'Manuel olarak adım sayısı girebilirsin',
                              style: TextStyle(fontSize: 11, color: muted),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _stepsController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: text),
                              readOnly: _isPedActive,
                              decoration: InputDecoration(
                                labelText: 'Adım sayısı',
                                prefixIcon: const Icon(Icons.directions_walk),
                                suffixIcon: _isPedActive ? Icon(Icons.lock_outline, size: 16, color: muted) : null,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _goalController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: text),
                              decoration: const InputDecoration(labelText: 'Günlük hedef', prefixIcon: Icon(Icons.flag_outlined)),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () => _save(stepsData),
                                child: _isLoading
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                    : Text(stepsData != null ? 'Güncelle' : 'Kaydet'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── v8: Son 7 gün adım grafiği ──────────────────────────
class _WeekStepsCard extends ConsumerWidget {
  final Color bgCard, border, text, muted, accent;
  final int goal;
  const _WeekStepsCard({
    required this.bgCard, required this.border, required this.text,
    required this.muted, required this.accent, required this.goal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(weekStepsProvider);
    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Son 7 Gün',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
          const SizedBox(height: 14),
          weekAsync.when(
            loading: () => const PulseSkeleton(height: 120, width: double.infinity),
            error: (_, __) => SizedBox(
              height: 120,
              child: Center(child: Text('Veri yok', style: TextStyle(color: muted, fontSize: 12))),
            ),
            data: (week) {
              if (week.isEmpty) {
                return SizedBox(
                  height: 120,
                  child: Center(child: Text('Henüz adım kaydın yok',
                      style: TextStyle(color: muted, fontSize: 12))),
                );
              }
              final maxVal = week
                  .map((d) => (d['step_count'] as num?)?.toInt() ?? 0)
                  .fold<int>(goal, (a, b) => a > b ? a : b)
                  .toDouble();
              const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
              return SizedBox(
                height: 130,
                child: BarChart(BarChartData(
                  maxY: maxVal * 1.1,
                  barTouchData: BarTouchData(enabled: true),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= week.length) return const SizedBox.shrink();
                          final dateStr = (week[i]['date'] ?? '').toString();
                          String label = '';
                          try {
                            final d = DateTime.parse(dateStr);
                            label = days[d.weekday - 1];
                          } catch (_) {}
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(label, style: TextStyle(fontSize: 9, color: muted)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(week.length, (i) {
                    final v = (week[i]['step_count'] as num?)?.toInt() ?? 0;
                    final reached = v >= goal;
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: v.toDouble(),
                        width: 16,
                        borderRadius: BorderRadius.circular(6),
                        color: reached ? const Color(0xFF34D399) : accent,
                      ),
                    ]);
                  }),
                )),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value, label;
  final Color bgSoft, border, text, muted;
  const _StatChip(this.value, this.label, this.bgSoft, this.border, this.text, this.muted);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, color: muted)),
      ]),
    );
  }
}