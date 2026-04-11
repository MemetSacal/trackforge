// ── recipe_screen.dart ──────────────────────────────────
// AI tarif önerisi ekranı.
// Kullanıcı elindeki malzemeleri girer, öğün tipini seçer.
// POST /ai/recipe → Claude malzemelere göre sağlıklı tarif önerir.

import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  // Malzeme girişi
  final _ingredientController = TextEditingController();
  final List<String> _ingredients = []; // Eklenen malzemeler listesi

  String _mealType = 'dinner';
  int? _calorieLimit;
  final _calorieLimitController = TextEditingController();

  Map<String, dynamic>? _recipe;
  bool _isLoading = false;
  String? _error;

  final _mealTypes = [
    {'key': 'breakfast', 'label': '🌅 Kahvaltı'},
    {'key': 'lunch', 'label': '☀️ Öğle'},
    {'key': 'dinner', 'label': '🌙 Akşam'},
    {'key': 'snack', 'label': '🍎 Atıştırmalık'},
  ];

  @override
  void dispose() {
    _ingredientController.dispose();
    _calorieLimitController.dispose();
    super.dispose();
  }

  // Malzeme ekle
  void _addIngredient() {
    final text = _ingredientController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _ingredients.add(text);
      _ingredientController.clear();
    });
  }

  // Tarif getir
  Future<void> _getRecipe() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az 1 malzeme ekleyin')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _recipe = null;
    });

    try {
      final response = await ApiClient.instance.post(
        Endpoints.aiRecipe,
        data: {
          'available_ingredients': _ingredients,
          'meal_type': _mealType,
          'calorie_limit': _calorieLimit,
        },
      );

      setState(() => _recipe = Map<String, dynamic>.from(response.data));
    } catch (e) {
      setState(() => _error = 'Tarif alınırken hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tarif Önerisi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_recipe == null && !_isLoading) ...[

              // ── ÖĞÜN TİPİ ───────────────────────────
              const Text(
                'Hangi öğün?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: _mealTypes.map((m) {
                  final isSelected = _mealType == m['key'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mealType = m['key']!),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.15)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).dividerColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          m['label']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // ── MALZEMELERİ GİR ─────────────────────
              const Text(
                'Elindeki malzemeler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ingredientController,
                      decoration: const InputDecoration(
                        labelText: 'Malzeme ekle (tavuk, pirinç...)',
                        prefixIcon: Icon(Icons.add_circle_outline),
                      ),
                      // Enter'a basınca ekle
                      onSubmitted: (_) => _addIngredient(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addIngredient,
                    icon: Icon(
                      Icons.add_circle,
                      color: Theme.of(context).primaryColor,
                      size: 36,
                    ),
                  ),
                ],
              ),

              // Eklenen malzemeler — chip listesi
              if (_ingredients.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _ingredients.map((ing) {
                    return Chip(
                      label: Text(ing),
                      // X butonuna basınca malzemeyi sil
                      onDeleted: () =>
                          setState(() => _ingredients.remove(ing)),
                      backgroundColor: Theme.of(context)
                          .primaryColor
                          .withOpacity(0.1),
                      deleteIconColor: Theme.of(context).primaryColor,
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),

              // ── KALORİ LİMİTİ ───────────────────────
              TextField(
                controller: _calorieLimitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kalori limiti (opsiyonel)',
                  prefixIcon: Icon(Icons.local_fire_department_outlined),
                  hintText: 'örn: 500',
                ),
                onChanged: (v) =>
                    setState(() => _calorieLimit = int.tryParse(v)),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _getRecipe,
                icon: const Text('👨‍🍳'),
                label: const Text('Tarif Öner'),
              ),
            ],

            // ── YÜKLEME ───────────────────────────────
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 24),
                    const Text('👨‍🍳 Tarif hazırlanıyor...'),
                    const SizedBox(height: 8),
                    Text(
                      'Bu 10-20 saniye sürebilir',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

            // ── HATA ──────────────────────────────────
            if (_error != null)
              Center(
                child: Column(
                  children: [
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _getRecipe,
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),

            // ── TARİF GELDİ ───────────────────────────
            if (_recipe != null) ...[
              // Tarif başlığı kartı
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recipe!['recipe_name'] as String? ?? 'Tarif',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_recipe!['description'] != null) ...[
                        const SizedBox(height: 8),
                        Text(_recipe!['description'] as String),
                      ],
                      const SizedBox(height: 12),
                      // Süre ve porsiyon bilgisi
                      Wrap(
                        spacing: 16,
                        children: [
                          if (_recipe!['prep_time_minutes'] != null)
                            _InfoChip(
                              icon: '⏱️',
                              label:
                              'Hazırlık: ${_recipe!['prep_time_minutes']} dk',
                            ),
                          if (_recipe!['cook_time_minutes'] != null)
                            _InfoChip(
                              icon: '🔥',
                              label:
                              'Pişirme: ${_recipe!['cook_time_minutes']} dk',
                            ),
                          if (_recipe!['servings'] != null)
                            _InfoChip(
                              icon: '🍽️',
                              label: '${_recipe!['servings']} porsiyon',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Besin değerleri
              if (_recipe!['nutrition'] != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📊 Besin Değerleri',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (Map<String, dynamic>.from(
                              _recipe!['nutrition']))
                              .entries
                              .map((e) => _InfoChip(
                            icon: '',
                            label: '${e.key}: ${e.value}',
                          ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Malzemeler
              if (_recipe!['ingredients'] != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🛒 Malzemeler',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...(_recipe!['ingredients'] as List).map((ing) {
                          final ingMap = ing is Map
                              ? Map<String, dynamic>.from(ing)
                              : {'name': ing.toString()};
                          final name = ingMap['name'] ??
                              ingMap['ingredient'] ??
                              ing.toString();
                          final amount = ingMap['amount'] ??
                              ingMap['quantity'] ??
                              ingMap['measure'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Text('• '),
                                Text('$name${amount.toString().isNotEmpty ? ' — $amount' : ''}'),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Yapılış adımları
              if (_recipe!['steps'] != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📝 Yapılış',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...(_recipe!['steps'] as List)
                            .asMap()
                            .entries
                            .map((entry) {
                          final step = entry.value;
                          final stepMap = step is Map
                              ? Map<String, dynamic>.from(step)
                              : null;
                          final stepText = stepMap?['instruction'] ??
                              stepMap?['step'] ??
                              stepMap?['description'] ??
                              step.toString();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(stepText.toString())),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // İpuçları
              if (_recipe!['tips'] != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💡 İpuçları',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(_recipe!['tips'] as String),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _recipe = null;
                  _ingredients.clear();
                }),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Yeni Tarif'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Bilgi chip'i
class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        '$icon $label'.trim(),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}