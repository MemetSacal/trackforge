// ── weekly_summary_screen.dart ──────────────────────────
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/utils/date_utils.dart';
import '../../app.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'ai_helpers.dart';
import '../profil/profil_screen.dart';
import '../../core/utils/rate_limiter.dart';

class WeeklySummaryScreen extends ConsumerStatefulWidget {
  const WeeklySummaryScreen({super.key});
  @override
  ConsumerState<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends ConsumerState<WeeklySummaryScreen> {
  String? _summary;
  bool _isLoading = false;
  String? _error;
  bool _limitReached = false;
  String _limitText = '';
  String? _plateauMsg; // v3: plato dedektörü mesajı

  @override
  void initState() { super.initState(); _fetch(); _checkPlateau(); }

  // ── v3: Plato kontrolü — AI çağrısı YOK, kotasız, anlık ──
  // Kilo 3+ haftadır sabitse kullanıcıyı proaktif yakala:
  // abonelikten soğuduğu an değil, soğumadan ÖNCE.
  Future<void> _checkPlateau() async {
    try {
      final res = await ApiClient.instance.get(Endpoints.aiPlateauStatus);
      if (res.data is Map && res.data['is_plateau'] == true && mounted) {
        setState(() => _plateauMsg = res.data['message_tr'] as String?);
      }
    } catch (_) {
      // Banner kritik değil — sessiz geç
    }
  }

  Future<void> _fetch() async {
    final canUse = await RateLimiter.canUseWeeklyAnalysis();
    if (!canUse) {
      setState(() {
        _limitReached = true;
        _limitText    = 'Bu haftaki haftalık analiz hakkını kullandın. Yeni hafta başında tekrar kullanılabilir.';
      });
      return;
    }
    setState(() { _isLoading = true; _error = null; _limitReached = false; });
    try {
      final response = await ApiClient.instance.post(Endpoints.aiWeeklySummary, data: {'reference_date': TFDateUtils.today()});
      await RateLimiter.recordWeeklyAnalysisUse();
      setState(() => _summary = response.data['summary'] as String?);
    } on DioException catch (e) {
      // v2: sunucu kotası
      final q = QuotaException.fromDioError(e);
      if (q != null) {
        setState(() => _limitReached = true);
        if (mounted) {
          await showQuotaDialog(context,
              message: q.message, isPremium: q.isPremium,
              resetsInDays: q.resetsInDays);
        }
      } else {
        setState(() => _error = 'Özet alınırken hata oluştu. Tekrar dene.');
      }
    } catch (_) { setState(() => _error = 'Özet alınırken hata oluştu. Tekrar dene.'); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg        = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard    = isDark ? const Color(0xFF141620) : Colors.white;
    final border    = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text      = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final textSoft  = isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);
    final muted     = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent    = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim = isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);
    final danger    = isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);
    final aiName    = ref.watch(profilePrefsProvider).value?['ai_name'] as String? ?? 'TrackForge AI';

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          aiHeader(context, ref, isDark, bg, bgCard, border, text, textSoft, muted, accent, 'Haftalık AI Özeti'),
          Expanded(
            child: _limitReached
                ? _buildLimitCard(accent, accentDim, border, text, muted)
                : _isLoading
                    ? aiLoadingState(accent, text, '🤖 $aiName verilerini analiz ediyor...')
                    : _error != null
                        ? aiErrorState(_error!, danger, accent, () => _fetch())
                        : _summary != null
                            ? SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                child: Column(
                                  children: [
                                    // ── v3: Plato banner'ı ──
                                    if (_plateauMsg != null) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0x1FFBBF24),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0x66FBBF24)),
                                        ),
                                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          const Text('⚖️', style: TextStyle(fontSize: 22)),
                                          const SizedBox(width: 10),
                                          Expanded(child: Text(_plateauMsg!,
                                              style: TextStyle(fontSize: 12.5, height: 1.45, color: text))),
                                        ]),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    Container(
                                      decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(20), border: Border.all(color: accent)),
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          const Text('📊', style: TextStyle(fontSize: 32)),
                                          const SizedBox(width: 12),
                                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text('Bu Haftanın Analizi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: text)),
                                            Text(TFDateUtils.today(), style: TextStyle(fontSize: 11, color: muted)),
                                          ])),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _SummaryCards(
                                      raw: _summary!,
                                      bgCard: bgCard, border: border,
                                      text: text, muted: muted, accent: accent,
                                    ),
                                    const SizedBox(height: 12),
                                    aiOutlineBtn('Yeniden Analiz Et', Icons.refresh, accent, border, _isLoading ? null : _fetch),
                                  ],
                                ),
                              )
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('📊', style: TextStyle(fontSize: 48)),
                                      const SizedBox(height: 16),
                                      Text('Analiz Hazırlanıyor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
                                      const SizedBox(height: 8),
                                      Text('Veriler işleniyor, lütfen bekle...', style: TextStyle(fontSize: 13, color: muted), textAlign: TextAlign.center),
                                    ],
                                  ),
                                ),
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitCard(Color accent, Color accentDim, Color border, Color text, Color muted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(20), border: Border.all(color: accent)),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⏳', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Haftalık Limit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent)),
            const SizedBox(height: 8),
            Text(_limitText, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: text, height: 1.5)),
          ]),
        ),
      ),
    );
  }
}

// ── v8 cila: Haftalık özeti bölümlü renkli kartlara ayırır ──
// Backend [ÖZET]/[BAŞARILAR]/[GELİŞİM]/[ÖNERİLER] işaretçileriyle döner.
// İşaretçi bulunamazsa (eski özet) düz metne düşer — geriye uyumlu.
class _SummaryCards extends StatelessWidget {
  final String raw;
  final Color bgCard, border, text, muted, accent;
  const _SummaryCards({
    required this.raw, required this.bgCard, required this.border,
    required this.text, required this.muted, required this.accent,
  });

  Map<String, String> _parse() {
    final sections = <String, String>{};
    final labels = ['ÖZET', 'BAŞARILAR', 'GELİŞİM', 'ÖNERİLER'];
    for (var i = 0; i < labels.length; i++) {
      final tag = '[${labels[i]}]';
      final start = raw.indexOf(tag);
      if (start == -1) continue;
      final contentStart = start + tag.length;
      // Bir sonraki etikete kadar al
      var end = raw.length;
      for (final other in labels) {
        if (other == labels[i]) continue;
        final idx = raw.indexOf('[$other]', contentStart);
        if (idx != -1 && idx < end) end = idx;
      }
      sections[labels[i]] = raw.substring(contentStart, end).trim();
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _parse();

    // İşaretçi yoksa → düz metin (geriye uyumlu fallback)
    if (sections.isEmpty) {
      return Container(
        decoration: BoxDecoration(
            color: bgCard, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border)),
        padding: const EdgeInsets.all(16),
        child: Text(raw, style: TextStyle(fontSize: 14, height: 1.6, color: text)),
      );
    }

    final cards = <Widget>[];

    // [ÖZET] — vurgulu üst kart
    if (sections['ÖZET'] != null) {
      cards.add(_card(
        emoji: '📋', title: 'Özet', body: sections['ÖZET']!,
        tint: accent, isHeader: true,
      ));
    }
    if (sections['BAŞARILAR'] != null) {
      cards.add(_card(
        emoji: '💪', title: 'İyi Gidenler', body: sections['BAŞARILAR']!,
        tint: const Color(0xFF34D399),
      ));
    }
    if (sections['GELİŞİM'] != null) {
      cards.add(_card(
        emoji: '⚠️', title: 'Geliştirilebilir', body: sections['GELİŞİM']!,
        tint: const Color(0xFFFBBF24),
      ));
    }
    if (sections['ÖNERİLER'] != null) {
      cards.add(_card(
        emoji: '🎯', title: 'Gelecek Hafta', body: sections['ÖNERİLER']!,
        tint: accent,
      ));
    }

    return Column(children: cards);
  }

  Widget _card({
    required String emoji,
    required String title,
    required String body,
    required Color tint,
    bool isHeader = false,
  }) {
    // "- " ile başlayan satırları madde olarak ayır
    final lines = body.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final bullets = lines.where((l) => l.startsWith('- ')).map((l) => l.substring(2).trim()).toList();
    final plain = lines.where((l) => !l.startsWith('- ')).join(' ');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHeader ? tint.withOpacity(0.10) : bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isHeader ? tint.withOpacity(0.35) : border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: tint)),
        ]),
        const SizedBox(height: 8),
        if (plain.isNotEmpty)
          Text(plain, style: TextStyle(fontSize: 13.5, height: 1.5, color: text)),
        ...bullets.map((b) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('•  ', style: TextStyle(fontSize: 13.5, color: tint, fontWeight: FontWeight.w900)),
            Expanded(child: Text(b, style: TextStyle(fontSize: 13.5, height: 1.5, color: text))),
          ]),
        )),
      ]),
    );
  }
}
