// ── su_tab.dart ─────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';

final todayWaterProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.instance.get('${Endpoints.water}/date/${TFDateUtils.today()}');
    return Map<String, dynamic>.from(response.data);
  } catch (_) { return null; }
});

class SuTab extends ConsumerStatefulWidget {
  const SuTab({super.key});
  @override
  ConsumerState<SuTab> createState() => _SuTabState();
}

class _SuTabState extends ConsumerState<SuTab> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() { _amountController.dispose(); super.dispose(); }

  Future<void> _addWater(int current, Map<String, dynamic>? existing, int target) async {
    final text = _amountController.text.trim();
    if (text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Miktar zorunludur'))); return; }
    final amount = int.tryParse(text);
    if (amount == null || amount < 50 || amount > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Miktar 50–10000 ml arasında olmalı'))); return;
    }
    setState(() => _isLoading = true);
    try {
      if (existing != null) {
        await ApiClient.instance.put('${Endpoints.water}/${existing['id']}', data: {
          'amount_ml': current + amount, 'target_ml': target,
        });
      } else {
        await ApiClient.instance.post(Endpoints.water, data: {
          'date': TFDateUtils.today(), 'amount_ml': amount, 'target_ml': 2000,
        });
      }
      _amountController.clear();
      ref.invalidate(todayWaterProvider);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Su eklenirken hata oluştu')));
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
    final accentDim= isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);

    final waterAsync = ref.watch(todayWaterProvider);

    return waterAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: accent)),
      error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
      data: (waterLog) {
        final current  = (waterLog?['amount_ml'] as num?)?.toInt() ?? 0;
        final target   = (waterLog?['target_ml'] as num?)?.toInt() ?? 2000;
        final progress = (current / target).clamp(0.0, 1.0);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            children: [
              // ── BÜYÜK SU KARTI ──────────────────────
              Container(
                decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // v8: dolan bardak — düz çubuk yerine sevimli metafor
                    _WaterGlass(progress: progress, accent: accent),
                    const SizedBox(height: 16),
                    Text(
                      current > 0 ? '${(current / 1000).toStringAsFixed(1)}L' : '0.0L',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: accent, height: 1),
                    ),
                    const SizedBox(height: 4),
                    Text('Günlük hedef: ${(target / 1000).toStringAsFixed(1)}L', style: TextStyle(fontSize: 13, color: textSoft)),
                    const SizedBox(height: 6),
                    Text(
                      progress >= 1.0 ? '🎉 Hedefe ulaştın!' : '%${(progress * 100).toInt()} tamamlandı',
                      style: TextStyle(fontSize: 12, color: progress >= 1.0 ? const Color(0xFF34D399) : muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── BUGÜNKÜ GİRİŞLER ────────────────────
              if (waterLog != null) ...[
                Container(
                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bugünkü Eklemeler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(5, (i) {
                          final h = i < (current / (target / 5)).floor()
                              ? 1.0
                              : (i == (current / (target / 5)).floor()
                                  ? (current % (target / 5)) / (target / 5)
                                  : 0.05);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(5)),
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: h.clamp(0.05, 1.0),
                                  child: Container(decoration: BoxDecoration(color: const Color(0xFF22D3EE), borderRadius: BorderRadius.circular(4))),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text('$current ml / $target ml', style: TextStyle(fontSize: 12, color: textSoft)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── HIZLI EKLE ──────────────────────────
              Container(
                decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hızlı Ekle', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                    const SizedBox(height: 12),
                    Row(
                      children: ['150ml', '250ml', '500ml', '1L'].map((label) {
                        final ml = label == '1L' ? 1000 : int.parse(label.replaceAll('ml', ''));
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: GestureDetector(
                              onTap: () {
                                _amountController.text = '$ml';
                                _addWater(current, waterLog, target);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: accentDim,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: accent.withOpacity(0.4)),
                                ),
                                child: Center(child: Text(label, style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 13))),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // ── FIX: Row içinde infinite width hatası giderildi ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: text),
                            decoration: const InputDecoration(
                              labelText: 'Miktar (ml)',
                              prefixIcon: Icon(Icons.water_drop_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 80,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _addWater(current, waterLog, target),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Text('Ekle'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
// ── v8: Dolan su bardağı — animasyonlu, dalgalı ──────────
class _WaterGlass extends StatefulWidget {
  final double progress;
  final Color accent;
  const _WaterGlass({required this.progress, required this.accent});

  @override
  State<_WaterGlass> createState() => _WaterGlassState();
}

class _WaterGlassState extends State<_WaterGlass>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))
    ..repeat();

  @override
  void dispose() { _wave.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110, height: 140,
      child: AnimatedBuilder(
        animation: _wave,
        builder: (_, __) => CustomPaint(
          painter: _GlassPainter(
            progress: widget.progress.clamp(0.0, 1.0),
            wavePhase: _wave.value * 2 * 3.14159,
            accent: widget.accent,
          ),
        ),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  final double progress, wavePhase;
  final Color accent;
  _GlassPainter({required this.progress, required this.wavePhase, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Bardak gövdesi: hafif daralan trapez
    final glass = Path()
      ..moveTo(w * 0.18, 0)
      ..lineTo(w * 0.82, 0)
      ..lineTo(w * 0.72, h)
      ..lineTo(w * 0.28, h)
      ..close();

    // Cam kenarı
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = accent.withOpacity(0.5);

    // FIX: bardak ağzına kadar dolmasın — %100'de bile görsel tavan %85.
    // Üstte bir miktar "hava payı" kalır, daha gerçekçi durur.
    const fillCap = 0.85;
    final visualFill = (progress.clamp(0.0, 1.0)) * fillCap;
    // Hedef (günlük su hedefi) çizgisi: %100'ün denk geldiği seviye.
    final targetY = h * (1 - fillCap);

    // Su seviyesi (alttan dolar) — iki dalga katmanı ile akış hissi
    canvas.save();
    canvas.clipPath(glass);
    final fillTop = h * (1 - visualFill);

    // Arka (açık) dalga
    final backWave = Path()..moveTo(0, fillTop);
    for (double x = 0; x <= w; x++) {
      final y = fillTop + 4 * sinApprox(wavePhase * 1.3 + x / w * 6.28 + 1.6);
      backWave.lineTo(x, y);
    }
    backWave..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(backWave, Paint()..color = accent.withOpacity(0.35));

    // Ön (koyu) dalga
    final wave = Path()..moveTo(0, fillTop);
    for (double x = 0; x <= w; x++) {
      final y = fillTop + 5 * (0.5 + 0.5 * (x / w)) * sinApprox(wavePhase + x / w * 6.28);
      wave.lineTo(x, y);
    }
    wave..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(wave, Paint()..color = accent.withOpacity(0.85));
    canvas.restore();

    // Hedef çizgisi (kesik kesik) — bardağın içinde, camın üstünde çizilir
    final dashPaint = Paint()
      ..color = accent.withOpacity(0.9)
      ..strokeWidth = 1.6;
    const dashW = 5.0, gapW = 4.0;
    double dx = w * 0.22;
    final lineEnd = w * 0.78;
    while (dx < lineEnd) {
      canvas.drawLine(Offset(dx, targetY), Offset((dx + dashW).clamp(0, lineEnd), targetY), dashPaint);
      dx += dashW + gapW;
    }
    // Küçük "hedef" etiketi (bayrak noktası)
    canvas.drawCircle(Offset(w * 0.78, targetY), 2.5, Paint()..color = accent);

    canvas.drawPath(glass, stroke);
  }

  // Hafif sinüs (dart:math'a bağımlılık azaltmak için inline)
  double sinApprox(double x) {
    while (x > 3.14159) x -= 6.28318;
    while (x < -3.14159) x += 6.28318;
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }

  @override
  bool shouldRepaint(_GlassPainter old) =>
      old.progress != progress || old.wavePhase != wavePhase;
}
