// ── meal_advice_screen.dart ─────────────────────────────
// AI diyet tavsiyesi ekranı.
// POST /ai/meal-advice → BMR/TDEE bazlı kişisel beslenme planı
// Kullanıcının profil bilgileri backend'de zaten var,
// sadece hedef ve tercih seçilir.

import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/date_utils.dart';

class MealAdviceScreen extends StatefulWidget {
  const MealAdviceScreen({super.key});

  @override
  State<MealAdviceScreen> createState() => _MealAdviceScreenState();
}

class _MealAdviceScreenState extends State<MealAdviceScreen> {
  String _goal = 'weight_loss';
  int _mealsPerDay = 3;

  String? _advice;
  bool _isLoading = false;
  String? _error;

  final _goals = [
    {'key': 'weight_loss', 'label': '⚡ Kilo Vermek'},
    {'key': 'muscle_gain', 'label': '💪 Kas Kazanmak'},
    {'key': 'maintenance', 'label': '⚖️ Kiloyu Korumak'},
    {'key': 'health', 'label': '🥗 Sağlıklı Beslenmek'},
  ];

  Future<void> _getAdvice() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _advice = null;
    });

    try {
      final response = await ApiClient.instance.post(
        Endpoints.aiMealAdvice,
        data: {
          'calorie_target': _goal == 'weight_loss' ? 1500 :
          _goal == 'muscle_gain' ? 2500 :
          _goal == 'maintenance' ? 2000 : 1800,
        },
      );

      final data = Map<String, dynamic>.from(response.data);

      // Tüm alanları birleştir
      final buffer = StringBuffer();

      if (data['summary'] != null)
        buffer.writeln('📋 Özet\n${data['summary']}\n');

      if (data['daily_calorie_target'] != null)
        buffer.writeln('🔥 Günlük Kalori Hedefi: ${data['daily_calorie_target']} kcal\n');

      if (data['macros'] != null) {
        buffer.writeln('⚖️ Makrolar');
        final macros = Map<String, dynamic>.from(data['macros']);
        macros.forEach((k, v) => buffer.writeln('  • $k: $v'));
        buffer.writeln();
      }

      if (data['meal_suggestions'] != null) {
        buffer.writeln('🍽️ Öğün Önerileri');
        final meals = Map<String, dynamic>.from(data['meal_suggestions']);
        meals.forEach((k, v) => buffer.writeln('  $k: $v'));
        buffer.writeln();
      }

      if (data['recommended_foods'] != null) {
        final foods = data['recommended_foods'] as List;
        buffer.writeln('✅ Önerilen Besinler');
        for (final f in foods) buffer.writeln('  • $f');
        buffer.writeln();
      }

      if (data['foods_to_avoid'] != null) {
        final avoid = data['foods_to_avoid'] as List;
        buffer.writeln('❌ Kaçınılacak Besinler');
        for (final f in avoid) buffer.writeln('  • $f');
        buffer.writeln();
      }

      if (data['warnings'] != null) {
        final warnings = data['warnings'] as List;
        if (warnings.isNotEmpty) {
          buffer.writeln('⚠️ Uyarılar');
          for (final w in warnings) buffer.writeln('  • $w');
        }
      }

      // Tavsiyeyi shared_preferences'a kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_meal_advice', buffer.toString().trim());
      await prefs.setString('last_meal_advice_date', TFDateUtils.today());

      setState(() => _advice = buffer.toString().trim());
    } catch (e) {
      setState(() => _error = 'Tavsiye alınırken hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diyet Tavsiyesi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_advice == null && !_isLoading) ...[

              // ── HEDEF ───────────────────────────────
              const Text(
                'Beslenme hedefiniz?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(_goals.map((g) {
                final isSelected = _goal == g['key'];
                return GestureDetector(
                  onTap: () => setState(() => _goal = g['key']!),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.15)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).dividerColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            g['label']!,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              color: Theme.of(context).primaryColor),
                      ],
                    ),
                  ),
                );
              })),

              const SizedBox(height: 24),

              // ── GÜNLÜK ÖĞÜN SAYISI ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Günlük öğün sayısı?',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$_mealsPerDay öğün',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _mealsPerDay.toDouble(),
                min: 2,
                max: 6,
                divisions: 4,
                label: '$_mealsPerDay',
                activeColor: Theme.of(context).primaryColor,
                onChanged: (v) =>
                    setState(() => _mealsPerDay = v.toInt()),
              ),

              const SizedBox(height: 8),

              // Bilgi notu
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Theme.of(context).primaryColor, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Profil bilgilerin (boy, kilo, yaş, aktivite) tavsiyeye dahil edilir.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _getAdvice,
                icon: const Text('🥗'),
                label: const Text('Tavsiye Al'),
              ),
            ],

            // ── YÜKLEME ───────────────────────────────
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 24),
                    const Text('🥗 Beslenme planı hazırlanıyor...'),
                    const SizedBox(height: 8),
                    Text(
                      'Bu 10-20 saniye sürebilir',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

            // ── HATA ──────────────────────────────────
            if (_error != null)
              Center(
                child: Column(
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _getAdvice,
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),

            // ── TAVSİYE GELDİ ─────────────────────────
            if (_advice != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('🥗', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Kişisel Beslenme Planın',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _advice!,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => setState(() => _advice = null),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Yeni Tavsiye Al'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}