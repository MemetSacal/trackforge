// ── recipe_screen.dart ──────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../app.dart';
import 'ai_helpers.dart';

class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({super.key});
  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  // ── Akış adımları ──
  // 0: Malzeme sorusu
  // 1: Craving + öğün seçimi
  // 2: Sonuç
  int _step = 0;

  final _ingredientController = TextEditingController();
  final List<String> _ingredients = [];
  String _mealType = 'dinner';
  String? _craving;
  Map<String, dynamic>? _recipe;
  bool _isLoading = false;
  String? _error;
  bool _addingToCart = false;
  bool _addedToCart  = false;

  final _mealTypes = [
    {'key': 'breakfast', 'label': '🌅 Kahvaltı'},
    {'key': 'lunch',     'label': '☀️ Öğle'},
    {'key': 'dinner',    'label': '🌙 Akşam'},
    {'key': 'snack',     'label': '🍎 Atıştırmalık'},
  ];

  final _cravings = [
    {'key': 'tatlı',          'label': '🍫 Tatlı',           'emoji': '🍫'},
    {'key': 'tuzlu',          'label': '🧂 Tuzlu',           'emoji': '🧂'},
    {'key': 'baharatlı',      'label': '🌶️ Baharatlı',       'emoji': '🌶️'},
    {'key': 'hafif',          'label': '🥗 Hafif',           'emoji': '🥗'},
    {'key': 'doyurucu',       'label': '🍖 Doyurucu',        'emoji': '🍖'},
    {'key': 'diyete uygun',   'label': '💪 Diyete Uygun',    'emoji': '💪'},
  ];

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final t = _ingredientController.text.trim();
    if (t.isEmpty) return;
    setState(() { _ingredients.add(t); _ingredientController.clear(); });
  }

  void _reset() {
    setState(() {
      _step        = 0;
      _ingredients.clear();
      _mealType    = 'dinner';
      _craving     = null;
      _recipe      = null;
      _error       = null;
      _addedToCart = false;
    });
  }

  Future<void> _getRecipe() async {
    setState(() { _isLoading = true; _error = null; _recipe = null; });
    try {
      final response = await ApiClient.instance.post(Endpoints.aiRecipe, data: {
        'available_ingredients': _ingredients,
        'meal_type':   _mealType,
        'craving':     _craving,
        'calorie_limit': null,
      });
      setState(() { _recipe = Map<String, dynamic>.from(response.data); _step = 2; });
    } catch (_) {
      setState(() => _error = 'Tarif alınırken hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Malzemeleri alışveriş listesine ekle ──────────────
  Future<void> _addToShoppingList() async {
    if (_recipe == null) return;
    final ingredients = (_recipe!['ingredients'] as List?) ?? [];
    if (ingredients.isEmpty) return;

    setState(() => _addingToCart = true);
    try {
      for (final ing in ingredients) {
        final m    = ing is Map ? Map<String, dynamic>.from(ing) : null;
        final name = m?['name'] ?? ing.toString();
        final amt  = m?['amount']?.toString() ?? '1';
        await ApiClient.instance.post(Endpoints.shopping, data: {
          'name':     name,
          'quantity': amt,
          'category': 'Tarif Malzemesi',
        });
      }
      setState(() => _addedToCart = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Malzemeler alışveriş listesine eklendi ✅')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listeye eklenirken hata oluştu')),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
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
    final danger   = isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);
    final positive = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          aiHeader(context, ref, isDark, bg, bgCard, border, text, textSoft, muted, accent, 'Tarif Önerici'),
          Expanded(
            child: _isLoading
                ? aiLoadingState(accent, text, '👨‍🍳 Tarif hazırlanıyor...')
                : _error != null
                    ? aiErrorState(_error!, danger, accent, _getRecipe)
                    : _step == 0
                        ? _stepIngredients(bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim)
                        : _step == 1
                            ? _stepCraving(bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim)
                            : _recipeResult(bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim, danger, positive),
          ),
        ],
      ),
    );
  }

  // ── ADIM 0: Malzeme sorusu ────────────────────────────
  Widget _stepIngredients(Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Progress
        _progressBar(1, accent, muted),
        const SizedBox(height: 20),

        Text('Eklemek istediğin malzeme var mı?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Text('İstersen özel malzeme ekle, yoksa geçebilirsin.', style: TextStyle(fontSize: 13, color: muted)),
        const SizedBox(height: 20),

        // Malzeme ekleme
        Row(children: [
          Expanded(
            child: TextField(
              controller: _ingredientController,
              style: TextStyle(color: text),
              decoration: InputDecoration(
                labelText: 'Malzeme ekle...',
                prefixIcon: GestureDetector(
                  onTap: _addIngredient,
                  child: const Icon(Icons.add_circle_outline),
                ),
              ),
              onSubmitted: (_) => _addIngredient(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _addIngredient,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(12), border: Border.all(color: accent)),
              child: Icon(Icons.add, color: accent),
            ),
          ),
        ]),

        if (_ingredients.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
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
            )).toList(),
          ),
        ],

        const SizedBox(height: 24),

        // Devam butonu
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              _ingredients.isEmpty ? 'Eklemek istediğim malzeme yok, devam et →' : 'Devam Et →',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ]),
    );
  }

  // ── ADIM 1: Craving + öğün seçimi ────────────────────
  Widget _stepCraving(Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _progressBar(2, accent, muted),
        const SizedBox(height: 20),

        Text('Canın ne istiyor?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Text('AI kalori bankana göre uygun tarifi bulacak.', style: TextStyle(fontSize: 13, color: muted)),
        const SizedBox(height: 16),

        // Craving seçimi
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.3,
          children: _cravings.map((c) {
            final sel = _craving == c['key'];
            return GestureDetector(
              onTap: () => setState(() => _craving = c['key']),
              child: Container(
                decoration: BoxDecoration(
                  color: sel ? accentDim : bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? accent : border, width: sel ? 1.5 : 1),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(c['emoji']!, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    c['key']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? accent : text),
                  ),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Öğün seçimi
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
                style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? accent : text)),
            ),
          ));
        }).toList()),
        const SizedBox(height: 24),

        Row(children: [
          // Geri
          GestureDetector(
            onTap: () => setState(() => _step = 0),
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
              child: Icon(Icons.arrow_back, color: muted),
            ),
          ),
          const SizedBox(width: 10),
          // Tarif Al
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _craving == null ? null : _getRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: accent.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('👨‍🍳  Tarif Öner', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ]),

        if (_craving == null) ...[
          const SizedBox(height: 10),
          Center(child: Text('Devam etmek için bir seçenek seç', style: TextStyle(fontSize: 12, color: muted))),
        ],
      ]),
    );
  }

  // ── ADIM 2: Tarif sonucu ──────────────────────────────
  Widget _recipeResult(Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim, Color danger, Color positive) {
    if (_recipe == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(children: [
        // Başlık
        Container(
          decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(20), border: Border.all(color: accent)),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('👨‍🍳', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: Text(
                _recipe!['recipe_name'] as String? ?? 'Tarif',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text),
              )),
            ]),
            if (_recipe!['description'] != null) ...[
              const SizedBox(height: 8),
              Text(_recipe!['description'] as String, style: TextStyle(fontSize: 13, color: textSoft, height: 1.5)),
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
              children: Map<String, dynamic>.from(_recipe!['nutrition']).entries.map((e) {
                final labels = {'calories': 'Kalori', 'protein_g': 'Protein', 'carbs_g': 'Karb', 'fat_g': 'Yağ', 'fiber_g': 'Lif'};
                final label  = labels[e.key] ?? e.key;
                return _chip('$label: ${e.value}', bgSoft, border, text);
              }).toList())),
          const SizedBox(height: 10),
        ],

        // Malzemeler + alışveriş listesi butonu
        if (_recipe!['ingredients'] != null) ...[
          Container(
            decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('🛒 Malzemeler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
                // Alışveriş listesine ekle butonu
                GestureDetector(
                  onTap: _addedToCart ? null : _addToShoppingList,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _addedToCart ? positive.withOpacity(0.1) : accentDim,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: _addedToCart ? positive : accent),
                    ),
                    child: _addingToCart
                        ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: accent))
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(_addedToCart ? Icons.check : Icons.add_shopping_cart, size: 13, color: _addedToCart ? positive : accent),
                            const SizedBox(width: 4),
                            Text(
                              _addedToCart ? 'Eklendi' : 'Listeye Ekle',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _addedToCart ? positive : accent),
                            ),
                          ]),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              ...(_recipe!['ingredients'] as List).map((ing) {
                final m      = ing is Map ? Map<String, dynamic>.from(ing) : {'name': ing.toString()};
                final name   = m['name'] ?? ing.toString();
                final amount = m['amount'] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Text('• ', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
                    Expanded(child: Text(
                      amount.toString().isNotEmpty ? '$name  —  $amount' : name,
                      style: TextStyle(fontSize: 13, color: text),
                    )),
                  ]),
                );
              }),
            ]),
          ),
          const SizedBox(height: 10),
        ],

        // Adımlar
        if (_recipe!['steps'] != null) ...[
          _section('📝 Yapılış', bgCard, border, text, child:
            Column(children: (_recipe!['steps'] as List).asMap().entries.map((e) {
              final step = e.value;
              final m    = step is Map ? Map<String, dynamic>.from(step) : null;
              final t    = m?['instruction'] ?? m?['step'] ?? m?['description'] ?? step.toString();
              final dur  = m?['duration_minutes'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('${e.key + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.toString(), style: TextStyle(fontSize: 13, color: text, height: 1.5)),
                    if (dur != null) Text('⏱ $dur dk', style: TextStyle(fontSize: 11, color: muted)),
                  ])),
                ]),
              );
            }).toList())),
          const SizedBox(height: 10),
        ],

        if (_recipe!['tips'] != null) ...[
          _section('💡 İpuçları', bgCard, border, text, child:
            Text(_recipe!['tips'] as String, style: TextStyle(fontSize: 13, color: text, height: 1.5))),
          const SizedBox(height: 10),
        ],

        aiOutlineBtn('Yeni Tarif', Icons.refresh, accent, border, _reset),
      ]),
    );
  }

  // ── Yardımcı widget'lar ───────────────────────────────
  Widget _progressBar(int step, Color accent, Color muted) {
    return Row(children: List.generate(2, (i) => Expanded(
      child: Container(
        margin: EdgeInsets.only(right: i < 1 ? 4 : 0),
        height: 4,
        decoration: BoxDecoration(
          color: i < step ? accent : muted.withOpacity(0.3),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    )));
  }

  Widget _chip(String label, Color bg, Color border, Color text) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99), border: Border.all(color: border)),
      child: Text(label, style: TextStyle(fontSize: 11, color: text)),
    );

  Widget _section(String title, Color bgCard, Color border, Color text, {required Widget child}) =>
    Container(
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text)),
        const SizedBox(height: 10),
        child,
      ]),
    );
}