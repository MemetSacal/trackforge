// ── calorie_vision_screen.dart ──────────────────────────
// Fotoğraftan kalori tahmin ekranı.
// Kullanıcı galeriden fotoğraf seçer.
// POST /ai/calorie-from-photo → multipart/form-data olarak gönderilir.
// Claude Vision fotoğrafı analiz eder — kalori, makro, yemek adı.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/auth/token_manager.dart';

class CalorieVisionScreen extends StatefulWidget {
  const CalorieVisionScreen({super.key});

  @override
  State<CalorieVisionScreen> createState() => _CalorieVisionScreenState();
}

class _CalorieVisionScreenState extends State<CalorieVisionScreen> {
  Uint8List? _imageBytes;
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _error;

  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _result = null;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Fotoğraf seçilirken hata oluştu.');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _result = null;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Fotoğraf çekilirken hata oluştu.');
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          _imageBytes!,
          filename: 'food.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      // Token'ı manuel ekle — multipart'ta interceptor bazen kaçırıyor
      final token = await TokenManager.getAccessToken();

      final response = await ApiClient.instance.post(
        Endpoints.aiCalorieFromPhoto,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      setState(() => _result = Map<String, dynamic>.from(response.data));
    } catch (e) {
      setState(() => _error = 'Analiz sırasında hata oluştu. Tekrar dene.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fotoğraftan Kalori')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── FOTOĞRAF SEÇ ──────────────────────────
            const Text(
              'Yemeğin fotoğrafını ekle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _imageBytes != null
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).dividerColor,
                    width: _imageBytes != null ? 2 : 1,
                  ),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Fotoğraf seçmek için tıkla',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'veya kamera ile çek',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeri'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Kamera'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── ANALİZ BUTONU ─────────────────────────
            if (_imageBytes != null && _result == null && !_isLoading)
              ElevatedButton.icon(
                onPressed: _analyzeImage,
                icon: const Text('📸'),
                label: const Text('Kaloriyi Hesapla'),
              ),

            // ── YÜKLEME ───────────────────────────────
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    CircularProgressIndicator(
                        color: Theme.of(context).primaryColor),
                    const SizedBox(height: 24),
                    const Text('📸 Claude yemeği analiz ediyor...'),
                    const SizedBox(height: 8),
                    Text(
                      'Bu 10-20 saniye sürebilir',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

            // ── HATA ──────────────────────────────────
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style:
                  TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),

            // ── SONUÇ GELDİ ───────────────────────────
            if (_result != null) ...[
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toplam kalori — büyük göster
                      Center(
                        child: Column(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 40)),
                            Text(
                              '${_result!['total_calories'] ?? '?'} kcal',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            Text(
                              'Tahmini Toplam Kalori',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Yemek öğeleri listesi
                      if (_result!['food_items'] != null) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          '🍽️ Tespit Edilen Yiyecekler',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...(_result!['food_items'] as List).map((item) {
                          final itemMap = item is Map
                              ? Map<String, dynamic>.from(item)
                              : {'name': item.toString()};
                          final name = itemMap['name'] ??
                              itemMap['food'] ??
                              item.toString();
                          final cal = itemMap['calories'] ??
                              itemMap['estimated_calories'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text('• $name'),
                                if (cal != null)
                                  Text(
                                    '$cal kcal',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],

                      // Makrolar
                      if (_result!['macros'] != null) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Makrolar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: Map<String, dynamic>.from(
                            _result!['macros'],
                          )
                              .entries
                              .map((e) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${e.key}: ${e.value}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ))
                              .toList(),
                        ),
                      ],

                      // Güven skoru
                      if (_result!['confidence'] != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          '📊 Güven: ${_result!['confidence']}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],

                      // Notlar
                      if (_result!['notes'] != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '⚠️ ${_result!['notes']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _result = null;
                  _imageBytes = null;
                }),
                icon: const Icon(Icons.refresh),
                label: const Text('Yeni Fotoğraf'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}