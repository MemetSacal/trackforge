// ── alisveris_screen.dart ───────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../app.dart';

final shoppingListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.shopping);
    final data = response.data['items'] as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) { return []; }
});

class AlisverisScreen extends ConsumerStatefulWidget {
  const AlisverisScreen({super.key});
  @override
  ConsumerState<AlisverisScreen> createState() => _AlisverisScreenState();
}

class _AlisverisScreenState extends ConsumerState<AlisverisScreen> {
  final _itemController     = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  bool _isAdding = false;

  @override
  void dispose() { _itemController.dispose(); _quantityController.dispose(); super.dispose(); }

  Future<void> _addItem(String name, {String? barcode}) async {
    if (name.isEmpty) return;
    setState(() => _isAdding = true);
    try {
      await ApiClient.instance.post(Endpoints.shopping, data: {
        'name': name,
        'quantity': _quantityController.text.isEmpty ? '1' : _quantityController.text,
        if (barcode != null) 'notes': barcode,
      });
      _itemController.clear();
      _quantityController.text = '1';
      ref.invalidate(shoppingListProvider);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün eklenemedi')));
    } finally { if (mounted) setState(() => _isAdding = false); }
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    try {
      await ApiClient.instance.put('${Endpoints.shopping}/${item['id']}',
          data: {'is_completed': !(item['is_completed'] as bool? ?? false)});
      ref.invalidate(shoppingListProvider);
    } catch (_) {}
  }

  Future<void> _delete(String id) async {
    try {
      await ApiClient.instance.delete('${Endpoints.shopping}/$id');
      ref.invalidate(shoppingListProvider);
    } catch (_) {}
  }

  Future<void> _openScanner() async {
    final result = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const _BarcodeScanner()));
    if (result != null && mounted) {
      try {
        final response = await ApiClient.instance.get('${Endpoints.barcode}/$result');
        final productName = response.data['product_name'] as String? ?? result;
        _itemController.text = productName;
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ürün bulundu: $productName')));
      } catch (_) {
        _itemController.text = result;
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Barkod: $result')));
      }
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
    final positive = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);

    final listAsync = ref.watch(shoppingListProvider);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── HEADER ──────────────────────────────────
          Container(
            color: bg,
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
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
                    Expanded(child: Text('Alışveriş', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5))),
                    GestureDetector(
                      onTap: _openScanner,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                        child: Icon(Icons.qr_code_scanner, size: 18, color: textSoft),
                      ),
                    ),
                    const SizedBox(width: 8),
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
              ],
            ),
          ),

          // ── İÇERİK ──────────────────────────────────
          Expanded(
            child: listAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: accent)),
              error: (_, __) => Center(child: Text('Liste yüklenemedi', style: TextStyle(color: text))),
              data: (items) {
                final pending   = items.where((i) => !(i['is_completed'] as bool? ?? false)).toList();
                final completed = items.where((i) =>  (i['is_completed'] as bool? ?? false)).toList();
                final sorted    = [...pending, ...completed];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                            padding: const EdgeInsets.all(14),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Toplam Ürün', style: TextStyle(fontSize: 10, color: muted)),
                              Text('${items.length}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: text)),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                            padding: const EdgeInsets.all(14),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Tamamlanan', style: TextStyle(fontSize: 10, color: muted)),
                              Text('${completed.length}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: positive)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('Alışveriş Listesi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                            if (completed.isNotEmpty)
                              GestureDetector(
                                onTap: () async { for (final c in completed) { await _delete(c['id'] as String); } },
                                child: Text('Temizle', style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w600)),
                              ),
                          ]),
                          const SizedBox(height: 14),
                          if (sorted.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(children: [
                                const Text('🛒', style: TextStyle(fontSize: 36)),
                                const SizedBox(height: 8),
                                Text('Liste boş', style: TextStyle(fontSize: 14, color: text)),
                                const SizedBox(height: 4),
                                Text('Ürün ekle veya barkod tara', style: TextStyle(fontSize: 12, color: muted)),
                              ]),
                            )
                          else
                            ...sorted.asMap().entries.map((e) {
                              final item   = e.value;
                              final isDone = item['is_completed'] as bool? ?? false;
                              final name   = item['name'] as String? ?? '';
                              final qty    = item['quantity']?.toString() ?? '1';
                              final cat    = item['category'] as String?;
                              final price  = item['price'];

                              return GestureDetector(
                                onTap: () => _toggle(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22, height: 22,
                                        decoration: BoxDecoration(
                                          color: isDone ? positive : Colors.transparent,
                                          borderRadius: BorderRadius.circular(7),
                                          border: Border.all(color: isDone ? positive : border, width: 2),
                                        ),
                                        child: isDone ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(
                                            qty != '1' ? '$name (x$qty)' : name,
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                              color: isDone ? muted : text,
                                              decoration: isDone ? TextDecoration.lineThrough : null),
                                          ),
                                          if (cat != null) Text(cat, style: TextStyle(fontSize: 11, color: muted)),
                                        ]),
                                      ),
                                      if (price != null) Text('₺$price', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textSoft)),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _delete(item['id'] as String),
                                        child: Container(
                                          width: 28, height: 28,
                                          decoration: BoxDecoration(color: const Color(0x1AFF5555), borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(Icons.delete_outline, size: 15, color: Color(0xFFFF5555)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('+ Ürün Ekle', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _itemController,
                                  style: TextStyle(color: text),
                                  decoration: const InputDecoration(labelText: 'Ürün adı', prefixIcon: Icon(Icons.add_shopping_cart)),
                                  onSubmitted: (_) => _addItem(_itemController.text),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 64,
                                child: TextField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: text),
                                  decoration: const InputDecoration(labelText: 'Adet'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isAdding ? null : () => _addItem(_itemController.text),
                                  child: _isAdding
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                      : const Text('Ekle'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: _openScanner,
                                child: Container(
                                  height: 52, width: 52,
                                  decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(12), border: Border.all(color: accent)),
                                  child: Icon(Icons.qr_code_scanner, color: accent),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodeScanner extends StatefulWidget {
  const _BarcodeScanner();
  @override
  State<_BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<_BarcodeScanner> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Barkod Tara', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.flash_on, color: Colors.white), onPressed: () => _controller.toggleTorch()),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_scanned) return;
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _scanned = true;
                Navigator.pop(context, barcode!.rawValue);
              }
            },
          ),
          Center(
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFFFB020), width: 3), borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const Positioned(
            bottom: 40, left: 0, right: 0,
            child: Text('Barkodu çerçeve içine getir', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 15, shadows: [Shadow(color: Colors.black, blurRadius: 6)])),
          ),
        ],
      ),
    );
  }
}