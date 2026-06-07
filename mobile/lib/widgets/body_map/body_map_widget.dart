// ── widgets/body_map/body_map_widget.dart ───────────────
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const Map<String, List<Rect>> _frontRects = {
  'quad': [
      Rect.fromLTWH(0.34, 0.54, 0.11, 0.20), // sol bacak
      Rect.fromLTWH(0.50, 0.54, 0.11, 0.20), // sağ bacak
    ],
    'hip_flexor': [
      Rect.fromLTWH(0.35, 0.48, 0.09, 0.08),
      Rect.fromLTWH(0.51, 0.48, 0.09, 0.08),
    ],
    'calf_front': [
      Rect.fromLTWH(0.35, 0.76, 0.09, 0.13),
      Rect.fromLTWH(0.51, 0.76, 0.09, 0.13),
    ],
    'chest': [
      Rect.fromLTWH(0.32, 0.20, 0.12, 0.10), // sol göğüs
      Rect.fromLTWH(0.49, 0.20, 0.12, 0.10), // sağ göğüs
    ],
    'abs': [
      Rect.fromLTWH(0.37, 0.32, 0.14, 0.17),
    ],
    'obliques': [
      Rect.fromLTWH(0.26, 0.32, 0.09, 0.14),
      Rect.fromLTWH(0.54, 0.32, 0.09, 0.14),
    ],
    'front_shoulder': [
      Rect.fromLTWH(0.24, 0.18, 0.09, 0.09),
      Rect.fromLTWH(0.62, 0.18, 0.09, 0.09),
    ],
    'side_shoulder': [
      Rect.fromLTWH(0.19, 0.19, 0.08, 0.08),
      Rect.fromLTWH(0.68, 0.19, 0.08, 0.08),
    ],
    'biceps': [
      Rect.fromLTWH(0.17, 0.29, 0.09, 0.12),
      Rect.fromLTWH(0.69, 0.29, 0.09, 0.12),
    ],
    'forearm_front': [
      Rect.fromLTWH(0.14, 0.42, 0.09, 0.12),
      Rect.fromLTWH(0.72, 0.42, 0.09, 0.12),
    ],
};

const Map<String, List<Rect>> _backRects = {
  'back': [
    Rect.fromLTWH(0.30, 0.26, 0.14, 0.14),
    Rect.fromLTWH(0.52, 0.26, 0.14, 0.14),
  ],
  'traps': [
    Rect.fromLTWH(0.34, 0.15, 0.24, 0.09),
  ],
  'lower_back': [
    Rect.fromLTWH(0.37, 0.39, 0.20, 0.07),
  ],
  'rear_shoulder': [
    Rect.fromLTWH(0.22, 0.18, 0.10, 0.09),
    Rect.fromLTWH(0.63, 0.18, 0.10, 0.09),
  ],
  'triceps': [
    Rect.fromLTWH(0.18, 0.28, 0.10, 0.12),
    Rect.fromLTWH(0.67, 0.28, 0.10, 0.12),
  ],
  'forearm_back': [
    Rect.fromLTWH(0.15, 0.41, 0.10, 0.10),
    Rect.fromLTWH(0.70, 0.41, 0.10, 0.10),
  ],
  'glutes': [
    Rect.fromLTWH(0.36, 0.48, 0.24, 0.10),
  ],
  'hamstring': [
    Rect.fromLTWH(0.35, 0.57, 0.12, 0.17),
    Rect.fromLTWH(0.52, 0.57, 0.12, 0.17),
  ],
  'calf': [
    Rect.fromLTWH(0.35, 0.76, 0.10, 0.12),
    Rect.fromLTWH(0.52, 0.76, 0.10, 0.12),
  ],
};

const _frontMuscles = {
  'chest', 'abs', 'obliques', 'front_shoulder', 'side_shoulder',
  'biceps', 'forearm_front', 'quad', 'hip_flexor', 'calf_front',
};
const _backMuscles = {
  'traps', 'back', 'lower_back', 'rear_shoulder', 'triceps',
  'forearm_back', 'glutes', 'hamstring', 'calf',
};

class BodyMapWidget extends StatefulWidget {
  final List<String> highlightedMuscles;
  final double height;

  const BodyMapWidget({
    super.key,
    required this.highlightedMuscles,
    this.height = 300,
  });

  @override
  State<BodyMapWidget> createState() => _BodyMapWidgetState();
}

class _BodyMapWidgetState extends State<BodyMapWidget> {
  bool _showFront = true;
  String? _svgContent;

  bool _svgLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_svgLoaded) {
      _svgLoaded = true;
      _loadSvg();
    }
  }
  Future<void> _loadSvg() async {
    final content = await DefaultAssetBundle.of(context)
        .loadString('assets/images/muscle_front_and_back.svg');
    if (mounted) setState(() => _svgContent = content);
  }

  @override
  void didUpdateWidget(BodyMapWidget old) {
    super.didUpdateWidget(old);
    if (old.highlightedMuscles != widget.highlightedMuscles &&
        widget.highlightedMuscles.isNotEmpty) {
      final hasFront = widget.highlightedMuscles.any(_frontMuscles.contains);
      final hasBack  = widget.highlightedMuscles.any(_backMuscles.contains);
      if (hasBack && !hasFront) setState(() => _showFront = false);
      if (hasFront && !hasBack) setState(() => _showFront = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final bgSoft = isDark ? const Color(0xFF1C1E2A) : const Color(0xFFE8EBF2);
    final muted  = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);

    // Ön: sol yarı, Arka: sağ yarı
   final svgViewBox = _showFront
       ? '0 0 203.495 354.434'
       : '203.495 0 203.495 354.434';
   const halfAspect = 203.495 / 354.434;

    final highlightRects   = _showFront ? _frontRects : _backRects;
    final activeHighlights = widget.highlightedMuscles
        .where(_showFront ? _frontMuscles.contains : _backMuscles.contains)
        .toList();

    return Column(
      children: [
        // ── ÖN / ARKA TAB ──────────────────────────────
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: bgSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _TabBtn(
                label: '👁 Ön Görünüm',
                active: _showFront,
                accent: accent,
                muted: muted,
                onTap: () => setState(() => _showFront = true),
              ),
              _TabBtn(
                label: '↩ Arka Görünüm',
                active: !_showFront,
                accent: accent,
                muted: muted,
                onTap: () => setState(() => _showFront = false),
              ),
            ],
          ),
        ),

        // ── SVG + OVERLAY ──────────────────────────────
        SizedBox(
          height: widget.height,
          width: double.infinity,
          child: _svgContent == null
              ? Center(child: CircularProgressIndicator(color: accent))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;

                    // viewBox'ı değiştirerek sadece ilgili yarıyı render et
                    final croppedSvg = _svgContent!.replaceFirst(
                      RegExp(r'viewBox="[^"]*"'),
                      'viewBox="$svgViewBox"',
                    );

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SvgPicture.string(
                          croppedSvg,
                          width: w,
                          height: widget.height,
                          fit: BoxFit.contain,
                        ),
                        CustomPaint(
                          size: Size(w, widget.height),
                          painter: _HighlightPainter(
                            highlightedMuscles: activeHighlights,
                            muscleRects: highlightRects,
                            svgAspectRatio: halfAspect,
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _HighlightPainter extends CustomPainter {
  final List<String> highlightedMuscles;
  final Map<String, List<Rect>> muscleRects;
  final double svgAspectRatio;

  const _HighlightPainter({
    required this.highlightedMuscles,
    required this.muscleRects,
    required this.svgAspectRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (highlightedMuscles.isEmpty) return;

    final widgetRatio = size.width / size.height;
    double renderW, renderH, offsetX, offsetY;

    if (widgetRatio > svgAspectRatio) {
      renderH = size.height;
      renderW = renderH * svgAspectRatio;
      offsetX = (size.width - renderW) / 2;
      offsetY = 0;
    } else {
      renderW = size.width;
      renderH = renderW / svgAspectRatio;
      offsetX = 0;
      offsetY = (size.height - renderH) / 2;
    }

    final fill = Paint()
      ..color = const Color(0xFFFFB020).withOpacity(0.45)
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = const Color(0xFFFFB020).withOpacity(0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final muscle in highlightedMuscles) {
      final rects = muscleRects[muscle];
      if (rects == null) continue;
      for (final nr in rects) {
        final rect = Rect.fromLTWH(
          offsetX + nr.left * renderW,
          offsetY + nr.top * renderH,
          nr.width * renderW,
          nr.height * renderH,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
        canvas.drawRRect(rrect, fill);
        canvas.drawRRect(rrect, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_HighlightPainter old) =>
      old.highlightedMuscles != highlightedMuscles ||
      old.muscleRects != muscleRects;
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent, muted;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.active,
    required this.accent,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active ? accent.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active ? Border.all(color: accent.withOpacity(0.4)) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? accent : muted,
            ),
          ),
        ),
      ),
    );
  }
}

List<String> getMusclesForExercise(String exerciseName) {
  final name = exerciseName.toLowerCase();
  if (name.contains('bench') || name.contains('chest') || name.contains('göğüs') || name.contains('pres')) return ['chest', 'front_shoulder', 'triceps'];
  if (name.contains('squat') || name.contains('sqat') || name.contains('bacak') || name.contains('leg press') || name.contains('goblet')) return ['quad', 'glutes', 'hamstring'];
  if (name.contains('deadlift') || name.contains('dead')) return ['back', 'lower_back', 'glutes', 'hamstring'];
  if (name.contains('pull') || name.contains('row') || name.contains('lat') || name.contains('sırt')) return ['back', 'traps', 'biceps'];
  if (name.contains('shoulder') || name.contains('omuz')) return ['front_shoulder', 'side_shoulder', 'rear_shoulder', 'triceps'];
  if (name.contains('bicep') || name.contains('curl') || name.contains('kol')) return ['biceps', 'forearm_front'];
  if (name.contains('tricep') || name.contains('dips') || name.contains('extension')) return ['triceps', 'forearm_back'];
  if (name.contains('lunge') || name.contains('step')) return ['quad', 'glutes', 'hamstring'];
  if (name.contains('calf') || name.contains('baldır')) return ['calf', 'calf_front'];
  if (name.contains('abs') || name.contains('karın') || name.contains('crunch') || name.contains('plank')) return ['abs', 'obliques'];
  if (name.contains('glute') || name.contains('hip') || name.contains('kalça')) return ['glutes', 'hip_flexor'];
  if (name.contains('run') || name.contains('koş') || name.contains('cardio')) return ['quad', 'hamstring', 'calf', 'calf_front'];
  if (name.contains('push') || name.contains('şınav')) return ['chest', 'triceps', 'front_shoulder'];
  if (name.contains('swing') || name.contains('kettlebell')) return ['glutes', 'hamstring', 'lower_back'];
  if (name.contains('press') && name.contains('over')) return ['front_shoulder', 'side_shoulder', 'triceps'];
  return [];
}