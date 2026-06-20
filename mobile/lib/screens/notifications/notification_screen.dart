// ── notification_screen.dart ────────────────────────────
// lib/screens/notifications/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../core/notifications/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});
  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  bool _loading = true;
  bool _hasPermission = false;

  // Ayarlar
  bool _waterEnabled   = true;
  bool _workoutEnabled = true;
  bool _sleepEnabled   = true;
  bool _mealEnabled    = true;
  bool _stepsEnabled   = true;
  bool _streakEnabled  = true;
  bool _weeklyEnabled  = true;

  // Saat seçimi
  TimeOfDay _workoutTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _sleepTime   = const TimeOfDay(hour: 22, minute: 30);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _hasPermission = await NotificationService.hasPermission();
    if (_hasPermission) {
      final settings = await NotificationService.getSettings();
      setState(() {
        _waterEnabled   = settings['water']   as bool;
        _workoutEnabled = settings['workout'] as bool;
        _sleepEnabled   = settings['sleep']   as bool;
        _mealEnabled    = settings['meal']    as bool;
        _stepsEnabled   = settings['steps']   as bool;
        _streakEnabled  = settings['streak']  as bool;
        _weeklyEnabled  = settings['weekly']  as bool;
        _workoutTime    = TimeOfDay(hour: settings['workoutHour'] as int, minute: settings['workoutMin'] as int);
        _sleepTime      = TimeOfDay(hour: settings['sleepHour']   as int, minute: settings['sleepMin']   as int);
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _requestPermission() async {
    final granted = await NotificationService.requestPermission();
    if (granted) {
      await NotificationService.scheduleAll();
      setState(() => _hasPermission = true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bildirimler aktif edildi ✅')),
      );
    }
  }

  Future<void> _toggle(String key, bool value) async {
    await NotificationService.saveSetting(key, value);
    await NotificationService.scheduleAll();
  }

  Future<void> _pickWorkoutTime() async {
    final picked = await showTimePicker(context: context, initialTime: _workoutTime);
    if (picked != null) {
      setState(() => _workoutTime = picked);
      await NotificationService.scheduleWorkoutReminder(hour: picked.hour, minute: picked.minute);
    }
  }

  Future<void> _pickSleepTime() async {
    final picked = await showTimePicker(context: context, initialTime: _sleepTime);
    if (picked != null) {
      setState(() => _sleepTime = picked);
      await NotificationService.scheduleSleepReminder(hour: picked.hour, minute: picked.minute);
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg        = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard    = isDark ? const Color(0xFF141620) : Colors.white;
    final bgSoft    = isDark ? const Color(0xFF0F1016) : const Color(0xFFE8EBF2);
    final border    = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text      = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final textSoft  = isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);
    final muted     = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent    = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim = isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);
    final danger    = isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);
    final positive  = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── HEADER ──────────────────────────────────
          Container(
            color: bg,
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                    child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: textSoft),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
                  Text('Bildirimler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5)),
                ])),
                GestureDetector(
                  onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                    child: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round, size: 15, color: textSoft),
                  ),
                ),
              ],
            ),
          ),

          // ── İÇERİK ──────────────────────────────────
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: accent))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    child: Column(
                      children: [
                        // İzin yoksa banner göster
                        if (!_hasPermission) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: accent.withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                Row(children: [
                                  Icon(Icons.notifications_off_outlined, color: accent, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text('Bildirimler kapalı', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text))),
                                ]),
                                const SizedBox(height: 8),
                                Text('Hatırlatıcıları almak için bildirimlere izin ver.', style: TextStyle(fontSize: 12, color: textSoft)),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _requestPermission,
                                    style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black),
                                    child: const Text('İzin Ver'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // İzin var — ayarlar
                        if (_hasPermission) ...[
                          // Su
                          _NotifCard(
                            emoji: '💧', title: 'Su Hatırlatıcısı',
                            desc: 'Her 2 saatte bir (09:00 - 21:00)',
                            value: _waterEnabled, accent: accent, bgCard: bgCard, border: border, text: text, muted: muted,
                            onChanged: (v) async {
                              setState(() => _waterEnabled = v);
                              await _toggle('water', v);
                            },
                          ),
                          const SizedBox(height: 8),

                          // Öğün
                          _NotifCard(
                            emoji: '🍽️', title: 'Öğün Hatırlatıcısı',
                            desc: '12:00 ve 19:00 — kalori takibi için',
                            value: _mealEnabled, accent: accent, bgCard: bgCard, border: border, text: text, muted: muted,
                            onChanged: (v) async {
                              setState(() => _mealEnabled = v);
                              await _toggle('meal', v);
                            },
                          ),
                          const SizedBox(height: 8),

                          // Antrenman + saat seçimi
                          Container(
                            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Row(children: [
                                  Text('🏋️', style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Antrenman Hatırlatıcısı', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                                    Text('Antrenman günlerinde hatırlatır', style: TextStyle(fontSize: 11, color: muted)),
                                  ])),
                                  Switch(value: _workoutEnabled, activeColor: accent, onChanged: (v) async {
                                    setState(() => _workoutEnabled = v);
                                    await _toggle('workout', v);
                                  }),
                                ]),
                                if (_workoutEnabled) ...[
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: _pickWorkoutTime,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
                                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Text('Saat', style: TextStyle(fontSize: 13, color: textSoft)),
                                        Row(children: [
                                          Text(_formatTime(_workoutTime), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: accent)),
                                          const SizedBox(width: 6),
                                          Icon(Icons.access_time, size: 16, color: accent),
                                        ]),
                                      ]),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Uyku + saat seçimi
                          Container(
                            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Row(children: [
                                  Text('😴', style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Uyku Hatırlatıcısı', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                                    Text('Yatma vakti yaklaşıyor bildirimi', style: TextStyle(fontSize: 11, color: muted)),
                                  ])),
                                  Switch(value: _sleepEnabled, activeColor: accent, onChanged: (v) async {
                                    setState(() => _sleepEnabled = v);
                                    await _toggle('sleep', v);
                                  }),
                                ]),
                                if (_sleepEnabled) ...[
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: _pickSleepTime,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
                                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Text('Saat', style: TextStyle(fontSize: 13, color: textSoft)),
                                        Row(children: [
                                          Text(_formatTime(_sleepTime), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: accent)),
                                          const SizedBox(width: 6),
                                          Icon(Icons.access_time, size: 16, color: accent),
                                        ]),
                                      ]),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Adım
                          _NotifCard(
                            emoji: '👟', title: 'Adım Hedefi',
                            desc: 'Her gün 20:00 — hedefini kontrol et',
                            value: _stepsEnabled, accent: accent, bgCard: bgCard, border: border, text: text, muted: muted,
                            onChanged: (v) async {
                              setState(() => _stepsEnabled = v);
                              await _toggle('steps', v);
                            },
                          ),
                          const SizedBox(height: 8),

                          // Seri
                          _NotifCard(
                            emoji: '🔥', title: 'Seri Koruma',
                            desc: 'Her gün 21:00 — veri girmeyi unutma',
                            value: _streakEnabled, accent: accent, bgCard: bgCard, border: border, text: text, muted: muted,
                            onChanged: (v) async {
                              setState(() => _streakEnabled = v);
                              await _toggle('streak', v);
                            },
                          ),
                          const SizedBox(height: 8),

                          // Haftalık rapor
                          _NotifCard(
                            emoji: '📊', title: 'Haftalık AI Raporu',
                            desc: 'Her Pazartesi 09:00 — haftalık analiz',
                            value: _weeklyEnabled, accent: accent, bgCard: bgCard, border: border, text: text, muted: muted,
                            onChanged: (v) async {
                              setState(() => _weeklyEnabled = v);
                              await _toggle('weekly', v);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Tümünü kapat butonu
                          GestureDetector(
                            onTap: () async {
                              await NotificationService.cancelAll();
                              setState(() {
                                _waterEnabled = _workoutEnabled = _sleepEnabled =
                                _mealEnabled  = _stepsEnabled  = _streakEnabled =
                                _weeklyEnabled = false;
                              });
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tüm bildirimler kapatıldı')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: bgCard,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: danger.withOpacity(0.3)),
                              ),
                              child: Row(children: [
                                Icon(Icons.notifications_off_outlined, color: danger, size: 18),
                                const SizedBox(width: 10),
                                Text('Tüm Bildirimleri Kapat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: danger)),
                              ]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final String emoji, title, desc;
  final bool value;
  final Color accent, bgCard, border, text, muted;
  final ValueChanged<bool> onChanged;

  const _NotifCard({
    required this.emoji, required this.title, required this.desc,
    required this.value, required this.accent, required this.bgCard,
    required this.border, required this.text, required this.muted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
          Text(desc,  style: TextStyle(fontSize: 11, color: muted)),
        ])),
        Switch(value: value, activeColor: accent, onChanged: onChanged),
      ]),
    );
  }
}