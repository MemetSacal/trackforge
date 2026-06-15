// ── pulse_skeleton.dart (v8 UI cilası) ──────────────────
// Paketsiz iskelet yükleme: boş spinner yerine içeriğin "hayaleti"
// nefes alır gibi parıldar. Premium hissin gizli kahramanı.
import 'package:flutter/material.dart';

class PulseSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? radius;
  const PulseSkeleton({super.key, this.height = 16, this.width, this.radius});

  @override
  State<PulseSkeleton> createState() => _PulseSkeletonState();
}

class _PulseSkeletonState extends State<PulseSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.white : Colors.black;
    return FadeTransition(
      opacity: Tween(begin: 0.06, end: 0.16).animate(
          CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          color: base,
          borderRadius: widget.radius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Hazır kart iskeleti — ekranlar tek satırla kullanır.
class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 110});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PulseSkeleton(height: height, radius: BorderRadius.circular(20)),
    );
  }
}
