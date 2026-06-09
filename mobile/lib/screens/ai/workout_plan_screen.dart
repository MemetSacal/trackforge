// ── workout_plan_screen.dart ────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';
import '../../app.dart';
import '../egzersiz/seans_detay_screen.dart';
import '../egzersiz/egzersiz_screen.dart';
import 'ai_helpers.dart';
import '../../core/utils/rate_limiter.dart';

class WorkoutPlanScreen extends ConsumerStatefulWidget {
  const WorkoutPlanScreen({super.key});
  @override
  ConsumerState<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends ConsumerState<WorkoutPlanScreen> {
  String _goal     = 'muscle_gain';
  String _location = 'gym';
  int _daysPerWeek      = 3;
  int _sessionDuration  = 60;

  String? _planTitle;
  String? _weeklyNotes;
  List<Map<String, dynamic>> _schedule = [];
  bool _isLoading         = false;
  bool _isCreatingSession = false;
  String? _error;
  bool _limitReached      = false;

  final _goals = [
    {'key': 'muscle_gain',     'label': '💪 Kas Kazanmak'},
    {'key': 'weight_loss',     'label': '⚡ Yağ Yakmak'},
    {'key': 'endurance',       'label': '🏃 Dayanıklılık'},
    {'key': 'strength',        'label': '🏋️ Güç'},
    {'key': 'general_fitness', 'label': '⭐ Genel Fitness'},
  ];

  final _locations = [
    {'key': 'gym',     'label': '🏋️ Spor Salonu'},
    {'key': 'home',    'label': '🏠 Ev'},
    {'key': 'outdoor', 'label': '🌳 Dışarısı'},
  ];

  final _turkishDays = {
    'pazartesi': 1, 'salı': 2, 'çarşamba': 3,
    'perşembe': 4,  'cuma': 5, 'cumartesi': 6, 'pazar': 7,
  };

  Future<void> _generate() async {
      final canUse = await RateLimiter.canUseWorkoutPlan();
      if (!canUse) {
        setState(() => _limitReached = true);
        return;
      }
      setState(() { _isLoading = true; _error = null; _planTitle = null; _weeklyNotes = null; _schedule = []; _limitReached = false; });
    try {
      final response = await ApiClient.instance.post(Endpoints.aiWorkoutPlan, data: {
        'workout_location': _location, 'fitness_goal': _goal,
        'fitness_level': 'intermediate', 'available_days': _daysPerWeek,
      });
      final raw = response.data['weekly_schedule'];
      if (raw is List) _schedule = raw.map((d) => Map<String, dynamic>.from(d)).toList();
      await RateLimiter.recordWorkoutPlanUse();
      setState(() {
        _planTitle   = response.data['plan_title']    as String? ?? '';
        _weeklyNotes = response.data['weekly_notes']  as String? ?? '';
      });
    } catch (e) { setState(() => _error = 'Plan oluşturulurken hata oluştu: $e'); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _startTodayWorkout() async {
    if (_schedule.isEmpty) return;
    final todayWd = DateTime.now().weekday;
    Map<String, dynamic>? todaySchedule;
    for (final day in _schedule) {
      final dayIndex = _turkishDays[(day['day'] as String? ?? '').toLowerCase().trim()];
      if (dayIndex == todayWd) { todaySchedule = day; break; }
    }
    todaySchedule ??= _schedule.first;

    final dayName  = todaySchedule['day'] as String? ?? 'Antrenman';
    final focus    = todaySchedule['focus'] as String? ?? '';
    final duration = todaySchedule['estimated_duration_minutes'] as int? ?? _sessionDuration;
    final calories = (todaySchedule['estimated_calories'] as num?)?.toDouble();
    final exercises= todaySchedule['exercises'] as List? ?? [];

    setState(() => _isCreatingSession = true);
    try {
      final sessionRes = await ApiClient.instance.post(Endpoints.exerciseSessions, data: {
        'date': TFDateUtils.today(), 'duration_minutes': duration,
        'calories_burned': calories, 'notes': '$dayName — $focus',
      });
      final session   = Map<String, dynamic>.from(sessionRes.data);
      final sessionId = session['id'] as String;

      for (final rawEx in exercises) {
        try {
          final ex   = rawEx is Map ? Map<String, dynamic>.from(rawEx) : {'name': rawEx.toString()};
          final name = ex['name'] as String? ?? ex['exercise_name'] as String? ?? 'Egzersiz';
          final sets = (ex['sets'] as num?)?.toInt();
          final repsRaw = ex['reps'];
          int? reps;
          if (repsRaw is int) reps = repsRaw;
          else if (repsRaw is String) reps = int.tryParse(repsRaw.split('-').first.trim().split(' ').first);
          await ApiClient.instance.post('${Endpoints.exerciseSessions}/$sessionId/exercises', data: {
            'exercise_name': name, 'sets': sets, 'reps': reps, 'weight_kg': null, 'notes': ex['notes'] as String?,
          });
        } catch (_) { continue; }
      }
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => SeansDetayScreen(session: session)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seans oluşturulurken hata oluştu')));
    } finally { if (mounted) setState(() => _isCreatingSession = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg       = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard   = isDark ? const Color(0xFF141620) : Colors.white;
    final bgSoft   = isDark ? const Color(0xFF0F1016) : const Color(0xFFE8EBF2);
    final border   = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text     = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final textSoft = isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);
    final muted    = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent   = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim= isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);
    final danger   = isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);

    final hasPlan = _planTitle != null;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          aiHeader(context, ref, isDark, bg, bgCard, border, text, textSoft, muted, accent, 'Antrenman Planı'),
          Expanded(
            child: _limitReached
                            ? _buildLimitCard(accentDim, accent, border, text)
                            : _isLoading
                            ? aiLoadingState(accent, text, '💪 Antrenman planı hazırlanıyor...')
                            : _error != null
                                ? aiErrorState(_error!, danger, accent, _generate)
                                : hasPlan
                        ? _planResult(bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim)
                        : _planForm(bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim),
          ),
        ],
      ),
    );
  }

  Widget _planForm(Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Nerede antrenman yapacaksın?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
        const SizedBox(height: 10),
        Row(children: _locations.map((l) {
          final sel = _location == l['key'];
          return Expanded(child: GestureDetector(onTap: () => setState(() => _location = l['key']!),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: sel ? accentDim : bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: sel ? accent : border, width: sel ? 1.5 : 1)),
              child: Text(l['label']!, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? accent : text)),
            )));
        }).toList()),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Haftada kaç gün?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
          Text('$_daysPerWeek gün', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: accent, thumbColor: accent, inactiveTrackColor: accent.withOpacity(0.2)),
          child: Slider(value: _daysPerWeek.toDouble(), min: 2, max: 6, divisions: 4, label: '$_daysPerWeek', onChanged: (v) => setState(() => _daysPerWeek = v.toInt())),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Seans süresi?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
          Text('$_sessionDuration dk', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: accent, thumbColor: accent, inactiveTrackColor: accent.withOpacity(0.2)),
          child: Slider(value: _sessionDuration.toDouble(), min: 30, max: 120, divisions: 6, label: '$_sessionDuration dk', onChanged: (v) => setState(() => _sessionDuration = v.toInt())),
        ),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _generate, child: const Text('🤖  Plan Oluştur'))),
      ]),
    );
  }

  Widget _planResult(Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(children: [
        // Plan başlık
        Container(
          decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(20), border: Border.all(color: accent)),
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Text('💪', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(child: Text(_planTitle!.isNotEmpty ? _planTitle! : 'Kişisel Antrenman Planın',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: text))),
          ]),
        ),
        const SizedBox(height: 12),

        // Günler
        ..._schedule.map((day) {
          final dayName  = day['day']    as String? ?? '';
          final focus    = day['focus']  as String? ?? '';
          final duration = day['estimated_duration_minutes'];
          final calories = day['estimated_calories'];
          final exercises= day['exercises'] as List? ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(99), border: Border.all(color: accent)),
                  child: Text(dayName.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(focus, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: text))),
              ]),
              if (duration != null || calories != null) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  if (duration != null) _chip2('⏱️ $duration dk', bgSoft, border, text),
                  if (calories != null) _chip2('🔥 $calories kcal', bgSoft, border, text),
                ]),
              ],
              if (exercises.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(color: border, height: 1),
                const SizedBox(height: 12),
                ...exercises.map((rawEx) {
                  final ex   = rawEx is Map ? Map<String, dynamic>.from(rawEx) : {'name': rawEx.toString()};
                  final name = ex['name'] as String? ?? ex['exercise_name'] as String? ?? 'Egzersiz';
                  final sets = ex['sets'];
                  final reps = ex['reps'];
                  final notes= ex['notes'] as String?;
                  return Padding(padding: const EdgeInsets.only(bottom: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 7, right: 10),
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: text)),
                        if (sets != null || reps != null)
                          Text([if (sets != null) '$sets set', if (reps != null) '$reps tekrar'].join(' × '),
                            style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w500)),
                        if (notes != null && notes.isNotEmpty)
                          Text(notes, style: TextStyle(fontSize: 11, color: muted)),
                      ])),
                    ]));
                }),
              ],
            ]),
          );
        }),

        if (_weeklyNotes != null && _weeklyNotes!.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('📝', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text(_weeklyNotes!, style: TextStyle(fontSize: 13, color: text, height: 1.5))),
            ]),
          ),
          const SizedBox(height: 10),
        ],

        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: _isCreatingSession ? null : _startTodayWorkout,
            child: _isCreatingSession
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('🚀  Bugün Antrenmana Başla'),
          ),
        ),
        const SizedBox(height: 10),
        aiOutlineBtn('Yeni Plan Oluştur', Icons.arrow_back, accent, border,
          () => setState(() { _planTitle = null; _weeklyNotes = null; _schedule = []; })),
      ]),
    );
  }
  Widget _buildLimitCard(Color accentDim, Color accent, Color border, Color text) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(20), border: Border.all(color: accent)),
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('⏳', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('Haftalık Limit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent)),
              const SizedBox(height: 8),
              Text('Bu haftaki antrenman planı hakkını kullandın.\nYeni hafta başında tekrar kullanılabilir.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: text, height: 1.5)),
            ]),
          ),
        ),
      );
    }

  Widget _chip2(String label, Color bg, Color border, Color text) =>
    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
      child: Text(label, style: TextStyle(fontSize: 11, color: text)));
}