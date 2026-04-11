// ── takip_screen.dart ───────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'olcum_tab.dart';
import 'su_tab.dart';
import 'uyku_tab.dart';
import 'diyet_tab.dart';

// Hangi tab'ın aktif olduğunu kontrol eden provider
// 0=Ölçüm, 1=Diyet, 2=Su, 3=Uyku
final takipTabIndexProvider = StateProvider<int>((ref) => 0);

class TakipScreen extends ConsumerStatefulWidget {
  const TakipScreen({super.key});

  @override
  ConsumerState<TakipScreen> createState() => _TakipScreenState();
}

class _TakipScreenState extends ConsumerState<TakipScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // initState'te mevcut provider değerini oku ve uygula
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = ref.read(takipTabIndexProvider);
      if (index != 0) {
        _tabController.animateTo(index);
      }
    });

    // Provider değişince tab'ı güncelle
    ref.listenManual(takipTabIndexProvider, (_, next) {
      if (_tabController.index != next) {
        _tabController.animateTo(next);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Takip'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor:
          Theme.of(context).textTheme.bodySmall?.color,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.monitor_weight_outlined), text: 'Ölçüm'),
            Tab(icon: Icon(Icons.restaurant_outlined), text: 'Diyet'),
            Tab(icon: Icon(Icons.water_drop_outlined), text: 'Su'),
            Tab(icon: Icon(Icons.bedtime_outlined), text: 'Uyku'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OlcumTab(),
          DiyetTab(),
          SuTab(),
          UykuTab(),
        ],
      ),
    );
  }
}