// ── profil_screen.dart ──────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/auth/token_manager.dart';
import '../../app.dart';
import '../takip/olcum_tab.dart';      // measurementsProvider
import '../steps/steps_screen.dart';   // todayStepsProvider
import '../alisveris/alisveris_screen.dart'; // shoppingListProvider
import '../../core/utils/rate_limiter.dart';

final profileUserProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response = await ApiClient.instance.get(Endpoints.me);
  return Map<String, dynamic>.from(response.data);
});

final profilePrefsProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.preferences);
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return null;
  }
});

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});
  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  int _tab = 0; // 0=Genel, 1=Sağlık, 2=Tercihler
  bool _isEditing = false;
  bool _isSaving = false;

  // ── SADECE BİR KEZ doldurmak için flag ──
  bool _prefsLoaded = false;

  // Genel tab alanları
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _aiNameController = TextEditingController();
  String _gender = 'male';
  String _activityLevel = 'sedentary';

  // Sağlık tab alanları
  final _bloodTypeController = TextEditingController();
  final _allergiesController = TextEditingController(); // virgülle ayrılmış
  final _diseasesController = TextEditingController();  // virgülle ayrılmış

  // Tercihler tab alanları
  final _likedFoodsController = TextEditingController();    // virgülle ayrılmış
  final _dislikedFoodsController = TextEditingController(); // virgülle ayrılmış
  String _workoutLocation = 'gym';
  String _dietPreference = 'balanced';

  final _activities = [
    {'key': 'sedentary', 'label': 'Sedanter'},
    {'key': 'lightly_active', 'label': 'Hafif Aktif'},
    {'key': 'light', 'label': 'Hafif'},
    {'key': 'moderate', 'label': 'Orta Aktif'},
    {'key': 'moderately_active', 'label': 'Orta Aktif'},
    {'key': 'active', 'label': 'Aktif'},
    {'key': 'very_active', 'label': 'Çok Aktif'},
  ];

  final _locations = [
    {'key': 'gym', 'label': 'Spor Salonu'},
    {'key': 'home', 'label': 'Ev'},
    {'key': 'outdoor', 'label': 'Dışarısı'},
  ];

  final _diets = [
    {'key': 'balanced', 'label': 'Dengeli'},
    {'key': 'high_protein', 'label': 'Yüksek Protein'},
    {'key': 'low_carb', 'label': 'Düşük Karbonhidrat'},
    {'key': 'vegan', 'label': 'Vegan'},
    {'key': 'vegetarian', 'label': 'Vejetaryen'},
    {'key': 'keto', 'label': 'Keto'},
  ];

  String _safeActivity(String v) =>
      _activities.any((a) => a['key'] == v) ? v : 'sedentary';

  String _safeLocation(String v) =>
      _locations.any((a) => a['key'] == v) ? v : 'gym';

  String _safeDiet(String v) =>
      _diets.any((a) => a['key'] == v) ? v : 'balanced';

  @override
  void dispose() {
    _heightController.dispose();
    _ageController.dispose();
    _aiNameController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _diseasesController.dispose();
    _likedFoodsController.dispose();
    _dislikedFoodsController.dispose();
    super.dispose();
  }

  // ── Prefs'i SADECE BİR KEZ doldur ──
  // build() içinde değil, data gelince bir kez çağrılır.
  void _fillPrefsOnce(Map<String, dynamic> prefs) {
    if (_prefsLoaded) return; // zaten doldurulduysa atla
    _prefsLoaded = true;

    // Genel
    _heightController.text = (prefs['height_cm'] as num?)?.toString() ?? '';
    _ageController.text = (prefs['age'] as num?)?.toString() ?? '';
    _aiNameController.text = prefs['ai_name'] as String? ?? 'TrackForge AI';
    _gender = prefs['gender'] as String? ?? 'male';
    _activityLevel = _safeActivity(prefs['activity_level'] as String? ?? 'sedentary');

    // Sağlık
    _bloodTypeController.text = prefs['blood_type'] as String? ?? '';
    final allergies = (prefs['allergies'] as List?)?.cast<String>() ?? [];
    _allergiesController.text = allergies.join(', ');
    final diseases = (prefs['diseases'] as List?)?.cast<String>() ?? [];
    _diseasesController.text = diseases.join(', ');

    // Tercihler
    final liked = (prefs['liked_foods'] as List?)?.cast<String>() ?? [];
    _likedFoodsController.text = liked.join(', ');
    final disliked = (prefs['disliked_foods'] as List?)?.cast<String>() ?? [];
    _dislikedFoodsController.text = disliked.join(', ');
    _workoutLocation = _safeLocation(prefs['workout_location'] as String? ?? 'gym');
    _dietPreference = _safeDiet(prefs['diet_preference'] as String? ?? 'balanced');
  }

  // ── Kaydet — hangi tab aktifse ona göre payload ──
  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      Map<String, dynamic> payload = {};

      if (_tab == 0) {
              final h = double.tryParse(_heightController.text);
              final a = int.tryParse(_ageController.text);
              payload = {
                if (h != null) 'height_cm': h,
                if (a != null) 'age': a,
                'gender': _gender,
                'activity_level': _activityLevel,
                if (_aiNameController.text.trim().isNotEmpty) 'ai_name': _aiNameController.text.trim(),
              };
      } else if (_tab == 1) {
        // Sağlık
        payload = {
          if (_bloodTypeController.text.isNotEmpty)
            'blood_type': _bloodTypeController.text.trim(),
          if (_allergiesController.text.isNotEmpty)
            'allergies': _allergiesController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
          if (_diseasesController.text.isNotEmpty)
            'diseases': _diseasesController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
        };
      } else if (_tab == 2) {
        // Tercihler
        payload = {
          'liked_foods': _likedFoodsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          'disliked_foods': _dislikedFoodsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          'workout_location': _workoutLocation,
          'diet_preference': _dietPreference,
           if (_aiNameController.text.isNotEmpty) 'ai_name': _aiNameController.text,
        };
      }

      final resp = await ApiClient.instance.put(Endpoints.preferences, data: payload);
      debugPrint('PROFIL SAVE: $payload');
      debugPrint('PROFIL RESP: ${resp.data}');
      _prefsLoaded = false; // ← setState dışında, invalidate'ten önce
      ref.invalidate(profilePrefsProvider);
      setState(() {
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil güncellendi ✅')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Güncelleme sırasında hata oluştu')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await RateLimiter.clearUserLimits();
          await _clearUserPrefsCache();
          await TokenManager.clearTokens();
          ref.invalidate(measurementsProvider);
          ref.invalidate(todayStepsProvider);
          ref.invalidate(shoppingListProvider);
          ref.invalidate(profileUserProvider);
          ref.invalidate(profilePrefsProvider);
          if (mounted) context.go('/login');
        }
      }
  Future<void> _clearUserPrefsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await TokenManager.getCurrentUserId() ?? 'guest';
    await prefs.remove('last_meal_advice_$userId');
    await prefs.remove('last_meal_advice_date_$userId');
    await prefs.remove('last_recommended_foods_$userId');
    await prefs.remove('last_foods_to_avoid_$userId');
    await prefs.remove('last_weekly_meal_plan_$userId');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard = isDark ? const Color(0xFF141620) : Colors.white;
    final bgSoft = isDark ? const Color(0xFF0F1016) : const Color(0xFFE8EBF2);
    final border = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final textSoft = isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);
    final muted = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim = isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);
    final danger = isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);

    final userAsync = ref.watch(profileUserProvider);
    final prefsAsync = ref.watch(profilePrefsProvider);

    // ── Prefs gelince sadece bir kez doldur ──
    if (prefsAsync.value != null) {
      _fillPrefsOnce(prefsAsync.value!);
    }

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── HEADER ──────────────────────────────────
          Container(
            color: bg,
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border)),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 15, color: textSoft),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TRACKFORGE',
                              style: TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 3,
                                  color: muted,
                                  fontWeight: FontWeight.w600)),
                          Text('Profil',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: text,
                                  letterSpacing: -0.5)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border)),
                        child: Icon(
                            isDark
                                ? Icons.wb_sunny_outlined
                                : Icons.nightlight_round,
                            size: 15,
                            color: textSoft),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _isEditing = !_isEditing),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isEditing ? accentDim : bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _isEditing ? accent : border),
                        ),
                        child: Icon(
                            _isEditing
                                ? Icons.close
                                : Icons.edit_outlined,
                            size: 15,
                            color: _isEditing ? accent : textSoft),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Profil kartı
                userAsync.when(
                  loading: () => const SizedBox(height: 80),
                  error: (_, __) => const SizedBox(),
                  data: (user) {
                    final name = user['full_name'] as String? ?? '';
                    final email = user['email'] as String? ?? '';
                    final initials = name.length >= 2
                        ? name.substring(0, 2).toUpperCase()
                        : name.isNotEmpty
                            ? name[0].toUpperCase()
                            : 'U';
                    return Container(
                      decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: border)),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: accentDim,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: accent, width: 2),
                            ),
                            child: Center(
                              child: Text(initials,
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: accent)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: text)),
                                const SizedBox(height: 2),
                                Text(email,
                                    style: TextStyle(
                                        fontSize: 12, color: accent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Tab bar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: bgSoft,
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      _TabBtn(
                          label: 'Genel',
                          active: _tab == 0,
                          accent: accent,
                          bgCard: bgCard,
                          muted: muted,
                          textSoft: textSoft,
                          onTap: () => setState(() {
                                _tab = 0;
                                _isEditing = false;
                              })),
                      _TabBtn(
                          label: 'Sağlık',
                          active: _tab == 1,
                          accent: accent,
                          bgCard: bgCard,
                          muted: muted,
                          textSoft: textSoft,
                          onTap: () => setState(() {
                                _tab = 1;
                                _isEditing = false;
                              })),
                      _TabBtn(
                          label: 'Tercihler',
                          active: _tab == 2,
                          accent: accent,
                          bgCard: bgCard,
                          muted: muted,
                          textSoft: textSoft,
                          onTap: () => setState(() {
                                _tab = 2;
                                _isEditing = false;
                              })),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          // ── İÇERİK ──────────────────────────────────
          Expanded(
            child: prefsAsync.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: accent)),
              error: (_, __) => Center(
                  child: Text('Veri yüklenemedi',
                      style: TextStyle(color: text))),
              data: (prefs) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    children: [
                      if (_tab == 0)
                        _buildGenel(prefs, bgCard, bgSoft, border, text,
                            textSoft, muted, accent, accentDim, danger, isDark),
                      if (_tab == 1)
                        _buildSaglik(prefs, bgCard, bgSoft, border, text,
                            textSoft, muted, accent, accentDim),
                      if (_tab == 2)
                        _buildTercihler(prefs, bgCard, bgSoft, border, text,
                            textSoft, muted, accent, accentDim, danger),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── GENEL TAB ───────────────────────────────────────
  Widget _buildGenel(
      Map? prefs,
      Color bgCard,
      Color bgSoft,
      Color border,
      Color text,
      Color textSoft,
      Color muted,
      Color accent,
      Color accentDim,
      Color danger,
      bool isDark) {
    final rows = [
      ['Boy', prefs?['height_cm'] != null ? '${prefs!['height_cm']} cm' : '-'],
      ['Yaş', prefs?['age']?.toString() ?? '-'],
      ['Cinsiyet', _gender == 'male' ? 'Erkek' : 'Kadın'],
      ['Hedef', prefs?['fitness_goal'] as String? ?? '-'],
      [
        'Aktivite',
        _activities
            .firstWhere((a) => a['key'] == _activityLevel,
                orElse: () => {'label': '-'})['label']!
      ],
    ];

    if (!_isEditing) {
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Temel Bilgiler',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: text)),
                const SizedBox(height: 14),
                ...rows.map((r) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: border))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r[0],
                              style: TextStyle(
                                  fontSize: 13, color: textSoft)),
                          Text(r[1],
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: text)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(
                    isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: accent,
                    size: 20),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(isDark ? 'Karanlık Mod' : 'Aydınlık Mod',
                        style: TextStyle(fontSize: 14, color: text))),
                Switch(
                  value: isDark,
                  activeColor: accent,
                  onChanged: (_) =>
                      ref.read(themeModeProvider.notifier).toggle(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _logout,
            child: Container(
              decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border)),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.logout, color: danger, size: 20),
                  const SizedBox(width: 12),
                  Text('Çıkış Yap',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: danger)),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: danger, size: 18),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Edit formu
    return Container(
      decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Düzenle',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: text)),
          const SizedBox(height: 14),
          _field(_heightController, 'Boy (cm)', Icons.height, text),
          const SizedBox(height: 10),
          _field(_ageController, 'Yaş', Icons.cake_outlined, text,
              isInt: true),
          const SizedBox(height: 10),
          _field(_aiNameController, 'AI Koç İsmi',
              Icons.smart_toy_outlined, text,
              hint: 'TrackForge AI', isText: true),
          const SizedBox(height: 14),
          Text('Cinsiyet',
              style: TextStyle(
                  fontSize: 13,
                  color: textSoft,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _genderBtn('male', '👨 Erkek', bgCard, bgSoft, border, text,
                  accent, accentDim),
              const SizedBox(width: 8),
              _genderBtn('female', '👩 Kadın', bgCard, bgSoft, border, text,
                  accent, accentDim),
            ],
          ),
          const SizedBox(height: 12),
          Text('Aktivite Seviyesi',
              style: TextStyle(
                  fontSize: 13,
                  color: textSoft,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _safeActivity(_activityLevel),
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.directions_run)),
            dropdownColor: bgCard,
            style: TextStyle(color: text, fontSize: 14),
            items: _activities
                .map((a) => DropdownMenuItem(
                    value: a['key'], child: Text(a['label']!)))
                .toList(),
            onChanged: (v) => setState(() => _activityLevel = v!),
          ),
          const SizedBox(height: 16),
          _saveButton(),
        ],
      ),
    );
  }

  // ── SAĞLIK TAB ──────────────────────────────────────
  Widget _buildSaglik(
      Map? prefs,
      Color bgCard,
      Color bgSoft,
      Color border,
      Color text,
      Color textSoft,
      Color muted,
      Color accent,
      Color accentDim) {
    // BMR/TDEE hesaplama
    String bmrText = '-';
    String tdeeText = '-';
    if (prefs != null) {
      final h = (prefs['height_cm'] as num?)?.toDouble();
      final a = (prefs['age'] as num?)?.toDouble();
      final g = prefs['gender'] as String? ?? 'male';
      final w = (prefs['weight_kg'] as num?)?.toDouble();
      if (h != null && a != null && w != null) {
        final bmr = g == 'male'
            ? 10 * w + 6.25 * h - 5 * a + 5
            : 10 * w + 6.25 * h - 5 * a - 161;
        final multipliers = {
          'sedentary': 1.2,
          'lightly_active': 1.375,
          'light': 1.375,
          'moderate': 1.55,
          'moderately_active': 1.55,
          'active': 1.725,
          'very_active': 1.9,
        };
        final m =
            multipliers[prefs['activity_level'] as String? ?? 'sedentary'] ??
                1.55;
        bmrText = '${bmr.toInt()} kcal';
        tdeeText = '${(bmr * m).toInt()} kcal';
      }
    }

    if (!_isEditing) {
      final rows = [
        ['Kan Grubu', prefs?['blood_type'] as String? ?? '-'],
        [
          'Alerjiler',
          (prefs?['allergies'] as List?)?.join(', ') ?? '-'
        ],
        [
          'Hastalıklar',
          (prefs?['diseases'] as List?)?.join(', ') ?? '-'
        ],
        ['BMR', bmrText],
        ['TDEE', tdeeText],
      ];

      return Container(
        decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border)),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sağlık Bilgileri',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: text)),
            const SizedBox(height: 14),
            ...rows.map((r) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: border))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r[0],
                          style:
                              TextStyle(fontSize: 13, color: textSoft)),
                      Flexible(
                        child: Text(r[1],
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: text)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
    }

    // Edit formu
    return Container(
      decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sağlık Bilgilerini Düzenle',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: text)),
          const SizedBox(height: 14),
          _field(_bloodTypeController, 'Kan Grubu (A+, B-, 0+ vb.)',
              Icons.bloodtype_outlined, text),
          const SizedBox(height: 10),
          _fieldMultiline(
            _allergiesController,
            'Alerjiler',
            Icons.warning_amber_outlined,
            text,
            hint: 'Virgülle ayırın: gluten, laktoz',
          ),
          const SizedBox(height: 10),
          _fieldMultiline(
            _diseasesController,
            'Hastalıklar',
            Icons.medical_services_outlined,
            text,
            hint: 'Virgülle ayırın: diyabet, hipertansiyon',
          ),
          const SizedBox(height: 16),
          _saveButton(),
        ],
      ),
    );
  }

  // ── TERCİHLER TAB ───────────────────────────────────
  Widget _buildTercihler(
      Map? prefs,
      Color bgCard,
      Color bgSoft,
      Color border,
      Color text,
      Color textSoft,
      Color muted,
      Color accent,
      Color accentDim,
      Color danger) {
    final liked =
        (prefs?['liked_foods'] as List?)?.cast<String>() ?? [];
    final disliked =
        (prefs?['disliked_foods'] as List?)?.cast<String>() ?? [];
    final aiName =
        prefs?['ai_name'] as String? ?? 'TrackForge AI';
    final location =
        prefs?['workout_location'] as String? ?? '-';
    final diet = prefs?['diet_preference'] as String? ?? '-';

    if (!_isEditing) {
      return Column(
        children: [
          // Yemek tercihleri
          Container(
            decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Yemek Tercihleri',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: text)),
                const SizedBox(height: 14),
                Text('Sevdiğim',
                    style: TextStyle(
                        fontSize: 12,
                        color: muted,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                liked.isEmpty
                    ? Text('Belirtilmemiş',
                        style: TextStyle(fontSize: 12, color: muted))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: liked
                            .map((f) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                      color: accentDim,
                                      borderRadius:
                                          BorderRadius.circular(99),
                                      border:
                                          Border.all(color: accent)),
                                  child: Text(f,
                                      style: TextStyle(
                                          fontSize: 12, color: accent)),
                                ))
                            .toList(),
                      ),
                const SizedBox(height: 14),
                Text('Sevmediğim',
                    style: TextStyle(
                        fontSize: 12,
                        color: muted,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                disliked.isEmpty
                    ? Text('Yok',
                        style: TextStyle(fontSize: 12, color: muted))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: disliked
                            .map((f) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                      color:
                                          danger.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(99),
                                      border:
                                          Border.all(color: danger)),
                                  child: Text(f,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: danger)),
                                ))
                            .toList(),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Antrenman + AI
          Container(
            decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Antrenman & AI',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: text)),
                const SizedBox(height: 14),
                ...[
                  ['Lokasyon', location],
                  ['Diyet Tipi', diet],
                  ['AI Koç İsmi', aiName],
                ].map((r) => Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: border))),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r[0],
                              style: TextStyle(
                                  fontSize: 13, color: textSoft)),
                          Text(r[1],
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: text)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      );
    }

    // Edit formu
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border)),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tercihleri Düzenle',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: text)),
              const SizedBox(height: 14),
              _fieldMultiline(
                _likedFoodsController,
                'Sevdiğim Yiyecekler',
                Icons.favorite_outline,
                text,
                hint: 'Virgülle ayırın: tavuk, yulaf, meyve',
              ),
              const SizedBox(height: 10),
              _fieldMultiline(
                _dislikedFoodsController,
                'Sevmediğim Yiyecekler',
                Icons.thumb_down_outlined,
                text,
                hint: 'Virgülle ayırın: brokoli, ıspanak',
              ),
              const SizedBox(height: 10),
              _field(
                _aiNameController,
                'AI Koç İsmi',
                Icons.smart_toy_outlined,
                text,
                hint: 'TrackForge AI', isText: true,
              ),
              const SizedBox(height: 14),
              Text('Antrenman Lokasyonu',
                  style: TextStyle(
                      fontSize: 13,
                      color: textSoft,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _safeLocation(_workoutLocation),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined)),
                dropdownColor: bgCard,
                style: TextStyle(color: text, fontSize: 14),
                items: _locations
                    .map((a) => DropdownMenuItem(
                        value: a['key'], child: Text(a['label']!)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _workoutLocation = v!),
              ),
              const SizedBox(height: 12),
              Text('Diyet Tercihi',
                  style: TextStyle(
                      fontSize: 13,
                      color: textSoft,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _safeDiet(_dietPreference),
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.restaurant_outlined)),
                dropdownColor: bgCard,
                style: TextStyle(color: text, fontSize: 14),
                items: _diets
                    .map((a) => DropdownMenuItem(
                        value: a['key'], child: Text(a['label']!)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _dietPreference = v!),
              ),
              const SizedBox(height: 16),
              _saveButton(),
            ],
          ),
        ),
      ],
    );
  }

  // ── YARDIMCI WİDGET'LAR ─────────────────────────────

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black))
            : const Text('Kaydet'),
      ),
    );
  }

  Widget _field(
      TextEditingController c, String label, IconData icon, Color text,
      {bool isInt = false, bool isText = false, String? hint}) {
    return TextField(
      controller: c,
      keyboardType: isText
          ? TextInputType.text                              // ← metin
          : isInt
              ? TextInputType.number                        // ← tam sayı
              : const TextInputType.numberWithOptions(decimal: true), // ← ondalık
      style: TextStyle(color: text),
      decoration: InputDecoration(
          labelText: label, prefixIcon: Icon(icon), hintText: hint),
    );
  }

  // Metin girişi (alerjiler, yiyecekler vb.)
  Widget _fieldMultiline(
      TextEditingController c, String label, IconData icon, Color text,
      {String? hint}) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.text,
      style: TextStyle(color: text),
      decoration: InputDecoration(
          labelText: label, prefixIcon: Icon(icon), hintText: hint),
    );
  }

  Widget _genderBtn(String val, String label, Color bgCard, Color bgSoft,
      Color border, Color text, Color accent, Color accentDim) {
    final sel = _gender == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sel ? accentDim : bgSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: sel ? accent : border, width: sel ? 1.5 : 1),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight:
                      sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? accent : text,
                  fontSize: 14)),
        ),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color accent, bgCard, muted, textSoft;
  final VoidCallback onTap;

  const _TabBtn(
      {required this.label,
      required this.active,
      required this.accent,
      required this.bgCard,
      required this.muted,
      required this.textSoft,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? bgCard : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4)
                  ]
                : null,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? accent : textSoft)),
        ),
      ),
    );
  }
}