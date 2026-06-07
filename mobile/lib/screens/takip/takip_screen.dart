// ── takip_screen.dart ───────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'olcum_tab.dart';
import 'su_tab.dart';
import 'uyku_tab.dart';
import 'diyet_tab.dart';
import '../../app.dart';
import '../home/dashboard_screen.dart'; // notificationsProvider için

final takipTabIndexProvider = StateProvider<int>((ref) => 0);

class _TC {
  static const bg        = Color(0xFF0C0D10);
  static const bgCard    = Color(0xFF141620);
  static const bgSoft    = Color(0xFF0F1016);
  static const border    = Color(0x12FFFFFF);
  static const text      = Color(0xFFF0EEF8);
  static const textSoft  = Color(0xFF8A88A8);
  static const textMuted = Color(0xFF4A4860);
  static const accent    = Color(0xFFFFB020);
  static const lBg       = Color(0xFFF0F2F6);
  static const lBgCard   = Color(0xFFFFFFFF);
  static const lBgSoft   = Color(0xFFE8EBF2);
  static const lBorder   = Color(0x12000000);
  static const lText     = Color(0xFF111318);
  static const lTextSoft = Color(0xFF5A6078);
  static const lTextMuted= Color(0xFF9AA0B8);
  static const lAccent   = Color(0xFFFF6B2B);
}

class TakipScreen extends ConsumerStatefulWidget {
  const TakipScreen({super.key});
  @override
  ConsumerState<TakipScreen> createState() => _TakipScreenState();
}

class _TakipScreenState extends ConsumerState<TakipScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    {'key': 0, 'label': 'Ölçümler'},
    {'key': 1, 'label': 'Diyet'},
    {'key': 2, 'label': 'Su'},
    {'key': 3, 'label': 'Uyku'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = ref.read(takipTabIndexProvider);
      if (index != 0) _tabController.animateTo(index);
    });
    ref.listenManual(takipTabIndexProvider, (_, next) {
      if (_tabController.index != next) _tabController.animateTo(next);
    });
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(takipTabIndexProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showNotifications(BuildContext context, bool isDark,
      Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final notifsAsync = ref.watch(notificationsProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(99)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('🔔 Bildirimler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
                    GestureDetector(
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('in_app_notifications');
                        ref.invalidate(notificationsProvider);
                      },
                      child: Text('Temizle', style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 300,
                child: notifsAsync.when(
                  loading: () => Center(child: CircularProgressIndicator(color: accent)),
                  error:   (_, __) => Center(child: Text('Yüklenemedi', style: TextStyle(color: text))),
                  data: (notifs) {
                    if (notifs.isEmpty) {
                      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('🔕', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text('Henüz bildirim yok', style: TextStyle(fontSize: 14, color: text)),
                        const SizedBox(height: 4),
                        Text('Hatırlatıcılar burada görünecek', style: TextStyle(fontSize: 12, color: muted)),
                      ]);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: notifs.length,
                      itemBuilder: (ctx, i) {
                        final n = notifs[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                          child: Row(children: [
                            const Text('🔔', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(n['title'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: text)),
                              const SizedBox(height: 2),
                              Text(n['body'] as String, style: TextStyle(fontSize: 11, color: textSoft)),
                              if ((n['time'] as String).isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(n['time'] as String, style: TextStyle(fontSize: 10, color: muted)),
                              ],
                            ])),
                          ]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? _TC.bg       : _TC.lBg;
    final bgCard   = isDark ? _TC.bgCard   : _TC.lBgCard;
    final bgSoft   = isDark ? _TC.bgSoft   : _TC.lBgSoft;
    final border   = isDark ? _TC.border   : _TC.lBorder;
    final text     = isDark ? _TC.text     : _TC.lText;
    final textSoft = isDark ? _TC.textSoft : _TC.lTextSoft;
    final muted    = isDark ? _TC.textMuted : _TC.lTextMuted;
    final accent   = isDark ? _TC.accent   : _TC.lAccent;

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
                    Expanded(
                      child: Text('Takip', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5)),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                        child: Icon(isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round, size: 15, color: textSoft),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showNotifications(context, isDark, bgCard, bgSoft, border, text, textSoft, muted, accent),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                        child: Icon(Icons.notifications_none_rounded, size: 15, color: textSoft),
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
                    indicator: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0,1))],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: accent,
                    unselectedLabelColor: muted,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    tabs: _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                OlcumTab(),
                DiyetTab(),
                SuTab(),
                UykuTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}