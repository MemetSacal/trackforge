// ── staged_loader.dart (v8 UI cilası) ───────────────────
// Job pattern sayesinde AI üretimi 30-60 sn arka planda. Boş spinner
// yerine aşamalı mesajlar akar: kullanıcı "düşünüyor" hisseder.
// Mesajlar zamanlamayla değişir (gerçek aşamaya bağlı değil — algı işi).
import 'package:flutter/material.dart';

class StagedLoader extends StatefulWidget {
  final List<String> stages;
  final Color accent;
  final Color text;
  const StagedLoader({
    super.key,
    required this.stages,
    required this.accent,
    required this.text,
  });

  @override
  State<StagedLoader> createState() => _StagedLoaderState();
}

class _StagedLoaderState extends State<StagedLoader>
    with SingleTickerProviderStateMixin {
  int _stage = 0;
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _advance();
  }

  void _advance() {
    // Her aşama ~4 sn; son aşamada takılı kal (üretim bitince ekran değişir)
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (!mounted) return;
      if (_stage < widget.stages.length - 1) {
        setState(() => _stage++);
        _advance();
      }
    });
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.4, end: 1.0).animate(_pulse),
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [widget.accent, widget.accent.withOpacity(0.5)],
                ),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              widget.stages[_stage],
              key: ValueKey(_stage),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: widget.text,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Aşama noktaları
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.stages.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: i <= _stage ? 18 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i <= _stage ? widget.accent : widget.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(99),
              ),
            )),
          ),
        ],
      ),
    );
  }
}
