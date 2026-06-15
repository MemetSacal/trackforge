// ── insights_card.dart (v1.1) — Veri Korelasyonları Kartı ──
// GET /reports/insights'tan gelen örüntüleri gösterir. Veri yoksa
// motive edici ipucu. Reusable — raporlar veya dashboard'a konabilir.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../app.dart';

final insightsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final res = await ApiClient.instance.get(Endpoints.reportsInsights);
    return Map<String, dynamic>.from(res.data);
  } catch (_) {
    return {'insights': [], 'has_enough_data': false, 'hint': null};
  }
});

class InsightsCard extends ConsumerWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bgCard = isDark ? const Color(0xFF141620) : Colors.white;
    final border = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text   = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final muted  = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);

    final async = ref.watch(insightsProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final insights = (data['insights'] as List? ?? []);
        final hint = data['hint'];

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('🔍', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Sana Özel İçgörüler',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: text)),
            ]),
            const SizedBox(height: 4),
            Text('Verilerinden çıkan örüntüler',
                style: TextStyle(fontSize: 11, color: muted)),
            const SizedBox(height: 14),

            if (insights.isEmpty)
              Text(
                (hint ?? 'Daha fazla veri girdikçe örüntülerini göstereceğim 📊').toString(),
                style: TextStyle(fontSize: 13, height: 1.5, color: muted),
              )
            else
              ...insights.map((raw) {
                final ins = Map<String, dynamic>.from(raw);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withOpacity(0.18)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((ins['icon'] ?? '💡').toString(), style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text((ins['title'] ?? '').toString(),
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: text)),
                      const SizedBox(height: 3),
                      Text((ins['text'] ?? '').toString(),
                          style: TextStyle(fontSize: 12.5, height: 1.45, color: muted)),
                    ])),
                  ]),
                );
              }),
          ]),
        );
      },
    );
  }
}
