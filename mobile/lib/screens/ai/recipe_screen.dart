// ── recipe_screen.dart ──────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../app.dart';
import 'ai_helpers.dart'; // import eklendi

class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({super.key});
  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  final _ingredientController   = TextEditingController();
  final _calorieLimitController = TextEditingController();
  final List<String> _ingredients = [];
  String _mealType = 'dinner';
  int? _calorieLimit;
  Map<String, dynamic>? _recipe;
  bool _isLoading = false;
  String? _error;

  final _mealTypes = [
    {'key': 'breakfast', 'label': '🌅 Kahvaltı'},
    {'key': 'lunch',     'label': '☀️ Öğle'},
    {'key': 'dinner',    'label': '🌙 Akşam'},
    {'key': 'snack',     'label': '🍎 Atıştırmalık'},
  ];

  @override
  void dispose() { _ingredientController.dispose(); _calorieLimitController.dispose(); super.dispose(); }

  void _addIngredient() {
    final t = _ingredientController.text.trim();
    if (t.isEmpty) return;
    setState(() { _ingredients.add(t); _ingredientController.clear(); });
  }

  Future<void> _getRecipe() async {
    if (_ingredients.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('En az 1 malzeme ekleyin'))); return; }
    setState(() { _isLoading = true; _error = null; _recipe = null; });
    try {
      final response = await ApiClient.instance.post(Endpoints.aiRecipe, data: {
        'available_ingredients': _ingredients,
        'meal_type':   _mealType,
        'calorie_limit': _calorieLimit,
      });
      setState(() => _recipe = Map<String, dynamic>.from(response.data));
    } catch (_) { setState(() => _error = 'Tarif alınırken hata oluştu.'); }
    finally { if (mounted) setState(() => _isLoading = false); }
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
    final danger   = isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          aiHeader(context, ref, isDark, bg, bgCard, border, text, textSoft, muted, accent, 'Tarif Önerisi'),
          Expanded(
            child: _isLoading
                ? aiLoadingState(accent, text, '👨‍🍳 Tarif hazırlanıyor...')
                : _error != null
                    ? aiErrorState(_error!, danger, accent, _getRecipe)
                    : _recipe != null
                        ? _recipeResult(bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim)
                        : _recipeForm(bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim),
          ),
        ],
      ),
    );
  }

  Widget _recipeForm(Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hangi öğün?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
        const SizedBox(height: 10),
        Row(children: _mealTypes.map((m) {
          final sel = _mealType == m['key'];
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _mealType = m['key']!),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel ? accentDim : bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? accent : border, width: sel ? 1.5 : 1),
              ),
              child: Text(m['label']!, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? accent : text)),
            ),
          ));
        }).toList()),
        const SizedBox(height: 20),
        Text('Elindeki malzemeler', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _ingredientController, style: TextStyle(color: text),
            decoration: const InputDecoration(labelText: 'Malzeme ekle...', prefixIcon: Icon(Icons.add_circle_outline)),
            onSubmitted: (_) => _addIngredient())),
          const SizedBox(width: 8),
          GestureDetector(onTap: _addIngredient,
            child: Container(width: 44, height: 44, decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(12), border: Border.all(color: accent)),
              child: Icon(Icons.add, color: accent))),
        ]),
        if (_ingredients.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8,
            children: _ingredients.map((ing) => GestureDetector(
              onTap: () => setState(() => _ingredients.remove(ing)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(99), border: Border.all(color: accent)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(ing, style: TextStyle(fontSize: 12, color: accent)),
                  const SizedBox(width: 6),
                  Icon(Icons.close, size: 12, color: accent),
                ]),
              ),
            )).toList()),
        ],
        const SizedBox(height: 16),
        TextField(controller: _calorieLimitController, keyboardType: TextInputType.number, style: TextStyle(color: text),
          decoration: const InputDecoration(labelText: 'Kalori limiti (opsiyonel)', prefixIcon: Icon(Icons.local_fire_department_outlined), hintText: 'örn: 500'),
          onChanged: (v) => setState(() => _calorieLimit = int.tryParse(v))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _getRecipe, child: const Text('👨‍🍳  Tarif Öner'))),
      ]),
    );
  }

  Widget _recipeResult(Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(children: [
        // Başlık
        Container(
          decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(20), border: Border.all(color: accent)),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_recipe!['recipe_name'] as String? ?? 'Tarif',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text)),
            if (_recipe!['description'] != null) ...[
              const SizedBox(height: 6),
              Text(_recipe!['description'] as String, style: TextStyle(fontSize: 13, color: textSoft)),
            ],
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (_recipe!['prep_time_minutes'] != null) _chip('⏱️ ${_recipe!['prep_time_minutes']} dk hazırlık', bgSoft, border, text),
              if (_recipe!['cook_time_minutes'] != null) _chip('🔥 ${_recipe!['cook_time_minutes']} dk pişirme', bgSoft, border, text),
              if (_recipe!['servings']          != null) _chip('🍽️ ${_recipe!['servings']} porsiyon', bgSoft, border, text),
            ]),
          ]),
        ),
        const SizedBox(height: 10),

        // Besin değerleri
        if (_recipe!['nutrition'] != null) ...[
          _section('📊 Besin Değerleri', bgCard, border, text, child:
            Wrap(spacing: 8, runSpacing: 8,
              children: Map<String, dynamic>.from(_recipe!['nutrition']).entries.map((e) =>
                _chip('${e.key}: ${e.value}', bgSoft, border, text)).toList())),
          const SizedBox(height: 10),
        ],

        // Malzemeler
        if (_recipe!['ingredients'] != null) ...[
          _section('🛒 Malzemeler', bgCard, border, text, child:
            Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: (_recipe!['ingredients'] as List).map((ing) {
                final m = ing is Map ? Map<String, dynamic>.from(ing) : {'name': ing.toString()};
                final name   = m['name'] ?? m['ingredient'] ?? ing.toString();
                final amount = m['amount'] ?? m['quantity'] ?? '';
                return Padding(padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Text('• ', style: TextStyle(color: accent)),
                    Text('$name${amount.toString().isNotEmpty ? " — $amount" : ""}', style: TextStyle(fontSize: 13, color: text)),
                  ]));
              }).toList())),
          const SizedBox(height: 10),
        ],

        // Adımlar
        if (_recipe!['steps'] != null) ...[
          _section('📝 Yapılış', bgCard, border, text, child:
            Column(children: (_recipe!['steps'] as List).asMap().entries.map((e) {
              final step = e.value;
              final m = step is Map ? Map<String, dynamic>.from(step) : null;
              final t = m?['instruction'] ?? m?['step'] ?? m?['description'] ?? step.toString();
              return Padding(padding: const EdgeInsets.only(bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 24, height: 24, decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text('${e.key + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent)))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t.toString(), style: TextStyle(fontSize: 13, color: text, height: 1.5))),
                ]));
            }).toList())),
          const SizedBox(height: 10),
        ],

        if (_recipe!['tips'] != null) ...[
          _section('💡 İpuçları', bgCard, border, text, child:
            Text(_recipe!['tips'] as String, style: TextStyle(fontSize: 13, color: text, height: 1.5))),
          const SizedBox(height: 10),
        ],

        aiOutlineBtn('Yeni Tarif', Icons.arrow_back, accent, border,
          () => setState(() { _recipe = null; _ingredients.clear(); })),
      ]),
    );
  }

  Widget _chip(String label, Color bg, Color border, Color text) =>
    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99), border: Border.all(color: border)),
      child: Text(label, style: TextStyle(fontSize: 11, color: text)));

  Widget _section(String title, Color bgCard, Color border, Color text, {required Widget child}) =>
    Container(decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
        const SizedBox(height: 10),
        child,
      ]));
}