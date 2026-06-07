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
import '../../core/utils/rate_limiter.dart';
import 'dart:convert';
import '../../core/auth/token_manager.dart';

final preferencesProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.preferences);
    return Map<String, dynamic>.from(response.data);
  } catch (_) { return null; }
});

class MealAdviceScreen extends ConsumerStatefulWidget {
  const MealAdviceScreen({super.key});
  @override
  ConsumerState<MealAdviceScreen> createState() => _MealAdviceScreenState();
}

class _MealAdviceScreenState extends ConsumerState<MealAdviceScreen> {
  Map<String, dynamic>? _rawData;
  bool _isLoading = false;
  String? _error;
  bool _limitReached = false;

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

  String _goalLabel(String goal) {
    const labels = {
      'weight_loss': 'Kilo Vermek',
      'muscle_gain': 'Kas Kazanmak',
      'maintenance': 'Kiloyu Korumak',
      'health':      'Sağlıklı Beslenmek',
    };
    return labels[goal] ?? goal;
  }

  int _getCalorieTarget(Map<String, dynamic>? prefs) {
    final fitnessGoal = prefs?['fitness_goal'] as String? ?? 'maintenance';
    switch (fitnessGoal) {
      case 'weight_loss': return 1500;
      case 'muscle_gain': return 2500;
      case 'maintenance': return 2000;
      default:            return 1800;
    }
  }

  Future<void> _getAdvice(Map<String, dynamic>? prefs) async {
    final canUse = await RateLimiter.canUseMealAdvice();
    if (!canUse) {
      setState(() => _limitReached = true);
      return;
    }
    setState(() { _isLoading = true; _error = null; _rawData = null; _limitReached = false; });
    try {
      final calorieTarget = _getCalorieTarget(prefs);
      final response = await ApiClient.instance.post(Endpoints.aiMealAdvice, data: {
        'calorie_target': calorieTarget,
      });
      final data = Map<String, dynamic>.from(response.data);
      data['recommended_foods'] = List<String>.from(data['recommended_foods'] ?? []);
      data['foods_to_avoid']    = List<String>.from(data['foods_to_avoid']    ?? []);
      setState(() => _rawData = data);
      await RateLimiter.recordMealAdviceUse();
    } catch (_) {
      setState(() => _error = 'Tavsiye alınırken hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSaveDialog(Map<String, dynamic> data, Color accent, Color bg, Color bgCard, Color border, Color text, Color muted, Color danger) async {
    final recommended   = List<String>.from(data['recommended_foods'] ?? []);
    final avoid         = List<String>.from(data['foods_to_avoid']    ?? []);
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
              Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                decoration: BoxDecoration(color: muted, borderRadius: BorderRadius.circular(99))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(children: [
                  Expanded(child: Text('Listeyi Düzenle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text))),
                  TextButton(onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Kaydet', style: TextStyle(color: accent, fontWeight: FontWeight.w700))),
                ]),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    Text('✅ Önerilen Besinler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6,
                      children: recommended.asMap().entries.map((e) => GestureDetector(
                        onTap: () => setModal(() => recommended.removeAt(e.key)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(99), border: Border.all(color: accent.withOpacity(0.4))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Flexible(child: Text(e.value, style: TextStyle(fontSize: 13, color: text), overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 4),
                            Icon(Icons.close, size: 14, color: muted),
                          ]),
                        ),
                      )).toList()),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: TextField(controller: addRecommCtrl, style: TextStyle(color: text, fontSize: 13),
                        decoration: InputDecoration(hintText: 'Besin ekle (örn: ceviz)', hintStyle: TextStyle(color: muted, fontSize: 13),
                          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border))))),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () { final v = addRecommCtrl.text.trim(); if (v.isNotEmpty) { setModal(() { recommended.add(v); addRecommCtrl.clear(); }); } },
                        child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.add, color: Colors.black, size: 18))),
                    ]),
                    const SizedBox(height: 20),
                    Text('❌ Kaçınılacak Besinler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6,
                      children: avoid.asMap().entries.map((e) => GestureDetector(
                        onTap: () => setModal(() => avoid.removeAt(e.key)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: danger.withOpacity(0.1), borderRadius: BorderRadius.circular(99), border: Border.all(color: danger.withOpacity(0.4))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Flexible(child: Text(e.value, style: TextStyle(fontSize: 13, color: text), overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 4),
                            Icon(Icons.close, size: 14, color: muted),
                          ]),
                        ),
                      )).toList()),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: TextField(controller: addAvoidCtrl, style: TextStyle(color: text, fontSize: 13),
                        decoration: InputDecoration(hintText: 'Besin ekle (örn: zeytin)', hintStyle: TextStyle(color: muted, fontSize: 13),
                          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border))))),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () { final v = addAvoidCtrl.text.trim(); if (v.isNotEmpty) { setModal(() { avoid.add(v); addAvoidCtrl.clear(); }); } },
                        child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: danger, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.add, color: Colors.white, size: 18))),
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
      data['recommended_foods'] = recommended;
      data['foods_to_avoid']    = avoid;
      await _saveAdvice(data);
    }
  }

  Future<void> _saveAdvice(Map<String, dynamic> data) async {
    final buf = StringBuffer();
    buf.writeln('## 🗓 Bugünkü Diyet Listeniz\n');
    if (data['summary'] != null) buf.writeln('📋 **Özet:** ${data['summary']}\n');
    if (data['daily_calorie_target'] != null) buf.writeln('🔥 **Günlük Kalori Hedefi:** ${data['daily_calorie_target']} kcal\n');
    if (data['macros'] != null) {
      buf.writeln('⚖️ **Makrolar**\n');
      Map<String, dynamic>.from(data['macros']).forEach((k, v) { buf.writeln('- **${_macroLabels[k] ?? k}:** ${v}g'); });
      buf.writeln();
    }
    if (data['meal_suggestions'] != null) {
      buf.writeln('🍽️ **Öğün Önerileri**\n');
      Map<String, dynamic>.from(data['meal_suggestions']).forEach((k, v) { buf.writeln('**${_mealLabels[k] ?? k}:** $v\n'); });
    }
    final prefs  = await SharedPreferences.getInstance();
    final userId = await TokenManager.getCurrentUserId() ?? 'guest';
    await prefs.setString('last_meal_advice_$userId', buf.toString().trim());
    await prefs.setString('last_meal_advice_date_$userId', TFDateUtils.today());
    await prefs.setStringList('last_recommended_foods_$userId', List<String>.from(data['recommended_foods'] ?? []));
    await prefs.setStringList('last_foods_to_avoid_$userId',    List<String>.from(data['foods_to_avoid']    ?? []));
    if (data['weekly_plan'] != null) await prefs.setString('last_weekly_meal_plan_$userId', jsonEncode(data['weekly_plan']));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diyet planı kaydedildi ✅')));
    setState(() => _rawData = null);
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
    final danger    = isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);
    final prefsAsync = ref.watch(preferencesProvider);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          aiHeader(context, ref, isDark, bg, bgCard, border, text, textSoft, muted, accent, 'Diyet Tavsiyesi'),
          Expanded(
            child: prefsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: accent)),
              error:   (_, __) => _buildContent(null, bg, bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim, danger),
              data:    (prefs) => _buildContent(prefs, bg, bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim, danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic>? prefs, Color bg, Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim, Color danger) {
    if (_limitReached) return _buildLimitCard(accentDim, accent, border, text);
    if (_isLoading) return aiLoadingState(accent, text, '🥗 Beslenme planı hazırlanıyor...');
    if (_error != null) return aiErrorState(_error!, danger, accent, () => _getAdvice(prefs));
    if (_rawData != null) return _buildResult(_rawData!, prefs, bg, bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim, danger);
    return _buildForm(prefs, bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim);
  }

  Widget _buildForm(Map<String, dynamic>? prefs, Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim) {
    final calorieTarget = _getCalorieTarget(prefs);
    final fitnessGoal   = prefs?['fitness_goal'] as String? ?? 'maintenance';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Kalori hedefi bilgisi
        if (prefs != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(12), border: Border.all(color: accent.withOpacity(0.3))),
            child: Row(children: [
              Icon(Icons.local_fire_department_outlined, color: accent, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Kalori hedefin: $calorieTarget kcal',
                style: TextStyle(fontSize: 12, color: text, fontWeight: FontWeight.w500))),
            ]),
          ),
          const SizedBox(height: 10),
          // Profil hedefi bilgisi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(12), border: Border.all(color: accent.withOpacity(0.3))),
            child: Row(children: [
              Icon(Icons.track_changes, color: accent, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Profilindeki hedefin kullanılıyor: ${_goalLabel(fitnessGoal)} ✓',
                style: TextStyle(fontSize: 12, color: text, fontWeight: FontWeight.w500),
              )),
            ]),
          ),
          const SizedBox(height: 20),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _getAdvice(prefs),
            child: const Text('🥗  Tavsiye Al'),
          ),
        ),
      ]),
    );
  }

  Widget _buildResult(Map<String, dynamic> data, Map<String, dynamic>? prefs, Color bg, Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim, Color danger) {
    final recommended = List<String>.from(data['recommended_foods'] ?? []);
    final avoid       = List<String>.from(data['foods_to_avoid']    ?? []);
    final buf = StringBuffer();
    buf.writeln('## 🗓 Bugünkü Diyet Listeniz\n');
    if (data['summary'] != null) buf.writeln('📋 **Özet:** ${data['summary']}\n');
    if (data['daily_calorie_target'] != null) buf.writeln('🔥 **Günlük Kalori Hedefi:** ${data['daily_calorie_target']} kcal\n');
    if (data['macros'] != null) {
      buf.writeln('⚖️ **Makrolar**\n');
      Map<String, dynamic>.from(data['macros']).forEach((k, v) { buf.writeln('- **${_macroLabels[k] ?? k}:** ${v}g'); });
      buf.writeln();
    }
    if (data['meal_suggestions'] != null) {
      buf.writeln('🍽️ **Öğün Önerileri**\n');
      Map<String, dynamic>.from(data['meal_suggestions']).forEach((k, v) { buf.writeln('**${_mealLabels[k] ?? k}:** $v\n'); });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        Container(
          decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
          padding: const EdgeInsets.all(16),
          child: MarkdownBody(data: buf.toString().trim(), selectable: true,
            styleSheet: MarkdownStyleSheet(
              p:      TextStyle(fontSize: 14, height: 1.6, color: text),
              h2:     TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accent),
              h3:     TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: accent),
              strong: TextStyle(fontWeight: FontWeight.w700, color: text),
              listBullet: TextStyle(fontSize: 14, color: text),
            )),
        ),
        const SizedBox(height: 12),
        if (recommended.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('✅ Önerilen Besinler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
              const SizedBox(height: 12),
              _foodGrid(recommended, accent, accent.withOpacity(0.1), accent.withOpacity(0.4), text),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        if (avoid.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('❌ Kaçınılacak Besinler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
              const SizedBox(height: 12),
              _foodGrid(avoid, danger, danger.withOpacity(0.1), danger.withOpacity(0.4), text),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: () => _showSaveDialog(data, accent, bg, bgCard, border, text, muted, danger),
            style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            child: const Text('💾  Düzenle & Kaydet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 8),
        aiOutlineBtn('Yeni Tavsiye Al', Icons.arrow_back, accent, border, () => setState(() => _rawData = null)),
      ]),
    );
  }

  Widget _foodGrid(List<String> foods, Color color, Color bgColor, Color borderColor, Color text) {
    return Wrap(spacing: 6, runSpacing: 6,
      children: foods.map((f) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(99), border: Border.all(color: borderColor)),
        child: Text(f, style: TextStyle(fontSize: 12, color: text, fontWeight: FontWeight.w500)),
      )).toList());
  }

  Widget _buildLimitCard(Color accentDim, Color accent, Color border, Color text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(20), border: Border.all(color: accent)),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⏳', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Haftalık Limit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent)),
            const SizedBox(height: 8),
            Text('Bu haftaki diyet tavsiyesi hakkını kullandın.\nYeni hafta başında tekrar kullanılabilir.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: text, height: 1.5)),
          ]),
        ),
      ),
    );
  }
}