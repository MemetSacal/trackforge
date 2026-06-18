// ── seans_detay_screen.dart ─────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../app.dart';
import 'package:url_launcher/url_launcher.dart';
import 'egzersiz_screen.dart';

final sessionExercisesProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, sessionId) async {
  try {
    final response = await ApiClient.instance.get('${Endpoints.exerciseSessions}/$sessionId/exercises');
    final list = response.data as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) { return []; }
});

class SeansDetayScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> session;
  const SeansDetayScreen({super.key, required this.session});
  @override
  ConsumerState<SeansDetayScreen> createState() => _SeansDetayScreenState();
}

class _SeansDetayScreenState extends ConsumerState<SeansDetayScreen> {
  final _nameController   = TextEditingController();
  final _setsController   = TextEditingController();
  final _repsController   = TextEditingController();
  final _weightController = TextEditingController();
  bool _isLoading = false;

  // Lokal tamamlama state'i — API'ye gitmeden önce anlık UI güncellemesi
  final Map<String, bool> _completedState = {};

  @override
  void dispose() {
    _nameController.dispose(); _setsController.dispose();
    _repsController.dispose(); _weightController.dispose();
    super.dispose();
  }

  String get _sessionId => widget.session['id'] as String;

  // Egzersiz tamamlandı toggle
  // v8: tamamlama anında dokunsal geri bildirim
  Future<void> _toggleCompleted(String exerciseId, bool current) async {
    final newVal = !current;
    setState(() => _completedState[exerciseId] = newVal);
    // v8: işaretleme anında dokunsal his — premium uygulamaların gizli imzası
    if (newVal) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    try {
      await ApiClient.instance.put(
        '${Endpoints.exerciseSessions.replaceAll('/sessions', '')}/exercises/$exerciseId',
        data: {'completed': newVal},
      );
      ref.invalidate(sessionExercisesProvider(_sessionId));
    } catch (_) {
      // Hata olursa geri al
      setState(() => _completedState[exerciseId] = current);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Güncellenemedi')));
    }
  }

  Future<void> _addExercise(BuildContext ctx) async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Egzersiz adını girin')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiClient.instance.post('${Endpoints.exerciseSessions}/$_sessionId/exercises', data: {
        'exercise_name': _nameController.text.trim(),
        'sets':      int.tryParse(_setsController.text),
        'reps':      int.tryParse(_repsController.text),
        'weight_kg': double.tryParse(_weightController.text),
      });
      _nameController.clear(); _setsController.clear();
      _repsController.clear(); _weightController.clear();
      if (mounted) Navigator.pop(ctx);
      ref.invalidate(sessionExercisesProvider(_sessionId));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Egzersiz eklenirken hata oluştu')));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _openYouTube(String name) async {
    final q   = Uri.encodeComponent('$name nasıl yapılır');
    final url = Uri.parse('https://www.youtube.com/results?search_query=$q');
    try { await launchUrl(url, mode: LaunchMode.externalApplication); }
    catch (_) { await launchUrl(url, mode: LaunchMode.inAppWebView); }
  }

  Future<void> _deleteExercise(String id) async {
    try {
      await ApiClient.instance.delete('/exercises/exercises/$id');
      _completedState.remove(id);
      ref.invalidate(sessionExercisesProvider(_sessionId));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silme sırasında hata oluştu')));
    }
  }

  void _showAddSheet(BuildContext context, Color bgCard, Color border, Color text, Color accent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 20),
            Text('Egzersiz Ekle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text)),
            const SizedBox(height: 16),
            TextField(controller: _nameController, style: TextStyle(color: text),
              decoration: const InputDecoration(labelText: 'Egzersiz Adı *', prefixIcon: Icon(Icons.fitness_center), hintText: 'Bench Press, Squat...')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _setsController,   keyboardType: TextInputType.number, style: TextStyle(color: text), decoration: const InputDecoration(labelText: 'Set'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _repsController,   keyboardType: TextInputType.number, style: TextStyle(color: text), decoration: const InputDecoration(labelText: 'Tekrar'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _weightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(color: text), decoration: const InputDecoration(labelText: 'Kg'))),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _addExercise(ctx),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
    final danger    = isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);

    final exercisesAsync = ref.watch(sessionExercisesProvider(_sessionId));
    final duration = widget.session['duration_minutes'] as int? ?? 0;
    final date     = widget.session['date'] as String? ?? '';
    final calories = (widget.session['calories_burned'] as num?)?.toInt();

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── HEADER ──────────────────────────────────
          Container(
            color: bg,
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: textSoft)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
                    Text('$duration dk · $date${calories != null ? ' · $calories kcal' : ''}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.3)),
                  ]),
                ),
                GestureDetector(
                  onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                  child: Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                    child: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round, size: 15, color: textSoft)),
                ),
              ],
            ),
          ),

          // ── İÇERİK ──────────────────────────────────
          Expanded(
            child: exercisesAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: accent)),
              error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
              data: (exercises) {
                // Lokal state'i başlat
                for (final ex in exercises) {
                  final id = ex['id'] as String;
                  _completedState.putIfAbsent(id, () => ex['completed'] as bool? ?? false);
                }

                // Tamamlama istatistikleri
                final total     = exercises.length;
                final completed = exercises.where((ex) {
                  final id = ex['id'] as String;
                  return _completedState[id] ?? (ex['completed'] as bool? ?? false);
                }).length;
                final progress  = total > 0 ? completed / total : 0.0;
                final isAllDone = total > 0 && completed == total;

                // Kas grubu dağılımı
                final muscleCounts = extractMuscleGroups(exercises);
                final sorted = muscleCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final totalCount = sorted.fold(0, (s, e) => s + e.value);

                const barColors = [
                  Color(0xFFFFB020), Color(0xFF22D3EE), Color(0xFF34D399),
                  Color(0xFFA78BFA), Color(0xFFFF5555), Color(0xFFFF6B2B),
                  Color(0xFFF472B6), Color(0xFF60A5FA),
                ];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [

                    // ── TAMAMLANMA PROGRESS KARTI ──────
                    if (total > 0) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: isAllDone ? positive.withOpacity(0.12) : accentDim,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isAllDone ? positive : accent),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isAllDone ? '🏆 Antrenman Tamamlandı!' : '💪 Antrenman İlerlemesi',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                    color: isAllDone ? positive : accent),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isAllDone ? positive : accent).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    '$completed/$total',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                                      color: isAllDone ? positive : accent),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: (isAllDone ? positive : accent).withOpacity(0.15),
                                color: isAllDone ? positive : accent,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isAllDone
                                  ? 'Tüm egzersizleri tamamladın, harika iş!'
                                  : '%${(progress * 100).toInt()} tamamlandı · ${total - completed} egzersiz kaldı',
                              style: TextStyle(fontSize: 11, color: isAllDone ? positive : textSoft),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Kas grubu grafiği ──────────────
                    if (sorted.isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bu Antrenman Çalışan Kaslar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                            Text('egzersiz sayısına göre', style: TextStyle(fontSize: 11, color: muted)),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 160,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: (sorted.first.value * 1.4).toDouble(),
                                  barTouchData: BarTouchData(enabled: false),
                                  titlesData: FlTitlesData(
                                    leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, meta) {
                                          final i = val.toInt();
                                          if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                                          final label = sorted[i].key;
                                          final short = label.length > 5 ? label.substring(0, 5) : label;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(short, style: TextStyle(fontSize: 9, color: muted)),
                                          );
                                        },
                                        reservedSize: 22,
                                      ),
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    getDrawingHorizontalLine: (_) => FlLine(color: border, strokeWidth: 1),
                                    drawVerticalLine: false,
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: sorted.asMap().entries.map((e) {
                                    final color = barColors[e.key % barColors.length];
                                    return BarChartGroupData(
                                      x: e.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: e.value.value.toDouble(),
                                          color: color,
                                          width: 20,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ...sorted.asMap().entries.map((e) {
                              final color  = barColors[e.key % barColors.length];
                              final muscle = e.value.key;
                              final count  = e.value.value;
                              final pct    = totalCount > 0 ? count / totalCount : 0.0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(children: [
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(muscle, style: TextStyle(fontSize: 12, color: text, fontWeight: FontWeight.w600))),
                                  Text('%${(pct * 100).toInt()}', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
                                ]),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Boş durum ──────────────────────
                    if (exercises.isEmpty)
                      Container(
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(children: [
                          const Text('💪', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text('Henüz egzersiz yok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
                          const SizedBox(height: 4),
                          Text('Aşağıdan ekle', style: TextStyle(fontSize: 12, color: muted)),
                        ]),
                      ),

                    // ── Egzersiz kartları ──────────────
                    ...exercises.asMap().entries.map((e) {
                      final ex       = e.value;
                      final id       = ex['id'] as String;
                      final name     = ex['exercise_name'] as String? ?? '';
                      final sets     = ex['sets']      as int?;
                      final reps     = ex['reps']      as int?;
                      final weight   = (ex['weight_kg'] as num?)?.toDouble();
                      final isDone   = _completedState[id] ?? (ex['completed'] as bool? ?? false);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isDone ? positive.withOpacity(0.07) : bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDone ? positive.withOpacity(0.4) : border),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Tamamlama checkbox
                            GestureDetector(
                              onTap: () => _toggleCompleted(id, isDone),
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: isDone ? positive.withOpacity(0.15) : accentDim,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDone ? positive : accent),
                                ),
                                child: Center(
                                  child: isDone
                                      ? Icon(Icons.check_rounded, size: 20, color: positive)
                                      : Text('${e.key + 1}', style: TextStyle(fontWeight: FontWeight.w800, color: accent)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDone ? positive : text,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                    decorationColor: positive,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [if (sets != null) '$sets set', if (reps != null) '$reps tekrar', if (weight != null) '$weight kg'].join(' · '),
                                  style: TextStyle(fontSize: 11, color: muted),
                                ),
                              ]),
                            ),
                            GestureDetector(
                              onTap: () => _openYouTube(name),
                              child: Container(
                                width: 32, height: 32,
                                decoration: const BoxDecoration(color: Color(0x1AFF0000), borderRadius: BorderRadius.all(Radius.circular(8))),
                                child: const Icon(Icons.play_circle_outline, size: 18, color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _deleteExercise(id),
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.delete_outline, size: 18, color: danger),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 12),
                    // ── v4: Plan kilidi ──
                    // AI planından gelen seansa elle egzersiz eklenmez:
                    // plan hacim/denge bütünlüğünü korur, compliance temiz ölçülür.
                    // Ekstra çalışmak isteyen serbest seans açar — o da AI'a
                    // "kullanıcı plan dışı şunu yapıyor" sinyali olarak gider.
                    if ((widget.session['source'] as String? ?? 'manual') == 'ai_plan')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                        child: Column(children: [
                          Row(children: [
                            const Text('🔒', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              'Bu seans AI koçunun planı — bütünlüğü korumak için kilitli.',
                              style: TextStyle(fontSize: 12, color: muted, height: 1.4),
                            )),
                          ]),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () async {
                              // Bugüne serbest seans aç ve detayına git
                              try {
                                final res = await ApiClient.instance.post(Endpoints.exerciseSessions, data: {
                                  'date': widget.session['date'],
                                  'notes': 'Serbest seans',
                                  'source': 'manual',
                                });
                                if (context.mounted) {
                                  Navigator.pushReplacement(context, MaterialPageRoute(
                                    builder: (_) => SeansDetayScreen(session: Map<String, dynamic>.from(res.data)),
                                  ));
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Serbest seans açılamadı')));
                                }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(14), border: Border.all(color: accent)),
                              child: Center(child: Text('💪 Ekstra mı çalışacaksın? Serbest seans aç',
                                  style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 13))),
                            ),
                          ),
                        ]),
                      )
                    else
                      GestureDetector(
                        onTap: () => _showAddSheet(context, bgCard, border, text, accent),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(16), border: Border.all(color: accent)),
                          child: Center(child: Text('+ Egzersiz Ekle', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 14))),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}