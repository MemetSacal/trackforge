// ── steps_screen.dart ───────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';
import '../../app.dart';

final todayStepsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.instance.get('${Endpoints.steps}/date/${TFDateUtils.today()}');
    return Map<String, dynamic>.from(response.data);
  } catch (_) { return null; }
});

class StepsScreen extends ConsumerStatefulWidget {
  const StepsScreen({super.key});
  @override
  ConsumerState<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends ConsumerState<StepsScreen> {
  final _stepsController = TextEditingController();
  final _goalController  = TextEditingController(text: '10000');
  bool _isLoading = false;

  // ── Pedometer ──────────────────────────────────────────
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;
  int  _liveSteps     = 0;
  bool _isPedActive   = false;
  bool _isWalking     = false;
  int  _sessionStart  = 0; // boot'tan itibaren adım, oturum başlangıcı
  bool _sessionActive = false;

  @override
  void initState() {
    super.initState();
    _requestAndStart();
  }

  Future<void> _requestAndStart() async {
    // Android 10+ için izin gerekiyor
    final status = await Permission.activityRecognition.request();
    if (status.isGranted) _startPedometer();
  }

  void _startPedometer() {
    _stepSub = Pedometer.stepCountStream.listen(
      (event) {
        if (!_sessionActive) {
          // İlk event — oturum başlangıcını kaydet
          _sessionStart  = event.steps;
          _sessionActive = true;
        }
        setState(() {
          _liveSteps   = event.steps - _sessionStart;
          _isPedActive = true;
        });
        // Adım sayısını controller'a yaz
        _stepsController.text = _liveSteps.toString();
      },
      onError: (_) => setState(() => _isPedActive = false),
    );

    _statusSub = Pedometer.pedestrianStatusStream.listen(
      (event) => setState(() => _isWalking = event.status == 'walking'),
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    _stepsController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _save(Map<String, dynamic>? existing) async {
    final stepsText = _stepsController.text.trim();
    if (stepsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adım sayısı zorunludur')));
      return;
    }
    final steps = int.tryParse(stepsText);
    if (steps == null || steps < 0 || steps > 100000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adım 0–100.000 arasında olmalı')));
      return;
    }
    final goalText = _goalController.text.trim();
    if (goalText.isNotEmpty) {
      final goal = int.tryParse(goalText);
      if (goal == null || goal < 1000 || goal > 50000) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hedef 1.000–50.000 arasında olmalı')));
        return;
      }
    }
    setState(() => _isLoading = true);
    try {
      if (existing != null) {
        await ApiClient.instance.put('${Endpoints.steps}/${existing['id']}', data: {
          'step_count': steps,
          'goal': int.tryParse(_goalController.text) ?? 10000,
        });
      } else {
        await ApiClient.instance.post(Endpoints.steps, data: {
          'date':       TFDateUtils.today(),
          'step_count': steps,
          'goal':       int.tryParse(_goalController.text) ?? 10000,
        });
      }
      ref.invalidate(todayStepsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adım kaydedildi ✅')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt sırasında hata oluştu')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    final positive  = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);

    final stepsAsync = ref.watch(todayStepsProvider);

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
                  Text('Adım Sayar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5)),
                ])),
                // Canlı durum badge
                if (_isPedActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (_isWalking ? positive : accent).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: (_isWalking ? positive : accent).withOpacity(0.4)),
                    ),
                    child: Text(
                      _isWalking ? '🚶 Yürüyor' : '⏸ Durdu',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _isWalking ? positive : accent),
                    ),
                  ),
                const SizedBox(width: 8),
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

          Expanded(
            child: stepsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: accent)),
              error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
              data: (stepsData) {
                // Kayıtlı veri varsa goal'u doldur
                final savedSteps = (stepsData?['step_count'] as num?)?.toInt() ?? 0;
                final goal       = (stepsData?['goal']       as num?)?.toInt() ?? 10000;
                if (stepsData != null) _goalController.text = goal.toString();

                // Gösterilecek adım: canlı pedometer varsa onu göster, yoksa kaydedileni
                final displaySteps = _isPedActive ? _liveSteps : savedSteps;
                final progress     = goal > 0 ? (displaySteps / goal).clamp(0.0, 1.0) : 0.0;
                final distance     = (displaySteps * 0.000762).toStringAsFixed(2);
                final calories     = (displaySteps * 0.04).toInt();

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Column(
                    children: [

                      // ── BÜYÜK PROGRESS KARTI ──────────
                      Container(
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: border)),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 160, height: 160,
                                  child: CircularProgressIndicator(
                                    value: progress, strokeWidth: 12,
                                    backgroundColor: accent.withOpacity(0.15),
                                    color: progress >= 1.0 ? positive : accent,
                                  ),
                                ),
                                Column(children: [
                                  Text(
                                    _isPedActive && _isWalking ? '🚶' : '👟',
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  Text(
                                    '$displaySteps',
                                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: accent),
                                  ),
                                  Text('adım', style: TextStyle(fontSize: 12, color: muted)),
                                ]),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              progress >= 1.0
                                  ? '🎉 Günlük hedefe ulaştın!'
                                  : 'Hedef: $goal adım — ${((1 - progress) * goal).toInt()} adım kaldı',
                              style: TextStyle(fontSize: 13, color: progress >= 1.0 ? positive : textSoft),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _StatChip('🏃 $distance km', 'Mesafe',  bgSoft, border, text, muted)),
                                const SizedBox(width: 8),
                                Expanded(child: _StatChip('🔥 $calories kcal', 'Kalori', bgSoft, border, text, muted)),
                                const SizedBox(width: 8),
                                Expanded(child: _StatChip('🎯 $goal', 'Hedef',          bgSoft, border, text, muted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── PEDOMETER DURUM KARTI ─────────
                      Container(
                        decoration: BoxDecoration(
                          color: _isPedActive ? positive.withOpacity(0.08) : bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _isPedActive ? positive.withOpacity(0.3) : border),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          Icon(
                            _isPedActive ? Icons.sensors : Icons.sensors_off,
                            color: _isPedActive ? positive : muted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isPedActive
                                  ? 'Pedometer aktif — adımların canlı sayılıyor'
                                  : 'Pedometer kapalı — manuel giriş yapabilirsin',
                              style: TextStyle(fontSize: 12, color: _isPedActive ? positive : muted),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 12),

                      // ── FORM ──────────────────────────
                      Container(
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stepsData != null ? 'Güncelle' : 'Adım Gir',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isPedActive
                                  ? 'Pedometer aktif — adımlar otomatik dolduruluyor'
                                  : 'Manuel olarak adım sayısı girebilirsin',
                              style: TextStyle(fontSize: 11, color: muted),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _stepsController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: text),
                              readOnly: _isPedActive, // pedometer aktifse readonly
                              decoration: InputDecoration(
                                labelText: 'Adım sayısı',
                                prefixIcon: const Icon(Icons.directions_walk),
                                suffixIcon: _isPedActive
                                    ? Icon(Icons.lock_outline, size: 16, color: muted)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _goalController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: text),
                              decoration: const InputDecoration(
                                labelText: 'Günlük hedef',
                                prefixIcon: Icon(Icons.flag_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () => _save(stepsData),
                                child: _isLoading
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                    : Text(stepsData != null ? 'Güncelle' : 'Kaydet'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value, label;
  final Color bgSoft, border, text, muted;
  const _StatChip(this.value, this.label, this.bgSoft, this.border, this.text, this.muted);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, color: muted)),
      ]),
    );
  }
}