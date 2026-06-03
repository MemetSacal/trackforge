// ── uyku_tab.dart ───────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';

final todaySleepProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.instance.get('${Endpoints.sleep}/date/${TFDateUtils.today()}');
    return Map<String, dynamic>.from(response.data);
  } catch (_) { return null; }
});

class UykuTab extends ConsumerStatefulWidget {
  const UykuTab({super.key});
  @override
  ConsumerState<UykuTab> createState() => _UykuTabState();
}

class _UykuTabState extends ConsumerState<UykuTab> {
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime  = const TimeOfDay(hour: 7,  minute: 0);
  int  _qualityScore = 7;
  bool _isLoading    = false;

  String _timeToString(TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}:00';

  double _duration() {
    final s = _sleepTime.hour * 60 + _sleepTime.minute;
    var   w = _wakeTime.hour  * 60 + _wakeTime.minute;
    if (w <= s) w += 24 * 60;
    return (w - s) / 60;
  }

  Future<void> _pickTime(bool isSleep) async {
    final picked = await showTimePicker(context: context, initialTime: isSleep ? _sleepTime : _wakeTime);
    if (picked != null) setState(() => isSleep ? _sleepTime = picked : _wakeTime = picked);
  }

  Future<void> _save(Map<String, dynamic>? existing) async {
    setState(() => _isLoading = true);
    try {
      final data = {
        'sleep_time': _timeToString(_sleepTime), 'wake_time': _timeToString(_wakeTime),
        'duration_hours': _duration(), 'quality_score': _qualityScore,
      };
      if (existing != null) {
        await ApiClient.instance.put('${Endpoints.sleep}/${existing['id']}', data: data);
      } else {
        await ApiClient.instance.post(Endpoints.sleep, data: {'date': TFDateUtils.today(), ...data});
      }
      ref.invalidate(todaySleepProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uyku logu kaydedildi ✅')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt sırasında hata oluştu')));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bgCard   = isDark ? const Color(0xFF141620) : Colors.white;
    final bgSoft   = isDark ? const Color(0xFF0F1016) : const Color(0xFFE8EBF2);
    final border   = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text     = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final textSoft = isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);
    final muted    = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent   = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final positive = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
    final danger   = isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);

    final sleepAsync = ref.watch(todaySleepProvider);

    return sleepAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: accent)),
      error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
      data: (sleepLog) {
        if (sleepLog != null && !_isLoading) {
          final ss = sleepLog['sleep_time'] as String?;
          final ws = sleepLog['wake_time']  as String?;
          if (ss != null) { final p = ss.split(':'); _sleepTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])); }
          if (ws != null) { final p = ws.split(':'); _wakeTime  = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])); }
          _qualityScore = (sleepLog['quality_score'] as num?)?.toInt() ?? 7;
        }

        final dur = _duration();
        final sleepPct = (dur / 8).clamp(0.0, 1.0);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            children: [

              // ── UYKU ÖZET KARTI ───────────────────────
              Container(
                decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sleepLog != null ? 'Dün gece' : 'Planlanan', style: TextStyle(fontSize: 11, color: muted)),
                              Text(
                                '${dur.toInt()}s ${((dur % 1) * 60).toInt()}d',
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: text),
                              ),
                              Text(
                                dur >= 7 ? '✔ iyi kalite · $_qualityScore/10' : '⚠ yetersiz · $_qualityScore/10',
                                style: TextStyle(fontSize: 13, color: dur >= 7 ? positive : danger),
                              ),
                            ],
                          ),
                        ),
                        // Yarım daire gauge
                        SizedBox(
                          width: 100, height: 60,
                          child: CustomPaint(
                            painter: _SleepGauge(progress: sleepPct, track: bgSoft, fill: accent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 3.5,
                      children: [
                        ['Yatış',      '${_sleepTime.hour.toString().padLeft(2,"0")}:${_sleepTime.minute.toString().padLeft(2,"0")}'],
                        ['Uyanış',     '${_wakeTime.hour.toString().padLeft(2,"0")}:${_wakeTime.minute.toString().padLeft(2,"0")}'],
                        ['Süre',       '${dur.toStringAsFixed(1)}s'],
                        ['Kalite',     '$_qualityScore/10'],
                      ].map((row) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(row[0], style: TextStyle(fontSize: 10, color: muted)),
                            Text(row[1], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                          ],
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── SAATLERİ SEÇ ─────────────────────────
              Container(
                decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Uyku Saatleri', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _TimeCard(label: 'Uyudum', icon: '🌙', time: _sleepTime, bgSoft: bgSoft, border: border, text: text, muted: muted, onTap: () => _pickTime(true))),
                        const SizedBox(width: 10),
                        Expanded(child: _TimeCard(label: 'Kalktım', icon: '☀️', time: _wakeTime,  bgSoft: bgSoft, border: border, text: text, muted: muted, onTap: () => _pickTime(false))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Uyku Kalitesi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('1', style: TextStyle(color: muted, fontSize: 12)),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(activeTrackColor: accent, thumbColor: accent, inactiveTrackColor: accent.withOpacity(0.2)),
                            child: Slider(value: _qualityScore.toDouble(), min: 1, max: 10, divisions: 9, label: '$_qualityScore', onChanged: (v) => setState(() => _qualityScore = v.toInt())),
                          ),
                        ),
                        Text('10', style: TextStyle(color: muted, fontSize: 12)),
                      ],
                    ),
                    Center(child: Text('${_qualityEmoji(_qualityScore)} $_qualityScore/10', style: TextStyle(fontSize: 16, color: text))),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── KAYDET ───────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _save(sleepLog),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(sleepLog != null ? '+ Uyku Güncelle' : '+ Uyku Ekle'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _qualityEmoji(int s) {
    if (s >= 9) return '🌟';
    if (s >= 7) return '😊';
    if (s >= 5) return '😐';
    if (s >= 3) return '😴';
    return '😫';
  }
}

class _SleepGauge extends CustomPainter {
  final double progress;
  final Color track, fill;
  const _SleepGauge({required this.progress, required this.track, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 1.0;
    final r  = size.width * 0.38;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 8..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 3.14159, 3.14159, false, p..color = track);
    canvas.drawArc(rect, 3.14159, 3.14159 * progress, false, p..color = fill);
  }

  @override bool shouldRepaint(_SleepGauge o) => o.progress != progress;
}

class _TimeCard extends StatelessWidget {
  final String label, icon;
  final TimeOfDay time;
  final Color bgSoft, border, text, muted;
  final VoidCallback onTap;
  const _TimeCard({required this.label, required this.icon, required this.time, required this.bgSoft, required this.border, required this.text, required this.muted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final h = time.hour.toString().padLeft(2,'0');
    final m = time.minute.toString().padLeft(2,'0');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text('$h:$m', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: text)),
            Text(label, style: TextStyle(fontSize: 11, color: muted)),
          ],
        ),
      ),
    );
  }
}