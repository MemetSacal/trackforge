// ── onboarding_screen.dart ──────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/api/endpoints.dart';

class _ON {
  static const bg        = Color(0xFF0C0D10);
  static const bgCard    = Color(0xFF141620);
  static const bgSoft    = Color(0xFF0F1016);
  static const border    = Color(0x12FFFFFF);
  static const text      = Color(0xFFF0EEF8);
  static const textSoft  = Color(0xFF8A88A8);
  static const textMuted = Color(0xFF4A4860);
  static const accent    = Color(0xFFFFB020);
  static const accentDim = Color(0x1FFFB020);
  static const positive  = Color(0xFF34D399);
  static const danger    = Color(0xFFFF5555);
  static const lBg       = Color(0xFFF0F2F6);
  static const lBgCard   = Color(0xFFFFFFFF);
  static const lBgSoft   = Color(0xFFE8EBF2);
  static const lBorder   = Color(0x12000000);
  static const lText     = Color(0xFF111318);
  static const lTextSoft = Color(0xFF5A6078);
  static const lTextMuted= Color(0xFF9AA0B8);
  static const lAccent   = Color(0xFFFF6B2B);
  static const lAccentDim= Color(0x1AFF6B2B);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  static const int _totalSteps = 6; // ← 5'ten 6'ya çıktı

  // Step 0 — Hedefler
  final List<String> _selectedGoals = [];
  final _goals = [
    {'key': 'lose_weight',    'label': 'Kilo Vermek',        'emoji': '⚡'},
    {'key': 'maintain_weight','label': 'Aynı Kiloda Kalmak', 'emoji': '⚖️'},
    {'key': 'gain_weight',    'label': 'Kilo Almak',         'emoji': '📈'},
    {'key': 'build_muscle',   'label': 'Kas Kazanmak',       'emoji': '💪'},
    {'key': 'change_diet',    'label': 'Diyetimi Değiştir',  'emoji': '🥗'},
    {'key': 'plan_meals',     'label': 'Öğün Planla',        'emoji': '🍽️'},
    {'key': 'manage_stress',  'label': 'Stresi Yönetmek',    'emoji': '🧘'},
    {'key': 'stay_active',    'label': 'Aktif Kal',          'emoji': '🏃'},
  ];

  // Step 1 — Temel bilgiler
  final _heightController    = TextEditingController();
  final _weightController    = TextEditingController();
  final _ageController       = TextEditingController();
  final _targetWeightController = TextEditingController(); // ← YENİ
  String _gender = 'male';

  // Step 2 — Aktivite
  String _activity = 'sedentary';
  final _activities = [
    {'key': 'sedentary',         'label': 'Sedanter',     'desc': 'Masa başı iş, az hareket'},
    {'key': 'lightly_active',    'label': 'Hafif Aktif',  'desc': 'Haftada 1-3 gün egzersiz'},
    {'key': 'moderately_active', 'label': 'Orta Aktif',   'desc': 'Haftada 3-5 gün egzersiz'},
    {'key': 'active',            'label': 'Aktif',        'desc': 'Haftada 6-7 gün egzersiz'},
    {'key': 'very_active',       'label': 'Çok Aktif',    'desc': 'Günde 2 antrenman'},
  ];

  // Step 3 — Diyet
  String _diet = 'normal';
  final _diets = [
    {'key': 'normal',      'label': 'Normal',    'emoji': '🍖'},
    {'key': 'vegetarian',  'label': 'Vejetaryen','emoji': '🥦'},
    {'key': 'vegan',       'label': 'Vegan',     'emoji': '🌱'},
    {'key': 'gluten_free', 'label': 'Glutensiz', 'emoji': '🌾'},
  ];

  // Step 4 — Kalori alışkanlığı ← YENİ
  String _calorieHabit = '1500_2000';
  final _calorieHabits = [
      {'key': 'under_1500', 'label': '1500 kcal altı',    'desc': 'Çok az yiyorum, genelde aç hissediyorum', 'emoji': '🥗'},
      {'key': '1500_2000',  'label': '1500–2000 kcal',    'desc': 'Ortalama, dengeli beslenirim',              'emoji': '🍽️'},
      {'key': '2000_2500',  'label': '2000–2500 kcal',    'desc': 'Aktif biriyim, iyi iştahım var',           'emoji': '🍖'},
      {'key': '2500_3000',  'label': '2500–3000 kcal',    'desc': 'Çok yerim veya çok spor yaparım',          'emoji': '🥩'},
      {'key': 'over_3000',  'label': '3000 kcal üzeri',   'desc': 'Çok yüksek kalori alıyorum',               'emoji': '🍔'},
    ];

  // Step 5 — AI Koç ismi
  final _aiNameController = TextEditingController(text: 'TrackForge AI');

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _targetWeightController.dispose();
    _aiNameController.dispose();
    super.dispose();
  }

  String? _validateStep() {
    switch (_step) {
      case 0:
        if (_selectedGoals.isEmpty) return 'En az 1 hedef seçmelisin';
        return null;
      case 1:
        final h = double.tryParse(_heightController.text);
        final w = double.tryParse(_weightController.text);
        final a = int.tryParse(_ageController.text);
        if (_heightController.text.isEmpty) return 'Boy zorunludur';
        if (h == null || h < 100 || h > 250) return 'Boy 100–250 cm arasında olmalı';
        if (_weightController.text.isEmpty) return 'Kilo zorunludur';
        if (w == null || w < 30 || w > 300) return 'Kilo 30–300 kg arasında olmalı';
        if (_ageController.text.isEmpty) return 'Yaş zorunludur';
        if (a == null || a < 10 || a > 100) return 'Yaş 10–100 arasında olmalı';
        // Hedef kilo opsiyonel ama girilmişse validate et
        if (_targetWeightController.text.isNotEmpty) {
          final tw = double.tryParse(_targetWeightController.text);
          if (tw == null || tw < 30 || tw > 300) return 'Hedef kilo 30–300 kg arasında olmalı';
        }
        return null;
      default:
        return null;
    }
  }

  Future<void> _complete(Color accent, Color bgCard, Color border, Color text) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final targetWeight = _targetWeightController.text.isNotEmpty
          ? double.tryParse(_targetWeightController.text)
          : null;

      // Onboarding
      try {
        await ApiClient.instance.get(Endpoints.onboarding);
        await ApiClient.instance.put(Endpoints.onboarding, data: {
          'goals': _selectedGoals,
          'diet_preference': _diet,
          'target_weight_kg': targetWeight,
          'daily_calorie_habit': _calorieHabit,
        });
      } catch (_) {
        await ApiClient.instance.post(Endpoints.onboarding, data: {
          'goals': _selectedGoals,
          'diet_preference': _diet,
        });
        await ApiClient.instance.put(Endpoints.onboarding, data: {
          'target_weight_kg': targetWeight,
          'daily_calorie_habit': _calorieHabit,
        });
      }

      // Preferences
      final aiName = _aiNameController.text.trim().isEmpty ? 'TrackForge AI' : _aiNameController.text.trim();
      try {
        await ApiClient.instance.get(Endpoints.preferences);
        await ApiClient.instance.put(Endpoints.preferences, data: {
          'height_cm':      double.tryParse(_heightController.text) ?? 0,
          'age':            int.tryParse(_ageController.text) ?? 0,
          'gender':         _gender,
          'activity_level': _activity,
          'ai_name':        aiName,
          if (targetWeight != null) 'target_weight_kg': targetWeight,
          'daily_calorie_habit': _calorieHabit,
        });
      } catch (_) {
        await ApiClient.instance.post(Endpoints.preferences, data: {
          'height_cm':      double.tryParse(_heightController.text) ?? 0,
          'age':            int.tryParse(_ageController.text) ?? 0,
          'gender':         _gender,
          'activity_level': _activity,
          'ai_name':        aiName,
        });
      }

      // Complete
      // İlk kilo ölçümünü kaydet
      final weightVal = double.tryParse(_weightController.text);
      if (weightVal != null) {
        try {
          await ApiClient.instance.post(Endpoints.measurements, data: {
            'date': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2,'0')}-${DateTime.now().day.toString().padLeft(2,'0')}',
            'weight_kg': weightVal,
          });
        } catch (_) {}
      }

      await ApiClient.instance.post(Endpoints.onboardingComplete, data: {
        'goals':               _selectedGoals,
        'diet_preference':     _diet,
        'target_weight_kg':    targetWeight,
        'daily_calorie_habit': _calorieHabit,
      });

      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _next(Color accent, Color bgCard, Color border, Color text) {
    final err = _validateStep();
    if (err != null) { setState(() => _error = err); return; }
    setState(() => _error = null);
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _complete(accent, bgCard, border, text);
    }
  }

  void _prev() {
    if (_step > 0) setState(() { _step--; _error = null; });
  }

  final _stepTitles = ['Hedeflerin', 'Temel Bilgiler', 'Aktivite', 'Diyet Tercihi', 'Kalori Alışkanlığı', 'AI Koçun'];
  final _stepSubs   = [
    'Ne elde etmek istiyorsun?',
    'Kalori hesaplama için gerekli',
    'TDEE hesaplama için gerekli',
    'AI önerileri buna göre kişiselleşir',
    'Şu an günde ne kadar yiyorsun?',
    'Koçun sana nasıl hitap etsin?',
  ];
  final _stepEmojis = ['🎯', '📏', '⚡', '🥗', '🍽️', '🤖'];

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bg        = isDark ? _ON.bg        : _ON.lBg;
    final bgCard    = isDark ? _ON.bgCard    : _ON.lBgCard;
    final bgSoft    = isDark ? _ON.bgSoft    : _ON.lBgSoft;
    final border    = isDark ? _ON.border    : _ON.lBorder;
    final text      = isDark ? _ON.text      : _ON.lText;
    final textSoft  = isDark ? _ON.textSoft  : _ON.lTextSoft;
    final muted     = isDark ? _ON.textMuted : _ON.lTextMuted;
    final accent    = isDark ? _ON.accent    : _ON.lAccent;
    final accentDim = isDark ? _ON.accentDim : _ON.lAccentDim;
    final positive  = isDark ? _ON.positive  : const Color(0xFF059669);
    final danger    = isDark ? _ON.danger    : const Color(0xFFDC2626);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── HEADER ────────────────────────────────
          Container(
            color: bg,
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_step > 0)
                      GestureDetector(
                        onTap: _prev,
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                          child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: textSoft),
                        ),
                      )
                    else
                      const SizedBox(width: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
                        Text('Kurulum', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5)),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(99), border: Border.all(color: accent.withOpacity(0.4))),
                      child: Text('${_step + 1} / $_totalSteps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 4,
                  decoration: BoxDecoration(color: bgSoft, borderRadius: BorderRadius.circular(99)),
                  child: FractionallySizedBox(
                    widthFactor: (_step + 1) / _totalSteps,
                    alignment: Alignment.centerLeft,
                    child: Container(decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(99))),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1a1400), const Color(0xFF2a1f00)]
                          : [accent, accent.withOpacity(0.8)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: accent.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(_stepEmojis[_step], style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_stepTitles[_step], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                            color: isDark ? accent : Colors.white)),
                        Text(_stepSubs[_step], style: TextStyle(fontSize: 12,
                            color: isDark ? accent.withOpacity(0.7) : Colors.white.withOpacity(0.85))),
                      ])),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _buildStep(bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim, positive, isDark),
            ),
          ),

          if (_error != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: danger.withOpacity(0.3))),
              child: Row(children: [
                Icon(Icons.error_outline, color: danger, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: TextStyle(color: danger, fontSize: 13))),
              ]),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _next(accent, bgCard, border, text),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(_step == _totalSteps - 1 ? 'Başlayalım 🚀' : 'İleri →',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim, Color positive, bool isDark) {
    switch (_step) {
      case 0: return _buildGoals(bgCard, bgSoft, border, text, accent, accentDim, positive);
      case 1: return _buildBasicInfo(bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim);
      case 2: return _buildActivity(bgCard, border, text, textSoft, muted, accent, accentDim, positive);
      case 3: return _buildDiet(bgCard, border, text, muted, accent, accentDim, positive);
      case 4: return _buildCalorieHabit(bgCard, border, text, muted, accent, accentDim); // ← YENİ
      case 5: return _buildAiName(bgCard, bgSoft, border, text, textSoft, muted, accent, accentDim, isDark);
      default: return const SizedBox();
    }
  }

  // ── STEP 0: HEDEFLER ────────────────────────────────────
  Widget _buildGoals(Color bgCard, Color bgSoft, Color border, Color text, Color accent, Color accentDim, Color positive) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2,
      ),
      itemCount: _goals.length,
      itemBuilder: (_, i) {
        final g   = _goals[i];
        final sel = _selectedGoals.contains(g['key']);
        return GestureDetector(
          onTap: () => setState(() {
            if (sel) _selectedGoals.remove(g['key']);
            else if (_selectedGoals.length < 3) _selectedGoals.add(g['key']!);
          }),
          child: Container(
            decoration: BoxDecoration(
              color: sel ? accentDim : bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sel ? accent : border, width: sel ? 1.5 : 1),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(g['emoji']!, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Flexible(child: Text(g['label']!, style: TextStyle(
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12, color: sel ? accent : text))),
              if (sel) ...[const SizedBox(width: 4), Icon(Icons.check_circle, color: accent, size: 14)],
            ]),
          ),
        );
      },
    );
  }

  // ── STEP 1: TEMEL BİLGİLER ──────────────────────────────
  Widget _buildBasicInfo(Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim) {
    return Column(
      children: [
        _field(_heightController, 'Boy (cm)', Icons.height, text, '100–250'),
        const SizedBox(height: 10),
        _field(_weightController, 'Mevcut Kilo (kg)', Icons.monitor_weight_outlined, text, '30–300'),
        const SizedBox(height: 10),
        _field(_ageController, 'Yaş', Icons.cake_outlined, text, '10–100', isNumber: true),
        const SizedBox(height: 10),
        // ── YENİ: Hedef kilo ──
        _field(_targetWeightController, 'Hedef Kilo (kg) — opsiyonel', Icons.flag_outlined, text, '30–300'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(Icons.info_outline, color: accent, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Hedef kilonu girersen AI sana ne kadar sürede ulaşabileceğini tahmin eder.',
              style: TextStyle(fontSize: 11, color: text),
            )),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          _genderBtn('male',   '👨 Erkek', bgCard, border, text, accent, accentDim),
          const SizedBox(width: 10),
          _genderBtn('female', '👩 Kadın', bgCard, border, text, accent, accentDim),
        ]),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, Color text, String hint, {bool isNumber = false}) {
    return TextField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: text),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), hintText: hint),
    );
  }

  Widget _genderBtn(String val, String label, Color bgCard, Color border, Color text, Color accent, Color accentDim) {
    final sel = _gender == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: sel ? accentDim : bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sel ? accent : border, width: sel ? 1.5 : 1),
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? accent : text, fontSize: 14)),
        ),
      ),
    );
  }

  // ── STEP 2: AKTİVİTE ────────────────────────────────────
  Widget _buildActivity(Color bgCard, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim, Color positive) {
    return Column(
      children: _activities.map((a) {
        final sel = _activity == a['key'];
        return GestureDetector(
          onTap: () => setState(() => _activity = a['key']!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sel ? accentDim : bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sel ? accent : border, width: sel ? 1.5 : 1),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a['label']!, style: TextStyle(fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? accent : text, fontSize: 14)),
                const SizedBox(height: 2),
                Text(a['desc']!, style: TextStyle(fontSize: 12, color: muted)),
              ])),
              if (sel) Icon(Icons.check_circle_rounded, color: accent, size: 20),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── STEP 3: DİYET ───────────────────────────────────────
  Widget _buildDiet(Color bgCard, Color border, Color text, Color muted, Color accent, Color accentDim, Color positive) {
    return Column(
      children: _diets.map((d) {
        final sel = _diet == d['key'];
        return GestureDetector(
          onTap: () => setState(() => _diet = d['key']!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sel ? accentDim : bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sel ? accent : border, width: sel ? 1.5 : 1),
            ),
            child: Row(children: [
              Text(d['emoji']!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(child: Text(d['label']!, style: TextStyle(
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? accent : text, fontSize: 15))),
              if (sel) Icon(Icons.check_circle_rounded, color: accent, size: 20),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── STEP 4: KALORİ ALIŞKANLIĞI ─────────────────────────
  Widget _buildCalorieHabit(Color bgCard, Color border, Color text, Color muted, Color accent, Color accentDim) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(12), border: Border.all(color: accent.withOpacity(0.3))),
          child: Row(children: [
            Icon(Icons.info_outline, color: accent, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Bunu doğru girmen önemli! Mevcut alışkanlığından başlayarak seni zorlamadan hedefe götüreceğiz.',
              style: TextStyle(fontSize: 12, color: text, height: 1.4),
            )),
          ]),
        ),
        const SizedBox(height: 16),
        ..._calorieHabits.map((h) {
          final sel = _calorieHabit == h['key'];
          return GestureDetector(
            onTap: () => setState(() => _calorieHabit = h['key']!),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: sel ? accentDim : bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel ? accent : border, width: sel ? 1.5 : 1),
              ),
              child: Row(children: [
                              Text(h['emoji']!, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 16),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(h['label']!, style: TextStyle(
                                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? accent : text, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text(h['desc']!, style: TextStyle(fontSize: 11, color: muted)),
                                ],
                              )),
                              if (sel) Icon(Icons.check_circle_rounded, color: accent, size: 20),
                            ]),
            ),
          );
        }),
      ],
    );
  }

  // ── STEP 5: AI KOÇ İSMİ ─────────────────────────────────
  Widget _buildAiName(Color bgCard, Color bgSoft, Color border, Color text, Color textSoft, Color muted, Color accent, Color accentDim, bool isDark) {
    final suggestions = ['TrackForge AI', 'Coach', 'Mentor', 'Atlas', 'Zara', 'Max'];
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const Text('🤖', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _aiNameController.text.trim().isEmpty ? 'TrackForge AI' : _aiNameController.text.trim(),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accent),
            ),
            const SizedBox(height: 4),
            Text('AI Koçunun adı bu olacak', style: TextStyle(fontSize: 12, color: muted)),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('İsim Ver', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
            const SizedBox(height: 12),
            TextField(
              controller: _aiNameController,
              style: TextStyle(color: text),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'AI Koç İsmi',
                prefixIcon: const Icon(Icons.smart_toy_outlined),
                hintText: 'TrackForge AI',
                suffixIcon: _aiNameController.text.isNotEmpty
                    ? IconButton(icon: Icon(Icons.clear, size: 16, color: muted),
                        onPressed: () { _aiNameController.clear(); setState(() {}); })
                    : null,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hazır İsimler', style: TextStyle(fontSize: 13, color: muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8,
              children: suggestions.map((s) {
                final sel = _aiNameController.text == s;
                return GestureDetector(
                  onTap: () { _aiNameController.text = s; setState(() {}); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? accentDim : bgSoft,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: sel ? accent : border),
                    ),
                    child: Text(s, style: TextStyle(fontSize: 13, color: sel ? accent : textSoft, fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                  ),
                );
              }).toList()),
          ]),
        ),
      ],
    );
  }
}