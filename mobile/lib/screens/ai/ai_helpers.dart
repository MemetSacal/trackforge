// ── ai_helpers.dart ─────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../app.dart';

// ── AI Koç ismi provider — autoDispose ile her açılışta fresh ──
// profil_screen.dart'tan invalidate edilebilir
final aiCoachNameProvider = FutureProvider.autoDispose<String>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.preferences);
    return response.data['ai_name'] as String? ?? 'TrackForge AI';
  } catch (_) {
    return 'TrackForge AI';
  }
});

Widget aiHeader(BuildContext context, WidgetRef ref, bool isDark,
    Color bg, Color bgCard, Color border, Color text, Color textSoft, Color muted, Color accent, String title) {
  return Container(
    color: bg,
    padding: const EdgeInsets.fromLTRB(16, 56, 16, 14),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(width: 36, height: 36,
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: textSoft)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.3)),
        ])),
        GestureDetector(
          onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          child: Container(width: 36, height: 36,
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
            child: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round, size: 15, color: textSoft)),
        ),
      ],
    ),
  );
}

Widget aiLoadingState(Color accent, Color text, String message) {
  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    CircularProgressIndicator(color: accent),
    const SizedBox(height: 24),
    Text(message, style: TextStyle(fontSize: 15, color: text)),
    const SizedBox(height: 8),
    Text('Bu 10–20 saniye sürebilir', style: TextStyle(fontSize: 12, color: accent.withOpacity(0.6))),
  ]));
}

Widget aiErrorState(String error, Color danger, Color accent, VoidCallback onRetry) {
  return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('😕', style: TextStyle(fontSize: 48)),
    const SizedBox(height: 16),
    Text(error, textAlign: TextAlign.center, style: TextStyle(color: danger, fontSize: 14)),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
  ])));
}

Widget aiErrorCard(String error, Color danger, Color border) =>
  Container(padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: danger.withOpacity(0.3))),
    child: Row(children: [
      Icon(Icons.error_outline, color: danger, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(error, style: TextStyle(color: danger, fontSize: 13))),
    ]));

Widget aiOutlineBtn(String label, IconData icon, Color accent, Color border, VoidCallback? onTap) =>
  SizedBox(width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: accent, size: 16),
      label: Text(label, style: TextStyle(color: accent)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: accent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ));
// ═════════════════════════════════════════════════════════
// ── v2 EKLEMELERİ: Kota + Feedback ──
// ═════════════════════════════════════════════════════════

/// Sunucudan dönen quota objesini gösteren çip.
/// Her başarılı AI yanıtındaki response.data['quota'] buraya verilir.
///   {"used": 2, "limit": 3, "remaining": 1, "period": "weekly", ...}
Widget aiQuotaChip(Map<String, dynamic>? quota, Color accent, Color muted) {
  if (quota == null) return const SizedBox.shrink();
  final remaining = (quota['remaining'] as num?)?.toInt() ?? 0;
  final limit = (quota['limit'] as num?)?.toInt() ?? 0;
  final period = quota['period'] == 'daily' ? 'bugün' : 'bu hafta';
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.bolt_rounded, size: 14, color: remaining > 0 ? accent : muted),
      const SizedBox(width: 4),
      Text('$period $remaining/$limit hakkın kaldı',
          style: TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w600)),
    ]),
  );
}

/// 429 (kota aşımı) durumunda gösterilen dialog.
/// Backend'in yapılandırılmış mesajını ve PRO köprüsünü gösterir.
/// Kullanım: QuotaException.fromDioError(e) null değilse bu çağrılır.
Future<void> showQuotaDialog(
  BuildContext context, {
  required String message,
  required bool isPremium,
  required int resetsInDays,
  VoidCallback? onUpgradeTap,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [
        Text('⚡', style: TextStyle(fontSize: 22)),
        SizedBox(width: 8),
        Expanded(child: Text('Hakkın doldu', style: TextStyle(fontSize: 17))),
      ]),
      content: Text(
        '$message\n\nLimitin $resetsInDays gün içinde yenilenecek.',
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
        if (!isPremium && onUpgradeTap != null)
          FilledButton(
            onPressed: () { Navigator.pop(ctx); onUpgradeTap(); },
            child: const Text('PRO\'ya geç'),
          ),
      ],
    ),
  );
}

/// ── Her AI çıktısının altına konan 👍/👎 geri bildirim barı ──
/// POST /ai/feedback'e gönderir. AI tek yönlü olmaktan çıkar:
/// hangi önerinin işe yaradığını ölçmeye başlarız.
class AiFeedbackBar extends StatefulWidget {
  final String feature; // workout_plan | meal_advice | vision | recipe | ...
  final Color accent;
  final Color muted;

  const AiFeedbackBar({
    super.key,
    required this.feature,
    required this.accent,
    required this.muted,
  });

  @override
  State<AiFeedbackBar> createState() => _AiFeedbackBarState();
}

class _AiFeedbackBarState extends State<AiFeedbackBar> {
  int? _sent; // 1 = 👍 gönderildi, -1 = 👎 gönderildi

  Future<void> _send(int rating) async {
    setState(() => _sent = rating); // iyimser UI — yanıt beklemeden işaretle
    try {
      await ApiClient.instance.post(Endpoints.aiFeedback, data: {
        'feature': widget.feature,
        'rating': rating,
      });
    } catch (_) {
      // Feedback kritik akış değil — hata sessizce yutulur,
      // kullanıcı deneyimi bozulmaz.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          _sent == 1 ? 'Teşekkürler, koçun not aldı 📝' : 'Anlaşıldı, daha iyisi için çalışacağız 💪',
          style: TextStyle(fontSize: 12, color: widget.muted),
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('Bu öneri işine yaradı mı?',
          style: TextStyle(fontSize: 12, color: widget.muted)),
      IconButton(
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.thumb_up_outlined, size: 17, color: widget.accent),
        onPressed: () => _send(1),
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        icon: Icon(Icons.thumb_down_outlined, size: 17, color: widget.muted),
        onPressed: () => _send(-1),
      ),
    ]);
  }
}
