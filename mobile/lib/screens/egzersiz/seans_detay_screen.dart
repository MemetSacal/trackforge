// ── seans_detay_screen.dart ─────────────────────────────
// Antrenman seans detay ekranı.
// GET /exercises/sessions/{id}/exercises → seansın egzersizlerini listeler
// POST /exercises/sessions/{id}/exercises → yeni egzersiz ekler
// DELETE /exercises/exercises/{id} → egzersiz siler

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';

// FutureProvider.family — parametreli provider
// Farklı seans ID'leri için farklı provider instance'ları oluşturur
final sessionExercisesProvider =
FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, sessionId) async {
      try {
        final response = await ApiClient.instance.get(
          '${Endpoints.exerciseSessions}/$sessionId/exercises',
        );
        final list = response.data as List;
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {
        return [];
      }
    });

class SeansDetayScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> session;
  const SeansDetayScreen({super.key, required this.session});

  @override
  ConsumerState<SeansDetayScreen> createState() => _SeansDetayScreenState();
}

class _SeansDetayScreenState extends ConsumerState<SeansDetayScreen> {
  final _nameController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  String get _sessionId => widget.session['id'] as String;

  Future<void> _addExercise() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Egzersiz adını girin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiClient.instance.post(
        '${Endpoints.exerciseSessions}/$_sessionId/exercises',
        data: {
          'exercise_name': _nameController.text.trim(),
          'sets': int.tryParse(_setsController.text),
          'reps': int.tryParse(_repsController.text),
          'weight_kg': double.tryParse(_weightController.text),
        },
      );

      _nameController.clear();
      _setsController.clear();
      _repsController.clear();
      _weightController.clear();

      ref.invalidate(sessionExercisesProvider(_sessionId));

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Egzersiz eklenirken hata oluştu')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExercise(String exerciseId) async {
    try {
      await ApiClient.instance.delete('/exercises/exercises/$exerciseId');
      ref.invalidate(sessionExercisesProvider(_sessionId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silme sırasında hata oluştu')),
        );
      }
    }
  }

  void _showAddExerciseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Egzersiz Ekle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Egzersiz Adı *',
                prefixIcon: Icon(Icons.fitness_center),
                hintText: 'Bench Press, Squat...',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Set'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tekrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Kg'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _addExercise,
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(sessionExercisesProvider(_sessionId));
    final duration = widget.session['duration_minutes'] as int? ?? 0;
    final date = widget.session['date'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('$duration dk — $date'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExerciseSheet,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Veri yüklenemedi')),
        data: (exercises) {
          if (exercises.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💪', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz egzersiz eklenmedi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+ butonuna tıkla',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              final name = exercise['exercise_name'] as String? ?? '';
              final sets = exercise['sets'] as int?;
              final reps = exercise['reps'] as int?;
              final weight = (exercise['weight_kg'] as num?)?.toDouble();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                      Theme.of(context).primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    [
                      if (sets != null) '$sets set',
                      if (reps != null) '$reps tekrar',
                      if (weight != null) '$weight kg',
                    ].join(' · '),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    onPressed: () =>
                        _deleteExercise(exercise['id'] as String),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}