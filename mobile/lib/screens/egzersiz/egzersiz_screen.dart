// ── egzersiz_screen.dart ────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';
import '../../app.dart';
import 'seans_detay_screen.dart';

final sessionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(
      Endpoints.exerciseSessions,
      queryParameters: {
        'from': TFDateUtils.toApiDate(DateTime.now().subtract(const Duration(days: 30))),
        'to': TFDateUtils.today(),
      },
    );
    final list = response.data as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) { return []; }
});

// ── RENKLER ─────────────────────────────────────────────
class _EC {
  static const bg       = Color(0xFF0C0D10);
  static const bgCard   = Color(0xFF141620);
  static const bgSoft   = Color(0xFF0F1016);
  static const border   = Color(0x12FFFFFF);
  static const text     = Color(0xFFF0EEF8);
  static const textSoft = Color(0xFF8A88A8);
  static const textMuted= Color(0xFF4A4860);
  static const accent   = Color(0xFFFFB020);
  static const accentDim= Color(0x1FFFB020);
  static const positive = Color(0xFF34D399);
  static const cyan     = Color(0xFF22D3EE);
  static const purple   = Color(0xFFA78BFA);
  static const lBg      = Color(0xFFF0F2F6);
  static const lBgCard  = Color(0xFFFFFFFF);
  static const lBgSoft  = Color(0xFFE8EBF2);
  static const lBorder  = Color(0x12000000);
  static const lText    = Color(0xFF111318);
  static const lTextSoft= Color(0xFF5A6078);
  static const lTextMuted=Color(0xFF9AA0B8);
  static const lAccent  = Color(0xFFFF6B2B);
  static const lAccentDim=Color(0x1AFF6B2B);
  static const lPositive= Color(0xFF059669);
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
  int  _activeTab = 0; // 0=Seanslar, 1=Kas Grupları

  @override
  void dispose() {
    _durationController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
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
      _durationController.clear(); _caloriesController.clear(); _notesController.clear();
      ref.invalidate(sessionsProvider);
      if (mounted) Navigator.pop(ctx);
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => SeansDetayScreen(session: newSession)))
          .then((_) => ref.invalidate(sessionsProvider));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Seans oluşturulurken hata oluştu')));
    } finally { if (mounted) setState(() => _isLoading = false); }
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
            // Handle
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
    final isDark   = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg       = isDark ? _EC.bg       : _EC.lBg;
    final bgCard   = isDark ? _EC.bgCard   : _EC.lBgCard;
    final bgSoft   = isDark ? _EC.bgSoft   : _EC.lBgSoft;
    final border   = isDark ? _EC.border   : _EC.lBorder;
    final text     = isDark ? _EC.text     : _EC.lText;
    final textSoft = isDark ? _EC.textSoft : _EC.lTextSoft;
    final muted    = isDark ? _EC.textMuted: _EC.lTextMuted;
    final accent   = isDark ? _EC.accent   : _EC.lAccent;
    final accentDim= isDark ? _EC.accentDim: _EC.lAccentDim;

    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── HEADER ──────────────────────────────────
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
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                        child: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round, size: 15, color: textSoft),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                      child: Icon(Icons.notifications_none_rounded, size: 15, color: textSoft),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── TAB BAR ─────────────────────────
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

          // ── İÇERİK ──────────────────────────────────
          Expanded(
            child: _activeTab == 0
                ? _SeanslarTab(
                    sessionsAsync: sessionsAsync,
                    bg: bg, bgCard: bgCard, bgSoft: bgSoft,
                    border: border, text: text, textSoft: textSoft,
                    muted: muted, accent: accent, accentDim: accentDim,
                    onNewSession: () => _showNewSessionSheet(context, isDark, accent, bgCard, border, text, textSoft),
                    onSessionTap: (session) => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => SeansDetayScreen(session: session)))
                        .then((_) => ref.invalidate(sessionsProvider)),
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

// ── TAB BUTON ───────────────────────────────────────────
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

// ── SEANSLAR TAB ────────────────────────────────────────
class _SeanslarTab extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> sessionsAsync;
  final Color bg, bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim;
  final VoidCallback onNewSession;
  final void Function(Map<String, dynamic>) onSessionTap;

  const _SeanslarTab({
    required this.sessionsAsync, required this.bg, required this.bgCard,
    required this.bgSoft, required this.border, required this.text,
    required this.textSoft, required this.muted, required this.accent,
    required this.accentDim, required this.onNewSession, required this.onSessionTap,
  });

  @override
  Widget build(BuildContext context) {
    return sessionsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: accent)),
      error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
      data: (sessions) {
        final reversed = sessions.reversed.toList();
        final sessionColors = [accent, _EC.cyan, _EC.positive, _EC.purple];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Seans kartları
            ...reversed.asMap().entries.map((e) {
              final s     = e.value;
              final color = sessionColors[e.key % sessionColors.length];
              final dur   = s['duration_minutes'] as int? ?? 0;
              final cal   = (s['calories_burned'] as num?)?.toInt();
              final date  = s['date'] as String? ?? '';
              final notes = s['notes'] as String?;

              return GestureDetector(
                onTap: () => onSessionTap(s),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(child: Text('🏋️', style: const TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notes ?? 'Antrenman', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                            const SizedBox(height: 2),
                            Text(
                              '$date · $dur dk${cal != null ? ' · $cal kcal' : ''}',
                              style: TextStyle(fontSize: 11, color: muted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: muted),
                    ],
                  ),
                ),
              );
            }),

            // Yeni seans butonu
            GestureDetector(
              onTap: onNewSession,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: accentDim,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent),
                ),
                child: Center(
                  child: Text('+ Yeni Seans', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── KAS GRUPLARI TAB ────────────────────────────────────
class _KasGruplariTab extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> sessionsAsync;
  final Color bg, bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim;

  const _KasGruplariTab({
    required this.sessionsAsync, required this.bg, required this.bgCard,
    required this.bgSoft, required this.border, required this.text,
    required this.textSoft, required this.muted, required this.accent,
    required this.accentDim,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Anatomik vücut SVG kartı
        Container(
          decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kas Grubu Anatomisi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: CustomPaint(
                    size: const Size(120, 220),
                    painter: _BodyPainter(accent: accent, border: border, bgCard: bgCard, accentDim: accentDim),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Kas grubu listesi
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: [
            ['Göğüs',  _EC.accent,   'Bu hafta: 2x'],
            ['Sırt',   _EC.cyan,     'Bu hafta: 1x'],
            ['Bacak',  _EC.positive, 'Bu hafta: 1x'],
            ['Omuz',   _EC.purple,   'Bu hafta: 2x'],
            ['Kol',    _EC.accent,   'Bu hafta: 1x'],
            ['Karın',  const Color(0xFFFF5555), 'Bu hafta: 0x'],
          ].map((row) => Container(
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: row[1] as Color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(row[0] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: text)),
                      Text(row[2] as String, style: TextStyle(fontSize: 10, color: muted)),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }
}

// Basit vücut anatomisi painter
class _BodyPainter extends CustomPainter {
  final Color accent, border, bgCard, accentDim;
  const _BodyPainter({required this.accent, required this.border, required this.bgCard, required this.accentDim});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint  = Paint()..color = accentDim..style = PaintingStyle.fill;
    final strokePaint= Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final bodyPaint  = Paint()..color = bgCard..style = PaintingStyle.fill;
    final bodySPaint = Paint()..color = border..style = PaintingStyle.stroke..strokeWidth = 1.5;

    // Baş
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width/2, 20), width: 32, height: 36), bodyPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width/2, 20), width: 32, height: 36), bodySPaint);

    // Gövde (göğüs — vurgulu)
    final chest = RRect.fromRectAndRadius(Rect.fromLTWH(38, 40, 44, 55), const Radius.circular(8));
    canvas.drawRRect(chest, fillPaint);
    canvas.drawRRect(chest, strokePaint);

    // Sol kol
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(18, 42, 18, 44), const Radius.circular(7)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(18, 42, 18, 44), const Radius.circular(7)), bodySPaint);

    // Sağ kol
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(84, 42, 18, 44), const Radius.circular(7)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(84, 42, 18, 44), const Radius.circular(7)), bodySPaint);

    // Sol üst bacak
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(36, 97, 20, 58), const Radius.circular(8)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(36, 97, 20, 58), const Radius.circular(8)), bodySPaint);

    // Sağ üst bacak
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(64, 97, 20, 58), const Radius.circular(8)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(64, 97, 20, 58), const Radius.circular(8)), bodySPaint);

    // Sol alt bacak
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(36, 157, 20, 48), const Radius.circular(7)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(36, 157, 20, 48), const Radius.circular(7)), bodySPaint);

    // Sağ alt bacak
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(64, 157, 20, 48), const Radius.circular(7)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(64, 157, 20, 48), const Radius.circular(7)), bodySPaint);

    // GÖĞÜS yazısı
    final tp = TextPainter(
      text: TextSpan(text: 'GÖĞÜS', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: accent)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width/2 - tp.width/2, 64));
  }

  @override bool shouldRepaint(_BodyPainter o) => false;
}