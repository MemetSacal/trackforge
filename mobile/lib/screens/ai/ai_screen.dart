// ── ai_screen.dart ──────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../app.dart';
import 'weekly_summary_screen.dart';
import 'workout_plan_screen.dart';
import 'meal_advice_screen.dart';
import 'recipe_screen.dart';
import 'calorie_vision_screen.dart';

final aiCoachNameProvider = FutureProvider<String>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.preferences);
    return response.data['ai_name'] as String? ?? 'TrackForge AI';
  } catch (_) { return 'TrackForge AI'; }
});

class AiScreen extends ConsumerWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final coachName = ref.watch(aiCoachNameProvider).value ?? 'TrackForge AI';

    final features = [
      _Feature('📊', 'Haftalık AI Özeti',   'Verilerine göre kişisel rapor',    'Hazır',  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeeklySummaryScreen()))),
      _Feature('📸', 'Fotoğraftan Kalori',  'Claude Vision ile tahmin',          'Yeni',   () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalorieVisionScreen()))),
      _Feature('🍽️', 'Diyet Tavsiyesi',    'BMR/TDEE bazlı öneri',             null,     () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealAdviceScreen()))),
      _Feature('👨‍🍳', 'Tarif Önerici',   'Malzeme bazlı tarifler',            null,     () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeScreen()))),
      _Feature('💪', 'Antrenman Planı',     'Lokasyon bazlı program',            null,     () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkoutPlanScreen()))),
      _Feature('🎯', 'Hedef Görselleştirme','DALL-E 3 ile vizyon',              'Yakında', null),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── HEADER ────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: bg,
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('AI Koç', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                          child: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round, size: 15, color: textSoft),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                        child: Icon(Icons.notifications_none_rounded, size: 15, color: textSoft),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── HERO CARD ────────────────────────
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF1a1400), const Color(0xFF2a1f00), const Color(0xFF1a1200)]
                          : [accent, accent.withOpacity(0.85)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: accent.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -20, right: -20,
                        child: Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coachName.toUpperCase(),
                            style: TextStyle(fontSize: 10, letterSpacing: 3,
                              color: isDark ? accent.withOpacity(0.7) : Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sana göre çalışan sistem',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                              color: isDark ? accent : Colors.white, height: 1.2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'AI veriyi göstermez — yorumlar, yönlendirir ve gerektiğinde tavrını değiştirir.',
                            style: TextStyle(fontSize: 12,
                              color: isDark ? accent.withOpacity(0.8) : Colors.white.withOpacity(0.85),
                              height: 1.5),
                          ),
                          const SizedBox(height: 14),
                          // Stat chips
                          Row(
                            children: [
                              _StatChip(label: '5 Özellik', isDark: isDark, accent: accent),
                              const SizedBox(width: 8),
                              _StatChip(label: 'Claude API', isDark: isDark, accent: accent),
                              const SizedBox(width: 8),
                              _StatChip(label: 'Kişisel', isDark: isDark, accent: accent),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── FEATURE KARTLARI ─────────────────
                ...features.map((f) => GestureDetector(
                  onTap: f.onTap,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(f.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                              const SizedBox(height: 2),
                              Text(f.desc, style: TextStyle(fontSize: 11, color: muted)),
                            ],
                          ),
                        ),
                        if (f.badge != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: f.badge == 'Yakında' ? bgSoft : accentDim,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: f.badge == 'Yakında' ? border : accent),
                            ),
                            child: Text(f.badge!, style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              color: f.badge == 'Yakında' ? muted : accent,
                            )),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(Icons.chevron_right, size: 16, color: f.onTap != null ? muted : border),
                      ],
                    ),
                  ),
                )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature {
  final String emoji, title, desc;
  final String? badge;
  final VoidCallback? onTap;
  const _Feature(this.emoji, this.title, this.desc, this.badge, this.onTap);
}

class _StatChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color accent;
  const _StatChip({required this.label, required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: isDark ? accent : Colors.white,
      )),
    );
  }
}