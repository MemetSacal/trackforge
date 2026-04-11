// ── onboarding_screen.dart ──────────────────────────────
// 4 adımlı ilk kurulum ekranı.
// Adım 1: Hedefler (max 3 seçim)
// Adım 2: Temel bilgiler (boy, kilo, yaş, cinsiyet)
// Adım 3: Aktivite seviyesi
// Adım 4: Diyet tercihi
// Tamamlanınca onboarding + preferences kaydedilir,
// ardından /home'a yönlendirilir.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/api/endpoints.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;

  // ── ADIM 1: HEDEFLER ────────────────────────────────────
  final List<String> _selectedGoals = [];
  final List<Map<String, String>> _goals = [
    {'key': 'lose_weight', 'label': 'Kilo Vermek', 'emoji': '⚡'},
    {'key': 'maintain_weight', 'label': 'Aynı Kiloda Kalmak', 'emoji': '⚖️'},
    {'key': 'gain_weight', 'label': 'Kilo Almak', 'emoji': '📈'},
    {'key': 'build_muscle', 'label': 'Kas Kazanmak', 'emoji': '💪'},
    {'key': 'change_diet', 'label': 'Diyetimi Değiştir', 'emoji': '🥗'},
    {'key': 'plan_meals', 'label': 'Öğün Planla', 'emoji': '🍽️'},
    {'key': 'manage_stress', 'label': 'Stresi Yönetmek', 'emoji': '🧘'},
    {'key': 'stay_active', 'label': 'Aktif Kal', 'emoji': '🏃'},
  ];

  // ── ADIM 2: TEMEL BİLGİLER ──────────────────────────────
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedGender = 'male';

  // ── ADIM 3: AKTİVİTE SEVİYESİ ───────────────────────────
  String _selectedActivity = 'sedentary';
  final List<Map<String, String>> _activityLevels = [
    {'key': 'sedentary', 'label': 'Sedanter', 'desc': 'Masa başı iş, az hareket'},
    {'key': 'lightly_active', 'label': 'Hafif Aktif', 'desc': 'Haftada 1-3 gün egzersiz'},
    {'key': 'moderately_active', 'label': 'Orta Aktif', 'desc': 'Haftada 3-5 gün egzersiz'},
    {'key': 'active', 'label': 'Aktif', 'desc': 'Haftada 6-7 gün egzersiz'},
    {'key': 'very_active', 'label': 'Çok Aktif', 'desc': 'Günde 2 antrenman'},
  ];

  // ── ADIM 4: DİYET TERCİHİ ───────────────────────────────
  String _selectedDiet = 'normal';
  final List<Map<String, String>> _dietOptions = [
    {'key': 'normal', 'label': 'Normal', 'emoji': '🍖'},
    {'key': 'vegetarian', 'label': 'Vejetaryen', 'emoji': '🥦'},
    {'key': 'vegan', 'label': 'Vegan', 'emoji': '🌱'},
    {'key': 'gluten_free', 'label': 'Glutensiz', 'emoji': '🌾'},
  ];

  // ── STATE ────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // ── TAMAMLA ─────────────────────────────────────────────
  Future<void> _complete() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ── ONBOARDING ──────────────────────────────────────
      // Kayıt var mı kontrol et — varsa PUT, yoksa POST
      try {
        await ApiClient.instance.get(Endpoints.onboarding);
        // 200 → kayıt var, güncelle
        await ApiClient.instance.put(
          Endpoints.onboarding,
          data: {
            'goals': _selectedGoals,
            'diet_preference': _selectedDiet,
          },
        );
      } catch (_) {
        // 404 → kayıt yok, oluştur
        await ApiClient.instance.post(
          Endpoints.onboarding,
          data: {
            'goals': _selectedGoals,
            'diet_preference': _selectedDiet,
          },
        );
      }

      // ── PREFERENCES ─────────────────────────────────────
      // Kayıt var mı kontrol et — varsa PUT, yoksa POST
      try {
        await ApiClient.instance.get(Endpoints.preferences);
        // 200 → kayıt var, güncelle
        await ApiClient.instance.put(
          Endpoints.preferences,
          data: {
            'height_cm': double.tryParse(_heightController.text) ?? 0,
            'age': int.tryParse(_ageController.text) ?? 0,
            'gender': _selectedGender,
            'activity_level': _selectedActivity,
          },
        );
      } catch (_) {
        // 404 → kayıt yok, oluştur
        await ApiClient.instance.post(
          Endpoints.preferences,
          data: {
            'height_cm': double.tryParse(_heightController.text) ?? 0,
            'age': int.tryParse(_ageController.text) ?? 0,
            'gender': _selectedGender,
            'activity_level': _selectedActivity,
          },
        );
      }

      // ── ONBOARDING COMPLETE ──────────────────────────────
      // is_completed = true — bir daha onboarding gösterilmez
      await ApiClient.instance.post(
        Endpoints.onboardingComplete,
        data: {
          'goals': _selectedGoals,
          'diet_preference': _selectedDiet,
        },
      );

      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── İLERİ / GERİ ────────────────────────────────────────
  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _complete();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  // ── UI ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _currentStep > 0
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevStep,
        )
            : null,
        title: Text('Adım ${_currentStep + 1} / 4'),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: Theme.of(context).colorScheme.surface,
            color: Theme.of(context).primaryColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildCurrentStep(),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(_currentStep == 3 ? 'Tamamla 🚀' : 'İleri →'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildGoalsStep();
      case 1:
        return _buildBasicInfoStep();
      case 2:
        return _buildActivityStep();
      case 3:
        return _buildDietStep();
      default:
        return const SizedBox();
    }
  }

  // ── ADIM 1: HEDEFLER ────────────────────────────────────
  Widget _buildGoalsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hedeflerini seç',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('En fazla 3 tane seçebilirsin'),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2,
          ),
          itemCount: _goals.length,
          itemBuilder: (context, index) {
            final goal = _goals[index];
            final isSelected = _selectedGoals.contains(goal['key']);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedGoals.remove(goal['key']);
                  } else if (_selectedGoals.length < 3) {
                    _selectedGoals.add(goal['key']!);
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.15)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(goal['emoji']!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        goal['label']!,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── ADIM 2: TEMEL BİLGİLER ──────────────────────────────
  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Temel Bilgiler',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Kalori hesaplama için gerekli'),
        const SizedBox(height: 24),
        TextField(
          controller: _heightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Boy (cm)',
            prefixIcon: Icon(Icons.height),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Kilo (kg)',
            prefixIcon: Icon(Icons.monitor_weight_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Yaş',
            prefixIcon: Icon(Icons.cake_outlined),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Cinsiyet', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            _genderButton('male', '👨 Erkek'),
            const SizedBox(width: 12),
            _genderButton('female', '👩 Kadın'),
          ],
        ),
      ],
    );
  }

  Widget _genderButton(String value, String label) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.15)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ── ADIM 3: AKTİVİTE SEVİYESİ ───────────────────────────
  Widget _buildActivityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aktivite Seviyesi',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('TDEE hesaplama için gerekli'),
        const SizedBox(height: 24),
        ..._activityLevels.map((activity) {
          final isSelected = _selectedActivity == activity['key'];
          return GestureDetector(
            onTap: () => setState(() => _selectedActivity = activity['key']!),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.15)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).dividerColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['label']!,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        Text(
                          activity['desc']!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle,
                        color: Theme.of(context).primaryColor),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── ADIM 4: DİYET TERCİHİ ───────────────────────────────
  Widget _buildDietStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Diyet Tercihi',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('AI önerileri buna göre kişiselleştirilir'),
        const SizedBox(height: 24),
        ..._dietOptions.map((diet) {
          final isSelected = _selectedDiet == diet['key'];
          return GestureDetector(
            onTap: () => setState(() => _selectedDiet = diet['key']!),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.15)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).dividerColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(diet['emoji']!, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      diet['label']!,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle,
                        color: Theme.of(context).primaryColor),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}