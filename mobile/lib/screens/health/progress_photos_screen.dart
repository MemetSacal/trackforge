// ── progress_photos_screen.dart (v1.1) — İlerleme Fotoğrafları ──
// Backend file_uploads (file_type="photo") hazırdı; bu ekran onu kullanır.
// Haftalık fotoğraf çek, ızgarada gör, iki tarihi yan yana karşılaştır.
// "Terazi yalan söyler, ayna söylemez" — kilo sabitken görünüm değişimini gösterir.
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../app.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';

final progressPhotosProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ApiClient.instance.get(Endpoints.photos);
    final list = (res.data as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    // Eskiden yeniye sırala (karşılaştırma "önce/sonra" için)
    list.sort((a, b) => (a['created_at'] ?? '').toString().compareTo((b['created_at'] ?? '').toString()));
    return list;
  } catch (_) { return []; }
});

class ProgressPhotosScreen extends ConsumerStatefulWidget {
  const ProgressPhotosScreen({super.key});
  @override
  ConsumerState<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends ConsumerState<ProgressPhotosScreen> {
  final _picker = ImagePicker();
  bool _uploading = false;
  final List<String> _selectedForCompare = []; // karşılaştırma için seçilen 2 id

  // Basit bellek içi cache — aynı foto tekrar tekrar inmesin
  final Map<String, Uint8List> _imageCache = {};

  Future<Uint8List?> _loadImage(String fileId) async {
    if (_imageCache.containsKey(fileId)) return _imageCache[fileId];
    try {
      final res = await ApiClient.instance.get(
        '/files/download/$fileId',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(res.data as List<int>);
      _imageCache[fileId] = bytes;
      return bytes;
    } catch (_) { return null; }
  }

  Future<void> _addPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, maxWidth: 1080, maxHeight: 1080, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes,
            filename: 'progress.jpg', contentType: DioMediaType('image', 'jpeg')),
        'description': DateTime.now().toIso8601String().split('T').first,
      });
      await ApiClient.instance.post(Endpoints.photos, data: form);
      ref.invalidate(progressPhotosProvider);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf yüklenemedi, tekrar dene')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg     = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard = isDark ? const Color(0xFF141620) : Colors.white;
    final border = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text   = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final muted  = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);

    final photosAsync = ref.watch(progressPhotosProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0, foregroundColor: text,
        title: const Text('İlerleme Fotoğrafları'),
        actions: [
          if (_selectedForCompare.length == 2)
            TextButton(
              onPressed: () => _showCompare(accent, bgCard, text, muted),
              child: Text('Karşılaştır', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent, foregroundColor: Colors.black,
        onPressed: _uploading ? null : () => _pickSource(),
        icon: _uploading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : const Icon(Icons.add_a_photo_rounded),
        label: Text(_uploading ? 'Yükleniyor...' : 'Fotoğraf Ekle'),
      ),
      body: photosAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: accent)),
        error: (_, __) => Center(child: Text('Yüklenemedi', style: TextStyle(color: muted))),
        data: (photos) {
          if (photos.isEmpty) return _emptyState(text, muted);
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                _selectedForCompare.isEmpty
                    ? 'İki fotoğrafa dokunup "Karşılaştır" ile yan yana gör'
                    : '${_selectedForCompare.length}/2 seçildi',
                style: TextStyle(fontSize: 12, color: muted),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75,
                ),
                itemCount: photos.length,
                itemBuilder: (_, i) {
                  final p = photos[i];
                  final id = p['id'].toString();
                  final selected = _selectedForCompare.contains(id);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (selected) {
                        _selectedForCompare.remove(id);
                      } else if (_selectedForCompare.length < 2) {
                        _selectedForCompare.add(id);
                      }
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? accent : border,
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            child: _photoThumb(id, muted),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            (p['description'] ?? (p['created_at'] ?? '').toString().split('T').first).toString(),
                            style: TextStyle(fontSize: 11, color: muted),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _photoThumb(String id, Color muted) => FutureBuilder<Uint8List?>(
    future: _loadImage(id),
    builder: (_, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return Center(child: SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: muted)));
      }
      if (snap.data == null) return Center(child: Icon(Icons.broken_image, color: muted));
      return Image.memory(snap.data!, fit: BoxFit.cover, width: double.infinity);
    },
  );

  Widget _emptyState(Color text, Color muted) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('📸', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('İlk fotoğrafını ekle',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: text)),
        const SizedBox(height: 8),
        Text('Haftada bir fotoğraf çek. Zamanla değişimini yan yana görmek '
             'en güçlü motivasyon — terazi göstermese bile.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.5, color: muted)),
      ]),
    ),
  );

  void _pickSource() {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          leading: const Icon(Icons.camera_alt_rounded),
          title: const Text('Kamera'),
          onTap: () { Navigator.pop(ctx); _addPhoto(ImageSource.camera); },
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_rounded),
          title: const Text('Galeri'),
          onTap: () { Navigator.pop(ctx); _addPhoto(ImageSource.gallery); },
        ),
      ]),
    ));
  }

  void _showCompare(Color accent, Color bgCard, Color text, Color muted) {
    final idA = _selectedForCompare[0];
    final idB = _selectedForCompare[1];
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: bgCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Karşılaştırma', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: text)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Column(children: [
              Text('Önce', style: TextStyle(fontSize: 12, color: muted)),
              const SizedBox(height: 6),
              AspectRatio(aspectRatio: 0.75, child: ClipRRect(
                borderRadius: BorderRadius.circular(12), child: _photoThumb(idA, muted))),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(children: [
              Text('Sonra', style: TextStyle(fontSize: 12, color: accent)),
              const SizedBox(height: 6),
              AspectRatio(aspectRatio: 0.75, child: ClipRRect(
                borderRadius: BorderRadius.circular(12), child: _photoThumb(idB, muted))),
            ])),
          ]),
          const SizedBox(height: 12),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kapat')),
        ]),
      ),
    ));
  }
}
