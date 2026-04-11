// ── sosyal_screen.dart ──────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';

final friendsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.friends);
    final data = response.data as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) {
    return [];
  }
});

final leaderboardProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.leaderboard);
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendFriendRequest() async {
    if (_emailController.text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await ApiClient.instance.post(
        Endpoints.friendRequest,
        data: {'email': _emailController.text.trim()},
      );
      _emailController.clear();
      ref.invalidate(friendsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arkadaşlık isteği gönderildi ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İstek gönderilemedi')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sosyal'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Arkadaşlar'),
            Tab(text: 'Liderlik'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FriendsTab(
            emailController: _emailController,
            isSending: _isSending,
            onSend: _sendFriendRequest,
          ),
          _LeaderboardTab(),
        ],
      ),
    );
  }
}

class _FriendsTab extends ConsumerWidget {
  final TextEditingController emailController;
  final bool isSending;
  final VoidCallback onSend;

  const _FriendsTab({
    required this.emailController,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Arkadaş Ekle',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // E-posta alanı — tam genişlik
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-posta adresi',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Gönder butonu — ayrı satırda, tam genişlik
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSending ? null : onSend,
                      child: isSending
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text('İstek Gönder'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Arkadaşlarım',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          friendsAsync.when(
            loading: () =>
            const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
            const Center(child: Text('Veri yüklenemedi')),
            data: (friends) {
              if (friends.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('👥', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        const Text('Henüz arkadaş yok'),
                        Text(
                          'E-posta ile arkadaş ekle',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: friends.map((friend) {
                  final name = friend['full_name'] ??
                      friend['username'] ??
                      'Kullanıcı';
                  final status = friend['status'] as String? ?? '';
                  final xp = friend['xp'] ?? friend['total_xp'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .primaryColor
                            .withOpacity(0.15),
                        child: Text(
                          name.toString().substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(name.toString()),
                      subtitle: status == 'pending'
                          ? const Text('İstek bekliyor...')
                          : Text('$xp XP'),
                      trailing: status == 'pending'
                          ? const Icon(Icons.schedule, size: 18)
                          : Icon(
                        Icons.check_circle,
                        color: Theme.of(context).primaryColor,
                        size: 18,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return leaderboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Veri yüklenemedi')),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  const Text(
                    'Liderlik tablosu boş',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Arkadaş ekle ve yarışmaya başla',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final name = entry['full_name'] ??
                entry['username'] ??
                'Kullanıcı';
            final xp = entry['xp'] ?? entry['total_xp'] ?? 0;
            final rank = index + 1;
            final rankEmoji = rank == 1
                ? '🥇'
                : rank == 2
                ? '🥈'
                : rank == 3
                ? '🥉'
                : '$rank.';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(
                  rankEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  name.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Text(
                  '$xp XP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}