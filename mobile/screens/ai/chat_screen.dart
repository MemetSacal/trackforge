// ── chat_screen.dart (v1.1) — Kişisel Koç Sohbeti ──
// Backend üç kilitli kapıyla korunuyor (plan üretmez/token tavanı/ucuz model+kota).
// Bu ekran sadece sohbet arayüzü: geçmişi yükler, mesaj gönderir,
// asistan yanıtını gösterir. 429'da kota dialogu.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/api/api_exceptions.dart';
import 'ai_helpers.dart'; // showQuotaDialog
import 'workout_plan_screen.dart'; // v8.1 FIX (TC-007)
import 'meal_advice_screen.dart';  // v8.1 FIX (TC-007)

class _ChatMsg {
  final String role; // 'user' | 'assistant'
  final String content;
  final String? navTarget; // v8.1 FIX (TC-007): 'workout' | 'meal' | null
  _ChatMsg(this.role, String rawContent)
      : navTarget = _extractNavTarget(rawContent),
        content = _stripNavTag(rawContent);

  // AI cevabının sonundaki [NAV:workout] / [NAV:meal] etiketini yakalar.
  static String? _extractNavTarget(String text) {
    final match = RegExp(r'\[NAV:(\w+)\]').firstMatch(text);
    final target = match?.group(1);
    if (target == 'workout' || target == 'meal') return target;
    return null;
  }

  // Görüntülenen metinden etiketi temizler — kullanıcı [NAV:workout] yazısını görmesin.
  static String _stripNavTag(String text) =>
      text.replaceAll(RegExp(r'\s*\[NAV:\w+\]\s*$'), '').trim();
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMsg> _messages = [];
  bool _loadingHistory = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadHistory() async {
    try {
      final res = await ApiClient.instance.get(Endpoints.aiChatHistory);
      final list = (res.data['messages'] as List? ?? []);
      setState(() {
        _messages
          ..clear()
          ..addAll(list.map((m) => _ChatMsg(
              (m['role'] ?? 'assistant').toString(),
              (m['content'] ?? '').toString())));
        _loadingHistory = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(_ChatMsg('user', text));
      _sending = true;
    });
    _scrollToBottom();
    try {
      final res = await ApiClient.instance.post(Endpoints.aiChat, data: {'message': text});
      final reply = (res.data['reply'] ?? '').toString();
      setState(() {
        _messages.add(_ChatMsg('assistant', reply));
        _sending = false;
      });
      _scrollToBottom();
    } on DioException catch (e) {
      setState(() => _sending = false);
      final q = QuotaException.fromDioError(e);
      if (q != null && mounted) {
        await showQuotaDialog(context,
            message: q.message, isPremium: q.isPremium, resetsInDays: q.resetsInDays);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Asistan şu an yanıt veremedi, tekrar dene')));
      }
    } catch (_) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bir hata oluştu, tekrar dene')));
      }
    }
  }

  Future<void> _clearHistory(Color accent) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sohbeti temizle?'),
        content: const Text('Tüm sohbet geçmişin silinecek. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Temizle', style: TextStyle(color: accent)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.delete(Endpoints.aiChatHistory);
      setState(() => _messages.clear());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Temizlenemedi, tekrar dene')));
      }
    }
  }

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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Üst bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: text),
                  onPressed: () => Navigator.pop(context),
                ),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: accentDim, shape: BoxShape.circle),
                  child: Icon(Icons.auto_awesome, color: accent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Koçun', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: text)),
                    Text('verilerini bilen asistan', style: TextStyle(fontSize: 11, color: muted)),
                  ],
                )),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: muted),
                  onPressed: () => _clearHistory(accent),
                ),
              ]),
            ),
            Divider(height: 1, color: border),

            // ── Mesaj listesi ──
            Expanded(
              child: _loadingHistory
                  ? Center(child: CircularProgressIndicator(color: accent))
                  : _messages.isEmpty
                      ? _emptyState(text, muted, accent)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length + (_sending ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (_sending && i == _messages.length) {
                              return _bubble(
                                isUser: false,
                                child: _TypingDots(color: muted),
                                bgCard: bgCard, accent: accent, border: border, text: text,
                              );
                            }
                            final m = _messages[i];
                            return _bubble(
                              isUser: m.role == 'user',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(m.content,
                                      style: TextStyle(
                                          fontSize: 14, height: 1.4,
                                          color: m.role == 'user' ? Colors.black : text)),
                                  // v8.1 FIX (TC-007): AI yönlendirme önerdiyse
                                  // gerçek tıklanabilir buton göster (eskiden statik metindi)
                                  if (m.navTarget != null) ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: accent,
                                          foregroundColor: Colors.black,
                                        ),
                                        icon: Icon(m.navTarget == 'workout'
                                            ? Icons.fitness_center
                                            : Icons.restaurant_menu, size: 18),
                                        label: Text(m.navTarget == 'workout'
                                            ? 'Antrenman Planına Git'
                                            : 'Diyet Planına Git'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => m.navTarget == 'workout'
                                                  ? const WorkoutPlanScreen()
                                                  : const MealAdviceScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              bgCard: bgCard, accent: accent, border: border, text: text,
                            );
                          },
                        ),
            ),

            // ── Giriş alanı ──
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: bgCard,
                border: Border(top: BorderSide(color: border)),
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: text, fontSize: 14),
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Koçuna bir şey sor... (🎤 ile söyleyebilirsin)',
                      hintStyle: TextStyle(color: muted, fontSize: 13),
                      filled: true,
                      fillColor: bg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: accent.withOpacity(0.6)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: _sending ? muted : accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _sending ? Icons.hourglass_empty_rounded : Icons.arrow_upward_rounded,
                      color: Colors.black, size: 22,
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(Color text, Color muted, Color accent) {
    final suggestions = [
      'Bugün ne yemeliyim?',
      'Bu hafta nasıl gidiyorum?',
      'Yorgunum, antrenman yapmalı mıyım?',
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💬', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Koçunla konuş',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text)),
            const SizedBox(height: 8),
            Text(
              'Verilerini bilen kişisel asistanın. Antrenman, beslenme, '
              'ilerlemen hakkında istediğini sor.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5, color: muted),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8, runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions.map((s) => GestureDetector(
                onTap: () { _controller.text = s; _send(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: accent.withOpacity(0.4)),
                  ),
                  child: Text(s, style: TextStyle(fontSize: 12.5, color: accent)),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble({
    required bool isUser,
    required Widget child,
    required Color bgCard,
    required Color accent,
    required Color border,
    required Color text,
  }) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? accent : bgCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: border),
        ),
        child: child,
      ),
    );
  }
}

// ── "Yazıyor..." üç nokta animasyonu ──
class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat();

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40, height: 18,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_c.value + i * 0.33) % 1.0;
            final scale = 0.5 + 0.5 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
