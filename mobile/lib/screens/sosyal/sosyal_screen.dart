// ── sosyal_screen.dart ──────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../app.dart';

final friendsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.friends);
    final data = response.data as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) { return []; }
});

final leaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.leaderboard);
    final data = response.data as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) { return []; }
});

class SosyalScreen extends ConsumerStatefulWidget {
  const SosyalScreen({super.key});
  @override
  ConsumerState<SosyalScreen> createState() => _SosyalScreenState();
}

class _SosyalScreenState extends ConsumerState<SosyalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  bool _isSending = false;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _activeTab = _tabController.index));
  }

  @override
  void dispose() { _tabController.dispose(); _emailController.dispose(); super.dispose(); }

  Future<void> _sendRequest(Color accent) async {
    if (_emailController.text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await ApiClient.instance.post(Endpoints.friendRequest, data: {'addressee_email': _emailController.text.trim()});
      _emailController.clear();
      ref.invalidate(friendsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arkadaşlık isteği gönderildi ✅')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İstek gönderilemedi')));
    } finally { if (mounted) setState(() => _isSending = false); }
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
    final accentDim= isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);
    final positive = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Container(
            color: bg,
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: textSoft),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Sosyal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5))),
                    GestureDetector(
                      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                        child: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round, size: 15, color: textSoft),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(14)),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)]),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: accent,
                    unselectedLabelColor: muted,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    tabs: const [Tab(text: 'Arkadaşlar'), Tab(text: 'Liderlik')],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FriendsTab(
                  emailController: _emailController,
                  isSending: _isSending,
                  onSend: () => _sendRequest(accent),
                  bg: bg, bgCard: bgCard, bgSoft: bgSoft, border: border,
                  text: text, textSoft: textSoft, muted: muted,
                  accent: accent, accentDim: accentDim, positive: positive,
                ),
                _LeaderboardTab(
                  bg: bg, bgCard: bgCard, bgSoft: bgSoft, border: border,
                  text: text, textSoft: textSoft, muted: muted,
                  accent: accent, accentDim: accentDim,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsTab extends ConsumerWidget {
  final TextEditingController emailController;
  final bool isSending;
  final VoidCallback onSend;
  final Color bg, bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim, positive;

  const _FriendsTab({
    required this.emailController, required this.isSending, required this.onSend,
    required this.bg, required this.bgCard, required this.bgSoft, required this.border,
    required this.text, required this.textSoft, required this.muted,
    required this.accent, required this.accentDim, required this.positive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Arkadaş Ekle', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: text),
                  decoration: const InputDecoration(labelText: 'E-posta adresi', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSending ? null : onSend,
                    child: isSending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('İstek Gönder'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Arkadaşlarım', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                const SizedBox(height: 14),
                friendsAsync.when(
                  loading: () => Center(child: CircularProgressIndicator(color: accent)),
                  error: (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
                  data: (friends) {
                    if (friends.isEmpty) return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(children: [
                        const Text('👥', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        Text('Henüz arkadaş yok', style: TextStyle(fontSize: 14, color: text)),
                        const SizedBox(height: 4),
                        Text('E-posta ile arkadaş ekle', style: TextStyle(fontSize: 12, color: muted)),
                      ]),
                    );
                    return Column(
                      children: friends.asMap().entries.map((e) {
                        final f = e.value;
                        final name = (f['full_name'] ?? f['username'] ?? 'Kullanıcı').toString();
                        final status = f['status'] as String? ?? '';
                        final xp = f['xp'] ?? f['total_xp'] ?? 0;
                        final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.substring(0, 1).toUpperCase();
                        final isPending = status == 'pending';

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
                          child: Row(
                            children: [
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(12)),
                                child: Center(child: Text(initials, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: accent))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text)),
                                  Text(isPending ? 'İstek bekliyor...' : '$xp puan', style: TextStyle(fontSize: 11, color: muted)),
                                ]),
                              ),
                              Icon(isPending ? Icons.schedule : Icons.chevron_right, size: 18, color: muted),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  final Color bg, bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim;

  const _LeaderboardTab({
    required this.bg, required this.bgCard, required this.bgSoft, required this.border,
    required this.text, required this.textSoft, required this.muted,
    required this.accent, required this.accentDim,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return leaderboardAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: accent)),
      error: (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
      data: (entries) {
        if (entries.isEmpty) return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🏆', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Liderlik tablosu boş', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
            const SizedBox(height: 4),
            Text('Arkadaş ekle ve yarışmaya başla', style: TextStyle(fontSize: 12, color: muted)),
          ]),
        );

        const medals = ['🥇', '🥈', '🥉'];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Container(
              decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('🏆 Liderlik Tablosu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                    Text('Bu Hafta', style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 14),
                  ...entries.asMap().entries.map((e) {
                    final entry = e.value;
                    final rank  = e.key + 1;
                    final name  = (entry['full_name'] ?? entry['username'] ?? 'Kullanıcı').toString();
                    final xp    = entry['xp'] ?? entry['total_xp'] ?? 0;
                    final isMe  = entry['is_me'] == true;
                    final medal = rank <= 3 ? medals[rank - 1] : '$rank';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? accentDim : bgSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isMe ? accent : border),
                      ),
                      child: Row(children: [
                        Text(medal, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(name, style: TextStyle(fontSize: 14, fontWeight: isMe ? FontWeight.w700 : FontWeight.w500, color: text))),
                        Text('$xp XP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isMe ? accent : textSoft)),
                      ]),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}