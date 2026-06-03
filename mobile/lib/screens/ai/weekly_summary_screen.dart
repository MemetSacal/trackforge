// ── weekly_summary_screen.dart ──────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';
import '../../app.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'ai_helpers.dart'; // import eklendi

class WeeklySummaryScreen extends ConsumerStatefulWidget {
  const WeeklySummaryScreen({super.key});
  @override
  ConsumerState<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends ConsumerState<WeeklySummaryScreen> {
  String? _summary;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await ApiClient.instance.post(Endpoints.aiWeeklySummary, data: {'reference_date': TFDateUtils.today()});
      setState(() => _summary = response.data['summary'] as String?);
    } catch (_) { setState(() => _error = 'Özet alınırken hata oluştu. Tekrar dene.'); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg       = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard   = isDark ? const Color(0xFF141620) : Colors.white;
    final border   = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text     = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final textSoft = isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);
    final muted    = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent   = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim= isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);
    final danger   = isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          aiHeader(context, ref, isDark, bg, bgCard, border, text, textSoft, muted, accent, 'Haftalık AI Özeti'),
          Expanded(
            child: _isLoading
                ? aiLoadingState(accent, text, '🤖 Claude verilerini analiz ediyor...')
                : _error != null
                    ? aiErrorState(_error!, danger, accent, () => _fetch())
                    : _summary != null
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            child: Column(
                              children: [
                                // Başlık kartı
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
                                // Özet içeriği
                                Container(
                                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                                  padding: const EdgeInsets.all(16),
                                  child: MarkdownBody(
                                    data: _summary!,
                                    selectable: true,
                                    styleSheet: MarkdownStyleSheet(
                                      p:      TextStyle(fontSize: 14, height: 1.6, color: text),
                                      h2:     TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: accent),
                                      h3:     TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: accent),
                                      strong: const TextStyle(fontWeight: FontWeight.w700),
                                      listBullet: TextStyle(fontSize: 14, color: text),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                aiOutlineBtn('Yeniden Analiz Et', Icons.refresh, accent, border, _isLoading ? null : _fetch),
                              ],
                            ),
                          )
                        : const SizedBox(),
          ),
        ],
      ),
    );
  }
}