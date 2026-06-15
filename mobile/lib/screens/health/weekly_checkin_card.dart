// ── weekly_checkin_card.dart (v1.1) — Haftalık Check-in ──
// Pazar günleri dashboard'da görünür. 3 soru: enerji, en zorlandığın,
// gelecek hafta hedefi. notes API'sine title="Haftalık Check-in" ile
// kaydedilir — context_builder bu başlığı arayıp AI'a verir
// (backend ile birebir eşleşmeli: "Haftalık Check-in").
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../app.dart';

// Bu hafta check-in yapıldı mı? (notes'tan son 7 günü kontrol eder)
final weeklyCheckinDoneProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 6));
    final res = await ApiClient.instance.get(Endpoints.notes, queryParameters: {
      'from': from.toIso8601String().split('T').first,
      'to': now.toIso8601String().split('T').first,
    });
    final list = (res.data as List? ?? []);
    return list.any((n) => (n['title'] ?? '').toString() == 'Haftalık Check-in');
  } catch (_) {
    return false;
  }
});

class WeeklyCheckinCard extends ConsumerWidget {
  const WeeklyCheckinCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sadece hafta sonu göster (Cumartesi=6, Pazar=7)
    final weekday = DateTime.now().weekday;
    if (weekday != DateTime.saturday && weekday != DateTime.sunday) {
      return const SizedBox.shrink();
    }

    final doneAsync = ref.watch(weeklyCheckinDoneProvider);
    return doneAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (done) {
        if (done) return const SizedBox.shrink(); // bu hafta yapıldı
        return _CheckinPrompt();
      },
    );
  }
}

class _CheckinPrompt extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final text   = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final accent = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);

    return GestureDetector(
      onTap: () => _openCheckin(context, ref, accent),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB020), Color(0xFFFF6B2B)],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          const Text('📅', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Haftalık Değerlendirme',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1208))),
            SizedBox(height: 2),
            Text('Haftanı 1 dakikada değerlendir, koçun sonraki haftayı buna göre ayarlasın',
                style: TextStyle(fontSize: 11.5, color: Color(0xCC1A1208))),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF1A1208)),
        ]),
      ),
    );
  }

  Future<void> _openCheckin(BuildContext context, WidgetRef ref, Color accent) async {
    int energy = 7;
    final hardCtrl = TextEditingController();
    final goalCtrl = TextEditingController();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        Future<void> save() async {
          setSheet(() => saving = true);
          // content: iki açık uçlu cevabı birleştir (AI bunu okuyacak)
          final content = 'Bu hafta en zorlandığım: '
              '${hardCtrl.text.trim().isEmpty ? "-" : hardCtrl.text.trim()}. '
              'Gelecek hafta hedefim: '
              '${goalCtrl.text.trim().isEmpty ? "-" : goalCtrl.text.trim()}.';
          try {
            await ApiClient.instance.post(Endpoints.notes, data: {
              'title': 'Haftalık Check-in', // backend context_builder ile birebir eşleşmeli
              'content': content,
              'energy_level': energy,
            });
            ref.invalidate(weeklyCheckinDoneProvider);
            if (ctx.mounted) {
              Navigator.pop(ctx);
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('✅ Değerlendirmen kaydedildi — koçun bunu dikkate alacak')));
            }
          } catch (_) {
            setSheet(() => saving = false);
            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Kaydedilemedi, tekrar dene')));
          }
        }

        return Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 4,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Haftalık Değerlendirme 📅',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            const Text('Bu hafta enerji seviyen nasıldı?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Row(children: [
              Expanded(child: Slider(
                value: energy.toDouble(), min: 1, max: 10, divisions: 9,
                label: '$energy', activeColor: accent,
                onChanged: (v) => setSheet(() => energy = v.round()),
              )),
              SizedBox(width: 28, child: Text('$energy/10',
                  style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 8),
            const Text('Bu hafta en çok ne zorladı?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: hardCtrl, maxLines: 2, maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'örn: akşam atıştırmalarına engel olamadım',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            const Text('Gelecek hafta hedefin ne?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: goalCtrl, maxLines: 2, maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'örn: haftada 3 gün antrenman yapmak',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving ? null : save,
                child: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Kaydet'),
              ),
            ),
          ]),
        );
      }),
    );
  }
}
