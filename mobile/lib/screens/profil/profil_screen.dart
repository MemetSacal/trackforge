// ── profil_screen.dart ──────────────────────────────────
// Kullanıcı profil ekranı.
// GET /auth/me → kullanıcı adı, email
// GET /preferences → sağlık bilgileri
// PUT /preferences → güncelleme
// Çıkış yap → token'ları sil, login'e yönlendir

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/auth/token_manager.dart';

// ── PROVIDER'LAR ────────────────────────────────────────
final profileUserProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiClient.instance.get(Endpoints.me);
  return Map<String, dynamic>.from(response.data);
});

final profilePrefsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.preferences);
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return null;
  }
});

// ── PROFİL SCREEN ───────────────────────────────────────
class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'male';
  String _activityLevel = 'sedentary';
  bool _isEditing = false;
  bool _isSaving = false;

  // Backend'den gelebilecek tüm aktivite değerlerini kapsıyoruz
  final _activityLevels = [
    {'key': 'sedentary', 'label': 'Sedanter'},
    {'key': 'lightly_active', 'label': 'Hafif Aktif'},
    {'key': 'light', 'label': 'Hafif'},
    {'key': 'moderate', 'label': 'Orta Aktif'},
    {'key': 'moderately_active', 'label': 'Orta Aktif'},
    {'key': 'active', 'label': 'Aktif'},
    {'key': 'very_active', 'label': 'Çok Aktif'},
  ];

  // Backend'den gelen aktivite değeri listede var mı kontrol et
  // Yoksa sedentary'e fall back et
  String _safeActivityLevel(String value) {
    final exists = _activityLevels.any((a) => a['key'] == value);
    return exists ? value : 'sedentary';
  }

  @override
  void dispose() {
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      await ApiClient.instance.put(
        Endpoints.preferences,
        data: {
          'height_cm': double.tryParse(_heightController.text),
          'age': int.tryParse(_ageController.text),
          'gender': _gender,
          'activity_level': _activityLevel,
        },
      );
      ref.invalidate(profilePrefsProvider);
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil güncellendi ✅')),
        );
      }
    } catch (e) {
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
            child: const Text('Çıkış Yap',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await TokenManager.clearTokens();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(profileUserProvider);
    final prefsAsync = ref.watch(profilePrefsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text('İptal'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── KULLANICI BİLGİSİ ─────────────────────
            userAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox(),
              data: (user) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Center(
                          child: Text(
                            (user['full_name'] as String? ?? 'U')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['full_name'] as String? ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user['email'] as String? ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── SAĞLIK BİLGİLERİ ──────────────────────
            prefsAsync.when(
              loading: () =>
              const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
              data: (prefs) {
                // Form'u doldur — backend'den gelen değeri safe parse et
                if (prefs != null && !_isEditing) {
                  _heightController.text =
                      (prefs['height_cm'] as num?)?.toString() ?? '';
                  _ageController.text =
                      (prefs['age'] as num?)?.toString() ?? '';
                  _gender = prefs['gender'] as String? ?? 'male';
                  _activityLevel = _safeActivityLevel(
                    prefs['activity_level'] as String? ?? 'sedentary',
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sağlık Bilgileri',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (!_isEditing) ...[
                          _InfoRow(
                            label: 'Boy',
                            value: prefs?['height_cm'] != null
                                ? '${prefs!['height_cm']} cm'
                                : '-',
                          ),
                          _InfoRow(
                            label: 'Yaş',
                            value: prefs?['age']?.toString() ?? '-',
                          ),
                          _InfoRow(
                            label: 'Cinsiyet',
                            value: _gender == 'male' ? 'Erkek' : 'Kadın',
                          ),
                          _InfoRow(
                            label: 'Aktivite',
                            value: _activityLevels.firstWhere(
                                  (a) => a['key'] == _activityLevel,
                              orElse: () => {'label': '-'},
                            )['label']!,
                          ),
                        ] else ...[
                          TextField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Boy (cm)',
                              prefixIcon: Icon(Icons.height),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Yaş',
                              prefixIcon: Icon(Icons.cake_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),

                          const Text('Cinsiyet',
                              style:
                              TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _GenderButton(
                                label: '👨 Erkek',
                                value: 'male',
                                selected: _gender,
                                onTap: (v) =>
                                    setState(() => _gender = v),
                              ),
                              const SizedBox(width: 8),
                              _GenderButton(
                                label: '👩 Kadın',
                                value: 'female',
                                selected: _gender,
                                onTap: (v) =>
                                    setState(() => _gender = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          const Text('Aktivite Seviyesi',
                              style:
                              TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            // Backend değeri listede yoksa sedentary'e fall back
                            value: _safeActivityLevel(_activityLevel),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.directions_run),
                            ),
                            items: _activityLevels
                                .map((a) => DropdownMenuItem(
                              value: a['key'],
                              child: Text(a['label']!),
                            ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _activityLevel = v!),
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton(
                            onPressed:
                            _isSaving ? null : _savePreferences,
                            child: _isSaving
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text('Kaydet'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ── ÇIKIŞ YAP ─────────────────────────────
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Çıkış Yap',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _logout,
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Function(String) onTap;
  const _GenderButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}