// ── su_tab.dart ─────────────────────────────────────────
// Günlük su takibi ekranı.
// GET /water/date/{date} → bugünkü su logunu çeker
// POST /water → yeni su ekler
// Hedef: günlük 2800ml (varsayılan)
// Progress bar ile görsel olarak gösterilir.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';

// ── PROVIDER ────────────────────────────────────────────
final todayWaterProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.instance.get(
      '${Endpoints.water}/date/${TFDateUtils.today()}',
    );
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return null;
  }
});

// ── SU TAB ──────────────────────────────────────────────
class SuTab extends ConsumerStatefulWidget {
  const SuTab({super.key});

  @override
  ConsumerState<SuTab> createState() => _SuTabState();
}

class _SuTabState extends ConsumerState<SuTab> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _addWater(int currentAmount) async {
    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final waterAsync = ref.read(todayWaterProvider);
      final existingLog = waterAsync.value;

      if (existingLog != null) {
        // Log var — mevcut miktara ekle, PUT ile güncelle
        // num cast — backend'den gelen değerler LinkedMap'ten num olarak gelir
        await ApiClient.instance.put(
          '${Endpoints.water}/${existingLog['id']}',
          data: {
            'amount_ml': currentAmount + amount,
            'target_ml': (existingLog['target_ml'] as num?)?.toInt() ?? 2800,
          },
        );
      } else {
        // Log yok — yeni oluştur
        await ApiClient.instance.post(
          Endpoints.water,
          data: {
            'date': TFDateUtils.today(),
            'amount_ml': amount,
            'target_ml': 2800,
          },
        );
      }

      _amountController.clear();
      ref.invalidate(todayWaterProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Su eklenirken hata oluştu')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waterAsync = ref.watch(todayWaterProvider);

    return waterAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Veri yüklenemedi')),
      data: (waterLog) {
        // num cast — LinkedMap'ten gelen değerler int değil num olabilir
        final current = (waterLog?['amount_ml'] as num?)?.toInt() ?? 0;
        final target = (waterLog?['target_ml'] as num?)?.toInt() ?? 2800;
        final progress = (current / target).clamp(0.0, 1.0);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ── DAİRESEL PROGRESS ─────────────────────
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 16,
                        backgroundColor: Theme.of(context)
                            .primaryColor
                            .withOpacity(0.15),
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💧', style: TextStyle(fontSize: 32)),
                        Text(
                          '${(current / 1000).toStringAsFixed(1)}L',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Hedef: ${(target / 1000).toStringAsFixed(1)}L',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── HIZLI EKLE BUTONLARI ──────────────────
              const Text(
                'Hızlı Ekle',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _QuickAddButton(
                    label: '150ml',
                    onTap: () {
                      _amountController.text = '150';
                      _addWater(current);
                    },
                  ),
                  _QuickAddButton(
                    label: '250ml',
                    onTap: () {
                      _amountController.text = '250';
                      _addWater(current);
                    },
                  ),
                  _QuickAddButton(
                    label: '500ml',
                    onTap: () {
                      _amountController.text = '500';
                      _addWater(current);
                    },
                  ),
                  _QuickAddButton(
                    label: '1L',
                    onTap: () {
                      _amountController.text = '1000';
                      _addWater(current);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── MANUEL GİRİŞ ──────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Miktar (ml)',
                        prefixIcon: Icon(Icons.water_drop_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _addWater(current),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 52),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Ekle'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── GÜNLÜK ÖZET ───────────────────────────
              if (waterLog != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bugün',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(context)
                              .primaryColor
                              .withOpacity(0.15),
                          color: Theme.of(context).primaryColor,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$current ml içildi'),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Hızlı ekle butonu
class _QuickAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickAddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}