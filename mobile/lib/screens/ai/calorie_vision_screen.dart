// ── calorie_vision_screen.dart ──────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/auth/token_manager.dart';
import '../../app.dart';
import 'ai_helpers.dart'; // import eklendi

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
  final _picker = ImagePicker();

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
    setState(() { _isLoading = true; _error = null; _result = null; });
    try {
      final formData = FormData.fromMap({'file': MultipartFile.fromBytes(_imageBytes!, filename: 'food.jpg', contentType: DioMediaType('image', 'jpeg'))});
      final token = await TokenManager.getAccessToken();
      final response = await ApiClient.instance.post(Endpoints.aiCalorieFromPhoto, data: formData, options: Options(headers: {'Authorization': 'Bearer $token'}));
      setState(() => _result = Map<String, dynamic>.from(response.data));
    } catch (_) { setState(() => _error = 'Analiz sırasında hata oluştu.'); }
    finally { if (mounted) setState(() => _isLoading = false); }
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
          aiHeader(context, ref, isDark, bg, bgCard, border, text, textSoft, muted, accent, 'Fotoğraftan Kalori'),
          Expanded(
            child: _isLoading
                ? aiLoadingState(accent, text, '📸 Claude yemeği analiz ediyor...')
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    child: Column(
                      children: [
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
                                  children: Map<String, dynamic>.from(_result!['macros']).entries.map((e) =>
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(99), border: Border.all(color: border)),
                                      child: Text('${e.key}: ${e.value}', style: TextStyle(fontSize: 12, color: text)))
                                  ).toList(),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 10),
                          ],

                          if (_result!['confidence'] != null)
                            Align(alignment: Alignment.centerLeft,
                              child: Text('📊 Güven: ${_result!['confidence']}', style: TextStyle(fontSize: 11, color: muted))),

                          const SizedBox(height: 12),
                          aiOutlineBtn('Yeni Fotoğraf', Icons.refresh, accent, border,
                            () => setState(() { _result = null; _imageBytes = null; })),
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