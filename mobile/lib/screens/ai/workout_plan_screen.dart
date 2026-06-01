// ── workout_plan_screen.dart ────────────────────────────
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

  String? _planTitle;
  String? _weeklyNotes;
  List<Map<String, dynamic>> _schedule = [];
  bool _isLoading = false;
  bool _isCreatingSession = false;
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
      _planTitle = null;
      _weeklyNotes = null;
      _schedule = [];
    });

    String? debugResponse;
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

      debugResponse = response.data.toString();

      final rawSchedule = response.data['weekly_schedule'];
      if (rawSchedule is List) {
        _schedule = rawSchedule
            .map((day) => Map<String, dynamic>.from(day))
            .toList();
      }

      setState(() {
        _planTitle = response.data['plan_title'] as String? ?? '';
        _weeklyNotes = response.data['weekly_notes'] as String? ?? '';
      });
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Debug Hata'),
            content: SingleChildScrollView(child: Text('$e\n\n$debugResponse')),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam'))],
          ),
        );
      }
      setState(() => _error = 'Hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startTodayWorkout() async {
    if (_schedule.isEmpty) return;

    final todayWeekday = DateTime.now().weekday;

    Map<String, dynamic>? todaySchedule;
    for (final day in _schedule) {
      final dayName = (day['day'] as String? ?? '').toLowerCase().trim();
      final dayIndex = _turkishDays[dayName];
      if (dayIndex == todayWeekday) {
        todaySchedule = day;
        break;
      }
    }
    todaySchedule ??= _schedule.first;

    final dayName = todaySchedule['day'] as String? ?? 'Antrenman';
    final focus = todaySchedule['focus'] as String? ?? '';
    final duration = todaySchedule['estimated_duration_minutes'] as int? ?? _sessionDuration;
    final calories = (todaySchedule['estimated_calories'] as num?)?.toDouble();
    final rawExercises = todaySchedule['exercises'] as List? ?? [];

    setState(() => _isCreatingSession = true);

    try {
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

      for (final rawEx in rawExercises) {
        try {
          Map<String, dynamic> ex;
          if (rawEx is Map) {
            ex = Map<String, dynamic>.from(rawEx);
          } else {
            ex = {'name': rawEx.toString()};
          }

          final name = ex['name'] as String? ?? ex['exercise_name'] as String? ?? 'Egzersiz';
          final sets = (ex['sets'] as num?)?.toInt();
          final repsRaw = ex['reps'];
          int? reps;
          if (repsRaw is int) {
            reps = repsRaw;
          } else if (repsRaw is String) {
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
          continue;
        }
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SeansDetayScreen(session: session)),
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
    final hasPlan = _planTitle != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Antrenman Planı')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (!hasPlan && !_isLoading) ...[
              const Text('Hedefin ne?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _goals.map((g) {
                  final isSelected = _goal == g['key'];
                  return GestureDetector(
                    onTap: () => setState(() => _goal = g['key']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      child: Text(g['label']!,
                          style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              const Text('Nerede antrenman yapacaksın?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        child: Text(l['label']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Haftada kaç gün?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('$_daysPerWeek gün',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _daysPerWeek.toDouble(),
                min: 2, max: 6, divisions: 4,
                label: '$_daysPerWeek',
                activeColor: Theme.of(context).primaryColor,
                onChanged: (v) => setState(() => _daysPerWeek = v.toInt()),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Seans süresi?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('$_sessionDuration dk',
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _sessionDuration.toDouble(),
                min: 30, max: 120, divisions: 6,
                label: '$_sessionDuration dk',
                activeColor: Theme.of(context).primaryColor,
                onChanged: (v) => setState(() => _sessionDuration = v.toInt()),
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
                    CircularProgressIndicator(color: Theme.of(context).primaryColor),
                    const SizedBox(height: 24),
                    const Text('💪 Antrenman planı hazırlanıyor...'),
                    const SizedBox(height: 8),
                    Text('Bu 10-20 saniye sürebilir',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),

            if (_error != null)
              Center(
                child: Column(
                  children: [
                    Text(_error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _generatePlan, child: const Text('Tekrar Dene')),
                  ],
                ),
              ),

            if (hasPlan) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('💪', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _planTitle!.isNotEmpty ? _planTitle! : 'Kişisel Antrenman Planın',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              ..._schedule.map((day) {
                final dayName = day['day'] as String? ?? '';
                final focus = day['focus'] as String? ?? '';
                final duration = day['estimated_duration_minutes'];
                final calories = day['estimated_calories'];
                final exercises = day['exercises'] as List? ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                dayName.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(focus,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                          ],
                        ),

                        if (duration != null || calories != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (duration != null)
                                _PlanChip(icon: '⏱️', label: '$duration dk'),
                              const SizedBox(width: 8),
                              if (calories != null)
                                _PlanChip(icon: '🔥', label: '$calories kcal'),
                            ],
                          ),
                        ],

                        if (exercises.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          ...exercises.map((rawEx) {
                            final ex = rawEx is Map
                                ? Map<String, dynamic>.from(rawEx)
                                : {'name': rawEx.toString()};
                            final name = ex['name'] as String? ??
                                ex['exercise_name'] as String? ??
                                'Egzersiz';
                            final sets = ex['sets'];
                            final reps = ex['reps'];
                            final notes = ex['notes'] as String?;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 8, height: 8,
                                    margin: const EdgeInsets.only(top: 6, right: 10),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14)),
                                        if (sets != null || reps != null)
                                          Text(
                                            [
                                              if (sets != null) '$sets set',
                                              if (reps != null) '$reps tekrar',
                                            ].join(' × '),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        if (notes != null && notes.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(notes,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color,
                                                )),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                );
              }),

              if (_weeklyNotes != null && _weeklyNotes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Card(
                  color: Theme.of(context).primaryColor.withOpacity(0.07),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_weeklyNotes!,
                              style: const TextStyle(fontSize: 14, height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _isCreatingSession ? null : _startTodayWorkout,
                icon: _isCreatingSession
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('🚀'),
                label: Text(_isCreatingSession
                    ? 'Seans oluşturuluyor...'
                    : 'Bugün Antrenmana Başla'),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _planTitle = null;
                  _weeklyNotes = null;
                  _schedule = [];
                }),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Yeni Plan Oluştur'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  final String icon;
  final String label;
  const _PlanChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text('$icon $label', style: const TextStyle(fontSize: 12)),
    );
  }
}