// ── gamification_screen.dart ────────────────────────────
// Gamification ekranı.
// GET /gamification/summary → XP, seviye, streak, rozetler
// Kullanıcının ilerleme durumunu görsel olarak gösterir.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';

// ── PROVIDER ────────────────────────────────────────────
final gamificationDetailProvider =
FutureProvider<Map<String, dynamic>>((ref) async {
  final response =
  await ApiClient.instance.get(Endpoints.gamificationSummary);
  return Map<String, dynamic>.from(response.data);
});

// ── GAMİFİCATİON SCREEN ─────────────────────────────────
class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(gamificationDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(gamificationDetailProvider),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
        const Center(child: Text('Veri yüklenemedi')),
        data: (data) {
          final level = data['level'] != null
              ? Map<String, dynamic>.from(data['level'])
              : <String, dynamic>{};
          final rawStreaks = data['streaks'] as List? ?? [];
          final streaks = rawStreaks
              .map((s) => Map<String, dynamic>.from(s))
              .toList();
          final rawBadges = data['badges'] as List? ?? [];
          final badges = rawBadges
              .map((b) => Map<String, dynamic>.from(b))
              .toList();

          // XP progress hesapla
          const thresholds = [0, 500, 1500, 3000, 6000];
          final xp = (level['xp'] as num?)?.toInt() ?? 0;
          final lvl = (level['level'] as num?)?.toInt() ?? 1;
          final nextThreshold =
          lvl < thresholds.length ? thresholds[lvl] : 9999;
          final currentThreshold =
          lvl > 0 ? thresholds[lvl - 1] : 0;
          final progress = lvl >= thresholds.length
              ? 1.0
              : ((xp - currentThreshold) /
              (nextThreshold - currentThreshold))
              .clamp(0.0, 1.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── SEVİYE KARTI ──────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Seviye rozeti
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(36),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${level['level'] ?? 1}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    level['level_title'] ?? 'Beginner',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$xp XP',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (lvl < thresholds.length)
                                    Text(
                                      'Sonraki seviye: $nextThreshold XP',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // XP progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            backgroundColor: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.15),
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$currentThreshold XP',
                                style:
                                Theme.of(context).textTheme.bodySmall),
                            Text(
                              lvl < thresholds.length
                                  ? '$nextThreshold XP'
                                  : 'MAX',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── STREAK KARTLARI ───────────────────
                const Text(
                  'Seriler',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (streaks.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Henüz seri yok — su, egzersiz ve uyku takip et!',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                else
                  Row(
                    children: streaks.map((streak) {
                      final type =
                          streak['streak_type'] as String? ?? '';
                      final current =
                          (streak['current_streak'] as num?)?.toInt() ??
                              0;
                      final longest =
                          (streak['longest_streak'] as num?)?.toInt() ??
                              0;

                      // Streak tipine göre emoji ve renk
                      final emoji = type == 'water'
                          ? '💧'
                          : type == 'exercise'
                          ? '🏋️'
                          : '😴';
                      final label = type == 'water'
                          ? 'Su'
                          : type == 'exercise'
                          ? 'Egzersiz'
                          : 'Uyku';

                      return Expanded(
                        child: Card(
                          margin: const EdgeInsets.only(right: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(emoji,
                                    style:
                                    const TextStyle(fontSize: 28)),
                                const SizedBox(height: 8),
                                Text(
                                  '$current',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                                Text(
                                  'gün',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'En iyi: $longest',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 16),

                // ── ROZETLER ─────────────────────────
                const Text(
                  'Rozetler',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (badges.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Henüz rozet kazanılmadı — hedeflere ulaş!',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: badges.length,
                    itemBuilder: (context, index) {
                      final badge = badges[index];
                      final name =
                          badge['badge_name'] as String? ?? '';
                      final desc =
                          badge['description'] as String? ?? '';
                      final key = badge['badge_key'] as String? ?? '';

                      // Badge key'e göre emoji
                      final emoji = key.contains('water')
                          ? '💧'
                          : key.contains('workout') ||
                          key.contains('exercise')
                          ? '💪'
                          : key.contains('weight')
                          ? '⚡'
                          : key.contains('photo')
                          ? '📸'
                          : key.contains('streak')
                          ? '⚔️'
                          : '🏆';

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Text(emoji,
                                  style:
                                  const TextStyle(fontSize: 32)),
                              const SizedBox(height: 8),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  desc,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontSize: 10),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}