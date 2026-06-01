// ── cycle_screen.dart ────────────────────────────────────
// Regl takvimi ekranı.
// GET /cycle → mevcut döngü bilgisi
// POST /cycle → yeni döngü başlat
// PUT /cycle/{id} → döngü güncelle

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';

// ── PROVIDER ────────────────────────────────────────────
final cycleProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.cycle);
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return null;
  }
});

// ── CYCLE SCREEN ────────────────────────────────────────
class CycleScreen extends ConsumerStatefulWidget {
  const CycleScreen({super.key});

  @override
  ConsumerState<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends ConsumerState<CycleScreen> {
  final _cycleLengthController = TextEditingController(text: '28');
  final _periodLengthController = TextEditingController(text: '5');
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _showForm = false;

  @override
  void dispose() {
    _cycleLengthController.dispose();
    _periodLengthController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Faz bilgisine göre renk
  Color _phaseColor(String phase) {
    if (phase.contains('Menstrü')) return Colors.red;
    if (phase.contains('Foliküler')) return Colors.green;
    if (phase.contains('Ovülasyon')) return Colors.orange;
    if (phase.contains('Luteal')) return Colors.purple;
    return Colors.pink;
  }

  // Faz bilgisine göre emoji
  String _phaseEmoji(String phase) {
    if (phase.contains('Menstrü')) return '🔴';
    if (phase.contains('Foliküler')) return '🌱';
    if (phase.contains('Ovülasyon')) return '🌟';
    if (phase.contains('Luteal')) return '🌙';
    return '🌸';
  }

  // Faz bilgisine göre tavsiye
  String _phaseAdvice(String phase) {
    if (phase.contains('Menstrü')) {
      return 'Hafif egzersiz önerilir: yürüyüş, yoga, esneme. Demir açısından zengin besinler tüket.';
    }
    if (phase.contains('Foliküler')) {
      return 'Enerji artıyor! Orta-yoğun antrenman ideal. Protein ağırlıklı beslenme önerilir.';
    }
    if (phase.contains('Ovülasyon')) {
      return 'Zirve performans dönemi! Yoğun antrenman için en iyi zaman. Kalori hedefini biraz artırabilirsin.';
    }
    if (phase.contains('Luteal')) {
      return 'Antrenman yoğunluğunu azalt. Magnezyum açısından zengin yiyecekler tüket. Tatlı isteği normal.';
    }
    return 'Döngünü takip et, AI önerilerin kişiselleşsin.';
  }

  // Validasyon
  String? _validate() {
    final cycleLength = int.tryParse(_cycleLengthController.text);
    final periodLength = int.tryParse(_periodLengthController.text);

    if (cycleLength == null || cycleLength < 20 || cycleLength > 45) {
      return 'Döngü uzunluğu 20–45 gün arasında olmalı';
    }
    if (periodLength == null || periodLength < 2 || periodLength > 10) {
      return 'Adet süresi 2–10 gün arasında olmalı';
    }
    return null;
  }

  Future<void> _saveCycle(Map<String, dynamic>? existing) async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        'cycle_start_date': TFDateUtils.today(),
        'cycle_length_days': int.parse(_cycleLengthController.text),
        'period_length_days': int.parse(_periodLengthController.text),
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      };

      if (existing != null) {
        await ApiClient.instance.put(
          '${Endpoints.cycle}/${existing['id']}',
          data: data,
        );
      } else {
        await ApiClient.instance.post(Endpoints.cycle, data: data);
      }

      setState(() => _showForm = false);
      ref.invalidate(cycleProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Döngü kaydedildi ✅')),
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
    final cycleAsync = ref.watch(cycleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Regl Takvimi')),
      body: cycleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Veri yüklenemedi')),
        data: (cycle) {
          // Mevcut döngü varsa form'a doldur
          if (cycle != null && !_showForm) {
            _cycleLengthController.text =
                (cycle['cycle_length_days'] as num?)?.toString() ?? '28';
            _periodLengthController.text =
                (cycle['period_length_days'] as num?)?.toString() ?? '5';
            _notesController.text = cycle['notes'] as String? ?? '';
          }

          final phase = cycle?['current_phase'] as String? ?? '';
          final currentDay = (cycle?['current_day'] as num?)?.toInt() ?? 0;
          final cycleLength =
              (cycle?['cycle_length_days'] as num?)?.toInt() ?? 28;
          final progress = cycleLength > 0
              ? (currentDay / cycleLength).clamp(0.0, 1.0)
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── MEVCUT FAZ KARTI ──────────────────
                if (cycle != null && phase.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Faz başlığı
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _phaseColor(phase).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Center(
                                  child: Text(
                                    _phaseEmoji(phase),
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      phase,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: _phaseColor(phase),
                                      ),
                                    ),
                                    Text(
                                      'Gün $currentDay / $cycleLength',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor:
                                  _phaseColor(phase).withOpacity(0.15),
                              color: _phaseColor(phase),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Tavsiye kutusu
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  _phaseColor(phase).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💡',
                                    style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _phaseAdvice(phase),
                                    style: const TextStyle(
                                        fontSize: 13, height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── FAZ TAKVİMİ ───────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Döngü Fazları',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _PhaseRow(
                            emoji: '🔴',
                            phase: 'Menstrüasyon',
                            days: 'Gün 1–5',
                            color: Colors.red,
                          ),
                          _PhaseRow(
                            emoji: '🌱',
                            phase: 'Foliküler',
                            days: 'Gün 6–13',
                            color: Colors.green,
                          ),
                          _PhaseRow(
                            emoji: '🌟',
                            phase: 'Ovülasyon',
                            days: 'Gün 14–16',
                            color: Colors.orange,
                          ),
                          _PhaseRow(
                            emoji: '🌙',
                            phase: 'Luteal',
                            days: 'Gün 17–28',
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],

                // ── YENİ / GÜNCELLE BUTONU ────────────
                ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => _showForm = !_showForm),
                  icon: Icon(_showForm ? Icons.close : Icons.add),
                  label: Text(
                    _showForm
                        ? 'İptal'
                        : cycle != null
                            ? 'Döngüyü Güncelle'
                            : 'Döngü Başlat',
                  ),
                ),

                // ── FORM ──────────────────────────────
                if (_showForm) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cycle != null
                                ? 'Döngüyü Güncelle'
                                : 'Yeni Döngü Başlat',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          // Döngü uzunluğu
                          TextField(
                            controller: _cycleLengthController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Döngü uzunluğu (gün) — 20–45',
                              prefixIcon: Icon(Icons.loop),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Adet süresi
                          TextField(
                            controller: _periodLengthController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Adet süresi (gün) — 2–10',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Not
                          TextField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Not (opsiyonel)',
                              prefixIcon: Icon(Icons.note_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _saveCycle(cycle),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : Text(cycle != null
                                    ? 'Güncelle'
                                    : 'Kaydet'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Döngü yoksa boş durum
                if (cycle == null && !_showForm) ...[
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        const Text('🌸',
                            style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        const Text(
                          'Henüz döngü kaydı yok',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Döngü Başlat butonuna tıkla',
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Faz satırı widget'ı
class _PhaseRow extends StatelessWidget {
  final String emoji;
  final String phase;
  final String days;
  final Color color;
  const _PhaseRow({
    required this.emoji,
    required this.phase,
    required this.days,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(phase,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              days,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}