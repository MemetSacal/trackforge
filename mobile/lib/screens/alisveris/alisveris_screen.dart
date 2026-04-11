// ── alisveris_screen.dart ───────────────────────────────
// Alışveriş listesi ekranı.
// GET /shopping → liste getir
// POST /shopping → ürün ekle
// PUT /shopping/{id} → tamamlandı işaretle
// DELETE /shopping/{id} → sil
// Barkod tarayıcı ile ürün ekleme

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';

final shoppingListProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.shopping);
    final data = response.data['items'] as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) {
    return [];
  }
});

class AlisverisScreen extends ConsumerStatefulWidget {
  const AlisverisScreen({super.key});

  @override
  ConsumerState<AlisverisScreen> createState() => _AlisverisScreenState();
}

class _AlisverisScreenState extends ConsumerState<AlisverisScreen> {
  final _itemController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  bool _isAdding = false;

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _addItem(String name, {String? barcode}) async {
    if (name.isEmpty) return;
    setState(() => _isAdding = true);
    try {
      await ApiClient.instance.post(
        Endpoints.shopping,
        data: {
          'name': name,
          'quantity': (_quantityController.text.isEmpty ? '1' : _quantityController.text), // int değil string
          if (barcode != null) 'notes': barcode,
        },
      );
      _itemController.clear();
      _quantityController.text = '1';
      ref.invalidate(shoppingListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ürün eklenemedi')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _toggleItem(Map<String, dynamic> item) async {
    try {
      await ApiClient.instance.put(
        '${Endpoints.shopping}/${item['id']}',
        data: {'is_completed': !(item['is_completed'] as bool? ?? false)},
      );
      ref.invalidate(shoppingListProvider);
    } catch (_) {}
  }

  Future<void> _deleteItem(String id) async {
    try {
      await ApiClient.instance.delete('${Endpoints.shopping}/$id');
      ref.invalidate(shoppingListProvider);
    } catch (_) {}
  }

  Future<void> _openScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _BarcodeScanner()),
    );
    if (result != null && mounted) {
      _itemController.text = result;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barkod okundu: $result')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışveriş Listesi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _openScanner,
            tooltip: 'Barkod Tara',
          ),
        ],
      ),
      body: Column(
        children: [

          // ── ÜRÜN EKLEME FORMU ─────────────────────
          // ElevatedButton'a SizedBox ile sabit genişlik vermek zorunlu —
          // Row içinde Expanded olmayan widget sonsuz genişlik alıyor
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _itemController,
                    decoration: const InputDecoration(
                      labelText: 'Ürün adı',
                      prefixIcon: Icon(Icons.add_shopping_cart),
                    ),
                    onSubmitted: (_) => _addItem(_itemController.text),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Adet',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isAdding
                        ? null
                        : () => _addItem(_itemController.text),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    child: _isAdding
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),

          // ── LİSTE ─────────────────────────────────
          Expanded(
            child: listAsync.when(
              loading: () =>
              const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
              const Center(child: Text('Liste yüklenemedi')),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🛒',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        const Text(
                          'Liste boş',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Ürün ekle veya barkod tara',
                          style:
                          Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                final pending = items
                    .where(
                        (i) => !(i['is_completed'] as bool? ?? false))
                    .toList();
                final completed = items
                    .where(
                        (i) => i['is_completed'] as bool? ?? false)
                    .toList();
                final sorted = [...pending, ...completed];

                return ListView.builder(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final item = sorted[index];
                    final isDone =
                        item['is_completed'] as bool? ?? false;
                    final name = item['name'] as String? ?? '';
                    final qty = item['quantity']?.toString() ?? '1';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Checkbox(
                          value: isDone,
                          activeColor:
                          Theme.of(context).primaryColor,
                          onChanged: (_) => _toggleItem(item),
                        ),
                        title: Text(
                          '$name ${qty != '1' ? '(x$qty)' : ''}',
                          style: TextStyle(
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: isDone ? Colors.grey : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              _deleteItem(item['id'] as String),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── BARKOD TARAYICI ─────────────────────────────────────
class _BarcodeScanner extends StatefulWidget {
  const _BarcodeScanner();

  @override
  State<_BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<_BarcodeScanner> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barkod Tara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
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
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: const Text(
              'Barkodu çerçeve içine getir',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 4)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}