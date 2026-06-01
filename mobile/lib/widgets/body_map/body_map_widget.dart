import 'package:flutter/material.dart';

// Kas grubu → egzersiz map
const Map<String, List<String>> exerciseMuscleMap = {
  'bench press': ['chest', 'triceps', 'front_shoulder'],
  'şınav': ['chest', 'triceps', 'front_shoulder'],
  'şınav (tempo: 3-0-1)': ['chest', 'triceps', 'front_shoulder'],
  'push up': ['chest', 'triceps', 'front_shoulder'],
  'elmas şınav': ['triceps', 'chest'],
  'diamond şınav': ['triceps', 'chest'],
  'pike push-up': ['abs', 'front_shoulder'],
  'pike şınav': ['abs', 'front_shoulder'],
  'triceps dips': ['triceps', 'chest'],
  'triceps dips (sandalye)': ['triceps', 'chest'],
  'dips (sandalye)': ['triceps', 'chest'],
  'dips': ['triceps', 'chest'],
  'incline press': ['chest', 'front_shoulder'],
  'dumbbell fly': ['chest'],
  'cable fly': ['chest'],
  'deadlift': ['lower_back', 'hamstring', 'glutes'],
  'pull up': ['back', 'biceps'],
  'lat pulldown': ['back', 'biceps'],
  'barbell row': ['back', 'biceps'],
  'seated row': ['back', 'biceps'],
  'face pull': ['rear_shoulder', 'back'],
  'superman': ['lower_back', 'glutes'],
  'overhead press': ['front_shoulder', 'triceps'],
  'ohp': ['front_shoulder', 'triceps'],
  'lateral raise': ['side_shoulder'],
  'dumbbell lateral raise': ['side_shoulder'],
  'shrugs': ['traps'],
  'squat': ['quad', 'glutes', 'hamstring'],
  'leg press': ['quad', 'glutes'],
  'lunge': ['quad', 'glutes', 'hamstring'],
  'leg extension': ['quad'],
  'leg curl': ['hamstring'],
  'calf raise': ['calf'],
  'romanian deadlift': ['hamstring', 'glutes', 'lower_back'],
  'hip thrust': ['glutes', 'hamstring'],
  'bulgarian split squat': ['quad', 'glutes', 'hamstring'],
  'bicep curl': ['biceps'],
  'biceps curl': ['biceps'],
  'hammer curl': ['biceps'],
  'tricep pushdown': ['triceps'],
  'skull crusher': ['triceps'],
  'plank': ['abs', 'lower_back'],
  'crunch': ['abs'],
  'sit up': ['abs'],
  'leg raise': ['abs'],
  'russian twist': ['abs'],
};

List<String> getMusclesForExercise(String exerciseName) {
  final lower = exerciseName.toLowerCase().trim();
  if (exerciseMuscleMap.containsKey(lower)) return exerciseMuscleMap[lower]!;
  for (final entry in exerciseMuscleMap.entries) {
    if (lower.contains(entry.key) || entry.key.contains(lower)) {
      return entry.value;
    }
  }
  return [];
}

class BodyMapWidget extends StatefulWidget {
  final List<String> highlightedMuscles;
  final double height;

  const BodyMapWidget({
    super.key,
    required this.highlightedMuscles,
    this.height = 320,
  });

  @override
  State<BodyMapWidget> createState() => _BodyMapWidgetState();
}

class _BodyMapWidgetState extends State<BodyMapWidget> {
  bool _showFront = true;

  // Ön görünüm kas koordinatları
  // Değerler 0.0-1.0 arası — PNG boyutuna göre oransal
  static const Map<String, List<_MuscleZone>> _frontZones = {
    'chest':          [_MuscleZone(0.44, 0.30, 0.13, 0.08)],
    'abs':            [_MuscleZone(0.44, 0.39, 0.13, 0.11)],
    'front_shoulder': [_MuscleZone(0.42, 0.24, 0.05, 0.06), _MuscleZone(0.53, 0.24, 0.05, 0.06)],
    'side_shoulder':  [_MuscleZone(0.41, 0.24, 0.05, 0.06), _MuscleZone(0.54, 0.24, 0.05, 0.06)],
    'biceps':         [_MuscleZone(0.41, 0.32, 0.05, 0.08), _MuscleZone(0.54, 0.32, 0.05, 0.08)],
    'triceps':        [_MuscleZone(0.40, 0.32, 0.04, 0.08), _MuscleZone(0.56, 0.32, 0.04, 0.08)],
    'traps':          [_MuscleZone(0.43, 0.19, 0.14, 0.06)],
    'quad':           [_MuscleZone(0.43, 0.59, 0.06, 0.13), _MuscleZone(0.51, 0.59, 0.06, 0.13)],
    'calf':           [_MuscleZone(0.43, 0.77, 0.05, 0.08), _MuscleZone(0.52, 0.77, 0.05, 0.08)],
    'glutes':         [_MuscleZone(0.43, 0.52, 0.06, 0.06), _MuscleZone(0.51, 0.52, 0.06, 0.06)],
  };

  static const Map<String, List<_MuscleZone>> _backZones = {
    'back':           [_MuscleZone(0.43, 0.27, 0.14, 0.13)],
    'lower_back':     [_MuscleZone(0.43, 0.41, 0.14, 0.06)],
    'traps':          [_MuscleZone(0.43, 0.17, 0.14, 0.07)],
    'rear_shoulder':  [_MuscleZone(0.41, 0.24, 0.05, 0.06), _MuscleZone(0.54, 0.24, 0.05, 0.06)],
    'triceps':        [_MuscleZone(0.41, 0.31, 0.05, 0.09), _MuscleZone(0.54, 0.31, 0.05, 0.09)],
    'glutes':         [_MuscleZone(0.43, 0.52, 0.07, 0.08), _MuscleZone(0.50, 0.52, 0.07, 0.08)],
    'hamstring':      [_MuscleZone(0.43, 0.61, 0.06, 0.11), _MuscleZone(0.51, 0.61, 0.06, 0.11)],
    'calf':           [_MuscleZone(0.43, 0.77, 0.05, 0.08), _MuscleZone(0.52, 0.77, 0.05, 0.08)],
  };

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).primaryColor;
    final zones = _showFront ? _frontZones : _backZones;

    return Column(
      children: [
        // Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildToggle('Ön', _showFront, () => setState(() => _showFront = true), accentColor),
            const SizedBox(width: 8),
            _buildToggle('Arka', !_showFront, () => setState(() => _showFront = false), accentColor),
          ],
        ),
        const SizedBox(height: 12),

        // PNG + overlay
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              // PNG oranı: figür PNG'nin %30-70 yatay, %5-95 dikey
              // Figürün gerçek piksel alanını hesapla
              const imgAspect = 1024.0 / 559.0;
              final displayW = h * imgAspect < w ? h * imgAspect : w;
              final displayH = displayW / imgAspect;
              final offsetX = (w - displayW) / 2;
              final offsetY = (h - displayH) / 2;

              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      _showFront
                          ? 'assets/images/body_front.jpg'
                          : 'assets/images/body_back.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  ...widget.highlightedMuscles
                      .where((m) => zones.containsKey(m))
                      .expand((muscle) => zones[muscle]!)
                      .map((zone) => Positioned(
                            left: offsetX + zone.x * displayW,
                            top: offsetY + zone.y * displayH,
                            width: zone.w * displayW,
                            height: zone.h * displayH,
                            child: Container(
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.8),
                                  width: 2,
                                ),
                              ),
                            ),
                          )),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Kas etiketleri
        if (widget.highlightedMuscles.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: widget.highlightedMuscles
                .map((m) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        _muscleLabel(m),
                        style: TextStyle(
                          fontSize: 12,
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildToggle(String label, bool isSelected, VoidCallback onTap, Color accentColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.15)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? accentColor : null,
          ),
        ),
      ),
    );
  }

  String _muscleLabel(String muscle) {
    const labels = {
      'chest': 'Göğüs', 'back': 'Sırt', 'lower_back': 'Alt Sırt',
      'traps': 'Trapez', 'front_shoulder': 'Ön Omuz',
      'side_shoulder': 'Yan Omuz', 'rear_shoulder': 'Arka Omuz',
      'biceps': 'Biceps', 'triceps': 'Triceps', 'abs': 'Karın',
      'quad': 'Ön Bacak', 'hamstring': 'Arka Bacak',
      'glutes': 'Kalça', 'calf': 'Baldır',
    };
    return labels[muscle] ?? muscle;
  }
}

// Kas bölgesi koordinat modeli
// x, y: sol üst köşe (0.0-1.0 oransal)
// w, h: genişlik ve yükseklik (0.0-1.0 oransal)
class _MuscleZone {
  final double x, y, w, h;
  const _MuscleZone(this.x, this.y, this.w, this.h);
}