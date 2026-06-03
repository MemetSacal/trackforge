// ── diyet_tab.dart ──────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

final todayMealProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.instance.get('${Endpoints.mealCompliance}/date/${TFDateUtils.today()}');
    return Map<String, dynamic>.from(response.data);
  } catch (_) { return null; }
});

class DiyetTab extends ConsumerStatefulWidget {
  const DiyetTab({super.key});
  @override
  ConsumerState<DiyetTab> createState() => _DiyetTabState();
}

class _DiyetTabState extends ConsumerState<DiyetTab> {
  final _caloriesController = TextEditingController();
  final _targetController   = TextEditingController();
  final _notesController    = TextEditingController();
  bool _complied  = true;
  bool _isLoading = false;
  String? _savedAdvice;
  String? _savedAdviceDate;
  bool _showAdvice = false;
  List<String> _recommendedFoods = [];
  List<String> _avoidFoods = [];

  @override
  void initState() { super.initState(); _loadAdvice(); }

  Future<void> _loadAdvice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedAdvice      = prefs.getString('last_meal_advice');
      _savedAdviceDate  = prefs.getString('last_meal_advice_date');
      _recommendedFoods = prefs.getStringList('last_recommended_foods') ?? [];
      _avoidFoods       = prefs.getStringList('last_foods_to_avoid')    ?? [];
    });
  }

  @override
  void dispose() { _caloriesController.dispose(); _targetController.dispose(); _notesController.dispose(); super.dispose(); }

  Future<void> _save(Map<String, dynamic>? existing) async {
    final calText = _caloriesController.text.trim();
    if (calText.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tüketilen kalori zorunludur'))); return; }
    final cal = double.tryParse(calText);
    if (cal == null || cal < 0 || cal > 10000) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kalori 0–10000 kcal arasında olmalı'))); return; }
    setState(() => _isLoading = true);
    try {
      final tgt = double.tryParse(_targetController.text);
      if (existing != null) {
        await ApiClient.instance.put('${Endpoints.mealCompliance}/${existing['id']}', data: {
          'complied': _complied, 'calories_consumed': cal, 'calories_target': tgt,
          'notes': _notesController.text.isEmpty ? null : _notesController.text,
        });
      } else {
        await ApiClient.instance.post(Endpoints.mealCompliance, data: {
          'date': TFDateUtils.today(), 'complied': _complied,
          'calories_consumed': cal, 'calories_target': tgt,
          'notes': _notesController.text.isEmpty ? null : _notesController.text,
        });
      }
      _caloriesController.clear(); _notesController.clear();
      ref.invalidate(todayMealProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diyet logu kaydedildi ✅')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt sırasında hata oluştu')));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bgCard   = isDark ? const Color(0xFF141620) : Colors.white;
    final bgSoft   = isDark ? const Color(0xFF0F1016) : const Color(0xFFE8EBF2);
    final border   = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text     = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final textSoft = isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);
    final muted    = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent   = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim= isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);
    final positive = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
    final danger   = isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);

    final mealAsync = ref.watch(todayMealProvider);

    return mealAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: accent)),
      error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
      data: (mealLog) {
        if (mealLog != null) {
          final consumed = (mealLog['calories_consumed'] as num?)?.toDouble();
          final target   = (mealLog['calories_target']   as num?)?.toDouble();
          if (consumed != null) _caloriesController.text = consumed.toInt().toString();
          if (target   != null) _targetController.text   = target.toInt().toString();
          _complied = mealLog['complied'] as bool? ?? true;
        }

        final consumed    = (mealLog?['calories_consumed']    as num?)?.toDouble() ?? 0;
        final target      = (mealLog?['calories_target']      as num?)?.toDouble() ?? 0;
        final balance     = (mealLog?['calorie_balance']      as num?)?.toDouble() ?? 0;
        final bankBalance = (mealLog?['weekly_bank_balance']  as num?)?.toDouble() ?? 0;
        final progress    = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── KALORİ BANKASI ────────────────────────
              if (mealLog != null) ...[
                Container(
                  decoration: BoxDecoration(
                    color: accentDim,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💳 Kalori Bankası', style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '${balance <= 0 ? "+" : ""}${(-balance).toInt()} kcal',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: accent),
                      ),
                      Text('TDEE: ${target.toInt()} kcal', style: TextStyle(fontSize: 12, color: textSoft)),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: accent.withOpacity(0.15),
                          color: progress > 1.0 ? danger : accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${consumed.toInt()} kcal tüketildi', style: TextStyle(fontSize: 11, color: textSoft)),
                          Text('%${(progress * 100).toInt()}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Makro özeti
                Container(
                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Makro Özeti', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                        Text('Detay', style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 12),
                      ...[
                        ['Günlük Fark',    '${balance > 0 ? "+" : ""}${balance.toInt()} kcal', balance <= 0],
                        ['Haftalık Banka', '${bankBalance > 0 ? "+" : ""}${bankBalance.toInt()} kcal', bankBalance >= 0],
                        ['Diyet Uyumu',    _complied ? '✔ uyuldu' : '✖ uyulmadı', _complied],
                      ].map((row) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(row[0] as String, style: TextStyle(fontSize: 13, color: text)),
                            Text(row[1] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                              color: (row[2] as bool) ? positive : danger)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── AI DİYET PLANI ────────────────────────
              if (_savedAdvice != null) ...[
                GestureDetector(
                  onTap: () => setState(() => _showAdvice = !_showAdvice),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        const Text('🥗', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Diyet Planım', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: text)),
                            if (_savedAdviceDate != null)
                              Text(_savedAdviceDate!, style: TextStyle(fontSize: 11, color: muted)),
                          ],
                        )),
                        Icon(_showAdvice ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: accent),
                      ],
                    ),
                  ),
                ),
                if (_showAdvice) ...[
                  const SizedBox(height: 8),
                  // Markdown özet
                  Container(
                    decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                    padding: const EdgeInsets.all(16),
                    child: MarkdownBody(
                      data: _savedAdvice!,
                      styleSheet: MarkdownStyleSheet(
                        p:      TextStyle(fontSize: 13, color: text, height: 1.6),
                        h2:     TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: accent),
                        h3:     TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: accent),
                        strong: TextStyle(fontWeight: FontWeight.w700, color: text),
                        listBullet: TextStyle(fontSize: 13, color: text),
                      ),
                      selectable: true,
                    ),
                  ),
                  // Önerilen besinler grid
                  if (_recommendedFoods.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('✅ Önerilen Besinler', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: text)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6, runSpacing: 6,
                            children: _recommendedFoods.map((f) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: accent.withOpacity(0.4)),
                              ),
                              child: Text(f, style: TextStyle(fontSize: 12, color: text, fontWeight: FontWeight.w500)),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Kaçınılacak besinler grid
                  if (_avoidFoods.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('❌ Kaçınılacak Besinler', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: text)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6, runSpacing: 6,
                            children: _avoidFoods.map((f) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: danger.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: danger.withOpacity(0.4)),
                              ),
                              child: Text(f, style: TextStyle(fontSize: 12, color: text, fontWeight: FontWeight.w500)),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 12),
              ],
              // ── FORM ──────────────────────────────────
              Container(
                decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mealLog != null ? 'Güncelle' : 'Bugünkü Öğünü Kaydet',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _caloriesController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: text),
                      decoration: const InputDecoration(labelText: 'Tüketilen Kalori (kcal)', prefixIcon: Icon(Icons.local_fire_department_outlined)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _targetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: text),
                      decoration: const InputDecoration(labelText: 'Hedef Kalori (kcal)', prefixIcon: Icon(Icons.flag_outlined)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                      child: Row(
                        children: [
                          Text('Diyete uyuldu mu?', style: TextStyle(fontSize: 13, color: text)),
                          const Spacer(),
                          Switch(value: _complied, activeColor: accent, onChanged: (v) => setState(() => _complied = v)),
                          Text(_complied ? '✅' : '❌'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
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
                        onPressed: _isLoading ? null : () => _save(mealLog),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : Text(mealLog != null ? 'Güncelle' : '+ Yemek Ekle'),
                      ),
                    ),
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