// ── calorie_vision_screen.dart ──────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/auth/token_manager.dart';
import '../../app.dart';
import 'ai_helpers.dart';
import '../profil/profil_screen.dart';
import '../../core/utils/rate_limiter.dart';
import '../takip/diyet_tab.dart';
import '../../core/utils/date_utils.dart';

class CalorieVisionScreen extends ConsumerStatefulWidget {
  const CalorieVisionScreen({super.key});
  @override
  ConsumerState<CalorieVisionScreen> createState() => _CalorieVisionScreenState();
}

class _CalorieVisionScreenState extends ConsumerState<CalorieVisionScreen> {
  Uint8List? _imageBytes;
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _error;
  bool _limitReached = false;
  int  _visionUsed   = 0;
  final _picker = ImagePicker();

  @override
    void initState() {
      super.initState();
      _loadVisionCount();
    }

    Future<void> _loadVisionCount() async {
      final used = await RateLimiter.getVisionUsedToday();
      if (mounted) setState(() => _visionUsed = used);
    }

    Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (picked == null) return;
      setState(() { _imageBytes = null; _result = null; _error = null; });
      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    } catch (_) { setState(() => _error = 'Fotoğraf seçilirken hata oluştu.'); }
  }

  Future<void> _analyze() async {
      if (_imageBytes == null) return;
      final canUse = await RateLimiter.canUseVision();
      if (!canUse) {
        setState(() => _limitReached = true);
        return;
      }
      setState(() { _isLoading = true; _error = null; _result = null; _limitReached = false; });
    try {
      final formData = FormData.fromMap({'file': MultipartFile.fromBytes(_imageBytes!, filename: 'food.jpg', contentType: DioMediaType('image', 'jpeg'))});
      final token = await TokenManager.getAccessToken();
      final response = await ApiClient.instance.post(Endpoints.aiCalorieFromPhoto, data: formData, options: Options(headers: {'Authorization': 'Bearer $token'}));
      // v2: lokal sayacı sunucunun gerçek değeriyle senkronla
      final quota = response.data['quota'];
      if (quota is Map) {
        await RateLimiter.syncFromServer('vision', (quota['used'] as num?)?.toInt() ?? 0);
      } else {
        await RateLimiter.recordVisionUse();
      }
      final used = await RateLimiter.getVisionUsedToday();
      setState(() { _result = Map<String, dynamic>.from(response.data); _visionUsed = used; });
    } on DioException catch (e) {
      // v2: sunucu kotası — yapılandırılmış 429
      final q = QuotaException.fromDioError(e);
      if (q != null) {
        setState(() => _limitReached = true);
        if (mounted) {
          await showQuotaDialog(context,
              message: q.message, isPremium: q.isPremium, resetsInDays: q.resetsInDays);
        }
      } else {
        setState(() => _error = 'Analiz sırasında hata oluştu.');
      }
    } catch (_) { setState(() => _error = 'Analiz sırasında hata oluştu.'); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  // YENİ — vision kalorisini diyet tabına ekle:
  Future<void> _addCaloriesToDiet(int calories) async {
    try {
      // Bugünkü meal_compliance kaydını çek
      final response = await ApiClient.instance.get(
        '${Endpoints.mealCompliance}/date/${TFDateUtils.today()}',
      );
      final existing = Map<String, dynamic>.from(response.data);
      final currentCalories = (existing['calories_consumed'] as num?)?.toDouble() ?? 0;
      final newCalories = currentCalories + calories;

      await ApiClient.instance.put(
        '${Endpoints.mealCompliance}/${existing['id']}',
        data: {'calories_consumed': newCalories},
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$calories kcal diyet planına eklendi ✅')),
      );
    } catch (_) {
      // Bugün kayıt yoksa POST ile yeni oluştur
      try {
        await ApiClient.instance.post(Endpoints.mealCompliance, data: {
          'date':               TFDateUtils.today(),
          'calories_consumed':  calories.toDouble(),
          'complied':           true,
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$calories kcal diyet planına eklendi ✅')),
        );
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diyet planına eklenemedi')),
        );
      }
    }
  }

  Future<void> _showAddToDietDialog(int calories, Color accent, Color bg, Color bgCard, Color border, Color text, Color muted) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Diyet Planına Ekle', style: TextStyle(color: text, fontWeight: FontWeight.w800)),
        content: Text(
          '$calories kcal bugünkü kalori tüketimine eklensin mi?',
          style: TextStyle(color: muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hayır', style: TextStyle(color: muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Evet, Ekle', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) await _addCaloriesToDiet(calories);
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
    final aiName = ref.watch(profilePrefsProvider).value?['ai_name'] as String? ?? 'TrackForge AI';

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          aiHeader(context, ref, isDark, bg, bgCard, border, text, textSoft, muted, accent, 'Fotoğraftan Kalori'),
          Expanded(
            child: _isLoading
                ? aiLoadingState(accent, text, '📸 $aiName yemeği analiz ediyor...')
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    child: Column(
                                          children: [
                                            // Vision kullanım sayacı
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(12), border: Border.all(color: accent.withOpacity(0.3))),
                                              child: Row(children: [
                                                Icon(Icons.camera_alt_outlined, size: 14, color: accent),
                                                const SizedBox(width: 8),
                                                Text('Bugün: $_visionUsed/${RateLimiter.visionDailyLimit} kullanım',
                                                    style: TextStyle(fontSize: 12, color: text, fontWeight: FontWeight.w500)),
                                              ]),
                                            ),
                                            const SizedBox(height: 10),

                                            if (_limitReached) ...[
                                              Container(
                                                decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(20), border: Border.all(color: accent)),
                                                padding: const EdgeInsets.all(20),
                                                child: Column(children: [
                                                  const Text('⏳', style: TextStyle(fontSize: 40)),
                                                  const SizedBox(height: 12),
                                                  Text('Günlük Limit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accent)),
                                                  const SizedBox(height: 8),
                                                  Text('Bugünlük ${RateLimiter.visionDailyLimit} kullanım hakkını doldurdun.\nYarın tekrar kullanılabilir.',
                                                      textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: text, height: 1.5)),
                                                ]),
                                              ),
                                            ] else ...[

                                            // Fotoğraf alanı
                                            GestureDetector(
                          onTap: () => _pick(ImageSource.gallery),
                          child: Container(
                            width: double.infinity, height: 220,
                            decoration: BoxDecoration(
                              color: bgCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _imageBytes != null ? accent : border, width: _imageBytes != null ? 2 : 1),
                            ),
                            child: _imageBytes != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.memory(_imageBytes!, fit: BoxFit.cover))
                                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.add_photo_alternate_outlined, size: 48, color: accent),
                                    const SizedBox(height: 12),
                                    Text('Fotoğraf seçmek için tıkla', style: TextStyle(fontSize: 14, color: text)),
                                    const SizedBox(height: 4),
                                    Text('veya kamera ile çek', style: TextStyle(fontSize: 12, color: muted)),
                                  ]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: aiOutlineBtn('Galeri',  Icons.photo_library_outlined, accent, border, () => _pick(ImageSource.gallery))),
                            const SizedBox(width: 10),
                            Expanded(child: aiOutlineBtn('Kamera',  Icons.camera_alt_outlined,    accent, border, () => _pick(ImageSource.camera))),
                          ],
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          aiErrorCard(_error!, danger, border),
                        ],

                        if (_imageBytes != null && _result == null && !_isLoading) ...[
                          const SizedBox(height: 12),
                          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _analyze, child: const Text('📸  Kaloriyi Hesapla'))),
                        ],

                        if (_result != null) ...[
                          const SizedBox(height: 16),
                          // Toplam kalori
                          Container(
                            decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(20), border: Border.all(color: accent)),
                            padding: const EdgeInsets.all(20),
                            child: Column(children: [
                              const Text('🔥', style: TextStyle(fontSize: 40)),
                              Text('${_result!['total_calories'] ?? '?'} kcal',
                                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: accent)),
                              Text('Tahmini Toplam Kalori', style: TextStyle(fontSize: 12, color: muted)),
                            ]),
                          ),
                          const SizedBox(height: 12),

                          if (_result!['food_items'] != null) ...[
                            Container(
                              decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('🍽️ Tespit Edilen Yiyecekler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                                const SizedBox(height: 10),
                                ...(_result!['food_items'] as List).map((item) {
                                  final m = item is Map ? Map<String, dynamic>.from(item) : {'name': item.toString()};
                                  final name = m['name'] ?? m['food'] ?? item.toString();
                                  final cal  = m['calories'] ?? m['estimated_calories'];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(10)),
                                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Text('$name', style: TextStyle(fontSize: 13, color: text)),
                                      if (cal != null) Text('$cal kcal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
                                    ]),
                                  );
                                }),
                              ]),
                            ),
                            const SizedBox(height: 10),
                          ],

                          if (_result!['macros'] != null) ...[
                            Container(
                              decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Makrolar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                                const SizedBox(height: 10),
                                Wrap(spacing: 8, runSpacing: 8,
                                  children: Map<String, dynamic>.from(_result!['macros']).entries.map((e) {
                                    const macroLabels = {
                                                                          'protein_g':      'Protein',
                                                                          'carbs_g':        'Karbonhidrat',
                                                                          'fat_g':          'Yağ',
                                                                          'fiber_g':        'Lif',
                                                                          'sugar_g':        'Şeker',
                                                                          'saturated_fat_g':'Doymuş Yağ',
                                                                          'protein':        'Protein',
                                                                          'carbs':          'Karbonhidrat',
                                                                          'fat':            'Yağ',
                                                                          'fiber':          'Lif',
                                                                          'sugar':          'Şeker',
                                                                          'saturated_fat':  'Doymuş Yağ',
                                                                          'calories':       'Kalori',
                                                                        };
                                                                        final label = macroLabels[e.key] ?? e.key
                                                                            .replaceAll('_g', '')
                                                                            .replaceAll('_', ' ');
                                                                        final unit = e.key.endsWith('_g') || macroLabels.containsKey('${e.key}_g') ? 'g' : '';
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(99), border: Border.all(color: border)),
                                      child: Text('$label: ${e.value}$unit', style: TextStyle(fontSize: 12, color: text)),
                                    );
                                  }).toList(),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 10),
                          ],

                          if (_result!['confidence'] != null)
                            Align(alignment: Alignment.centerLeft,
                              child: Text('📊 Güven: ${_result!['confidence']}', style: TextStyle(fontSize: 11, color: muted))),

                          const SizedBox(height: 12),
                          if (_result!['total_calories'] != null) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () => _showAddToDietDialog(
                                  (_result!['total_calories'] as num).toInt(),
                                  accent, bg, bgCard, border, text, muted,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: const Text('➕  Diyet Planına Ekle', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          // v2: 👍/👎 — vision tahmin kalitesini ölçmeye başla
                          AiFeedbackBar(feature: 'vision', accent: accent, muted: muted),
                          aiOutlineBtn('Yeni Fotoğraf', Icons.refresh, accent, border,
                            () => setState(() { _result = null; _imageBytes = null; })),
                        ],
                      ],
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }
}