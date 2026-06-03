// ── gamification_screen.dart ────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../app.dart';

final gamificationDetailProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiClient.instance.get(Endpoints.gamificationSummary);
  return Map<String, dynamic>.from(response.data);
});

class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark   = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg       = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard   = isDark ? const Color(0xFF141620) : Colors.white;
    final bgSoft   = isDark ? const Color(0xFF0F1016) : const Color(0xFFE8EBF2);
    final border   = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text     = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final textSoft = isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);
    final muted    = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent   = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim= isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);
    final positive = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);

    final dataAsync = ref.watch(gamificationDetailProvider);

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
                      Text('Gamification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5)),
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
                GestureDetector(
                  onTap: () => ref.invalidate(gamificationDetailProvider),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                    child: Icon(Icons.refresh_rounded, size: 16, color: textSoft),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: dataAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: accent)),
              error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
              data: (data) {
                final level = data['level'] != null ? Map<String, dynamic>.from(data['level']) : <String, dynamic>{};
                final streaks = (data['streaks'] as List? ?? []).map((s) => Map<String, dynamic>.from(s)).toList();
                final badges  = (data['badges']  as List? ?? []).map((b) => Map<String, dynamic>.from(b)).toList();

                const thresholds = [0, 500, 1500, 3000, 6000];
                final xp  = (level['xp']    as num?)?.toInt() ?? 0;
                final lvl = (level['level'] as num?)?.toInt() ?? 1;
                final nextT    = lvl < thresholds.length ? thresholds[lvl] : 9999;
                final currentT = lvl > 0 ? thresholds[lvl - 1] : 0;
                final progress = lvl >= thresholds.length ? 1.0 : ((xp - currentT) / (nextT - currentT)).clamp(0.0, 1.0);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Column(
                    children: [

                      // ── SEVİYE KARTI ──────────────────
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF1a1400), const Color(0xFF2a1f00)]
                                : [accent, accent.withOpacity(0.8)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [BoxShadow(color: accent.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? accent : Colors.white, width: 2.5),
                              ),
                              child: Center(child: Text('${level['level'] ?? 1}',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? accent : Colors.white))),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(level['level_title'] ?? 'Beginner',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? accent : Colors.white)),
                                  const SizedBox(height: 4),
                                  Text('$xp XP', style: TextStyle(fontSize: 15, color: isDark ? accent.withOpacity(0.8) : Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600)),
                                  if (lvl < thresholds.length)
                                    Text('Sonraki: $nextT XP', style: TextStyle(fontSize: 11, color: isDark ? accent.withOpacity(0.6) : Colors.white.withOpacity(0.7))),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: progress, minHeight: 8,
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                      color: isDark ? accent : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Text('$currentT XP', style: TextStyle(fontSize: 9, color: isDark ? accent.withOpacity(0.6) : Colors.white.withOpacity(0.7))),
                                    Text(lvl < thresholds.length ? '$nextT XP' : 'MAX', style: TextStyle(fontSize: 9, color: isDark ? accent.withOpacity(0.6) : Colors.white.withOpacity(0.7))),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── SERİLER ───────────────────────
                      _sectionHeader('🔥 Seriler', text),
                      const SizedBox(height: 10),
                      streaks.isEmpty
                          ? _emptyCard('Henüz seri yok — su, egzersiz ve uyku takip et!', bgCard, border, muted)
                          : Row(
                              children: streaks.map((s) {
                                final type    = s['streak_type'] as String? ?? '';
                                final current = (s['current_streak'] as num?)?.toInt() ?? 0;
                                final longest = (s['longest_streak'] as num?)?.toInt() ?? 0;
                                final emoji   = type == 'water' ? '💧' : type == 'exercise' ? '🏋️' : '😴';
                                final label   = type == 'water' ? 'Su' : type == 'exercise' ? 'Egzersiz' : 'Uyku';

                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      children: [
                                        Text(emoji, style: const TextStyle(fontSize: 28)),
                                        const SizedBox(height: 6),
                                        Text('$current', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: accent)),
                                        Text('gün', style: TextStyle(fontSize: 10, color: muted)),
                                        const SizedBox(height: 4),
                                        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: text)),
                                        Text('En iyi: $longest', style: TextStyle(fontSize: 10, color: muted)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 16),

                      // ── ROZETLER ──────────────────────
                      _sectionHeader('🏅 Rozetler', text),
                      const SizedBox(height: 10),
                      badges.isEmpty
                          ? _emptyCard('Henüz rozet kazanılmadı — hedeflere ulaş!', bgCard, border, muted)
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85),
                              itemCount: badges.length,
                              itemBuilder: (_, i) {
                                final b    = badges[i];
                                final name = b['badge_name'] as String? ?? '';
                                final desc = b['description'] as String? ?? '';
                                final key  = b['badge_key']  as String? ?? '';
                                final emoji = key.contains('water') ? '💧'
                                    : key.contains('workout') || key.contains('exercise') ? '💪'
                                    : key.contains('weight') ? '⚡'
                                    : key.contains('photo') ? '📸'
                                    : key.contains('streak') ? '⚔️' : '🏆';

                                return Container(
                                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(emoji, style: const TextStyle(fontSize: 30)),
                                      const SizedBox(height: 6),
                                      Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: text)),
                                      if (desc.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(desc, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 9, color: muted)),
                                      ],
                                    ],
                                  ),
                                );
                              },
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

  Widget _sectionHeader(String title, Color text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
  );

  Widget _emptyCard(String msg, Color bgCard, Color border, Color muted) => Container(
    width: double.infinity,
    decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
    padding: const EdgeInsets.all(20),
    child: Text(msg, style: TextStyle(fontSize: 13, color: muted), textAlign: TextAlign.center),
  );
}