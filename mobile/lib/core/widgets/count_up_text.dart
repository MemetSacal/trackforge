// ── count_up_text.dart (v8 UI cilası) ───────────────────
// Sayılar anında basılmak yerine 0'dan değerine "sayarak" çıkar.
// Bedava ama "canlı uygulama" hissinin yarısı budur.
import 'package:flutter/material.dart';

class CountUpText extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final String Function(num v)? formatter; // örn. binlik ayraç, "1.2L"
  final Duration duration;

  const CountUpText({
    super.key,
    required this.value,
    this.style,
    this.formatter,
    this.duration = const Duration(milliseconds: 650),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(
        formatter != null ? formatter!(v) : v.toInt().toString(),
        style: style,
      ),
    );
  }
}
