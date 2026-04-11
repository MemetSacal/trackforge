// ── olcum_tab.dart ──────────────────────────────────────
// Vücut ölçümleri ekranı.
// GET /measurements → son ölçümü çeker
// POST /measurements → yeni ölçüm ekler
// Kilo, vücut yağ %, kas kütlesi, bel, göğüs, kalça, kol, bacak

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';

// ── PROVIDER ────────────────────────────────────────────
// Son ölçümü çeker — tarih aralığı bugünden 30 gün geriye
final measurementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(
      Endpoints.measurements,
      queryParameters: {
        'from': TFDateUtils.toApiDate(
          DateTime.now().subtract(const Duration(days: 30)),
        ),
        'to': TFDateUtils.today(),
      },
    );
    final list = response.data as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) {
    return [];
  }
});

// ── ÖLÇÜM TAB ───────────────────────────────────────────
class OlcumTab extends ConsumerStatefulWidget {
  const OlcumTab({super.key});

  @override
  ConsumerState<OlcumTab> createState() => _OlcumTabState();
}

class _OlcumTabState extends ConsumerState<OlcumTab> {
  // Her ölçüm için ayrı controller
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _muscleMassController = TextEditingController();
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _hipController = TextEditingController();
  final _armController = TextEditingController();
  final _legController = TextEditingController();

  bool _isLoading = false;
  bool _showForm = false; // Form göster/gizle toggle

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _muscleMassController.dispose();
    _waistController.dispose();
    _chestController.dispose();
    _hipController.dispose();
    _armController.dispose();
    _legController.dispose();
    super.dispose();
  }

  // Ölçüm kaydet — POST /measurements
  Future<void> _saveMeasurement() async {
    setState(() => _isLoading = true);

    try {
      await ApiClient.instance.post(
        Endpoints.measurements,
        data: {
          'date': TFDateUtils.today(),
          // tryParse → boş bırakılan alanlar null gönderilir
          'weight_kg': double.tryParse(_weightController.text),
          'body_fat_pct': double.tryParse(_bodyFatController.text),
          'muscle_mass_kg': double.tryParse(_muscleMassController.text),
          'waist_cm': double.tryParse(_waistController.text),
          'chest_cm': double.tryParse(_chestController.text),
          'hip_cm': double.tryParse(_hipController.text),
          'arm_cm': double.tryParse(_armController.text),
          'leg_cm': double.tryParse(_legController.text),
        },
      );

      // Formu kapat, provider'ı yenile
      setState(() => _showForm = false);
      ref.invalidate(measurementsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ölçüm kaydedildi ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt sırasında hata oluştu')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final measurementsAsync = ref.watch(measurementsProvider);

    return measurementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Veri yüklenemedi')),
      data: (measurements) {
        // En son ölçüm — liste boş değilse ilk eleman
        final latest = measurements.isNotEmpty ? measurements.last : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── SON ÖLÇÜM KARTI ───────────────────────
              if (latest != null) ...[
                const Text(
                  'Son Ölçüm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Tarih
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              latest['date'] ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Ana metrik — kilo büyük göster
                        if (latest['weight_kg'] != null)
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  '${latest['weight_kg']} kg',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Text(
                                  'Kilo',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Diğer metrikler — 2 sütun grid
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (latest['body_fat_pct'] != null)
                              _MetricChip(
                                label: 'Yağ %',
                                value: '${latest['body_fat_pct']}%',
                              ),
                            if (latest['muscle_mass_kg'] != null)
                              _MetricChip(
                                label: 'Kas',
                                value: '${latest['muscle_mass_kg']} kg',
                              ),
                            if (latest['waist_cm'] != null)
                              _MetricChip(
                                label: 'Bel',
                                value: '${latest['waist_cm']} cm',
                              ),
                            if (latest['chest_cm'] != null)
                              _MetricChip(
                                label: 'Göğüs',
                                value: '${latest['chest_cm']} cm',
                              ),
                            if (latest['hip_cm'] != null)
                              _MetricChip(
                                label: 'Kalça',
                                value: '${latest['hip_cm']} cm',
                              ),
                            if (latest['arm_cm'] != null)
                              _MetricChip(
                                label: 'Kol',
                                value: '${latest['arm_cm']} cm',
                              ),
                            if (latest['leg_cm'] != null)
                              _MetricChip(
                                label: 'Bacak',
                                value: '${latest['leg_cm']} cm',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── YENİ ÖLÇÜM BUTONU ─────────────────────
              ElevatedButton.icon(
                onPressed: () => setState(() => _showForm = !_showForm),
                icon: Icon(_showForm ? Icons.close : Icons.add),
                label: Text(_showForm ? 'İptal' : 'Yeni Ölçüm Ekle'),
              ),

              // ── ÖLÇÜM FORMU ───────────────────────────
              // AnimatedContainer — form açılıp kapanırken animasyon yapar
              if (_showForm) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yeni Ölçüm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Boş bırakılabilir — sadece girilen değerler kaydedilir
                        _MeasurementField(
                          controller: _weightController,
                          label: 'Kilo (kg)',
                          icon: Icons.monitor_weight_outlined,
                        ),
                        _MeasurementField(
                          controller: _bodyFatController,
                          label: 'Vücut Yağ % ',
                          icon: Icons.percent,
                        ),
                        _MeasurementField(
                          controller: _muscleMassController,
                          label: 'Kas Kütlesi (kg)',
                          icon: Icons.fitness_center,
                        ),
                        _MeasurementField(
                          controller: _waistController,
                          label: 'Bel (cm)',
                          icon: Icons.straighten,
                        ),
                        _MeasurementField(
                          controller: _chestController,
                          label: 'Göğüs (cm)',
                          icon: Icons.straighten,
                        ),
                        _MeasurementField(
                          controller: _hipController,
                          label: 'Kalça (cm)',
                          icon: Icons.straighten,
                        ),
                        _MeasurementField(
                          controller: _armController,
                          label: 'Kol (cm)',
                          icon: Icons.straighten,
                        ),
                        _MeasurementField(
                          controller: _legController,
                          label: 'Bacak (cm)',
                          icon: Icons.straighten,
                        ),

                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveMeasurement,
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text('Kaydet'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// Metrik chip — küçük bilgi kartı
class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// Ölçüm input alanı
class _MeasurementField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  const _MeasurementField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}