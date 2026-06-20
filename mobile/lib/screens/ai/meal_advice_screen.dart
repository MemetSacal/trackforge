// ── meal_advice_screen.dart ─────────────────────────────
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/widgets/staged_loader.dart';
import '../../core/api/endpoints.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/utils/date_utils.dart';
import '../../app.dart';
import 'ai_helpers.dart';
import '../../core/utils/rate_limiter.dart';
import 'dart:convert';
import '../../core/auth/token_manager.dart';

final preferencesProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.preferences);
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return null;
  }
});

class MealAdviceScreen extends ConsumerStatefulWidget {
  const MealAdviceScreen({super.key});
  @override
  ConsumerState<MealAdviceScreen> createState() => _MealAdviceScreenState();
}

class _MealAdviceScreenState extends ConsumerState<MealAdviceScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _rawData;
  bool _isLoading = false;
  String? _error;
  bool _limitReached = false;
  TabController? _tabController;

  // Türkçe gün sırası
  static const _days = [
    'pazartesi',
    'salı',
    'çarşamba',
    'perşembe',
    'cuma',
    'cumartesi',
    'pazar',
  ];
  static const _dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  final _mealLabels = {
    'breakfast': '🌅 Kahvaltı',
    'lunch': '☀️ Öğle',
    'dinner': '🌙 Akşam',
    'snack': '🍎 Ara Öğün',
  };

  final _macroLabels = {
    'protein_g': 'Protein',
    'carbs_g': 'Karbonhidrat',
    'fat_g': 'Yağ',
  };

  String _goalLabel(String goal) {
    const labels = {
      'weight_loss': 'Kilo Vermek',
      'muscle_gain': 'Kas Kazanmak',
      'maintenance': 'Kiloyu Korumak',
      'health': 'Sağlıklı Beslenmek',
    };
    return labels[goal] ?? goal;
  }

  int _getCalorieTarget(Map<String, dynamic>? prefs) {
    final fitnessGoal = prefs?['fitness_goal'] as String? ?? 'maintenance';
    switch (fitnessGoal) {
      case 'weight_loss':
        return 1500;
      case 'muscle_gain':
        return 2500;
      case 'maintenance':
        return 2000;
      default:
        return 1800;
    }
  }

  // Bugünün index'i (0=Pazartesi)
  int get _todayIndex => DateTime.now().weekday - 1;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _initTabs() {
    _tabController?.dispose();
    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: _todayIndex,
    );
  }

  // ─────────────────────────────────────────────────────────
  // v7: JOB PATTERN — uzun diyet üretimi arka planda yoklanır.
  // workout_plan_screen._awaitJob ile AYNI mantık:
  //  • Cache isabetinde POST anında {status:'done', result:{...}} döner
  //    → hiç beklemeden sonucu kullanırız (job_id null'dır, bu HATA DEĞİL).
  //  • Aksi halde job başlar; durumu /ai/jobs/{id} ile 2.5 sn'de bir yoklarız.
  // ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> _awaitMealJob(Response startResponse) async {
    try {
      final body = Map<String, dynamic>.from(startResponse.data);

      // 1) CACHE İSABETİ — sonuç POST yanıtında hazır geldi (job_id == null normal)
      if (body['status'] == 'done' && body['result'] != null) {
        return Map<String, dynamic>.from(body['result']);
      }

      // 2) Arka plan job'u başlatıldı — job_id ile yoklayacağız
      final jobId = body['job_id'] as String?;
      if (jobId == null) {
        setState(() => _error = 'İş başlatılamadı, tekrar dene.');
        return null;
      }

      // ~2 dk tavan: 48 x 2.5 sn (workout ekranıyla birebir aynı)
      for (int i = 0; i < 48; i++) {
        await Future.delayed(const Duration(milliseconds: 2500));
        if (!mounted) return null; // ekran kapandı — sunucu yine de bitirir,
                                    // sonuç cache'e düşer, kota boşa yanmaz

        // KRİTİK: durum sorgusu /ai/jobs/{id} adresine gider → aiJobs sabiti.
        // (aiJobsMeal = /ai/jobs/meal-advice; o YALNIZCA job başlatan POST içindir.
        //  Eski kod buraya aiJobsMeal koyduğu için /ai/jobs/meal-advice/{id} → 404 oluyordu.)
        final poll =
            await ApiClient.instance.get('${Endpoints.aiJobs}/$jobId');
        final status = poll.data['status'] as String?;

        // Backend yalnızca 'pending' | 'running' | 'done' | 'error' döndürür
        if (status == 'done') {
          return Map<String, dynamic>.from(poll.data['result']);
        }
        if (status == 'error') {
          setState(() => _error =
              'Diyet planı oluşturulamadı: ${poll.data['error'] ?? 'bilinmeyen hata'}');
          return null;
        }
        // 'pending' / 'running' → döngü devam eder
      }

      setState(() => _error = 'İşlem çok uzun sürdü — birazdan tekrar dene, '
          'sonuç hazırsa anında gelecek.');
      return null;
    } catch (_) {
      setState(() => _error = 'Job takibi sırasında hata oluştu.');
      return null;
    }
  }

  Future<void> _getAdvice(Map<String, dynamic>? prefs) async {
    final canUse = await RateLimiter.canUseMealAdvice();
    if (!canUse) {
      setState(() => _limitReached = true);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _rawData = null;
      _limitReached = false;
    });
    try {
      final calorieTarget = _getCalorieTarget(prefs);
      // v7: job pattern — uzun üretim arka planda, biz yoklarız.
      // Cache isabetinde anında 'done' döner, kota yanmaz.
      final start = await ApiClient.instance
          .post(Endpoints.aiJobsMeal, data: {'calorie_target': calorieTarget});
      final jobData = await _awaitMealJob(start);
      if (jobData == null) return; // hata _awaitMealJob içinde işlendi
      final data = Map<String, dynamic>.from(jobData);
      data['recommended_foods'] =
          List<String>.from(data['recommended_foods'] ?? []);
      data['foods_to_avoid'] =
          List<String>.from(data['foods_to_avoid'] ?? []);
      _initTabs();
      setState(() => _rawData = data);
      // v2: lokal sayacı sunucu gerçeğiyle senkronla
      // (sunucu cache'den döndüyse kota yanmamıştır, sayaç şişmez)
      final quota = data['quota'];
      if (quota is Map) {
        await RateLimiter.syncFromServer('meal_advice',
            (quota['used'] as num?)?.toInt() ?? 0);
      } else {
        await RateLimiter.recordMealAdviceUse();
      }
    } on DioException catch (e) {
      // v2: sunucu kotası — yapılandırılmış 429
      final q = QuotaException.fromDioError(e);
      if (q != null) {
        setState(() => _limitReached = true);
        if (mounted) {
          await showQuotaDialog(context,
              message: q.message, isPremium: q.isPremium,
              resetsInDays: q.resetsInDays);
        }
      } else {
        setState(() => _error = 'Tavsiye alınırken hata oluştu.');
      }
    } catch (_) {
      setState(() => _error = 'Tavsiye alınırken hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSaveDialog(
    Map<String, dynamic> data,
    Color accent,
    Color bg,
    Color bgCard,
    Color border,
    Color text,
    Color muted,
    Color danger,
  ) async {
    final recommended = List<String>.from(data['recommended_foods'] ?? []);
    final avoid = List<String>.from(data['foods_to_avoid'] ?? []);
    final addRecommCtrl = TextEditingController();
    final addAvoidCtrl = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => Column(
            children: [
              Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: muted,
                      borderRadius: BorderRadius.circular(99))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(children: [
                  Expanded(
                      child: Text('Listeyi Düzenle',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: text))),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Kaydet',
                        style: TextStyle(
                            color: accent, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    Text('✅ Önerilen Besinler',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: text)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: recommended
                          .asMap()
                          .entries
                          .map((e) => GestureDetector(
                                onTap: () =>
                                    setModal(() => recommended.removeAt(e.key)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                          color: accent.withOpacity(0.4))),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                            child: Text(e.value,
                                                style: TextStyle(
                                                    fontSize: 13, color: text),
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                        const SizedBox(width: 4),
                                        Icon(Icons.close,
                                            size: 14, color: muted),
                                      ]),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    // FIX #14: Serbest giriş kısıtlaması — özelliğin amacı
                    // istenmeyen besini sağlıklı alternatifle DEĞİŞTİRMEK,
                    // cips/burger gibi diyet dışı gıda eklemek değil.
                    // Bilinen junk food anahtar kelimelerini reddedip kullanıcıya
                    // amacı hatırlatıyoruz; meşru besinler serbestçe girilebilir.
                    Builder(builder: (bCtx) {
                      String? errorMsg;
                      const _junkKeywords = [
                        'cips','chips','burger','hamburger','pizza','hot dog','hotdog',
                        'kızarmış tavuk','fried chicken','nugget','sosisli','sosis',
                        'patates kızartma','french fry','fries','çikolata','chocolate',
                        'gofret','wafer','bisküvi','kurabiye','kek','pasta','tatlı',
                        'şeker','candy','şekerleme','gummy','limonata','kola','soda',
                        'enerji içeceği','energy drink','alkol','beer','bira','şarap',
                        'wine','viski','vodka','rakı',
                      ];
                      return StatefulBuilder(builder: (_, setErr) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: TextField(
                                controller: addRecommCtrl,
                                style: TextStyle(color: text, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Alternatif sağlıklı besin ekle (örn: ceviz)',
                                  hintStyle: TextStyle(color: muted, fontSize: 13),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: errorMsg != null ? danger : border),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                final v = addRecommCtrl.text.trim();
                                if (v.isEmpty) return;
                                final lower = v.toLowerCase();
                                final isJunk = _junkKeywords.any((k) => lower.contains(k));
                                if (isJunk) {
                                  setErr(() => errorMsg = 'Bu alan diyet planına uygun alternatif besinler içindir. Lütfen sağlıklı bir seçenek gir.');
                                  return;
                                }
                                setErr(() => errorMsg = null);
                                setModal(() {
                                  recommended.add(v);
                                  addRecommCtrl.clear();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.add, color: Colors.black, size: 18),
                              ),
                            ),
                          ]),
                          if (errorMsg != null) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.info_outline, size: 13, color: danger),
                              const SizedBox(width: 4),
                              Expanded(child: Text(errorMsg!, style: TextStyle(fontSize: 11, color: danger))),
                            ]),
                          ],
                        ],
                      ));
                    }),
                    const SizedBox(height: 20),
                    Text('❌ Kaçınılacak Besinler',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: text)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: avoid
                          .asMap()
                          .entries
                          .map((e) => GestureDetector(
                                onTap: () =>
                                    setModal(() => avoid.removeAt(e.key)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: danger.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                          color: danger.withOpacity(0.4))),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                            child: Text(e.value,
                                                style: TextStyle(
                                                    fontSize: 13, color: text),
                                                overflow:
                                                    TextOverflow.ellipsis)),
                                        const SizedBox(width: 4),
                                        Icon(Icons.close,
                                            size: 14, color: muted),
                                      ]),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: addAvoidCtrl,
                              style: TextStyle(color: text, fontSize: 13),
                              decoration: InputDecoration(
                                  hintText: 'Besin ekle (örn: zeytin)',
                                  hintStyle:
                                      TextStyle(color: muted, fontSize: 13),
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: border))))),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final v = addAvoidCtrl.text.trim();
                          if (v.isNotEmpty) {
                            setModal(() {
                              avoid.add(v);
                              addAvoidCtrl.clear();
                            });
                          }
                        },
                        child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: danger,
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 18)),
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
      data['recommended_foods'] = recommended;
      data['foods_to_avoid'] = avoid;
      await _saveAdvice(data);
    }
  }

  Future<void> _saveAdvice(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await TokenManager.getCurrentUserId() ?? 'guest';

    // Haftalık plan JSON olarak kaydet
    if (data['weekly_plan'] != null) {
      await prefs.setString(
          'last_weekly_meal_plan_$userId', jsonEncode(data['weekly_plan']));
    }
    // v2: AI'ın ürettiği konsolide alışveriş listesini de sakla —
    // diyet_tab'daki "Alışveriş listesine aktar" butonu bunu kullanır
    if (data['shopping_list'] != null) {
      await prefs.setString(
          'last_shopping_list_$userId', jsonEncode(data['shopping_list']));
    }

    // Makro / kalori özeti
    final buf = StringBuffer();
    buf.writeln('## 🗓 Haftalık Diyet Planı\n');
    if (data['summary'] != null)
      buf.writeln('📋 **Özet:** ${data['summary']}\n');
    if (data['daily_calorie_target'] != null)
      buf.writeln(
          '🔥 **Günlük Kalori Hedefi:** ${data['daily_calorie_target']} kcal\n');
    if (data['macros'] != null) {
      buf.writeln('⚖️ **Makrolar**\n');
      Map<String, dynamic>.from(data['macros']).forEach((k, v) {
        buf.writeln('- **${_macroLabels[k] ?? k}:** ${v}g');
      });
    }

    await prefs.setString(
        'last_meal_advice_$userId', buf.toString().trim());
    await prefs.setString(
        'last_meal_advice_date_$userId', TFDateUtils.today());
    await prefs.setStringList('last_recommended_foods_$userId',
        List<String>.from(data['recommended_foods'] ?? []));
    await prefs.setStringList('last_foods_to_avoid_$userId',
        List<String>.from(data['foods_to_avoid'] ?? []));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Haftalık diyet planı kaydedildi ✅')));
    }
    setState(() => _rawData = null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg =
        isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard = isDark ? const Color(0xFF141620) : Colors.white;
    final bgSoft =
        isDark ? const Color(0xFF0F1016) : const Color(0xFFE8EBF2);
    final border = isDark
        ? const Color(0x12FFFFFF)
        : const Color(0x12000000);
    final text =
        isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final textSoft =
        isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);
    final muted =
        isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent =
        isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim =
        isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);
    final danger =
        isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);
    final prefsAsync = ref.watch(preferencesProvider);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          aiHeader(context, ref, isDark, bg, bgCard, border, text, textSoft,
              muted, accent, 'Diyet Tavsiyesi'),
          Expanded(
            child: prefsAsync.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: accent)),
              error: (_, __) => _buildContent(null, bg, bgCard, bgSoft,
                  border, text, textSoft, muted, accent, accentDim, danger),
              data: (prefs) => _buildContent(prefs, bg, bgCard, bgSoft,
                  border, text, textSoft, muted, accent, accentDim, danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    Map<String, dynamic>? prefs,
    Color bg,
    Color bgCard,
    Color bgSoft,
    Color border,
    Color text,
    Color textSoft,
    Color muted,
    Color accent,
    Color accentDim,
    Color danger,
  ) {
    if (_limitReached)
      return _buildLimitCard(accentDim, accent, border, text);
    if (_isLoading)
      return StagedLoader(accent: accent, text: text, stages: const [
                        '📊 Beslenme geçmişini okuyorum...',
                        '🔢 Kalori hedefini hesaplıyorum...',
                        '🥗 Haftalık menüyü kuruyorum...',
                        '🛒 Alışveriş listesini çıkarıyorum...',
                      ]);
    if (_error != null)
      return aiErrorState(_error!, danger, accent, () => _getAdvice(prefs));
    if (_rawData != null)
      return _buildResult(_rawData!, prefs, bg, bgCard, bgSoft, border, text,
          textSoft, muted, accent, accentDim, danger);
    return _buildForm(prefs, bgCard, bgSoft, border, text, textSoft, muted,
        accent, accentDim);
  }

  // ─────────────────────────────────────────────────────────
  // FORM
  // ─────────────────────────────────────────────────────────
  Widget _buildForm(
    Map<String, dynamic>? prefs,
    Color bgCard,
    Color bgSoft,
    Color border,
    Color text,
    Color textSoft,
    Color muted,
    Color accent,
    Color accentDim,
  ) {
    final calorieTarget = _getCalorieTarget(prefs);
    final fitnessGoal =
        prefs?['fitness_goal'] as String? ?? 'maintenance';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (prefs != null) ...[
          _infoChip(
            icon: Icons.local_fire_department_outlined,
            text: 'Kalori hedefin: $calorieTarget kcal',
            accent: accent,
            accentDim: accentDim,
            textColor: text,
          ),
          const SizedBox(height: 10),
          _infoChip(
            icon: Icons.track_changes,
            text:
                'Profilindeki hedefin kullanılıyor: ${_goalLabel(fitnessGoal)} ✓',
            accent: accent,
            accentDim: accentDim,
            textColor: text,
          ),
          const SizedBox(height: 20),
        ],
        Container(
          decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border)),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Diyet Tavsiyesi neler içerir?',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: text)),
              const SizedBox(height: 12),
              ...[
                [
                  '🗓',
                  '7 günlük haftalık menü',
                  'Her gün kahvaltı, öğle, akşam ve ara öğün önerisi'
                ],
                [
                  '⚖️',
                  'Kişisel makro hedefleri',
                  'Protein, karbonhidrat ve yağ dengesi'
                ],
                [
                  '✅',
                  'Önerilen besinler listesi',
                  'Hedefine uygun yiyecekler'
                ],
                [
                  '❌',
                  'Kaçınılacak besinler',
                  'Seni hedefinden uzaklaştırabilecek yiyecekler'
                ],
                [
                  '💾',
                  'Diyet sekmesine kayıt',
                  'Haftalık plan her gün Diyet sekmesinde görünür'
                ],
              ].map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r[0],
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                Text(r[1],
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: text)),
                                Text(r[2],
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: muted,
                                        height: 1.4)),
                              ])),
                        ]),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: bgSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border)),
          child: Row(children: [
            Icon(Icons.info_outline, size: 14, color: muted),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    'Free planda haftada 1 kez kullanılabilir',
                    style: TextStyle(fontSize: 11, color: muted))),
          ]),
        ),
        const SizedBox(height: 20),
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

  // ─────────────────────────────────────────────────────────
  // RESULT — haftalık plan tab sistemi
  // ─────────────────────────────────────────────────────────
  Widget _buildResult(
    Map<String, dynamic> data,
    Map<String, dynamic>? prefs,
    Color bg,
    Color bgCard,
    Color bgSoft,
    Color border,
    Color text,
    Color textSoft,
    Color muted,
    Color accent,
    Color accentDim,
    Color danger,
  ) {
    final recommended =
        List<String>.from(data['recommended_foods'] ?? []);
    final avoid = List<String>.from(data['foods_to_avoid'] ?? []);
    final weeklyPlan =
        data['weekly_plan'] as Map<String, dynamic>? ?? {};
    final macros =
        data['macros'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        // ── Üst özet kartı ──
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: accentDim,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.5))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('🥗', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text('Kişisel Haftalık Beslenme Planın',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: text))),
              ]),
              if (data['summary'] != null) ...[
                const SizedBox(height: 8),
                Text(data['summary'],
                    style: TextStyle(
                        fontSize: 12, color: textSoft, height: 1.4)),
              ],
              if (macros.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (data['daily_calorie_target'] != null)
                      _macroPill(
                          '🔥 ${data['daily_calorie_target']} kcal',
                          accent,
                          text),
                    if (macros['protein_g'] != null) ...[
                      const SizedBox(width: 6),
                      _macroPill('P: ${macros['protein_g']}g',
                          const Color(0xFF4CAF50), text),
                    ],
                    if (macros['carbs_g'] != null) ...[
                      const SizedBox(width: 6),
                      _macroPill('K: ${macros['carbs_g']}g',
                          const Color(0xFF2196F3), text),
                    ],
                    if (macros['fat_g'] != null) ...[
                      const SizedBox(width: 6),
                      _macroPill('Y: ${macros['fat_g']}g',
                          const Color(0xFFFF9800), text),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Gün tabları ──
        if (_tabController != null && weeklyPlan.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border)),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: accent,
              unselectedLabelColor: muted,
              indicatorColor: accent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500),
              tabs: List.generate(_days.length, (i) {
                final isToday = i == _todayIndex;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_dayLabels[i]),
                      if (isToday) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),

          // ── Tab içerikleri ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _days.map((day) {
                final dayData =
                    weeklyPlan[day] as Map<String, dynamic>? ?? {};
                return ListView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  children: [
                    ..._mealLabels.entries.map((e) {
                      final mealKey = e.key;
                      final mealLabel = e.value;
                      final mealText =
                          dayData[mealKey] as String? ?? '';
                      return _mealCard(
                          mealLabel, mealText, bgCard, border,
                          text, muted, accent);
                    }),
                    const SizedBox(height: 12),

                    // Önerilen / kaçınılacak besinler
                    if (recommended.isNotEmpty) ...[
                      _sectionTitle('✅ Önerilen Besinler', text),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(color: border)),
                        child: _foodGrid(
                            recommended,
                            accent,
                            accent.withOpacity(0.1),
                            accent.withOpacity(0.4),
                            text),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (avoid.isNotEmpty) ...[
                      _sectionTitle('❌ Kaçınılacak Besinler', text),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(color: border)),
                        child: _foodGrid(
                            avoid,
                            danger,
                            danger.withOpacity(0.1),
                            danger.withOpacity(0.4),
                            text),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Kaydet butonu
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _showSaveDialog(data,
                            accent, bg, bgCard, border, text,
                            muted, danger),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                            elevation: 0),
                        child: const Text('💾  Düzenle & Kaydet',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    aiOutlineBtn(
                        'Yeni Tavsiye Al',
                        Icons.arrow_back,
                        accent,
                        border,
                        () => setState(() => _rawData = null)),
                  ],
                );
              }).toList(),
            ),
          ),
        ] else ...[
          // weekly_plan yoksa eski davranış
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(children: [
                const SizedBox(height: 12),
                if (recommended.isNotEmpty)
                  _foodSection('✅ Önerilen Besinler', recommended,
                      accent, bgCard, border, text, danger, false),
                if (avoid.isNotEmpty)
                  _foodSection('❌ Kaçınılacak Besinler', avoid,
                      danger, bgCard, border, text, danger, true),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _showSaveDialog(data, accent,
                        bg, bgCard, border, text, muted, danger),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14)),
                        elevation: 0),
                    child: const Text('💾  Düzenle & Kaydet',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
                aiOutlineBtn(
                    'Yeni Tavsiye Al',
                    Icons.arrow_back,
                    accent,
                    border,
                    () => setState(() => _rawData = null)),
              ]),
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // YARDIMCI WİDGET'LAR
  // ─────────────────────────────────────────────────────────

  Widget _mealCard(String label, String content, Color bgCard,
      Color border, Color text, Color muted, Color accent) {
    final items = content.isEmpty
        ? <String>[]
        : content.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accent)),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text('Belirtilmemiş',
              style: TextStyle(fontSize: 13, color: muted))
        else
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, right: 8),
                child: Container(
                  width: 5, height: 5,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
              ),
              Expanded(
                child: Text(item,
                    style: TextStyle(fontSize: 13, color: text, height: 1.4)),
              ),
            ]),
          )),
      ]),
    );
  }

  Widget _macroPill(String label, Color color, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withOpacity(0.4))),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }

  Widget _sectionTitle(String title, Color text) {
    return Text(title,
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: text));
  }

  Widget _infoChip({
    required IconData icon,
    required String text,
    required Color accent,
    required Color accentDim,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: accentDim,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.3))),
      child: Row(children: [
        Icon(icon, color: accent, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _foodSection(
    String title,
    List<String> foods,
    Color color,
    Color bgCard,
    Color border,
    Color text,
    Color danger,
    bool isDanger,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border)),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: text)),
        const SizedBox(height: 12),
        _foodGrid(foods, color, color.withOpacity(0.1),
            color.withOpacity(0.4), text),
      ]),
    );
  }

  Widget _foodGrid(List<String> foods, Color color, Color bgColor,
      Color borderColor, Color text) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: foods
          .map((f) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: borderColor)),
                child: Text(f,
                    style: TextStyle(
                        fontSize: 12,
                        color: text,
                        fontWeight: FontWeight.w500)),
              ))
          .toList(),
    );
  }

  Widget _buildLimitCard(
      Color accentDim, Color accent, Color border, Color text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
              color: accentDim,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent)),
          padding: const EdgeInsets.all(24),
          child:
              Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⏳', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Haftalık Limit',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: accent)),
            const SizedBox(height: 8),
            Text(
                'Bu haftaki diyet tavsiyesi hakkını kullandın.\nYeni hafta başında tekrar kullanılabilir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: text, height: 1.5)),
          ]),
        ),
      ),
    );
  }
}