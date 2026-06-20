// ── diyet_tab.dart ──────────────────────────────────────
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/auth/token_manager.dart';
import '../ai/calorie_vision_screen.dart'; // v2: foto-kalori kısayolu
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
  final _notesController    = TextEditingController();
  bool _isLoading   = false;
  bool _initialized = false;
  String? _savedAdvice;
  String? _savedAdviceDate;
  bool _showAdvice      = false;
  bool _showWeeklyPlan  = true; // haftalık plan aç/kapat
  List<String> _recommendedFoods = [];
  List<String> _avoidFoods       = [];
  Map<String, dynamic>? _weeklyPlan;
  List<dynamic> _shoppingList = []; // v2: AI'ın ürettiği haftalık alışveriş listesi
  bool _exportingShopping = false;  // v2: aktarım sırasında buton durumu

  // Gün sırası ve Türkçe etiketler
  static const _dayKeys    = ['pazartesi','salı','çarşamba','perşembe','cuma','cumartesi','pazar'];
  static const _dayLabels  = ['Pzt','Sal','Çar','Per','Cum','Cmt','Paz'];
  static const _mealLabels = {
    'breakfast': '🌅 Kahvaltı',
    'lunch':     '☀️ Öğle',
    'dinner':    '🌙 Akşam',
    'snack':     '🍎 Ara Öğün',
  };

  @override
  void initState() { super.initState(); _loadAdvice(); }

  // ── v6: Yazıyla/sesle öğün girişi ───────────────────────
  // "2 yumurta, bir dilim ekmek, çay" yaz (veya klavyenin 🎤 tuşuyla
  // söyle) → AI kaloriyi hesaplar → kalori alanına tek dokunuşla işler.
  // Veri girişi sürtünmesinin en büyük kırıcısı.
  Future<void> _showTextCalorieSheet(BuildContext context) async {
    final controller = TextEditingController();
    Map<String, dynamic>? result;
    bool loading = false;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        Future<void> analyze() async {
          final desc = controller.text.trim();
          if (desc.length < 3) return;
          setSheet(() { loading = true; error = null; });
          try {
            final res = await ApiClient.instance
                .post(Endpoints.aiCalorieFromText, data: {'description': desc});
            setSheet(() => result = Map<String, dynamic>.from(res.data));
          } on DioException catch (e) {
            final q = QuotaException.fromDioError(e);
            setSheet(() => error = q?.message ?? 'Analiz yapılamadı, tekrar dene');
          } catch (_) {
            setSheet(() => error = 'Analiz yapılamadı, tekrar dene');
          } finally {
            setSheet(() => loading = false);
          }
        }

        return Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 4,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ne yedin? 🍽',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Yaz veya klavyedeki 🎤 tuşuyla söyle — AI hesaplasın.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 2,
                maxLength: 500,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'örn: 2 yumurta, bir dilim tam buğday ekmeği, çay',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 4),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(error!,
                      style: const TextStyle(fontSize: 12, color: Colors.red)),
                ),
              if (result != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0x1FFFB020),
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔥 ${result!['total_calories']} kcal',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        ((result!['food_items'] as List?) ?? [])
                            .map((f) => '${f['name']} (${f['calories']} kcal)')
                            .join(' · '),
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (result!['macros'] is Map)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'P: ${result!['macros']['protein_g']}g · K: ${result!['macros']['carbs_g']}g · Y: ${result!['macros']['fat_g']}g',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading
                      ? null
                      : result == null
                          ? analyze
                          : () {
                              // Kaloriyi giriş alanına işle — mevcut değerin üstüne ekle
                              final current = double.tryParse(
                                      _caloriesController.text.replaceAll(',', '.')) ?? 0;
                              final add = (result!['total_calories'] as num?)?.toDouble() ?? 0;
                              _caloriesController.text =
                                  (current + add).toStringAsFixed(0);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      '✅ ${add.toStringAsFixed(0)} kcal kalori alanına eklendi — Kaydet\'e basmayı unutma')));
                            },
                  child: loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(result == null ? 'Hesapla' : 'Kalori alanına ekle'),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ── v2: Plan → Alışveriş listesi ────────────────────────
  // AI zaten diyet planıyla birlikte konsolide malzeme listesi üretiyor
  // (meal_advisor shopping_list alanı). Bu fonksiyon o listeyi tek
  // dokunuşla mevcut alışveriş sistemine (POST /shopping) aktarır —
  // sıfır ek AI maliyeti, iki mevcut özelliğin birleşimi.
  Future<void> _exportShoppingList() async {
    if (_shoppingList.isEmpty || _exportingShopping) return;
    setState(() => _exportingShopping = true);
    var added = 0;
    var skipped = 0;
    try {
      // FIX #18: idempotency — mevcut listeyi çek, aynı isimde ürün varsa atla.
      // Önceden her basışta aynı 25 malzeme yeniden eklenerek duplicate oluşuyordu.
      Set<String> existing = {};
      try {
        final res = await ApiClient.instance.get(Endpoints.shopping);
        final items = res.data['items'] as List? ?? [];
        existing = items
            .map((e) => ((e as Map)['name'] as String?)?.toLowerCase().trim() ?? '')
            .where((n) => n.isNotEmpty)
            .toSet();
      } catch (_) {}

      for (final item in _shoppingList) {
        final m = item is Map ? item : {};
        final name = (m['name'] as String?)?.trim();
        if (name == null || name.isEmpty) continue;
        if (existing.contains(name.toLowerCase())) { skipped++; continue; }
        await ApiClient.instance.post(Endpoints.shopping, data: {
          'name': name,
          'quantity': (m['quantity'] as String?)?.trim() ?? '1',
          'notes': 'AI diyet planından',
        });
        existing.add(name.toLowerCase()); // tekrar eklemeye karşı lokal güncelle
        added++;
      }
      if (mounted) {
        final msg = added == 0
            ? '🛒 Tüm malzemeler zaten listende var'
            : skipped > 0
                ? '🛒 $added malzeme eklendi, $skipped zaten vardı'
                : '🛒 $added malzeme alışveriş listene eklendi';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(added > 0
              ? '🛒 $added malzeme eklendi, kalanlar eklenemedi'
              : 'Alışveriş listesine aktarılamadı'),
        ));
      }
    } finally {
      if (mounted) setState(() => _exportingShopping = false);
    }
  }

  // ── FIX #13: Besin tercihleri inline bottom sheet ─────
  // Kullanıcı diyet tabından çıkmadan liked/disliked besinlerini güncelleyebilir.
  // Kaydet → /preferences PUT → toast "Yeni diyet planı oluştururken tercihler güncellendi"
  Future<void> _showFoodPrefsSheet(BuildContext ctx, Color accent, Color bgCard, Color border, Color text, Color muted) async {
    // Mevcut tercihleri çek
    String liked = '', disliked = '';
    try {
      final res = await ApiClient.instance.get(Endpoints.preferences);
      final likedList  = (res.data['liked_foods']    as List?)?.cast<String>() ?? [];
      final dislikedList = (res.data['disliked_foods'] as List?)?.cast<String>() ?? [];
      liked    = likedList.join(', ');
      disliked = dislikedList.join(', ');
    } catch (_) {}

    final likedCtrl    = TextEditingController(text: liked);
    final dislikedCtrl = TextEditingController(text: disliked);

    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 16),
          Text('Besin Tercihlerini Güncelle',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: text)),
          const SizedBox(height: 4),
          Text('Virgülle ayırarak yaz. AI koçun bir sonraki diyet planında kullanacak.',
            style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 14),
          TextField(controller: likedCtrl,
            style: TextStyle(color: text),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: '✅ Sevdiğin besinler',
              hintText: 'örn: tavuk, yumurta, brokoli',
              hintStyle: TextStyle(color: muted, fontSize: 12),
            )),
          const SizedBox(height: 10),
          TextField(controller: dislikedCtrl,
            style: TextStyle(color: text),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: '❌ Sevmediğin / alerjin',
              hintText: 'örn: zeytin, deniz ürünleri',
              hintStyle: TextStyle(color: muted, fontSize: 12),
            )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                try {
                  final likedList    = likedCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  final dislikedList = dislikedCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  await ApiClient.instance.put(Endpoints.preferences, data: {
                    'liked_foods':    likedList,
                    'disliked_foods': dislikedList,
                  });
                  if (ctx.mounted) {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('✅ Tercihler güncellendi — yeni diyet planında geçerli olacak'),
                    ));
                  }
                } catch (_) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Kaydedilemedi')));
                  }
                }
              },
              child: const Text('Kaydet'),
            ),
          ),
        ]),
      ),
    );
    likedCtrl.dispose();
    dislikedCtrl.dispose();
  }

  Future<void> _loadAdvice() async {
    final prefs  = await SharedPreferences.getInstance();
    final userId = await TokenManager.getCurrentUserId() ?? 'guest';

    Map<String, dynamic>? weeklyPlan;
    final weeklyRaw = prefs.getString('last_weekly_meal_plan_$userId');
    if (weeklyRaw != null) {
      try { weeklyPlan = Map<String, dynamic>.from(jsonDecode(weeklyRaw)); } catch (_) {}
    }

    // v2: AI'ın diyet planıyla birlikte ürettiği alışveriş listesi
    List<dynamic> shoppingList = [];
    final shoppingRaw = prefs.getString('last_shopping_list_$userId');
    if (shoppingRaw != null) {
      try { shoppingList = List<dynamic>.from(jsonDecode(shoppingRaw)); } catch (_) {}
    }

    setState(() {
      _savedAdvice      = prefs.getString('last_meal_advice_$userId');
      _savedAdviceDate  = prefs.getString('last_meal_advice_date_$userId');
      _recommendedFoods = prefs.getStringList('last_recommended_foods_$userId') ?? [];
      _avoidFoods       = prefs.getStringList('last_foods_to_avoid_$userId')    ?? [];
      _weeklyPlan       = weeklyPlan;
      _shoppingList     = shoppingList;
    });
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save(Map<String, dynamic>? existing) async {
    final calText = _caloriesController.text.trim();
    if (calText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tüketilen kalori zorunludur')));
      return;
    }
    final cal = double.tryParse(calText);
    if (cal == null || cal < 0 || cal > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kalori 0–10000 kcal arasında olmalı')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (existing != null) {
        await ApiClient.instance.put('${Endpoints.mealCompliance}/${existing['id']}', data: {
          'calories_consumed': cal,
          'notes': _notesController.text.isEmpty ? null : _notesController.text,
        });
      } else {
        await ApiClient.instance.post(Endpoints.mealCompliance, data: {
          'date': TFDateUtils.today(),
          'calories_consumed': cal,
          'notes': _notesController.text.isEmpty ? null : _notesController.text,
        });
      }
      _caloriesController.clear();
      _notesController.clear();
      _initialized = false;
      ref.invalidate(todayMealProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diyet logu kaydedildi ✅')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt sırasında hata oluştu')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
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

    final mealAsync = ref.watch(todayMealProvider);
    final todayKey  = _dayKeys[DateTime.now().weekday - 1];

    return mealAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: accent)),
      error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
      data: (mealLog) {
        if (mealLog != null && !_initialized && !_isLoading) {
          final consumed = (mealLog['calories_consumed'] as num?)?.toDouble();
          if (consumed != null) _caloriesController.text = consumed.toInt().toString();
          _initialized = true;
        }

        final consumed    = (mealLog?['calories_consumed']   as num?)?.toDouble() ?? 0;
        final target      = (mealLog?['calories_target']     as num?)?.toDouble() ?? 0;
        final balance     = (mealLog?['calorie_balance']     as num?)?.toDouble() ?? 0;
        final bankBalance = (mealLog?['weekly_bank_balance'] as num?)?.toDouble() ?? 0;
        final todayMax    = (mealLog?['today_max_calories']  as num?)?.toDouble();
        final bankMessage = mealLog?['bank_message'] as String?;
        final progress    = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
        final isOverTarget = consumed > target && target > 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── KALORİ BANKASI KARTI ──────────────────
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('💳 Kalori Bankası', style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
                          if (todayMax != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(99)),
                              child: Text('Maks: ${todayMax.toInt()} kcal', style: TextStyle(fontSize: 10, color: accent, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${consumed.toInt()}',
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: isOverTarget ? danger : accent),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 4),
                            child: Text('/ ${target.toInt()} kcal', style: TextStyle(fontSize: 14, color: textSoft, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: accent.withOpacity(0.15),
                          color: isOverTarget ? danger : accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isOverTarget
                                ? '⚠ ${(consumed - target).toInt()} kcal fazla'
                                : '${(target - consumed).toInt()} kcal kaldı',
                            style: TextStyle(fontSize: 11, color: isOverTarget ? danger : textSoft),
                          ),
                          Text('%${(progress * 100).toInt()}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isOverTarget ? danger : accent)),
                        ],
                      ),
                      if (bankMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: accent.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                          child: Text(bankMessage, style: TextStyle(fontSize: 12, color: text, height: 1.4)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── MAKRO ÖZETİ ────────────────────────
                Container(
                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Makro Özeti', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                      const SizedBox(height: 12),
                      ...[
                        ['Günlük Fark',    '${balance > 0 ? "+" : ""}${balance.toInt()} kcal', balance <= 0],
                        ['Haftalık Banka', '${bankBalance > 0 ? "+" : ""}${bankBalance.toInt()} kcal', bankBalance >= 0],
                        ['Diyet Uyumu', (mealLog?['complied'] as bool? ?? true) ? '✔ uyuldu' : '✖ uyulmadı', (mealLog?['complied'] as bool? ?? true)],
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
                // ── Başlık satırı ──
                GestureDetector(
                  onTap: () => setState(() => _showAdvice = !_showAdvice),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
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

                  // ── BUGÜNÜN MENÜSÜ ──────────────────
                  if (_weeklyPlan != null) Builder(
                    builder: (ctx) {
                      final todayMeals = _weeklyPlan![todayKey] as Map?;
                      if (todayMeals == null) return const SizedBox.shrink();
                      final todayLabel = _dayLabels[DateTime.now().weekday - 1];
                      return Column(children: [
                        Container(
                          decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accent.withOpacity(0.4)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('🗓 Bugünün Menüsü — $todayLabel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
                              const SizedBox(height: 12),
                              ..._mealLabels.entries.map((entry) {
                                final meal = todayMeals[entry.key] as String?;
                                if (meal == null) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 80, child: Text(entry.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: muted))),
                                      Expanded(child: Text(meal, style: TextStyle(fontSize: 12, color: text, height: 1.4))),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ]);
                    },
                  ),

                  // ── HAFTALIK PLAN (7 gün) ──────────
                  if (_weeklyPlan != null) ...[
                    GestureDetector(
                      onTap: () => setState(() => _showWeeklyPlan = !_showWeeklyPlan),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                        child: Row(
                          children: [
                            const Text('📅', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(child: Text('Haftalık Plan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text))),
                            Icon(_showWeeklyPlan ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: accent),
                          ],
                        ),
                      ),
                    ),
                    if (_showWeeklyPlan) ...[
                      const SizedBox(height: 8),
                      // Gün sekmeleri
                      _WeeklyPlanView(
                        weeklyPlan: _weeklyPlan!,
                        dayKeys: _dayKeys,
                        dayLabels: _dayLabels,
                        mealLabels: _mealLabels,
                        todayIndex: DateTime.now().weekday - 1,
                        bgCard: bgCard,
                        bgSoft: bgSoft,
                        border: border,
                        text: text,
                        textSoft: textSoft,
                        muted: muted,
                        accent: accent,
                        accentDim: accentDim,
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],

                  // ── v2: PLAN → ALIŞVERİŞ LİSTESİ ───
                  if (_shoppingList.isNotEmpty) ...[
                    GestureDetector(
                      onTap: _exportingShopping ? null : _exportShoppingList,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent.withOpacity(0.4)),
                        ),
                        child: Row(children: [
                          const Text('🛒', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _exportingShopping ? 'Aktarılıyor...' : 'Alışveriş listesine aktar',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text),
                              ),
                              if (!_exportingShopping) ...[
                                const SizedBox(height: 3),
                                // FIX #18: "25 kalem" yerine gerçek ürün isimleri
                                Builder(builder: (_) {
                                  final names = _shoppingList
                                      .map((e) => (e is Map ? e['name'] as String? : null) ?? '')
                                      .where((n) => n.isNotEmpty)
                                      .toList();
                                  final preview = names.take(3).join(', ');
                                  final extra = names.length > 3 ? ' +${names.length - 3} daha' : '';
                                  return Text(
                                    '$preview$extra',
                                    style: TextStyle(fontSize: 11, color: muted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }),
                              ],
                            ],
                          )),
                          _exportingShopping
                              ? SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: accent))
                              : Icon(Icons.add_shopping_cart_rounded, size: 18, color: accent),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ── GENEL ÖZET (Markdown) ──────────
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

                  // ── Önerilen Besinler ──────────────
                  if (_recommendedFoods.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('✅ Önerilen Besinler', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: text)),
                            const SizedBox(width: 4),
                            // FIX #13: ? tooltip — nereden geldiğini açıkla
                            Tooltip(
                              message: 'AI koçun profildeki sevilen besinlerine göre belirledi.\nDeğiştirmek için "Düzenle"ye bas.',
                              child: Icon(Icons.info_outline, size: 14, color: muted),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showFoodPrefsSheet(context, accent, bgCard, border, text, muted),
                              child: Text('Düzenle', style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                            ),
                          ]),
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

                  // ── Kaçınılacak Besinler ───────────
                  if (_avoidFoods.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('❌ Kaçınılacak Besinler', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: text)),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'AI koçun profildeki sevilmeyen besinlere/alerjilere göre belirledi.\nDeğiştirmek için "Düzenle"ye bas.',
                              child: Icon(Icons.info_outline, size: 14, color: muted),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showFoodPrefsSheet(context, accent, bgCard, border, text, muted),
                              child: Text('Düzenle', style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                            ),
                          ]),
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
                    Text(
                      mealLog != null ? 'Güncelle' : 'Bugünkü Öğünü Kaydet',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text),
                    ),
                    if (target > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined, size: 14, color: muted),
                            const SizedBox(width: 8),
                            Text('Hedef kalori: ', style: TextStyle(fontSize: 12, color: muted)),
                            Text('${target.toInt()} kcal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
                            const SizedBox(width: 4),
                            Text('(otomatik)', style: TextStyle(fontSize: 10, color: muted)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _caloriesController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: text),
                      decoration: const InputDecoration(
                        labelText: 'Tüketilen Kalori (kcal)',
                        prefixIcon: Icon(Icons.local_fire_department_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ── v2: Foto-kalori artık köşede bir ekran değil,
                    // öğün kaydının doğal giriş yollarından biri.
                    // Vision sonucu zaten "Diyet Planına Ekle" ile buraya yazıyor.
                    Row(children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const CalorieVisionScreen()));
                        },
                        icon: Icon(Icons.camera_alt_rounded, size: 16, color: accent),
                        label: Text('Fotoğrafla',
                            style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                      ),
                      // v6: yazıyla/sesle tarif — klavyenin 🎤 tuşu dikteyi halleder
                      TextButton.icon(
                        onPressed: () => _showTextCalorieSheet(context),
                        icon: Icon(Icons.keyboard_voice_rounded, size: 16, color: accent),
                        label: Text('Tarif et — AI hesaplasın ✨',
                            style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      style: TextStyle(color: text),
                      decoration: const InputDecoration(
                        labelText: 'Not (opsiyonel)',
                        prefixIcon: Icon(Icons.note_outlined),
                      ),
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

// ── Haftalık Plan Widget ──────────────────────────────────
class _WeeklyPlanView extends StatefulWidget {
  final Map<String, dynamic> weeklyPlan;
  final List<String> dayKeys;
  final List<String> dayLabels;
  final Map<String, String> mealLabels;
  final int todayIndex;
  final Color bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim;

  const _WeeklyPlanView({
    required this.weeklyPlan,
    required this.dayKeys,
    required this.dayLabels,
    required this.mealLabels,
    required this.todayIndex,
    required this.bgCard,
    required this.bgSoft,
    required this.border,
    required this.text,
    required this.textSoft,
    required this.muted,
    required this.accent,
    required this.accentDim,
  });

  @override
  State<_WeeklyPlanView> createState() => _WeeklyPlanViewState();
}

class _WeeklyPlanViewState extends State<_WeeklyPlanView> {
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.todayIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Gün seçici ──
        Container(
          decoration: BoxDecoration(color: widget.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: widget.border)),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: List.generate(7, (i) {
              final isToday = i == widget.todayIndex;
              final isSel   = i == _selectedDay;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? widget.accentDim : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSel ? widget.accent : Colors.transparent),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.dayLabels[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                            color: isSel ? widget.accent : widget.muted,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(height: 2),
                          Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.accent)),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),

        // ── Seçili günün menüsü ──
        Builder(builder: (ctx) {
          final dayKey  = widget.dayKeys[_selectedDay];
          final dayData = widget.weeklyPlan[dayKey];
          if (dayData == null) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: widget.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: widget.border)),
              child: Center(child: Text('Bu gün için plan yok', style: TextStyle(fontSize: 13, color: widget.muted))),
            );
          }
          final meals = Map<String, dynamic>.from(dayData);
          return Container(
            decoration: BoxDecoration(color: widget.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: widget.border)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.dayLabels[_selectedDay]} Menüsü',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: widget.accent),
                ),
                const SizedBox(height: 12),
                ...widget.mealLabels.entries.map((entry) {
                  final meal = meals[entry.key] as String?;
                  if (meal == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 80, child: Text(entry.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.muted))),
                        Expanded(child: Text(meal, style: TextStyle(fontSize: 12, color: widget.text, height: 1.4))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}