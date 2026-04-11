// ── more_screen.dart ────────────────────────────────────
// "Daha Fazla" menü ekranı.
// Raporlar, Sosyal, Alışveriş, Profil ekranlarına erişim.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../raporlar/raporlar_screen.dart';
import '../sosyal/sosyal_screen.dart';
import '../alisveris/alisveris_screen.dart';
import '../profil/profil_screen.dart';
import '../gamification/gamification_screen.dart';
import '../steps/steps_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daha Fazla')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── BÖLÜM: ANALİZ ─────────────────────────
            _SectionTitle(title: 'Analiz'),
            _MenuItem(
              emoji: '📊',
              title: 'Raporlar',
              description: 'Haftalık ve aylık grafikler',
              color: Colors.blue,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RaporlarScreen())),
            ),
            _MenuItem(
              emoji: '🏆',
              title: 'Gamification',
              description: 'XP, rozetler, seviye',
              color: Colors.amber,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GamificationScreen())),
            ),
            _MenuItem(
              emoji: '👟',
              title: 'Adım Sayar',
              description: 'Günlük adım takibi',
              color: Colors.green,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StepsScreen())),
            ),

            const SizedBox(height: 16),

            // ── BÖLÜM: SOSYAL ─────────────────────────
            _SectionTitle(title: 'Sosyal'),
            _MenuItem(
              emoji: '👥',
              title: 'Arkadaşlar & Liderlik',
              description: 'Arkadaşlarınla yarış',
              color: Colors.purple,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SosyalScreen())),
            ),

            const SizedBox(height: 16),

            // ── BÖLÜM: ALIŞVERIŞ ──────────────────────
            _SectionTitle(title: 'Alışveriş'),
            _MenuItem(
              emoji: '🛒',
              title: 'Alışveriş Listesi',
              description: 'Barkod tarayıcı dahil',
              color: Colors.orange,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AlisverisScreen())),
            ),

            const SizedBox(height: 16),

            // ── BÖLÜM: HESAP ──────────────────────────
            _SectionTitle(title: 'Hesap'),
            _MenuItem(
              emoji: '👤',
              title: 'Profil',
              description: 'Sağlık bilgileri ve tercihler',
              color: Colors.teal,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfilScreen())),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// Bölüm başlığı
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodySmall?.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// Menü item kartı
class _MenuItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}