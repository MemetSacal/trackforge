// ── quota_packet_sheet.dart (operasyon hazırlığı) ──────────
// Kota dolunca (429) açılan bottom sheet. Kullanıcıya iki yol sunar:
//   1. Hızlı AI hakkı paketi al (consumable — anlık ihtiyaç)
//   2. PRO'ya geç (sık kullanan için daha avantajlı)
//
// Kullanım (AI ekranlarında 429 yakalanınca):
//   showQuotaPacketSheet(context, featureLabel: 'antrenman');
//
// RevenueCat bağlanınca: paket satın alma → backend POST /billing/add-credits
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../billing/subscription_screen.dart';

Future<void> showQuotaPacketSheet(
  BuildContext context, {
  required String featureLabel, // örn: 'antrenman', 'sohbet', 'diyet'
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuotaPacketSheet(featureLabel: featureLabel),
  );
}

class _QuotaPacketSheet extends ConsumerStatefulWidget {
  final String featureLabel;
  const _QuotaPacketSheet({required this.featureLabel});
  @override
  ConsumerState<_QuotaPacketSheet> createState() => _QuotaPacketSheetState();
}

class _QuotaPacketSheetState extends ConsumerState<_QuotaPacketSheet> {
  String _selected = 'c50';

  @override
  Widget build(BuildContext context) {
    final isDark   = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg       = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard   = isDark ? const Color(0xFF141620) : Colors.white;
    final border   = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text     = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final muted    = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent   = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim = isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: border),
      ),
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: muted.withOpacity(0.4), borderRadius: BorderRadius.circular(99))),

          const Text('⚡', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 6),
          Text('Bu hafta ${widget.featureLabel} hakkın bitti',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text)),
          const SizedBox(height: 6),
          Text(
            'Hakların pazartesi sıfırlanır. Beklemek istemiyorsan hızlıca hak '
            'ekle ya da PRO’ya geç.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: muted, height: 1.45),
          ),
          const SizedBox(height: 18),

          // Hızlı paketler (kompakt)
          AIPacketsSection(
            selected: _selected,
            onSelect: (k) => setState(() => _selected = k),
            onBuy: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paket satın alma — RevenueCat yakında bağlanacak')),
              );
            },
            compact: true,
          ),

          const SizedBox(height: 14),
          // PRO alternatifi
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accentDim, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withOpacity(0.35)),
              ),
              child: Row(children: [
                Icon(Icons.star_rounded, color: accent, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Sık kullanıyorsan PRO daha avantajlı',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: text)),
                  Text('Sınırsız AI · Founder ₺149/ay',
                      style: TextStyle(fontSize: 11, color: muted)),
                ])),
                Icon(Icons.chevron_right_rounded, color: accent, size: 18),
              ]),
            ),
          ),

          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Şimdilik kalsın', style: TextStyle(fontSize: 13, color: muted)),
          ),
        ]),
      ),
    );
  }
}
