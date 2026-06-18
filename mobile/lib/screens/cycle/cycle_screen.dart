// ── cycle_screen.dart ────────────────────────────────────
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';
import '../../app.dart';

// ── PROVIDER ────────────────────────────────────────────
final cycleProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.cycle);
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return null;
  }
});

// ── CYCLE SCREEN ────────────────────────────────────────
class CycleScreen extends ConsumerStatefulWidget {
  const CycleScreen({super.key});

  @override
  ConsumerState<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends ConsumerState<CycleScreen> {
  final _cycleLengthController  = TextEditingController(text: '28');
  final _periodLengthController = TextEditingController(text: '5');
  final _notesController        = TextEditingController();
  bool _isLoading    = false;
  bool _showForm     = false;
  bool _aiLoading    = false;
  String? _aiError;
  Map<String, dynamic>? _aiAdvice;
  bool _showAiAdvice = false;

  @override
  void dispose() {
    _cycleLengthController.dispose();
    _periodLengthController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Faz rengi ─────────────────────────────────────────
  Color _phaseColor(String phase, Color accent) {
    if (phase.contains('Menstrü') || phase.toLowerCase().contains('menstrual')) return const Color(0xFFEF4444);
    if (phase.contains('Foliküler') || phase.toLowerCase().contains('follicular')) return const Color(0xFF22C55E);
    if (phase.contains('Ovülasyon') || phase.toLowerCase().contains('ovulation')) return accent;
    if (phase.contains('Luteal') || phase.toLowerCase().contains('luteal')) return const Color(0xFFA855F7);
    return const Color(0xFFEC4899);
  }

  String _phaseEmoji(String phase) {
    if (phase.contains('Menstrü') || phase.toLowerCase().contains('menstrual')) return '🔴';
    if (phase.contains('Foliküler') || phase.toLowerCase().contains('follicular')) return '🌱';
    if (phase.contains('Ovülasyon') || phase.toLowerCase().contains('ovulation')) return '🌟';
    if (phase.contains('Luteal') || phase.toLowerCase().contains('luteal')) return '🌙';
    return '🌸';
  }

  String? _validate() {
    final cycleLength  = int.tryParse(_cycleLengthController.text);
    final periodLength = int.tryParse(_periodLengthController.text);
    if (cycleLength == null || cycleLength < 20 || cycleLength > 45)
      return 'Döngü uzunluğu 20–45 gün arasında olmalı';
    if (periodLength == null || periodLength < 2 || periodLength > 10)
      return 'Adet süresi 2–10 gün arasında olmalı';
    return null;
  }

  Future<void> _saveCycle(Map<String, dynamic>? existing) async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = {
        'cycle_start_date':   TFDateUtils.today(),
        'cycle_length_days':  int.parse(_cycleLengthController.text),
        'period_length_days': int.parse(_periodLengthController.text),
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      };
      if (existing != null) {
        await ApiClient.instance.put('${Endpoints.cycle}/${existing['id']}', data: data);
      } else {
        await ApiClient.instance.post(Endpoints.cycle, data: data);
      }
      setState(() => _showForm = false);
      ref.invalidate(cycleProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Döngü kaydedildi ✅')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt sırasında hata oluştu')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── AI Tavsiye Al ─────────────────────────────────────
  Future<void> _getAiAdvice() async {
    setState(() { _aiLoading = true; _aiError = null; _aiAdvice = null; });
    try {
      final response = await ApiClient.instance.post(Endpoints.aiCycleAdvice);
      setState(() {
        _aiAdvice    = Map<String, dynamic>.from(response.data);
        _showAiAdvice = true;
      });
    } on DioException catch (e) {
      // v2: cycle-advice artık kotalı — kota mesajını aynen göster
      final q = QuotaException.fromDioError(e);
      setState(() => _aiError = q?.message ?? 'AI tavsiyesi alınamadı. Lütfen tekrar deneyin.');
    } catch (_) {
      setState(() => _aiError = 'AI tavsiyesi alınamadı. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
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

    final cycleAsync = ref.watch(cycleProvider);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── HEADER ──────────────────────────────────
          Container(
            color: bg,
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
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
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
                      Text('Regl Takvimi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5)),
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
          const SizedBox(height: 12),

          // ── İÇERİK ──────────────────────────────────
          Expanded(
            child: cycleAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: accent)),
              error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
              data: (cycle) {
                if (cycle != null && !_showForm) {
                  _cycleLengthController.text  = (cycle['cycle_length_days']  as num?)?.toString() ?? '28';
                  _periodLengthController.text = (cycle['period_length_days'] as num?)?.toString() ?? '5';
                  _notesController.text        =  cycle['notes'] as String? ?? '';
                }

                final phase       = cycle?['current_phase']     as String? ?? '';
                final currentDay  = (cycle?['current_day']      as num?)?.toInt() ?? 0;
                final cycleLength = (cycle?['cycle_length_days'] as num?)?.toInt() ?? 28;
                final progress    = cycleLength > 0 ? (currentDay / cycleLength).clamp(0.0, 1.0) : 0.0;
                final phaseColor  = _phaseColor(phase, accent);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── MEVCUT FAZ KARTI ────────────
                      if (cycle != null && phase.isNotEmpty) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: phaseColor.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 56, height: 56,
                                    decoration: BoxDecoration(
                                      color: phaseColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Center(child: Text(_phaseEmoji(phase), style: const TextStyle(fontSize: 28))),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(phase, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: phaseColor)),
                                        const SizedBox(height: 2),
                                        Text('Gün $currentDay / $cycleLength', style: TextStyle(fontSize: 12, color: muted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: phaseColor.withOpacity(0.15),
                                  color: phaseColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── FAZ TAKVİMİ ─────────────────
                        Container(
                          decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Döngü Fazları', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                              const SizedBox(height: 12),
                              _phaseRow('🔴', 'Menstrüasyon',  'Gün 1–5',    const Color(0xFFEF4444), bgSoft, border, text, muted),
                              _phaseRow('🌱', 'Foliküler',     'Gün 6–13',   const Color(0xFF22C55E), bgSoft, border, text, muted),
                              _phaseRow('🌟', 'Ovülasyon',     'Gün 14–16',  accent,                  bgSoft, border, text, muted),
                              _phaseRow('🌙', 'Luteal',        'Gün 17–28',  const Color(0xFFA855F7), bgSoft, border, text, muted),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── AI TAVSİYE BUTONU ───────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _aiLoading ? null : _getAiAdvice,
                            icon: _aiLoading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Text('✨', style: TextStyle(fontSize: 18)),
                            label: Text(
                              _aiLoading ? 'AI tavsiyesi hazırlanıyor...' : 'AI\'dan Faz Tavsiyesi Al',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── AI HATA ─────────────────────
                        if (_aiError != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: danger.withOpacity(0.3)),
                            ),
                            child: Row(children: [
                              Icon(Icons.error_outline, color: danger, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_aiError!, style: TextStyle(fontSize: 13, color: danger))),
                            ]),
                          ),

                        // ── AI TAVSİYE SONUCU ───────────
                        if (_aiAdvice != null && _showAiAdvice) ...[
                          _buildAiAdviceCard(_aiAdvice!, bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim, danger, phaseColor),
                          const SizedBox(height: 12),
                        ],
                      ],

                      // ── GÜNCELLE BUTONU ─────────────
                      GestureDetector(
                        onTap: () => setState(() => _showForm = !_showForm),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _showForm ? accent : border),
                          ),
                          child: Row(
                            children: [
                              Icon(_showForm ? Icons.close : (cycle != null ? Icons.edit_outlined : Icons.add), color: accent, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                _showForm ? 'İptal' : (cycle != null ? 'Döngüyü Güncelle' : 'Döngü Başlat'),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: accent),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── FORM ──────────────────────────
                      if (_showForm) ...[
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cycle != null ? 'Döngüyü Güncelle' : 'Yeni Döngü Başlat',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _cycleLengthController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: text),
                                decoration: const InputDecoration(labelText: 'Döngü uzunluğu (gün) — 20–45', prefixIcon: Icon(Icons.loop)),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _periodLengthController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: text),
                                decoration: const InputDecoration(labelText: 'Adet süresi (gün) — 2–10', prefixIcon: Icon(Icons.calendar_today)),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _notesController,
                                maxLines: 2,
                                style: TextStyle(color: text),
                                decoration: const InputDecoration(labelText: 'Not (opsiyonel)', prefixIcon: Icon(Icons.note_outlined)),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () => _saveCycle(cycle),
                                  child: _isLoading
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                      : Text(cycle != null ? 'Güncelle' : 'Kaydet'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── BOŞ DURUM ─────────────────────
                      if (cycle == null && !_showForm) ...[
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: [
                              const Text('🌸', style: TextStyle(fontSize: 64)),
                              const SizedBox(height: 16),
                              Text('Henüz döngü kaydı yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text)),
                              const SizedBox(height: 8),
                              Text('Döngü Başlat butonuna tıkla', style: TextStyle(fontSize: 13, color: muted)),
                            ],
                          ),
                        ),
                      ],
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

  // ── AI Tavsiye Kartı ──────────────────────────────────
  Widget _buildAiAdviceCard(
    Map<String, dynamic> advice,
    Color bgCard, Color bgSoft, Color border, Color text, Color textSoft,
    Color muted, Color accent, Color accentDim, Color danger, Color phaseColor,
  ) {
    final dietAdvice    = advice['diet_advice']    as Map<String, dynamic>? ?? {};
    final workoutAdvice = advice['workout_advice'] as Map<String, dynamic>? ?? {};
    final wellnessTips  = (advice['wellness_tips'] as List?)?.cast<String>() ?? [];
    final energyLevel   =  advice['energy_level']  as String? ?? '';
    final phaseSummary  =  advice['phase_summary'] as String? ?? '';

    final focusNutrients  = (dietAdvice['focus_nutrients']   as List?)?.cast<String>() ?? [];
    final recommendedFoods= (dietAdvice['recommended_foods'] as List?)?.cast<String>() ?? [];
    final foodsToLimit    = (dietAdvice['foods_to_limit']    as List?)?.cast<String>() ?? [];
    final mealTip         =  dietAdvice['meal_tip']          as String? ?? '';
    final calorieAdj      =  dietAdvice['calorie_adjustment'] as String? ?? '';

    final workoutTypes    = (workoutAdvice['recommended_types'] as List?)?.cast<String>() ?? [];
    final intensity       =  workoutAdvice['intensity']          as String? ?? '';
    final duration        = (workoutAdvice['duration_minutes']   as num?)?.toInt() ?? 30;
    final workoutTip      =  workoutAdvice['workout_tip']        as String? ?? '';
    final avoidExercises  = (workoutAdvice['avoid']              as List?)?.cast<String>() ?? [];

    final energyColors = {'düşük': danger, 'orta': accent, 'yüksek': const Color(0xFF22C55E)};
    final energyColor  = energyColors[energyLevel.toLowerCase()] ?? accent;

    return Column(
      children: [
        // Özet kart
        Container(
          decoration: BoxDecoration(
            color: phaseColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: phaseColor.withOpacity(0.25)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('✨ AI Faz Tavsiyesi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: energyColor.withOpacity(0.15), borderRadius: BorderRadius.circular(99)),
                    child: Text('Enerji: $energyLevel', style: TextStyle(fontSize: 11, color: energyColor, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(phaseSummary, style: TextStyle(fontSize: 13, color: textSoft, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Diyet kartı
        Container(
          decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🥗 Beslenme Önerileri', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
              const SizedBox(height: 12),

              if (focusNutrients.isNotEmpty) ...[
                Text('Odak Besinler', style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: focusNutrients.map((n) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(99), border: Border.all(color: accent.withOpacity(0.4))),
                    child: Text(n, style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
                const SizedBox(height: 12),
              ],

              if (recommendedFoods.isNotEmpty) ...[
                Text('Önerilen Yiyecekler', style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: recommendedFoods.map((f) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(99), border: Border.all(color: border)),
                    child: Text(f, style: TextStyle(fontSize: 12, color: text)),
                  )).toList(),
                ),
                const SizedBox(height: 12),
              ],

              if (foodsToLimit.isNotEmpty) ...[
                Text('Kısıtlanacaklar', style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: foodsToLimit.map((f) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: danger.withOpacity(0.08), borderRadius: BorderRadius.circular(99), border: Border.all(color: danger.withOpacity(0.3))),
                    child: Text(f, style: TextStyle(fontSize: 12, color: danger)),
                  )).toList(),
                ),
                const SizedBox(height: 12),
              ],

              if (calorieAdj.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                  child: Row(children: [
                    Icon(Icons.local_fire_department_outlined, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Kalori: $calorieAdj', style: TextStyle(fontSize: 12, color: text))),
                  ]),
                ),
                const SizedBox(height: 8),
              ],

              if (mealTip.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(12)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(mealTip, style: TextStyle(fontSize: 12, color: text, height: 1.5))),
                  ]),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Antrenman kartı
        Container(
          decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🏃 Antrenman Önerileri', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
              const SizedBox(height: 12),

              Row(children: [
                _statChip('Yoğunluk', intensity, bgSoft, border, text, muted),
                const SizedBox(width: 8),
                _statChip('Süre', '$duration dk', bgSoft, border, text, muted),
              ]),
              const SizedBox(height: 10),

              if (workoutTypes.isNotEmpty) ...[
                Text('Önerilen Egzersizler', style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: workoutTypes.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(99), border: Border.all(color: border)),
                    child: Text(t, style: TextStyle(fontSize: 12, color: text)),
                  )).toList(),
                ),
                const SizedBox(height: 10),
              ],

              if (avoidExercises.isNotEmpty) ...[
                Text('Kaçınılacaklar', style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: avoidExercises.map((e) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: danger.withOpacity(0.08), borderRadius: BorderRadius.circular(99), border: Border.all(color: danger.withOpacity(0.3))),
                    child: Text(e, style: TextStyle(fontSize: 12, color: danger)),
                  )).toList(),
                ),
                const SizedBox(height: 10),
              ],

              if (workoutTip.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(12)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(workoutTip, style: TextStyle(fontSize: 12, color: text, height: 1.5))),
                  ]),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Wellness tips
        if (wellnessTips.isNotEmpty)
          Container(
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🌸 Genel Tavsiyeler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                const SizedBox(height: 10),
                ...wellnessTips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('•', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tip, style: TextStyle(fontSize: 13, color: textSoft, height: 1.5))),
                  ]),
                )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _statChip(String label, String value, Color bgSoft, Color border, Color text, Color muted) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
        child: Column(children: [
          Text(label, style: TextStyle(fontSize: 10, color: muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, color: text, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _phaseRow(String emoji, String phase, String days, Color color, Color bgSoft, Color border, Color text, Color muted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(phase, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: text))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(days, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}