// ── ai_screen.dart ──────────────────────────────────────
// AI Koç ana ekranı.
// 5 AI özelliğine erişim kartları gösterilir.
// Her karta tıklanınca ilgili AI ekranı açılır.

import 'package:flutter/material.dart';
import 'weekly_summary_screen.dart';
import 'workout_plan_screen.dart';
import 'meal_advice_screen.dart';
import 'recipe_screen.dart';
import 'calorie_vision_screen.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Koç')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık açıklaması
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '🤖',
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Claude AI ile Tanış',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Verilerine göre kişiselleştirilmiş öneriler',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // AI özellik kartları
            _AiFeatureCard(
              emoji: '📊',
              title: 'Haftalık Özet',
              description: 'Bu haftanın tam analizi — kazanımlar, eksikler ve öneriler',
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WeeklySummaryScreen(),
                ),
              ),
            ),

            _AiFeatureCard(
              emoji: '💪',
              title: 'Antrenman Planı',
              description: 'Hedeflerine ve ekipmanına göre kişisel program',
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WorkoutPlanScreen(),
                ),
              ),
            ),

            _AiFeatureCard(
              emoji: '🥗',
              title: 'Diyet Tavsiyesi',
              description: 'BMR/TDEE bazlı, tercihlerine göre beslenme planı',
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MealAdviceScreen(),
                ),
              ),
            ),

            _AiFeatureCard(
              emoji: '👨‍🍳',
              title: 'Tarif Önerisi',
              description: 'Elindeki malzemelerle sağlıklı tarifler',
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RecipeScreen(),
                ),
              ),
            ),

            _AiFeatureCard(
              emoji: '📸',
              title: 'Fotoğraftan Kalori',
              description: 'Yemeğin fotoğrafını çek, kalori tahminini al',
              color: Colors.red,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CalorieVisionScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// AI özellik kartı
class _AiFeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _AiFeatureCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        // InkWell — tıklanabilir alan, ripple efekti ekler
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Emoji container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 16),

              // Başlık ve açıklama
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
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