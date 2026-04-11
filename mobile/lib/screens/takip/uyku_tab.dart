// ── uyku_tab.dart ───────────────────────────────────────
// Günlük uyku takibi ekranı.
// GET /sleep/date/{date} → bugünkü uyku logunu çeker
// POST /sleep → yeni uyku logu ekler
// PUT /sleep/{id} → mevcut logu günceller
// Uyku saati, kalkış saati, kalite puanı (1-10) kaydedilir.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';

// ── PROVIDER ────────────────────────────────────────────
final todaySleepProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.instance.get(
      '${Endpoints.sleep}/date/${TFDateUtils.today()}',
    );
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return null;
  }
});

// ── UYKU TAB ────────────────────────────────────────────
class UykuTab extends ConsumerStatefulWidget {
  const UykuTab({super.key});

  @override
  ConsumerState<UykuTab> createState() => _UykuTabState();
}

class _UykuTabState extends ConsumerState<UykuTab> {
  // Uyku ve kalkış saatleri — TimeOfDay Flutter'ın saat tipi
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  int _qualityScore = 7; // 1-10 arası kalite puanı
  bool _isLoading = false;

  // TimeOfDay → "HH:MM:SS" string'e çevirir (backend bu formatı bekler)
  String _timeToString(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  // Uyku süresini saat olarak hesaplar
  double _calculateDuration() {
    final sleepMinutes = _sleepTime.hour * 60 + _sleepTime.minute;
    var wakeMinutes = _wakeTime.hour * 60 + _wakeTime.minute;
    // Gece yarısını geçen uyku için düzeltme
    if (wakeMinutes <= sleepMinutes) wakeMinutes += 24 * 60;
    return (wakeMinutes - sleepMinutes) / 60;
  }

  // Saat seçici dialog — Flutter'ın yerleşik time picker'ı
  Future<void> _pickTime(bool isSleep) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isSleep ? _sleepTime : _wakeTime,
    );
    if (picked != null) {
      setState(() {
        if (isSleep) {
          _sleepTime = picked;
        } else {
          _wakeTime = picked;
        }
      });
    }
  }

  // Uyku logu kaydet
  Future<void> _saveSleep(Map<String, dynamic>? existingLog) async {
    setState(() => _isLoading = true);

    try {
      final data = {
        'date': TFDateUtils.today(),
        'sleep_time': _timeToString(_sleepTime),
        'wake_time': _timeToString(_wakeTime),
        'duration_hours': _calculateDuration(),
        'quality_score': _qualityScore,
      };

      if (existingLog != null) {
        // Log var — güncelle
        await ApiClient.instance.put(
          '${Endpoints.sleep}/${existingLog['id']}',
          data: {
            'sleep_time': _timeToString(_sleepTime),
            'wake_time': _timeToString(_wakeTime),
            'duration_hours': _calculateDuration(),
            'quality_score': _qualityScore,
          },
        );
      } else {
        // Log yok — oluştur
        await ApiClient.instance.post(Endpoints.sleep, data: data);
      }

      ref.invalidate(todaySleepProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uyku logu kaydedildi ✅')),
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
    final sleepAsync = ref.watch(todaySleepProvider);

    return sleepAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Veri yüklenemedi')),
      data: (sleepLog) {
        // Mevcut log varsa değerleri doldur
        if (sleepLog != null && !_isLoading) {
          // String → TimeOfDay parse
          final sleepStr = sleepLog['sleep_time'] as String?;
          final wakeStr = sleepLog['wake_time'] as String?;
          if (sleepStr != null) {
            final parts = sleepStr.split(':');
            _sleepTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
          if (wakeStr != null) {
            final parts = wakeStr.split(':');
            _wakeTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
          _qualityScore = (sleepLog['quality_score'] as num?)?.toInt() ?? 7;
        }

        final duration = _calculateDuration();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── UYKU SÜRESİ ÖZET KARTI ───────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('😴', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            '${duration.toStringAsFixed(1)} saat',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Uyku Süresi',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      // Kalite göstergesi
                      Column(
                        children: [
                          Text(
                            _qualityEmoji(_qualityScore),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_qualityScore/10',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Kalite',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── UYKU SAATİ SEÇİCİ ─────────────────────
              const Text(
                'Uyku Saatleri',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Uyuma saati
                  Expanded(
                    child: _TimeCard(
                      label: 'Uyudum',
                      icon: '🌙',
                      time: _sleepTime,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Kalkış saati
                  Expanded(
                    child: _TimeCard(
                      label: 'Kalktım',
                      icon: '☀️',
                      time: _wakeTime,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── KALİTE PUANI ──────────────────────────
              const Text(
                'Uyku Kalitesi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Slider — 1'den 10'a kadar
              Row(
                children: [
                  const Text('1'),
                  Expanded(
                    child: Slider(
                      value: _qualityScore.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9, // 9 bölüm = 10 değer
                      label: '$_qualityScore',
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (value) {
                        setState(() => _qualityScore = value.toInt());
                      },
                    ),
                  ),
                  const Text('10'),
                ],
              ),
              Center(
                child: Text(
                  '${_qualityEmoji(_qualityScore)} $_qualityScore/10',
                  style: const TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 24),

              // ── KAYDET BUTONU ─────────────────────────
              ElevatedButton(
                onPressed: _isLoading ? null : () => _saveSleep(sleepLog),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(sleepLog != null ? 'Güncelle' : 'Kaydet'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Kalite puanına göre emoji döndürür
  String _qualityEmoji(int score) {
    if (score >= 9) return '🌟';
    if (score >= 7) return '😊';
    if (score >= 5) return '😐';
    if (score >= 3) return '😴';
    return '😫';
  }
}

// Saat seçim kartı
class _TimeCard extends StatelessWidget {
  final String label;
  final String icon;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeCard({
    required this.label,
    required this.icon,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // TimeOfDay → okunabilir string
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              '$h:$m',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}