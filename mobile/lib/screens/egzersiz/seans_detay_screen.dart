// ── seans_detay_screen.dart ─────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../app.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/body_map/body_map_widget.dart';

final sessionExercisesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, sessionId) async {
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

  @override
  void dispose() {
    _nameController.dispose(); _setsController.dispose();
    _repsController.dispose(); _weightController.dispose();
    super.dispose();
  }

  String get _sessionId => widget.session['id'] as String;

  Future<void> _addExercise(BuildContext ctx) async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Egzersiz adını girin')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiClient.instance.post('${Endpoints.exerciseSessions}/$_sessionId/exercises', data: {
        'exercise_name': _nameController.text.trim(),
        'sets':       int.tryParse(_setsController.text),
        'reps':       int.tryParse(_repsController.text),
        'weight_kg':  double.tryParse(_weightController.text),
      });
      _nameController.clear(); _setsController.clear();
      _repsController.clear(); _weightController.clear();
      ref.invalidate(sessionExercisesProvider(_sessionId));
      if (mounted) Navigator.pop(ctx);
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
            Row(
              children: [
                Expanded(child: TextField(controller: _setsController,   keyboardType: TextInputType.number, style: TextStyle(color: text), decoration: const InputDecoration(labelText: 'Set'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _repsController,   keyboardType: TextInputType.number, style: TextStyle(color: text), decoration: const InputDecoration(labelText: 'Tekrar'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _weightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(color: text), decoration: const InputDecoration(labelText: 'Kg'))),
              ],
            ),
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
    final danger   = isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);

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
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: textSoft),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
                      Text(
                        '$duration dk · $date${calories != null ? ' · $calories kcal' : ''}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.3),
                      ),
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

          // ── İÇERİK ──────────────────────────────────
          Expanded(
            child: exercisesAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: accent)),
              error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
              data: (exercises) {
                final allMuscles = exercises
                    .expand((e) => getMusclesForExercise(e['exercise_name'] as String? ?? ''))
                    .toSet().toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [

                    // Vücut haritası
                    if (allMuscles.isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Çalışan Kaslar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                            const SizedBox(height: 12),
                            BodyMapWidget(highlightedMuscles: allMuscles, height: 260),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Boş durum
                    if (exercises.isEmpty)
                      Container(
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Text('💪', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('Henüz egzersiz yok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
                            const SizedBox(height: 4),
                            Text('Aşağıdan ekle', style: TextStyle(fontSize: 12, color: muted)),
                          ],
                        ),
                      ),

                    // Egzersiz kartları
                    ...exercises.asMap().entries.map((e) {
                      final ex     = e.value;
                      final name   = ex['exercise_name'] as String? ?? '';
                      final sets   = ex['sets']      as int?;
                      final reps   = ex['reps']      as int?;
                      final weight = (ex['weight_kg'] as num?)?.toDouble();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text('${e.key + 1}', style: TextStyle(fontWeight: FontWeight.w800, color: accent))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                                  const SizedBox(height: 2),
                                  Text(
                                    [if (sets != null) '$sets set', if (reps != null) '$reps tekrar', if (weight != null) '$weight kg'].join(' · '),
                                    style: TextStyle(fontSize: 11, color: muted),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _openYouTube(name),
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: const Color(0x1AFF0000), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.play_circle_outline, size: 18, color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _deleteExercise(ex['id'] as String),
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

                    // Egzersiz ekle butonu
                    GestureDetector(
                      onTap: () => _showAddSheet(context, bgCard, border, text, accent),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: accentDim,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accent),
                        ),
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