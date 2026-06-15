// ── celebrate.dart (v8 UI cilası) ───────────────────────
// Paketsiz konfeti patlaması — rozet, seri, düello kazanımı anlarında.
// Tek satırla çağrılır: Celebrate.burst(context).
import 'dart:math';
import 'package:flutter/material.dart';

class Celebrate {
  static void burst(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiLayer(onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

class _ConfettiLayer extends StatefulWidget {
  final VoidCallback onDone;
  const _ConfettiLayer({required this.onDone});
  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));
  final _rng = Random();
  late final List<_Particle> _particles;

  static const _colors = [
    Color(0xFFFFB020), Color(0xFFFF6B2B), Color(0xFF34D399),
    Color(0xFF60A5FA), Color(0xFFF472B6),
  ];

  @override
  void initState() {
    super.initState();
    _particles = List.generate(40, (_) => _Particle(
      angle: _rng.nextDouble() * 2 * pi,
      speed: 120 + _rng.nextDouble() * 220,
      color: _colors[_rng.nextInt(_colors.length)],
      size: 6 + _rng.nextDouble() * 7,
      spin: _rng.nextDouble() * 6 - 3,
    ));
    _c.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: size,
          painter: _ConfettiPainter(_particles, _c.value, size),
        ),
      ),
    );
  }
}

class _Particle {
  final double angle, speed, size, spin;
  final Color color;
  _Particle({required this.angle, required this.speed, required this.color,
      required this.size, required this.spin});
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  final Size screen;
  _ConfettiPainter(this.particles, this.t, this.screen);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = screen.width / 2, cy = screen.height * 0.38;
    final paint = Paint();
    for (final p in particles) {
      final dx = cx + cos(p.angle) * p.speed * t;
      final dy = cy + sin(p.angle) * p.speed * t + 380 * t * t; // yerçekimi
      paint.color = p.color.withOpacity((1 - t).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.spin * t * 6);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
