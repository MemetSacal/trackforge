// ── workout_plan_screen.dart ────────────────────────────
// AI antrenman planı ekranı.
// Plan oluşturulduktan sonra "Bugün Antrenmana Başla" butonu çıkar.
// Butona basınca bugünün antrenmanı otomatik seans olarak eklenir.

import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';
import '../egzersiz/seans_detay_screen.dart';

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  String _goal = 'muscle_gain';
  String _location = 'gym';
  int _daysPerWeek = 3;
  int _sessionDuration = 60;

  String? _plan;
  // Ham schedule verisi — seans oluştururken kullanacağız
  List<Map<String, dynamic>> _schedule = [];
  bool _isLoading = false;
  bool _isCreatingSession = false; // Seans oluşturma loading
  String? _error;

  final _goals = [
    {'key': 'muscle_gain', 'label': '💪 Kas Kazanmak'},
    {'key': 'weight_loss', 'label': '⚡ Yağ Yakmak'},
    {'key': 'endurance', 'label': '🏃 Dayanıklılık'},
    {'key': 'strength', 'label': '🏋️ Güç'},
    {'key': 'general_fitness', 'label': '⭐ Genel Fitness'},
  ];

  final _locations = [
    {'key': 'gym', 'label': '🏋️ Spor Salonu'},
    {'key': 'home', 'label': '🏠 Ev'},
    {'key': 'outdoor', 'label': '🌳 Dışarısı'},
  ];

  // Türkçe gün adları → weekday indexi (1=Pazartesi, 7=Pazar)
  final _turkishDays = {
    'pazartesi': 1,
    'salı': 2,
    'çarşamba': 3,
    'perşembe': 4,
    'cuma': 5,
    'cumartesi': 6,
    'pazar': 7,
  };

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _plan = null;
      _schedule = [];
    });

    try {
      final response = await ApiClient.instance.post(
        Endpoints.aiWorkoutPlan,
        data: {
          'workout_location': _location,
          'fitness_goal': _goal,
          'fitness_level': 'intermediate',
          'available_days': _daysPerWeek,
        },
      );

      final planTitle = response.data['plan_title'] as String? ?? '';
      final weeklyNotes = response.data['weekly_notes'] as String? ?? '';
      final rawSchedule = response.data['weekly_schedule'];

      // Ham schedule'ı sakla — seans oluştururken kullanacağız
      if (rawSchedule is List) {
        _schedule = rawSchedule
            .map((day) => Map<String, dynamic>.from(day))
            .toList();
      }

      String scheduleText = '';
      if (_schedule.isNotEmpty) {
        scheduleText = _schedule.map((day) {
          return day.entries.map((e) {
            if (e.value is List) {
              final items = (e.value as List).join('\n  • ');
              return '${e.key}:\n  • $items';
            }
            return '${e.key}: ${e.value}';
          }).join('\n');
        }).join('\n\n─────────────────\n\n');
      }

      setState(() => _plan =
          '$planTitle\n\n$scheduleText\n\n📝 Notlar:\n$weeklyNotes'.trim());
    } catch (e) {
      setState(() => _error = 'Plan oluşturulurken hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Bugünün antrenmanını bul ve seans oluştur
  Future<void> _startTodayWorkout() async {
    if (_schedule.isEmpty) return;

    // Bugünün Türkçe gün adını bul
    final todayWeekday = DateTime.now().weekday; // 1=Pazartesi

    // Schedule'dan bugüne ait günü bul
    Map<String, dynamic>? todaySchedule;
    for (final day in _schedule) {
      final dayName = (day['day'] as String? ?? '').toLowerCase().trim();
      final dayIndex = _turkishDays[dayName];
      if (dayIndex == todayWeekday) {
        todaySchedule = day;
        break;
      }
    }

    // Bugün antrenman günü değilse ilk günü al
    todaySchedule ??= _schedule.first;

    final dayName = todaySchedule['day'] as String? ?? 'Antrenman';
    final focus = todaySchedule['focus'] as String? ?? '';
    final duration = todaySchedule['estimated_duration_minutes'] as int? ?? _sessionDuration;
    final calories = (todaySchedule['estimated_calories'] as num?)?.toDouble();
    final rawExercises = todaySchedule['exercises'] as List? ?? [];

    setState(() => _isCreatingSession = true);

    try {
      // 1 — Seans oluştur
      final sessionResponse = await ApiClient.instance.post(
        Endpoints.exerciseSessions,
        data: {
          'date': TFDateUtils.today(),
          'duration_minutes': duration,
          'calories_burned': calories,
          'notes': '$dayName — $focus',
        },
      );

      final session = Map<String, dynamic>.from(sessionResponse.data);
      final sessionId = session['id'] as String;

      // 2 — Her egzersizi seansa ekle
      for (final rawEx in rawExercises) {
        try {
          // rawEx bir Map veya string olabilir
          Map<String, dynamic> ex;
          if (rawEx is Map) {
            ex = Map<String, dynamic>.from(rawEx);
          } else {
            // String ise sadece isim olarak ekle
            ex = {'name': rawEx.toString()};
          }

          final name = ex['name'] as String? ?? ex['exercise_name'] as String? ?? 'Egzersiz';
          final sets = (ex['sets'] as num?)?.toInt();
          // Reps string olabilir ("10-12"), int'e çevirmeye çalış
          final repsRaw = ex['reps'];
          int? reps;
          if (repsRaw is int) {
            reps = repsRaw;
          } else if (repsRaw is String) {
            // "10-12" → 10 al
            reps = int.tryParse(repsRaw.split('-').first.trim().split(' ').first);
          }

          await ApiClient.instance.post(
            '${Endpoints.exerciseSessions}/$sessionId/exercises',
            data: {
              'exercise_name': name,
              'sets': sets,
              'reps': reps,
              'weight_kg': null,
              'notes': ex['notes'] as String?,
            },
          );
        } catch (_) {
          // Tek egzersiz hata verse bile devam et
          continue;
        }
      }

      if (!mounted) return;

      // 3 — Seans detay ekranına git
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SeansDetayScreen(session: session),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seans oluşturulurken hata oluştu')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingSession = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Antrenman Planı')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_plan == null && !_isLoading) ...[

              const Text(
                'Hedefin ne?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _goals.map((g) {
                  final isSelected = _goal == g['key'];
                  return GestureDetector(
                    onTap: () => setState(() => _goal = g['key']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.15)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        g['label']!,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              const Text(
                'Nerede antrenman yapacaksın?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: _locations.map((l) {
                  final isSelected = _location == l['key'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _location = l['key']!),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                        child: Text(
                          l['label']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Haftada kaç gün?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$_daysPerWeek gün',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _daysPerWeek.toDouble(),
                min: 2,
                max: 6,
                divisions: 4,
                label: '$_daysPerWeek',
                activeColor: Theme.of(context).primaryColor,
                onChanged: (v) => setState(() => _daysPerWeek = v.toInt()),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Seans süresi?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$_sessionDuration dk',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _sessionDuration.toDouble(),
                min: 30,
                max: 120,
                divisions: 6,
                label: '$_sessionDuration dk',
                activeColor: Theme.of(context).primaryColor,
                onChanged: (v) =>
                    setState(() => _sessionDuration = v.toInt()),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _generatePlan,
                icon: const Text('🤖'),
                label: const Text('Plan Oluştur'),
              ),
            ],

            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 24),
                    const Text('💪 Antrenman planı hazırlanıyor...'),
                    const SizedBox(height: 8),
                    Text(
                      'Bu 10-20 saniye sürebilir',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

            if (_error != null)
              Center(
                child: Column(
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _generatePlan,
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),

            if (_plan != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('💪', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Kişisel Antrenman Planın',
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
                    _plan!,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── BUGÜN ANTRENMANA BAŞLA ────────────────
              ElevatedButton.icon(
                onPressed: _isCreatingSession ? null : _startTodayWorkout,
                icon: _isCreatingSession
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('🚀'),
                label: Text(_isCreatingSession
                    ? 'Seans oluşturuluyor...'
                    : 'Bugün Antrenmana Başla'),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _plan = null;
                  _schedule = [];
                }),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Yeni Plan Oluştur'),
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