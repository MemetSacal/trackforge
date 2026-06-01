// ── olcum_tab.dart ──────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';

final measurementsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(
      Endpoints.measurements,
      queryParameters: {
        'from': TFDateUtils.toApiDate(
            DateTime.now().subtract(const Duration(days: 30))),
        'to': TFDateUtils.today(),
      },
    );
    final list = response.data as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) {
    return [];
  }
});

class OlcumTab extends ConsumerStatefulWidget {
  const OlcumTab({super.key});

  @override
  ConsumerState<OlcumTab> createState() => _OlcumTabState();
}

class _OlcumTabState extends ConsumerState<OlcumTab> {
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _muscleMassController = TextEditingController();
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _hipController = TextEditingController();
  final _armController = TextEditingController();
  final _legController = TextEditingController();

  bool _isLoading = false;
  bool _showForm = false;

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

  // ── VALİDASYON ──────────────────────────────────────────
  String? _validate() {
    final weight = double.tryParse(_weightController.text);
    final bodyFat = double.tryParse(_bodyFatController.text);
    final muscleMass = double.tryParse(_muscleMassController.text);
    final waist = double.tryParse(_waistController.text);
    final chest = double.tryParse(_chestController.text);
    final hip = double.tryParse(_hipController.text);
    final arm = double.tryParse(_armController.text);
    final leg = double.tryParse(_legController.text);

    // En az bir alan dolu olmalı
    final allEmpty = _weightController.text.isEmpty &&
        _bodyFatController.text.isEmpty &&
        _muscleMassController.text.isEmpty &&
        _waistController.text.isEmpty &&
        _chestController.text.isEmpty &&
        _hipController.text.isEmpty &&
        _armController.text.isEmpty &&
        _legController.text.isEmpty;
    if (allEmpty) return 'En az bir ölçüm girmelisin';

    if (_weightController.text.isNotEmpty) {
      if (weight == null || weight < 30 || weight > 300)
        return 'Kilo 30–300 kg arasında olmalı';
    }
    if (_bodyFatController.text.isNotEmpty) {
      if (bodyFat == null || bodyFat < 1 || bodyFat > 60)
        return 'Vücut yağı %1–60 arasında olmalı';
    }
    if (_muscleMassController.text.isNotEmpty) {
      if (muscleMass == null || muscleMass < 10 || muscleMass > 150)
        return 'Kas kütlesi 10–150 kg arasında olmalı';
    }
    if (_waistController.text.isNotEmpty) {
      if (waist == null || waist < 30 || waist > 200)
        return 'Bel 30–200 cm arasında olmalı';
    }
    if (_chestController.text.isNotEmpty) {
      if (chest == null || chest < 30 || chest > 200)
        return 'Göğüs 30–200 cm arasında olmalı';
    }
    if (_hipController.text.isNotEmpty) {
      if (hip == null || hip < 30 || hip > 200)
        return 'Kalça 30–200 cm arasında olmalı';
    }
    if (_armController.text.isNotEmpty) {
      if (arm == null || arm < 10 || arm > 100)
        return 'Kol 10–100 cm arasında olmalı';
    }
    if (_legController.text.isNotEmpty) {
      if (leg == null || leg < 10 || leg > 120)
        return 'Bacak 10–120 cm arasında olmalı';
    }
    return null;
  }

  Future<void> _saveMeasurement() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiClient.instance.post(Endpoints.measurements, data: {
        'date': TFDateUtils.today(),
        'weight_kg': double.tryParse(_weightController.text),
        'body_fat_pct': double.tryParse(_bodyFatController.text),
        'muscle_mass_kg': double.tryParse(_muscleMassController.text),
        'waist_cm': double.tryParse(_waistController.text),
        'chest_cm': double.tryParse(_chestController.text),
        'hip_cm': double.tryParse(_hipController.text),
        'arm_cm': double.tryParse(_armController.text),
        'leg_cm': double.tryParse(_legController.text),
      });

      setState(() => _showForm = false);
      ref.invalidate(measurementsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ölçüm kaydedildi ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kayıt sırasında hata oluştu')));
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
        final latest =
            measurements.isNotEmpty ? measurements.last : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (latest != null) ...[
                const Text('Son Ölçüm',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(latest['date'] ?? '',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (latest['weight_kg'] != null)
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  '${latest['weight_kg']} kg',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).primaryColor,
                                  ),
                                ),
                                Text('Kilo',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (latest['body_fat_pct'] != null)
                              _MetricChip(
                                  label: 'Yağ %',
                                  value:
                                      '${latest['body_fat_pct']}%'),
                            if (latest['muscle_mass_kg'] != null)
                              _MetricChip(
                                  label: 'Kas',
                                  value:
                                      '${latest['muscle_mass_kg']} kg'),
                            if (latest['waist_cm'] != null)
                              _MetricChip(
                                  label: 'Bel',
                                  value: '${latest['waist_cm']} cm'),
                            if (latest['chest_cm'] != null)
                              _MetricChip(
                                  label: 'Göğüs',
                                  value:
                                      '${latest['chest_cm']} cm'),
                            if (latest['hip_cm'] != null)
                              _MetricChip(
                                  label: 'Kalça',
                                  value: '${latest['hip_cm']} cm'),
                            if (latest['arm_cm'] != null)
                              _MetricChip(
                                  label: 'Kol',
                                  value: '${latest['arm_cm']} cm'),
                            if (latest['leg_cm'] != null)
                              _MetricChip(
                                  label: 'Bacak',
                                  value: '${latest['leg_cm']} cm'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              ElevatedButton.icon(
                onPressed: () =>
                    setState(() => _showForm = !_showForm),
                icon: Icon(_showForm ? Icons.close : Icons.add),
                label: Text(
                    _showForm ? 'İptal' : 'Yeni Ölçüm Ekle'),
              ),

              if (_showForm) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Yeni Ölçüm',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          'En az bir alan zorunludur',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color),
                        ),
                        const SizedBox(height: 16),
                        _MeasurementField(
                            controller: _weightController,
                            label: 'Kilo (kg) — 30–300',
                            icon: Icons.monitor_weight_outlined),
                        _MeasurementField(
                            controller: _bodyFatController,
                            label: 'Vücut Yağ % — 1–60',
                            icon: Icons.percent),
                        _MeasurementField(
                            controller: _muscleMassController,
                            label: 'Kas Kütlesi (kg) — 10–150',
                            icon: Icons.fitness_center),
                        _MeasurementField(
                            controller: _waistController,
                            label: 'Bel (cm) — 30–200',
                            icon: Icons.straighten),
                        _MeasurementField(
                            controller: _chestController,
                            label: 'Göğüs (cm) — 30–200',
                            icon: Icons.straighten),
                        _MeasurementField(
                            controller: _hipController,
                            label: 'Kalça (cm) — 30–200',
                            icon: Icons.straighten),
                        _MeasurementField(
                            controller: _armController,
                            label: 'Kol (cm) — 10–100',
                            icon: Icons.straighten),
                        _MeasurementField(
                            controller: _legController,
                            label: 'Bacak (cm) — 10–120',
                            icon: Icons.straighten),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              _isLoading ? null : _saveMeasurement,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
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
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MeasurementField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  const _MeasurementField(
      {required this.controller,
      required this.label,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
            labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }
}