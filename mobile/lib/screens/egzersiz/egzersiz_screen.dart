// ── egzersiz_screen.dart ────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';
import '../../app.dart';
import '../home/dashboard_screen.dart';
import 'seans_detay_screen.dart';

// ── Seanslar provider — egzersizleri de içeriyor ────────
// Her seans için ayrı /exercises endpoint'i çekiyoruz
final sessionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(
      Endpoints.exerciseSessions,
      queryParameters: {
        'from': TFDateUtils.toApiDate(DateTime.now().subtract(const Duration(days: 90))),
        'to': TFDateUtils.today(),
      },
    );
    final list = response.data as List;
    final sessions = list.map((e) => Map<String, dynamic>.from(e)).toList();

    // Her seans için egzersizleri ayrı çek — kas grubu grafiği için gerekli
    for (final session in sessions) {
      try {
        final exRes = await ApiClient.instance.get(
          '${Endpoints.exerciseSessions}/${session['id']}/exercises',
        );
        session['exercises'] = exRes.data as List? ?? [];
      } catch (_) {
        session['exercises'] = [];
      }
    }
    return sessions;
  } catch (_) {
    return [];
  }
});

class _EC {
  static const bg        = Color(0xFF0C0D10);
  static const bgCard    = Color(0xFF141620);
  static const bgSoft    = Color(0xFF0F1016);
  static const border    = Color(0x12FFFFFF);
  static const text      = Color(0xFFF0EEF8);
  static const textSoft  = Color(0xFF8A88A8);
  static const textMuted = Color(0xFF4A4860);
  static const accent    = Color(0xFFFFB020);
  static const accentDim = Color(0x1FFFB020);
  static const positive  = Color(0xFF34D399);
  static const cyan      = Color(0xFF22D3EE);
  static const purple    = Color(0xFFA78BFA);
  static const lBg       = Color(0xFFF0F2F6);
  static const lBgCard   = Color(0xFFFFFFFF);
  static const lBgSoft   = Color(0xFFE8EBF2);
  static const lBorder   = Color(0x12000000);
  static const lText     = Color(0xFF111318);
  static const lTextSoft = Color(0xFF5A6078);
  static const lTextMuted= Color(0xFF9AA0B8);
  static const lAccent   = Color(0xFFFF6B2B);
  static const lAccentDim= Color(0x1AFF6B2B);
  static const lPositive = Color(0xFF059669);
  static const danger    = Color(0xFFFF5555);
  static const lDanger   = Color(0xFFDC2626);
}

Map<String, int> extractMuscleGroups(List<Map<String, dynamic>> exercises) {
  final counts = <String, int>{};
  for (final ex in exercises) {
    final raw = ex['muscle_groups'];
    List<String> groups = [];
    if (raw is List) {
      groups = raw.map((e) => e.toString()).toList();
    } else if (raw is String && raw.isNotEmpty) {
      groups = [raw];
    }
    for (final g in groups) {
      final key = _normalizeMuscle(g);
      counts[key] = (counts[key] ?? 0) + 1;
    }
  }
  return counts;
}

String _normalizeMuscle(String raw) {
  final lower = raw.toLowerCase().trim();
  if (lower.contains('chest') || lower.contains('göğüs'))       return 'Göğüs';
  if (lower.contains('back') || lower.contains('sırt'))         return 'Sırt';
  if (lower.contains('shoulder') || lower.contains('omuz'))     return 'Omuz';
  if (lower.contains('bicep') || lower.contains('biceps'))      return 'Biceps';
  if (lower.contains('tricep') || lower.contains('triceps'))    return 'Triceps';
  if (lower.contains('leg') || lower.contains('quad') ||
      lower.contains('hamstring') || lower.contains('bacak'))   return 'Bacak';
  if (lower.contains('glute') || lower.contains('kalça'))       return 'Kalça';
  if (lower.contains('abs') || lower.contains('core') ||
      lower.contains('karın'))                                   return 'Karın';
  if (lower.contains('calf') || lower.contains('baldır'))       return 'Baldır';
  if (lower.contains('trap') || lower.contains('tuzak'))        return 'Trapez';
  return raw.isNotEmpty ? raw[0].toUpperCase() + raw.substring(1) : 'Diğer';
}

class EgzersizScreen extends ConsumerStatefulWidget {
  const EgzersizScreen({super.key});
  @override
  ConsumerState<EgzersizScreen> createState() => _EgzersizScreenState();
}

class _EgzersizScreenState extends ConsumerState<EgzersizScreen> {
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController    = TextEditingController();
  bool _isLoading = false;
  int  _activeTab = 0;

  @override
  void dispose() {
    _durationController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showNotifications(BuildContext context, bool isDark,
      Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final notifsAsync = ref.watch(notificationsProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(99))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('🔔 Bildirimler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
                    GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('in_app_notifications');
                        ref.invalidate(notificationsProvider);
                      },
                      child: Text('Temizle', style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 300,
                child: notifsAsync.when(
                  loading: () => Center(child: CircularProgressIndicator(color: accent)),
                  error:   (_, __) => Center(child: Text('Yüklenemedi', style: TextStyle(color: text))),
                  data: (notifs) {
                    if (notifs.isEmpty) {
                      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('🔕', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text('Henüz bildirim yok', style: TextStyle(fontSize: 14, color: text)),
                        const SizedBox(height: 4),
                        Text('Hatırlatıcılar burada görünecek', style: TextStyle(fontSize: 12, color: muted)),
                      ]);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: notifs.length,
                      itemBuilder: (ctx, i) {
                        final n = notifs[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                          child: Row(children: [
                            const Text('🔔', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(n['title'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: text)),
                              const SizedBox(height: 2),
                              Text(n['body'] as String, style: TextStyle(fontSize: 11, color: textSoft)),
                              if ((n['time'] as String).isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(n['time'] as String, style: TextStyle(fontSize: 10, color: muted)),
                              ],
                            ])),
                          ]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createSession(BuildContext ctx) async {
    final durText = _durationController.text.trim();
    if (durText.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Süre zorunludur')));
      return;
    }
    final dur = int.tryParse(durText);
    if (dur == null || dur < 1 || dur > 600) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Süre 1–600 dakika arasında olmalı')));
      return;
    }
    final calText = _caloriesController.text.trim();
    if (calText.isNotEmpty) {
      final cal = double.tryParse(calText);
      if (cal == null || cal < 0 || cal > 5000) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Kalori 0–5000 kcal arasında olmalı')));
        return;
      }
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.post(Endpoints.exerciseSessions, data: {
        'date': TFDateUtils.today(),
        'duration_minutes': dur,
        'calories_burned': double.tryParse(_caloriesController.text),
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      });
      final newSession = Map<String, dynamic>.from(response.data);
      _durationController.clear();
      _caloriesController.clear();
      _notesController.clear();

      // Önce sheet'i kapat
      if (mounted) Navigator.pop(ctx);

      ref.invalidate(sessionsProvider);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SeansDetayScreen(session: newSession)),
      ).then((_) => ref.invalidate(sessionsProvider));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Seans oluşturulurken hata oluştu')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      await ApiClient.instance.delete('${Endpoints.exerciseSessions}/$sessionId');
      ref.invalidate(sessionsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seans silindi ✅')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silme sırasında hata oluştu')));
    }
  }

  Future<void> _confirmDelete(BuildContext context, String sessionId, String sessionName, bool isDark) async {
    final danger = isDark ? _EC.danger : _EC.lDanger;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? _EC.bgCard : _EC.lBgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Seansı Sil', style: TextStyle(color: isDark ? _EC.text : _EC.lText, fontWeight: FontWeight.w800)),
        content: Text(
          '"$sessionName" seansını silmek istediğine emin misin?\nİçindeki egzersizler de silinecek.',
          style: TextStyle(color: isDark ? _EC.textSoft : _EC.lTextSoft),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('İptal', style: TextStyle(color: isDark ? _EC.textSoft : _EC.lTextSoft))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Sil', style: TextStyle(color: danger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed == true) await _deleteSession(sessionId);
  }

  void _showNewSessionSheet(BuildContext context, bool isDark, Color accent, Color bgCard, Color border, Color text, Color textSoft) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 20),
            Text('Yeni Antrenman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text)),
            const SizedBox(height: 16),
            TextField(controller: _durationController, keyboardType: TextInputType.number, style: TextStyle(color: text),
              decoration: const InputDecoration(labelText: 'Süre (dakika) *', prefixIcon: Icon(Icons.timer_outlined))),
            const SizedBox(height: 12),
            TextField(controller: _caloriesController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(color: text),
              decoration: const InputDecoration(labelText: 'Yakılan Kalori (opsiyonel)', prefixIcon: Icon(Icons.local_fire_department_outlined))),
            const SizedBox(height: 12),
            TextField(controller: _notesController, style: TextStyle(color: text),
              decoration: const InputDecoration(labelText: 'Not (opsiyonel)', prefixIcon: Icon(Icons.note_outlined))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _createSession(ctx),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Antrenmanı Başlat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg        = isDark ? _EC.bg        : _EC.lBg;
    final bgCard    = isDark ? _EC.bgCard    : _EC.lBgCard;
    final bgSoft    = isDark ? _EC.bgSoft    : _EC.lBgSoft;
    final border    = isDark ? _EC.border    : _EC.lBorder;
    final text      = isDark ? _EC.text      : _EC.lText;
    final textSoft  = isDark ? _EC.textSoft  : _EC.lTextSoft;
    final muted     = isDark ? _EC.textMuted : _EC.lTextMuted;
    final accent    = isDark ? _EC.accent    : _EC.lAccent;
    final accentDim = isDark ? _EC.accentDim : _EC.lAccentDim;
    final danger    = isDark ? _EC.danger    : _EC.lDanger;

    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Container(
            color: bg,
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(child: Text('Egzersiz', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5))),
                    GestureDetector(
                      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                      child: Container(width: 36, height: 36,
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                        child: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round, size: 15, color: textSoft)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showNotifications(context, isDark, bgCard, bgSoft, border, text, textSoft, muted, accent),
                      child: Container(width: 36, height: 36,
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                        child: Icon(Icons.notifications_none_rounded, size: 15, color: textSoft)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      _TabBtn(label: 'Seanslar',     active: _activeTab == 0, accent: accent, bgCard: bgCard, muted: muted, onTap: () => setState(() => _activeTab = 0)),
                      _TabBtn(label: 'Kas Grupları', active: _activeTab == 1, accent: accent, bgCard: bgCard, muted: muted, onTap: () => setState(() => _activeTab = 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Expanded(
            child: _activeTab == 0
                ? _SeanslarTab(
                    sessionsAsync: sessionsAsync,
                    bg: bg, bgCard: bgCard, bgSoft: bgSoft,
                    border: border, text: text, textSoft: textSoft,
                    muted: muted, accent: accent, accentDim: accentDim, danger: danger,
                    onNewSession: () => _showNewSessionSheet(context, isDark, accent, bgCard, border, text, textSoft),
                    onSessionTap: (session) => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => SeansDetayScreen(session: session)))
                        .then((_) => ref.invalidate(sessionsProvider)),
                    onSessionDelete: (session) => _confirmDelete(
                      context, session['id'] as String,
                      session['notes'] as String? ?? 'Antrenman', isDark),
                  )
                : _KasGruplariTab(
                    sessionsAsync: sessionsAsync,
                    bg: bg, bgCard: bgCard, bgSoft: bgSoft,
                    border: border, text: text, textSoft: textSoft,
                    muted: muted, accent: accent, accentDim: accentDim,
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent, bgCard, muted;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.accent, required this.bgCard, required this.muted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? bgCard : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)] : null,
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? accent : muted)),
        ),
      ),
    );
  }
}

// ── Seanslar Tab ─────────────────────────────────────────
class _SeanslarTab extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> sessionsAsync;
  final Color bg, bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim, danger;
  final VoidCallback onNewSession;
  final void Function(Map<String, dynamic>) onSessionTap;
  final void Function(Map<String, dynamic>) onSessionDelete;

  const _SeanslarTab({
    required this.sessionsAsync,
    required this.bg, required this.bgCard, required this.bgSoft,
    required this.border, required this.text, required this.textSoft,
    required this.muted, required this.accent, required this.accentDim,
    required this.danger,
    required this.onNewSession,
    required this.onSessionTap,
    required this.onSessionDelete,
  });

  @override
  Widget build(BuildContext context) {
    return sessionsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: accent)),
      error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
      data: (sessions) {
        final reversed      = sessions.reversed.toList();
        final sessionColors = [accent, _EC.cyan, _EC.positive, _EC.purple];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            if (reversed.isEmpty)
              Container(
                decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(children: [
                  const Text('🏋️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('Henüz antrenman yok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
                  const SizedBox(height: 4),
                  Text('Aşağıdan yeni seans oluştur', style: TextStyle(fontSize: 12, color: muted)),
                ]),
              ),
            ...reversed.asMap().entries.map((e) {
              final s     = e.value;
              final color = sessionColors[e.key % sessionColors.length];
              final dur   = s['duration_minutes'] as int? ?? 0;
              final cal   = (s['calories_burned'] as num?)?.toInt();
              final date  = s['date'] as String? ?? '';
              final notes = s['notes'] as String?;
              final exercises = s['exercises'] as List? ?? [];
              final exCount = exercises.length;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => onSessionTap(s),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                        child: const Center(child: Text('🏋️', style: TextStyle(fontSize: 20))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onSessionTap(s),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(notes ?? 'Antrenman', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                          const SizedBox(height: 2),
                          Text(
                            '$date · $dur dk${cal != null ? ' · $cal kcal' : ''}${exCount > 0 ? ' · $exCount egzersiz' : ''}',
                            style: TextStyle(fontSize: 11, color: muted),
                          ),
                        ]),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onSessionDelete(s),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.delete_outline, size: 18, color: danger),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => onSessionTap(s),
                      child: Icon(Icons.chevron_right, size: 16, color: muted),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onNewSession,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(16), border: Border.all(color: accent)),
                child: Center(child: Text('+ Yeni Seans', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 14))),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Kas Grupları Tab ─────────────────────────────────────
class _KasGruplariTab extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> sessionsAsync;
  final Color bg, bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim;

  const _KasGruplariTab({
    required this.sessionsAsync, required this.bg, required this.bgCard,
    required this.bgSoft, required this.border, required this.text,
    required this.textSoft, required this.muted, required this.accent,
    required this.accentDim,
  });

  static const _barColors = [
    Color(0xFFFFB020), Color(0xFF22D3EE), Color(0xFF34D399),
    Color(0xFFA78BFA), Color(0xFFFF5555), Color(0xFFFF6B2B),
    Color(0xFFF472B6), Color(0xFF60A5FA), Color(0xFFFBBF24),
  ];

  @override
  Widget build(BuildContext context) {
    return sessionsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: accent)),
      error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
      data: (sessions) {
        final allExercises = sessions.expand((s) {
          final exs = s['exercises'] as List? ?? [];
          return exs.map((e) => Map<String, dynamic>.from(e as Map));
        }).toList();

        final muscleCounts = extractMuscleGroups(allExercises);
        final sorted = muscleCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final totalSessions  = sessions.length;
        final totalExercises = allExercises.length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Row(children: [
              Expanded(child: _StatMini(label: 'Toplam Seans', value: '$totalSessions', icon: '🏋️', bgCard: bgCard, border: border, text: text, muted: muted, accent: accent)),
              const SizedBox(width: 10),
              Expanded(child: _StatMini(label: 'Toplam Egzersiz', value: '$totalExercises', icon: '💪', bgCard: bgCard, border: border, text: text, muted: muted, accent: accent)),
            ]),
            const SizedBox(height: 14),

            if (sorted.isEmpty) ...[
              Container(
                decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  const Text('📊', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('Henüz veri yok', style: TextStyle(fontSize: 16, color: text, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Egzersizlere kas grubu eklenince burada görünür', style: TextStyle(fontSize: 12, color: muted), textAlign: TextAlign.center),
                ]),
              ),
            ] else ...[
              Container(
                decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Çalışan Kaslar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                    Text('90 günlük geçmiş · egzersiz sayısına göre', style: TextStyle(fontSize: 11, color: muted)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (sorted.first.value * 1.3).toDouble(),
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final i = val.toInt();
                                  if (i < 0 || i >= sorted.length) return const SizedBox.shrink();
                                  final label = sorted[i].key;
                                  final short = label.length > 5 ? label.substring(0, 5) : label;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(short, style: TextStyle(fontSize: 9, color: muted)),
                                  );
                                },
                                reservedSize: 22,
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            getDrawingHorizontalLine: (_) => FlLine(color: border, strokeWidth: 1),
                            drawVerticalLine: false,
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: sorted.asMap().entries.map((e) {
                            final color = _barColors[e.key % _barColors.length];
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value.value.toDouble(),
                                  color: color,
                                  width: 18,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Çalışma Oranları', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                    const SizedBox(height: 14),
                    ...sorted.asMap().entries.map((e) {
                      final color   = _barColors[e.key % _barColors.length];
                      final muscle  = e.value.key;
                      final count   = e.value.value;
                      final total   = sorted.fold(0, (sum, x) => sum + x.value);
                      final pct     = total > 0 ? count / total : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Text(muscle, style: TextStyle(fontSize: 13, color: text, fontWeight: FontWeight.w600)),
                                ]),
                                Text('$count egzersiz · %${(pct * 100).toInt()}', style: TextStyle(fontSize: 11, color: muted)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                                backgroundColor: bgSoft,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label, value, icon;
  final Color bgCard, border, text, muted, accent;
  const _StatMini({required this.label, required this.value, required this.icon,
    required this.bgCard, required this.border, required this.text, required this.muted, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: accent)),
          Text(label, style: TextStyle(fontSize: 10, color: muted)),
        ]),
      ]),
    );
  }
}