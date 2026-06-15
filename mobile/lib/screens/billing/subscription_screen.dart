// ── subscription_screen.dart (operasyon hazırlığı) ──────────
// Abonelik (paywall) ekranı: Free / PRO / PRO+ planları + tek seferlik
// AI hakkı paketleri (consumable). Görsel + akış HAZIR; gerçek satın alma
// RevenueCat'e bağlanacak — _purchase() ve _restore() içine RC çağrıları girecek.
//
// ENTEGRASYON NOTU (RevenueCat eklendiğinde):
//   1. Purchases.configure(...) main.dart'ta
//   2. _purchase(packageId): Purchases.purchasePackage(...)
//   3. Consumable satın alımda backend'e POST /billing/add-credits {amount}
//      → kullanıcının kotasına ek hak ekler (mevcut ai_rate_limiter ile uyumlu)
//   4. _restore(): Purchases.restorePurchases()
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _yearly = true;
  String _selectedPlan = 'pro';
  String _selectedPacket = 'c50';

  // ── Plan tanımları ──
  static const _plans = [
    {
      'key': 'free', 'name': 'Free', 'tag': null,
      'priceM': '₺0', 'priceY': '₺0', 'sub': 'Sonsuza dek ücretsiz',
      'features': [
        'Temel takip (ölçüm, su, uyku)',
        'Manuel egzersiz kaydı',
        'Günde 2 AI sohbet hakkı',
        'Reklamsız deneyim',
      ],
    },
    {
      'key': 'pro', 'name': 'PRO', 'tag': 'Founder', 'popular': true,
      'priceM': '₺249', 'priceY': '₺1.490', 'sub': 'İlk 1000 üyeye ₺149/ay',
      'features': [
        'Free’deki her şey +',
        'Sınırsız AI antrenman & diyet planı',
        'Günde 15 AI sohbet hakkı',
        'Fotoğraftan kalori analizi',
        'Haftalık AI özeti & içgörüler',
        'Kan değeri takibi',
      ],
    },
    {
      'key': 'proplus', 'name': 'PRO+', 'tag': 'En İyi',
      'priceM': '₺299', 'priceY': '₺1.790', 'sub': 'Tam güç',
      'features': [
        'PRO’daki her şey +',
        'Öncelikli AI yanıt hızı',
        'Sınırsız AI sohbet',
        'Giyilebilir entegrasyonu',
        'Detaylı PDF sağlık raporu',
        'Erken erişim özellikleri',
      ],
    },
  ];

  // ── RevenueCat bağlanınca buraya gerçek satın alma gelecek ──
  Future<void> _purchasePlan() async {
    HapticFeedback.lightImpact();
    _todo('Plan satın alma');
  }

  Future<void> _purchasePacket() async {
    HapticFeedback.lightImpact();
    _todo('Paket satın alma');
  }

  Future<void> _restore() async => _todo('Satın alımları geri yükleme');

  void _todo(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what — ödeme sistemi (RevenueCat) yakında bağlanacak')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg       = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard   = isDark ? const Color(0xFF141620) : Colors.white;
    final bgSoft   = isDark ? const Color(0xFF0F1016) : const Color(0xFFE8EBF2);
    final border   = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text     = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final textSoft = isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);
    final muted    = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent   = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim = isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);
    final purple   = const Color(0xFFA78BFA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0, foregroundColor: text,
        title: const Text('Aboneliğim'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Mevcut durum ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accentDim, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withOpacity(0.35)),
            ),
            child: Row(children: [
              Icon(Icons.star_rounded, color: accent, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Şu an PRO üyesin',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: text)),
                Text('14 Tem 2026’da ₺149 ile yenilenecek',
                    style: TextStyle(fontSize: 11, color: muted)),
              ])),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Aylık / Yıllık toggle ──
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              _periodTab('Aylık', !_yearly, () => setState(() => _yearly = false), bgCard, accent, muted),
              _periodTab('Yıllık · 2 ay bedava', _yearly, () => setState(() => _yearly = true), bgCard, accent, muted),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Plan kartları ──
          ..._plans.map((p) => _planCard(p, bgCard, border, text, textSoft, muted, accent, purple)),

          const SizedBox(height: 16),
          // ── Plan CTA ──
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accent, foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _purchasePlan,
              child: Text(
                _selectedPlan == 'free'
                    ? 'Free’ye Geç'
                    : '${_planName(_selectedPlan)}’a Yükselt',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(onPressed: _restore,
                child: Text('Satın alımları geri yükle', style: TextStyle(fontSize: 11, color: muted))),
            TextButton(onPressed: () => _todo('İptal'),
                child: Text('Aboneliği iptal et', style: TextStyle(fontSize: 11, color: muted))),
          ]),
          Text(
            'Ödeme App Store / Google Play hesabından alınır. Dönem bitiminden '
            '24 saat önce iptal etmezsen otomatik yenilenir.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: muted, height: 1.5),
          ),

          // ── AI hakkı paketleri ──
          const SizedBox(height: 28),
          Text('Abonelik istemiyor musun?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: text)),
          const SizedBox(height: 3),
          Text(
            'Tek seferlik AI hakkı al, istediğinde kullan. Aylık taahhüt yok — '
            'kontörün bitene kadar geçerli.',
            style: TextStyle(fontSize: 12, color: muted, height: 1.45),
          ),
          const SizedBox(height: 14),
          AIPacketsSection(
            selected: _selectedPacket,
            onSelect: (k) => setState(() => _selectedPacket = k),
            onBuy: _purchasePacket,
          ),
        ],
      ),
    );
  }

  String _planName(String key) =>
      (_plans.firstWhere((p) => p['key'] == key)['name'] as String);

  Widget _periodTab(String label, bool on, VoidCallback onTap,
      Color bgCard, Color accent, Color muted) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: on ? bgCard : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  color: on ? accent : muted)),
        ),
      ),
    );
  }

  Widget _planCard(Map p, Color bgCard, Color border, Color text,
      Color textSoft, Color muted, Color accent, Color purple) {
    final key = p['key'] as String;
    final isSel = _selectedPlan == key;
    final planColor = key == 'proplus' ? purple : (key == 'free' ? textSoft : accent);
    final price = _yearly ? p['priceY'] : p['priceM'];
    final popular = p['popular'] == true;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSel ? planColor.withOpacity(0.06) : bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSel ? planColor : border, width: isSel ? 2 : 1),
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(p['name'] as String,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: text)),
              if (p['tag'] != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: planColor.withOpacity(0.13), borderRadius: BorderRadius.circular(99)),
                  child: Text(p['tag'] as String,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: planColor)),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic, children: [
              Text(price as String,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: planColor)),
              const SizedBox(width: 6),
              Text(key == 'free' ? '' : (_yearly ? '/yıl' : '/ay'),
                  style: TextStyle(fontSize: 12, color: muted)),
            ]),
            Text(p['sub'] as String,
                style: TextStyle(fontSize: 11, color: muted)),
            const SizedBox(height: 12),
            ...(p['features'] as List).map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check_rounded, size: 15, color: planColor),
                const SizedBox(width: 8),
                Expanded(child: Text(f as String,
                    style: TextStyle(fontSize: 12.5, color: textSoft, height: 1.4))),
              ]),
            )),
          ]),
          if (popular)
            Positioned(
              top: -26, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(99)),
                child: const Text('EN POPÜLER',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black)),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── AI hakkı paketleri bölümü (ekranda + pop-up'ta ortak) ──
const aiPacketsCommon = [
  {'key': 'c20', 'amount': 20, 'price': '₺49', 'per': '₺2.45', 'tag': null},
  {'key': 'c50', 'amount': 50, 'price': '₺99', 'per': '₺1.98', 'tag': 'En popüler'},
  {'key': 'c120', 'amount': 120, 'price': '₺199', 'per': '₺1.66', 'tag': 'En avantajlı'},
];
const aiPacketsSpecial = [
  {'key': 'w10', 'icon': '💪', 'name': '10 Antrenman Planı', 'price': '₺39'},
  {'key': 'd10', 'icon': '🍽️', 'name': '10 Diyet Planı', 'price': '₺39'},
];

class AIPacketsSection extends ConsumerWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onBuy;
  final bool compact;
  const AIPacketsSection({
    super.key, required this.selected, required this.onSelect,
    required this.onBuy, this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark   = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bgCard   = isDark ? const Color(0xFF141620) : Colors.white;
    final border   = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text     = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final muted    = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent   = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim = isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);

    final selPacket = aiPacketsCommon.firstWhere((p) => p['key'] == selected,
        orElse: () => aiPacketsCommon[1]);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!compact)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Genel AI Kontörü · her özellikte geçerli',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted)),
        ),
      ...aiPacketsCommon.map((p) {
        final isSel = selected == p['key'];
        return GestureDetector(
          onTap: () => onSelect(p['key'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSel ? accentDim : bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSel ? accent : border, width: isSel ? 2 : 1),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.bolt_rounded, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('${p['amount']} AI Hakkı',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: text)),
                  if (p['tag'] != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(99)),
                      child: Text(p['tag'] as String,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: accent)),
                    ),
                  ],
                ]),
                Text('hak başına ${p['per']}',
                    style: TextStyle(fontSize: 11, color: muted)),
              ])),
              Text(p['price'] as String,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: accent)),
            ]),
          ),
        );
      }),

      if (!compact) ...[
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text('Özel Paketler · tek özelliğe',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted)),
        ),
        Row(children: aiPacketsSpecial.map((p) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: p == aiPacketsSpecial.first ? 10 : 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgCard, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(children: [
              Text(p['icon'] as String, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(p['name'] as String, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text, height: 1.3)),
              const SizedBox(height: 6),
              Text(p['price'] as String,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: accent)),
            ]),
          ),
        )).toList()),
      ],

      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: accent, foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: onBuy,
          child: Text('${selPacket['amount']} Hakkı Al · ${selPacket['price']}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        ),
      ),
    ]);
  }
}
