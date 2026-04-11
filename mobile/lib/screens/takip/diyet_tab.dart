// ── diyet_tab.dart ──────────────────────────────────────
// Günlük kalori ve diyet takibi ekranı.
// Üst kısım: AI'ın önerdiği diyet planı (shared_preferences'tan okunur)
// Alt kısım: Bugünkü kalori takibi (backend'den çekilir)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';

// ── PROVIDER ────────────────────────────────────────────
final todayMealProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.instance.get(
      '${Endpoints.mealCompliance}/date/${TFDateUtils.today()}',
    );
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return null;
  }
});

// ── DİYET TAB ───────────────────────────────────────────
class DiyetTab extends ConsumerStatefulWidget {
  const DiyetTab({super.key});

  @override
  ConsumerState<DiyetTab> createState() => _DiyetTabState();
}

class _DiyetTabState extends ConsumerState<DiyetTab> {
  final _caloriesController = TextEditingController();
  final _targetController = TextEditingController();
  final _notesController = TextEditingController();
  bool _complied = true;
  bool _isLoading = false;

  // AI tavsiyesi
  String? _savedAdvice;
  String? _savedAdviceDate;
  bool _showAdvice = false; // Tavsiye paneli açık/kapalı

  @override
  void initState() {
    super.initState();
    _loadSavedAdvice();
  }

  // Kaydedilmiş AI tavsiyesini yükle
  Future<void> _loadSavedAdvice() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedAdvice = prefs.getString('last_meal_advice');
      _savedAdviceDate = prefs.getString('last_meal_advice_date');
    });
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _targetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveMeal(Map<String, dynamic>? existingLog) async {
    final calories = double.tryParse(_caloriesController.text);
    final target = double.tryParse(_targetController.text);

    if (calories == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kalori miktarını girin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'date': TFDateUtils.today(),
        'complied': _complied,
        'calories_consumed': calories,
        'calories_target': target,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      };

      if (existingLog != null) {
        await ApiClient.instance.put(
          '${Endpoints.mealCompliance}/${existingLog['id']}',
          data: {
            'complied': _complied,
            'calories_consumed': calories,
            'calories_target': target,
            'notes': _notesController.text.isEmpty ? null : _notesController.text,
          },
        );
      } else {
        await ApiClient.instance.post(Endpoints.mealCompliance, data: data);
      }

      _caloriesController.clear();
      _notesController.clear();
      ref.invalidate(todayMealProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diyet logu kaydedildi ✅')),
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
    final mealAsync = ref.watch(todayMealProvider);

    return mealAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Veri yüklenemedi')),
      data: (mealLog) {
        if (mealLog != null) {
          final consumed = (mealLog['calories_consumed'] as num?)?.toDouble();
          final target = (mealLog['calories_target'] as num?)?.toDouble();
          if (consumed != null) _caloriesController.text = consumed.toString();
          if (target != null) _targetController.text = target.toString();
          _complied = mealLog['complied'] as bool? ?? true;
        }

        final consumed = (mealLog?['calories_consumed'] as num?)?.toDouble() ?? 0;
        final target = (mealLog?['calories_target'] as num?)?.toDouble() ?? 0;
        final balance = (mealLog?['calorie_balance'] as num?)?.toDouble() ?? 0;
        final bankBalance = (mealLog?['weekly_bank_balance'] as num?)?.toDouble() ?? 0;
        final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── AI DİYET PLANI KARTI ──────────────────
              if (_savedAdvice != null) ...[
                // Başlık + aç/kapat butonu
                GestureDetector(
                  onTap: () => setState(() => _showAdvice = !_showAdvice),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🥗', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI Diyet Planım',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (_savedAdviceDate != null)
                                Text(
                                  '$_savedAdviceDate tarihinde oluşturuldu',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          _showAdvice
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),

                // Tavsiye içeriği — açıksa göster
                if (_showAdvice) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _savedAdvice!,
                        style: const TextStyle(fontSize: 14, height: 1.6),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
              ] else ...[
                // Henüz tavsiye alınmamış
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      const Text('🥗', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Diyet Planı Yok',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'AI Koç → Diyet Tavsiyesi\'nden plan al',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── KALORİ BANKASI KARTI ──────────────────
              if (mealLog != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bugünkü Kalori',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(context)
                              .primaryColor
                              .withOpacity(0.15),
                          color: progress > 1.0
                              ? Colors.red
                              : Theme.of(context).primaryColor,
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${consumed.toInt()} kcal tüketildi'),
                            Text('Hedef: ${target.toInt()} kcal'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _CalorieBox(
                                label: 'Günlük Fark',
                                value: '${balance > 0 ? '+' : ''}${balance.toInt()}',
                                color: balance <= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CalorieBox(
                                label: 'Haftalık Banka',
                                value: '${bankBalance > 0 ? '+' : ''}${bankBalance.toInt()}',
                                color: bankBalance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── KAYIT FORMU ───────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mealLog != null ? 'Güncelle' : 'Bugünkü Öğünü Kaydet',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _caloriesController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tüketilen Kalori (kcal)',
                          prefixIcon: Icon(Icons.local_fire_department_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _targetController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Hedef Kalori (kcal)',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Diyete uyuldu mu?'),
                          const Spacer(),
                          Switch(
                            value: _complied,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (value) =>
                                setState(() => _complied = value),
                          ),
                          Text(_complied ? '✅' : '❌'),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                        onPressed: _isLoading ? null : () => _saveMeal(mealLog),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(mealLog != null ? 'Güncelle' : 'Kaydet'),
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

// Kalori kutusu
class _CalorieBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _CalorieBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}