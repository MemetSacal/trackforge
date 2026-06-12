// ── sosyal_screen.dart ──────────────────────────────────
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../app.dart';

// ── Kabul edilmiş arkadaşlar ──
final friendsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.friends);
    final data = response.data as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) {
    return [];
  }
});

// ── Gelen bekleyen istekler ──
final pendingRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get('/social/friends/pending');
    final data = response.data as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) {
    return [];
  }
});

// ── Leaderboard ──
final leaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.leaderboard);
    final data = response.data as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) {
    return [];
  }
});

// ── v5: Düellolar ──
final duelsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.socialDuels);
    final data = response.data as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) {
    return [];
  }
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
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest(Color accent) async {
    if (_emailController.text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await ApiClient.instance.post(
        Endpoints.friendRequest,
        data: {'addressee_email': _emailController.text.trim()},
      );
      _emailController.clear();
      ref.invalidate(friendsProvider);
      ref.invalidate(pendingRequestsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arkadaşlık isteği gönderildi ✅')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İstek gönderilemedi')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _acceptRequest(String friendshipId) async {
    try {
      await ApiClient.instance.post('/social/friends/accept/$friendshipId');
      // Her iki listeyi de yenile — kabul edilen istek arkadaşlar listesine geçer
      ref.invalidate(friendsProvider);
      ref.invalidate(pendingRequestsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arkadaşlık isteği kabul edildi ✅')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem başarısız')));
    }
  }

  Future<void> _rejectRequest(String friendshipId) async {
    try {
      await ApiClient.instance.delete('/social/friends/$friendshipId');
      ref.invalidate(pendingRequestsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İstek reddedildi')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem başarısız')));
    }
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
                Text('TRACKFORGE',
                    style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 3,
                        color: muted,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border)),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 15, color: textSoft),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Sosyal',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: text,
                              letterSpacing: -0.5)),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border)),
                        child: Icon(
                            isDark
                                ? Icons.wb_sunny_outlined
                                : Icons.nightlight_round,
                            size: 15,
                            color: textSoft),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: bgSoft, borderRadius: BorderRadius.circular(14)),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4)
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: accent,
                    unselectedLabelColor: muted,
                    labelStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
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
                  onAccept: _acceptRequest,
                  onReject: _rejectRequest,
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

// ────────────────────────────────────────────────────────
//  _FriendsTab
// ────────────────────────────────────────────────────────
// ── v5: Düello aksiyonları ──
Future<void> challengeToDuel(BuildContext context, WidgetRef ref, String friendId, String friendName) async {
  try {
    await ApiClient.instance.post(Endpoints.socialDuels, data: {'opponent_id': friendId});
    ref.invalidate(duelsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⚔️ $friendName düelloya davet edildi! Kabul edince 7 günlük sayım başlar.')));
    }
  } on DioException catch (e) {
    final msg = (e.response?.data is Map ? e.response?.data['detail'] : null)?.toString()
        ?? 'Düello daveti gönderilemedi';
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Düello daveti gönderilemedi')));
    }
  }
}

Future<void> respondDuel(BuildContext context, WidgetRef ref, String duelId, bool accept) async {
  try {
    await ApiClient.instance.post(
        '${Endpoints.socialDuels}/$duelId/respond',
        queryParameters: {'accept': accept});
    ref.invalidate(duelsProvider);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem başarısız, tekrar dene')));
    }
  }
}

class _FriendsTab extends ConsumerWidget {
  final TextEditingController emailController;
  final bool isSending;
  final VoidCallback onSend;
  final void Function(String) onAccept;
  final void Function(String) onReject;
  final Color bg, bgCard, bgSoft, border, text, textSoft, muted, accent,
      accentDim, positive;

  const _FriendsTab({
    required this.emailController,
    required this.isSending,
    required this.onSend,
    required this.onAccept,
    required this.onReject,
    required this.bg,
    required this.bgCard,
    required this.bgSoft,
    required this.border,
    required this.text,
    required this.textSoft,
    required this.muted,
    required this.accent,
    required this.accentDim,
    required this.positive,
  });

  // ── Avatar baş harfleri yardımcısı ──
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync  = ref.watch(friendsProvider);
    final pendingAsync  = ref.watch(pendingRequestsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Arkadaş Ekle ──
          Container(
            decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Arkadaş Ekle',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: text)),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: text),
                  decoration: const InputDecoration(
                    labelText: 'E-posta adresi',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSending ? null : onSend,
                    child: isSending
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Text('İstek Gönder'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Gelen İstekler ──
          // Backend'den requester_id dönüyor; isim için ayrı bir endpoint
          // olmadığından şimdilik requester_id'nin baş kısmını gösteriyoruz.
          // V1.1'de /users/{id} endpoint'i eklenince tam isim çekilebilir.
          pendingAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (pending) {
              // Hiç istek yoksa kartı gösterme
              if (pending.isEmpty) return const SizedBox.shrink();

              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            // Dikkat çekici ince accent border
                            color: accent.withOpacity(0.35),
                            width: 1.2)),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text('Gelen İstekler',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: text)),
                          const SizedBox(width: 8),
                          // Kaç istek geldiğini gösteren badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              '${pending.length}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        ...pending.asMap().entries.map((e) {
                          final req         = e.value;
                          final id          = req['id']?.toString() ?? '';
                          // Backend FriendshipResponse döndürüyor:
                          // requester_id var, full_name yok (henüz join yok)
                          // Kısa UUID göstermek yerine genel "Kullanıcı" yazıyoruz
                          final requesterId = req['requester_id']?.toString() ?? '';
                          final displayName = req['requester_name']?.toString() ?? 'Kullanıcı';
                          final initials    = _initials(displayName);
                          final isLast      = e.key == pending.length - 1;

                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: isLast
                                            ? Colors.transparent
                                            : border))),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                      color: positive.withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  child: Center(
                                    child: Text(initials,
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: positive)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // İsim + alt yazı
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(displayName,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: text)),
                                      Text('Arkadaşlık isteği gönderdi',
                                          style: TextStyle(
                                              fontSize: 11, color: muted)),
                                    ],
                                  ),
                                ),
                                // Kabul butonu
                                GestureDetector(
                                  onTap: () => onAccept(id),
                                  child: Container(
                                    width: 34, height: 34,
                                    decoration: BoxDecoration(
                                        color: positive.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Icon(Icons.check_rounded,
                                        size: 18, color: positive),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Red butonu
                                GestureDetector(
                                  onTap: () => onReject(id),
                                  child: Container(
                                    width: 34, height: 34,
                                    decoration: BoxDecoration(
                                        color:
                                            Colors.red.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: const Icon(Icons.close_rounded,
                                        size: 18, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),

          // ── Arkadaşlarım ──
          Container(
            decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Arkadaşlarım',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: text)),
                const SizedBox(height: 14),
                friendsAsync.when(
                  loading: () =>
                      Center(child: CircularProgressIndicator(color: accent)),
                  error: (_, __) => Center(
                      child: Text('Veri yüklenemedi',
                          style: TextStyle(color: text))),
                  data: (friends) {
                    if (friends.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(children: [
                          const Text('👥',
                              style: TextStyle(fontSize: 36)),
                          const SizedBox(height: 8),
                          Text('Henüz arkadaş yok',
                              style: TextStyle(fontSize: 14, color: text)),
                          const SizedBox(height: 4),
                          Text('E-posta ile arkadaş ekle',
                              style:
                                  TextStyle(fontSize: 12, color: muted)),
                        ]),
                      );
                    }
                    return Column(
                      children: friends.asMap().entries.map((e) {
                        final f       = e.value;
                        final name    = (f['friend_name'] ?? // v5: backend artık adı gönderiyor
                                f['full_name'] ??
                                f['username'] ??
                                'Kullanıcı')
                            .toString();
                        final xp      = f['xp'] ?? f['total_xp'] ?? 0;
                        final initials = _initials(name);

                        final friendId = (f['friend_id'] ?? '').toString(); // v5
                        return Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: border))),
                          child: Row(
                            children: [
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                    color: accentDim,
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                child: Center(
                                  child: Text(initials,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: accent)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: text)),
                                    Text('$xp puan',
                                        style: TextStyle(
                                            fontSize: 11, color: muted)),
                                  ],
                                ),
                              ),
                              // v5: düello daveti
                              if (friendId.isNotEmpty)
                                GestureDetector(
                                  onTap: () => challengeToDuel(
                                      context, ref, friendId, name),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                        color: accentDim,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(color: accent)),
                                    child: Text('⚔️ Düello',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: accent)),
                                  ),
                                )
                              else
                                Icon(Icons.chevron_right,
                                    size: 18, color: muted),
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

          // ── v5: DÜELLOLAR ─────────────────────────────
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚔️ Düellolar',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: text)),
                const SizedBox(height: 4),
                Text('7 günde kim daha çok adım atacak?',
                    style: TextStyle(fontSize: 11, color: muted)),
                const SizedBox(height: 12),
                Consumer(builder: (context, ref, _) {
                  final duelsAsync = ref.watch(duelsProvider);
                  return duelsAsync.when(
                    loading: () => Center(
                        child: CircularProgressIndicator(color: accent)),
                    error: (_, __) => Text('Düellolar yüklenemedi',
                        style: TextStyle(fontSize: 12, color: muted)),
                    data: (duels) {
                      if (duels.isEmpty) {
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                              'Henüz düello yok — arkadaşının yanındaki ⚔️ butonuna bas!',
                              style:
                                  TextStyle(fontSize: 12, color: muted)),
                        );
                      }
                      return Column(
                        children: duels.map((d) {
                          final status = d['status'] as String? ?? '';
                          final isChallenger =
                              d['is_challenger'] as bool? ?? false;
                          final me = Map<String, dynamic>.from(
                              (isChallenger ? d['challenger'] : d['opponent']) as Map);
                          final them = Map<String, dynamic>.from(
                              (isChallenger ? d['opponent'] : d['challenger']) as Map);
                          final mySteps = (me['steps'] as num?)?.toInt() ?? 0;
                          final theirSteps =
                              (them['steps'] as num?)?.toInt() ?? 0;
                          final total = (mySteps + theirSteps).clamp(1, 1 << 31);
                          final winnerId = d['winner_id'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: bgSoft,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: border)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(
                                        'Sen  ⚔️  ${them['name']}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: text)),
                                  ),
                                  if (status == 'active')
                                    Text('${d['days_left']} gün kaldı',
                                        style: TextStyle(
                                            fontSize: 10, color: muted)),
                                ]),
                                const SizedBox(height: 8),
                                if (status == 'pending' && !isChallenger) ...[
                                  Row(children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => respondDuel(context,
                                            ref, d['id'] as String, true),
                                        child: Container(
                                          padding: const EdgeInsets
                                              .symmetric(vertical: 9),
                                          decoration: BoxDecoration(
                                              color: accent,
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: const Center(
                                              child: Text('Kabul Et 💪',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.black))),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => respondDuel(context, ref,
                                          d['id'] as String, false),
                                      child: Padding(
                                        padding: const EdgeInsets
                                            .symmetric(horizontal: 8, vertical: 9),
                                        child: Text('Reddet',
                                            style: TextStyle(
                                                fontSize: 12, color: muted)),
                                      ),
                                    ),
                                  ]),
                                ] else if (status == 'pending') ...[
                                  Text('⏳ ${them['name']} kabul edince sayım başlar',
                                      style: TextStyle(
                                          fontSize: 11, color: muted)),
                                ] else ...[
                                  // Skor barı
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: Row(children: [
                                      Expanded(
                                        flex: (mySteps * 100 / total)
                                            .round()
                                            .clamp(1, 99),
                                        child: Container(
                                            height: 8, color: accent),
                                      ),
                                      Expanded(
                                        flex: (theirSteps * 100 / total)
                                            .round()
                                            .clamp(1, 99),
                                        child: Container(
                                            height: 8,
                                            color: muted.withOpacity(0.4)),
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Sen: $mySteps adım',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: accent)),
                                      Text('${them['name']}: $theirSteps',
                                          style: TextStyle(
                                              fontSize: 11, color: muted)),
                                    ],
                                  ),
                                  if (status == 'finished') ...[
                                    const SizedBox(height: 6),
                                    Text(
                                        winnerId == null
                                            ? '🤝 Berabere bitti!'
                                            : winnerId == me['id']
                                                ? '🏆 KAZANDIN! Hava atma hakkın saklıdır.'
                                                : '😤 Bu sefer ${them['name']} aldı — rövanş?',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: winnerId == me['id']
                                                ? accent
                                                : text)),
                                  ],
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
//  _LeaderboardTab
// ────────────────────────────────────────────────────────
class _LeaderboardTab extends ConsumerWidget {
  final Color bg, bgCard, bgSoft, border, text, textSoft, muted, accent,
      accentDim;

  const _LeaderboardTab({
    required this.bg,
    required this.bgCard,
    required this.bgSoft,
    required this.border,
    required this.text,
    required this.textSoft,
    required this.muted,
    required this.accent,
    required this.accentDim,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return leaderboardAsync.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: accent)),
      error: (_, __) => Center(
          child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text('Liderlik tablosu boş',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: text)),
                  const SizedBox(height: 4),
                  Text('Arkadaş ekle ve yarışmaya başla',
                      style: TextStyle(fontSize: 12, color: muted)),
                ]),
          );
        }

        const medals = ['🥇', '🥈', '🥉'];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Container(
              decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border)),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('🏆 Liderlik Tablosu',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: text)),
                        Text('Bu Hafta',
                            style: TextStyle(
                                fontSize: 13,
                                color: accent,
                                fontWeight: FontWeight.w600)),
                      ]),
                  const SizedBox(height: 14),
                  ...entries.asMap().entries.map((e) {
                    final entry = e.value;
                    final rank  = e.key + 1;
                    final name  = (entry['full_name'] ??
                            entry['username'] ??
                            'Kullanıcı')
                        .toString();
                    final xp    = entry['xp'] ?? entry['total_xp'] ?? 0;
                    final isMe  = entry['is_me'] == true;
                    final medal = rank <= 3 ? medals[rank - 1] : '$rank';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? accentDim : bgSoft,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: isMe ? accent : border),
                      ),
                      child: Row(children: [
                        Text(medal,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(name,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isMe
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: text))),
                        Text('$xp XP',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isMe ? accent : textSoft)),
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