// ── home_screen.dart ────────────────────────────────────
// Ana sayfa — Dashboard.
// Bottom navigation bar burada tanımlanır.
// 5 sekme: Ana Sayfa | Takip | Egzersiz | AI | Daha Fazla
// Her sekme kendi screen'ini gösterir.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../takip/takip_screen.dart';
import '../egzersiz/egzersiz_screen.dart';
import '../ai/ai_screen.dart';
import 'dashboard_screen.dart';
import 'more_screen.dart';

// Hangi sekmenin aktif olduğunu tutan provider
// StateProvider — tek bir değeri tutan basit provider
// int: sekme indexi (0=AnaSayfa, 1=Takip, 2=Egzersiz, 3=AI, 4=Daha Fazla)
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Her sekmenin göstereceği ekran listesi
  // Index ile eşleşiyor — 0=Dashboard, 1=Takip vs.
  static const List<Widget> _screens = [
    DashboardScreen(),
    TakipScreen(),
    EgzersizScreen(),
    AiScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider'dan aktif sekme indexini oku
    // watch — değer değişince widget yeniden çizilir
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      // Aktif sekmenin ekranını göster
      body: _screens[currentIndex],

      // ── BOTTOM NAVIGATION BAR ─────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        // Sekmeye tıklanınca provider'ı güncelle
        // notifier.state = ... ile değeri değiştiriyoruz
        onTap: (index) =>
        ref.read(bottomNavIndexProvider.notifier).state = index,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            activeIcon: Icon(Icons.track_changes),
            label: 'Takip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: 'Egzersiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            activeIcon: Icon(Icons.more_horiz),
            label: 'Daha Fazla',
          ),
        ],
      ),
    );
  }
}