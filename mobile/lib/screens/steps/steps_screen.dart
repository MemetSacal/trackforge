// ── steps_screen.dart ───────────────────────────────────
// Adım sayar ekranı.
// GET /steps/today → bugünkü adım verisi
// POST /steps → adım ekle (manuel giriş)
// Telefonda pedometer sensörü ile entegrasyon polish aşamasında

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';

final todayStepsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.instance.get(
      '${Endpoints.steps}/date/${TFDateUtils.today()}',
    );
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return null;
  }
});

class StepsScreen extends ConsumerStatefulWidget {
  const StepsScreen({super.key});

  @override
  ConsumerState<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends ConsumerState<StepsScreen> {
  final _stepsController = TextEditingController();
  final _goalController = TextEditingController(text: '10000');
  bool _isLoading = false;

  @override
  void dispose() {
    _stepsController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _saveSteps(Map<String, dynamic>? existing) async {
    final steps = int.tryParse(_stepsController.text);
    if (steps == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir adım sayısı girin')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (existing != null) {
        await ApiClient.instance.put(
          '${Endpoints.steps}/${existing['id']}',
          data: {
            'step_count': steps,
            'goal': int.tryParse(_goalController.text) ?? 10000,
          },
        );
      } else {
        await ApiClient.instance.post(
          Endpoints.steps,
          data: {
            'date': TFDateUtils.today(),
            'step_count': steps,
            'goal': int.tryParse(_goalController.text) ?? 10000,
          },
        );
      }
      ref.invalidate(todayStepsProvider);
      _stepsController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adım kaydedildi ✅')),
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
    final stepsAsync = ref.watch(todayStepsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Adım Sayar')),
      body: stepsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Veri yüklenemedi')),
        data: (stepsData) {
          final stepCount = (stepsData?['step_count'] as num?)?.toInt() ?? 0;
          final goal = (stepsData?['goal'] as num?)?.toInt() ?? 10000;
          final progress = goal > 0
              ? (stepCount / goal).clamp(0.0, 1.0)
              : 0.0;

          if (stepsData != null) {
            _goalController.text = goal.toString();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── ADIM PROGRESS ─────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Dairesel progress göstergesi
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 12,
                                backgroundColor: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.15),
                                color: progress >= 1.0
                                    ? Colors.green
                                    : Theme.of(context).primaryColor,
                              ),
                            ),
                            Column(
                              children: [
                                const Text('👟',
                                    style: TextStyle(fontSize: 32)),
                                Text(
                                  '$stepCount',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Text(
                                  'adım',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          progress >= 1.0
                              ? '🎉 Günlük hedefe ulaştın!'
                              : 'Hedef: $goal adım — ${((1 - progress) * goal).toInt()} adım kaldı',
                          style: TextStyle(
                            color: progress >= 1.0
                                ? Colors.green
                                : Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── MANUEL GİRİŞ ──────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stepsData != null ? 'Güncelle' : 'Adım Gir',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _stepsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Adım sayısı',
                            prefixIcon: Icon(Icons.directions_walk),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _goalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Günlük hedef',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _saveSteps(stepsData),
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Text(stepsData != null
                              ? 'Güncelle'
                              : 'Kaydet'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '💡 Gerçek adım takibi için mobil uygulama gereklidir',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}