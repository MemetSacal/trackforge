// ── meal_advice_screen.dart ─────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';
import '../../app.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'ai_helpers.dart';

class MealAdviceScreen extends ConsumerStatefulWidget {
  const MealAdviceScreen({super.key});
  @override
  ConsumerState<MealAdviceScreen> createState() => _MealAdviceScreenState();
}

class _MealAdviceScreenState extends ConsumerState<MealAdviceScreen> {
  String _goal = 'weight_loss';
  int _mealsPerDay = 3;
  Map<String, dynamic>? _rawData; // ham JSON
  bool _isLoading = false;
  String? _error;

  final _goals = [
    {'key': 'weight_loss', 'label': '⚡ Kilo Vermek'},
    {'key': 'muscle_gain', 'label': '💪 Kas Kazanmak'},
    {'key': 'maintenance', 'label': '⚖️ Kiloyu Korumak'},
    {'key': 'health',      'label': '🥗 Sağlıklı Beslenmek'},
  ];

  final _mealLabels = {
    'breakfast': '🌅 Kahvaltı',
    'lunch':     '☀️ Öğle',
    'dinner':    '🌙 Akşam',
    'snack':     '🍎 Ara Öğün',
  };

  final _macroLabels = {
    'protein_g': 'Protein',
    'carbs_g':   'Karbonhidrat',
    'fat_g':     'Yağ',
  };

  Future<void> _getAdvice() async {
    setState(() { _isLoading = true; _error = null; _rawData = null; });
    try {
      final response = await ApiClient.instance.post(Endpoints.aiMealAdvice, data: {
        'calorie_target': _goal == 'weight_loss' ? 1500
            : _goal == 'muscle_gain' ? 2500
            : _goal == 'maintenance' ? 2000 : 1800,
      });
      final data = Map<String, dynamic>.from(response.data);
      // Listeleri mutable kopyaya al (kullanıcı düzenleyebilsin)
      data['recommended_foods'] = List<String>.from(data['recommended_foods'] ?? []);
      data['foods_to_avoid']    = List<String>.from(data['foods_to_avoid']    ?? []);
      setState(() => _rawData = data);
    } catch (_) {
      setState(() => _error = 'Tavsiye alınırken hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Kaydet öncesi düzenleme dialog'u ──────────────────
  Future<void> _showSaveDialog(Map<String, dynamic> data, Color accent, Color bg, Color bgCard, Color border, Color text, Color muted, Color danger) async {
    // Düzenlenebilir kopya
    final recommended = List<String>.from(data['recommended_foods'] ?? []);
    final avoid       = List<String>.from(data['foods_to_avoid']    ?? []);
    final addRecommCtrl = TextEditingController();
    final addAvoidCtrl  = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: muted, borderRadius: BorderRadius.circular(99)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(child: Text('Listeyi Düzenle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text))),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Kaydet', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    // ── Önerilen Besinler ──
                    Text('✅ Önerilen Besinler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: recommended.asMap().entries.map((e) => GestureDetector(
                        onTap: () => setModal(() => recommended.removeAt(e.key)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: accent.withOpacity(0.4)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(e.value, style: TextStyle(fontSize: 13, color: text)),
                            const SizedBox(width: 4),
                            Icon(Icons.close, size: 14, color: muted),
                          ]),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: addRecommCtrl,
                          style: TextStyle(color: text, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Besin ekle (örn: ceviz)',
                            hintStyle: TextStyle(color: muted, fontSize: 13),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final v = addRecommCtrl.text.trim();
                          if (v.isNotEmpty) { setModal(() { recommended.add(v); addRecommCtrl.clear(); }); }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.add, color: Colors.black, size: 18),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Kaçınılacak Besinler ──
                    Text('❌ Kaçınılacak Besinler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: avoid.asMap().entries.map((e) => GestureDetector(
                        onTap: () => setModal(() => avoid.removeAt(e.key)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: danger.withOpacity(0.4)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(e.value, style: TextStyle(fontSize: 13, color: text)),
                            const SizedBox(width: 4),
                            Icon(Icons.close, size: 14, color: muted),
                          ]),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: addAvoidCtrl,
                          style: TextStyle(color: text, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Besin ekle (örn: zeytin)',
                            hintStyle: TextStyle(color: muted, fontSize: 13),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final v = addAvoidCtrl.text.trim();
                          if (v.isNotEmpty) { setModal(() { avoid.add(v); addAvoidCtrl.clear(); }); }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: danger, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true) {
      // Güncellenmiş listeleri data'ya yaz
      data['recommended_foods'] = recommended;
      data['foods_to_avoid']    = avoid;
      await _saveAdvice(data);
    }
  }

  Future<void> _saveAdvice(Map<String, dynamic> data) async {
    final buf = StringBuffer();
    buf.writeln('## 🗓 Bugünkü Diyet Listeniz\n');
    if (data['summary'] != null)
      buf.writeln('📋 **Özet:** ${data['summary']}\n');
    if (data['daily_calorie_target'] != null)
      buf.writeln('🔥 **Günlük Kalori Hedefi:** ${data['daily_calorie_target']} kcal\n');
    if (data['macros'] != null) {
      buf.writeln('⚖️ **Makrolar**\n');
      Map<String, dynamic>.from(data['macros']).forEach((k, v) {
        final label = _macroLabels[k] ?? k;
        buf.writeln('- **$label:** ${v}g');
      });
      buf.writeln();
    }
    if (data['meal_suggestions'] != null) {
      buf.writeln('🍽️ **Öğün Önerileri**\n');
      Map<String, dynamic>.from(data['meal_suggestions']).forEach((k, v) {
        final label = _mealLabels[k] ?? k;
        buf.writeln('**$label:** $v\n');
      });
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_meal_advice', buf.toString().trim());
    await prefs.setString('last_meal_advice_date', TFDateUtils.today());
    // Besin listelerini ayrıca sakla (diyet_tab'da grid için)
    await prefs.setStringList('last_recommended_foods', List<String>.from(data['recommended_foods'] ?? []));
    await prefs.setStringList('last_foods_to_avoid',    List<String>.from(data['foods_to_avoid']    ?? []));

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diyet planı kaydedildi ✅')));
    setState(() => _rawData = null); // form'a geri dön
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

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          aiHeader(context, ref, isDark, bg, bgCard, border, text, textSoft, muted, accent, 'Diyet Tavsiyesi'),
          Expanded(
            child: _isLoading
                ? aiLoadingState(accent, text, '🥗 Beslenme planı hazırlanıyor...')
                : _error != null
                    ? aiErrorState(_error!, danger, accent, _getAdvice)
                    : _rawData != null
                        ? _buildResult(_rawData!, bg, bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim, danger)
                        : _buildForm(bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim),
          ),
        ],
      ),
    );
  }

  // ── SONUÇ EKRANI ────────────────────────────────────
  Widget _buildResult(Map<String, dynamic> data, Color bg, Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim, Color danger) {
    final recommended = List<String>.from(data['recommended_foods'] ?? []);
    final avoid       = List<String>.from(data['foods_to_avoid']    ?? []);

    // Markdown metin oluştur (sadece özet + makro + öğünler)
    final buf = StringBuffer();
    buf.writeln('## 🗓 Bugünkü Diyet Listeniz\n');
    if (data['summary'] != null)
      buf.writeln('📋 **Özet:** ${data['summary']}\n');
    if (data['daily_calorie_target'] != null)
      buf.writeln('🔥 **Günlük Kalori Hedefi:** ${data['daily_calorie_target']} kcal\n');
    if (data['macros'] != null) {
      buf.writeln('⚖️ **Makrolar**\n');
      Map<String, dynamic>.from(data['macros']).forEach((k, v) {
        final label = _macroLabels[k] ?? k;
        buf.writeln('- **$label:** ${v}g');
      });
      buf.writeln();
    }
    if (data['meal_suggestions'] != null) {
      buf.writeln('🍽️ **Öğün Önerileri**\n');
      Map<String, dynamic>.from(data['meal_suggestions']).forEach((k, v) {
        final label = _mealLabels[k] ?? k;
        buf.writeln('**$label:** $v\n');
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header kart
          Container(
            decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(20), border: Border.all(color: accent)),
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Text('🥗', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Text('Kişisel Beslenme Planın', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: text)),
            ]),
          ),
          const SizedBox(height: 12),

          // Özet + makro + öğünler (markdown)
          Container(
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
            padding: const EdgeInsets.all(16),
            child: MarkdownBody(
              data: buf.toString().trim(),
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p:      TextStyle(fontSize: 14, height: 1.6, color: text),
                h2:     TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accent),
                h3:     TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: accent),
                strong: TextStyle(fontWeight: FontWeight.w700, color: text),
                listBullet: TextStyle(fontSize: 14, color: text),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Önerilen Besinler Grid ──
          if (recommended.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ Önerilen Besinler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                  const SizedBox(height: 12),
                  _foodGrid(recommended, accent, accent.withOpacity(0.1), accent.withOpacity(0.4), text),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Kaçınılacak Besinler Grid ──
          if (avoid.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('❌ Kaçınılacak Besinler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                  const SizedBox(height: 12),
                  _foodGrid(avoid, danger, danger.withOpacity(0.1), danger.withOpacity(0.4), text),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Butonlar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _showSaveDialog(data, accent, bg, bgCard, border, text, muted, danger),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('💾  Düzenle & Kaydet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          aiOutlineBtn('Yeni Tavsiye Al', Icons.arrow_back, accent, border, () => setState(() => _rawData = null)),
        ],
      ),
    );
  }

  // ── 3 kolonlu besin grid'i ────────────────────────────
  Widget _foodGrid(List<String> foods, Color color, Color bgColor, Color borderColor, Color text) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: foods.map((f) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: borderColor),
        ),
        child: Text(f, style: TextStyle(fontSize: 12, color: text, fontWeight: FontWeight.w500)),
      )).toList(),
    );
  }

  // ── FORM EKRANI ──────────────────────────────────────
  Widget _buildForm(Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Beslenme hedefiniz?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
          const SizedBox(height: 12),
          ..._goals.map((g) {
            final sel = _goal == g['key'];
            return GestureDetector(
              onTap: () => setState(() => _goal = g['key']!),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sel ? accentDim : bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: sel ? accent : border, width: sel ? 1.5 : 1),
                ),
                child: Row(children: [
                  Expanded(child: Text(g['label']!, style: TextStyle(fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? accent : text))),
                  if (sel) Icon(Icons.check_circle_rounded, color: accent, size: 18),
                ]),
              ),
            );
          }),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Günlük öğün sayısı?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
            Text('$_mealsPerDay öğün', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: accent, thumbColor: accent, inactiveTrackColor: accent.withOpacity(0.2)),
            child: Slider(value: _mealsPerDay.toDouble(), min: 2, max: 6, divisions: 4, label: '$_mealsPerDay', onChanged: (v) => setState(() => _mealsPerDay = v.toInt())),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(12), border: Border.all(color: accent.withOpacity(0.3))),
            child: Row(children: [
              Icon(Icons.info_outline, color: accent, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Profil bilgilerin tavsiyeye dahil edilir.', style: TextStyle(fontSize: 12, color: textSoft))),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _getAdvice, child: const Text('🥗  Tavsiye Al'))),
        ],
      ),
    );
  }
}