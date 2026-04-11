// ── egzersiz_screen.dart ────────────────────────────────
// Egzersiz ana ekranı.
// Antrenman seanslarını listeler, yeni seans oluşturur.
// GET /exercises/sessions → seansları listeler
// POST /exercises/sessions → yeni seans oluşturur
// Her seansa tıklanınca detay ekranına gider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';
import 'seans_detay_screen.dart';

// ── PROVIDER ────────────────────────────────────────────
// Son 30 günün seanslarını çeker
final sessionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(
      Endpoints.exerciseSessions,
      queryParameters: {
        'from': TFDateUtils.toApiDate(
          DateTime.now().subtract(const Duration(days: 30)),
        ),
        'to': TFDateUtils.today(),
      },
    );
    final list = response.data as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) {
    return [];
  }
});

// ── EGZERSİZ SCREEN ─────────────────────────────────────
class EgzersizScreen extends ConsumerStatefulWidget {
  const EgzersizScreen({super.key});

  @override
  ConsumerState<EgzersizScreen> createState() => _EgzersizScreenState();
}

class _EgzersizScreenState extends ConsumerState<EgzersizScreen> {
  // Yeni seans form controller'ları
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _durationController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Yeni seans oluştur
  Future<void> _createSession() async {
    final duration = int.tryParse(_durationController.text);
    if (duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Süreyi girin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.instance.post(
        Endpoints.exerciseSessions,
        data: {
          'date': TFDateUtils.today(),
          'duration_minutes': duration,
          'calories_burned': double.tryParse(_caloriesController.text),
          'notes': _notesController.text.isEmpty ? null : _notesController.text,
        },
      );

      // Yeni oluşturulan seansın ID'sini al
      final newSession = Map<String, dynamic>.from(response.data);

      _durationController.clear();
      _caloriesController.clear();
      _notesController.clear();

      ref.invalidate(sessionsProvider);

      if (mounted) Navigator.pop(context); // Bottom sheet'i kapat

      // Detay ekranına git — egzersizleri ekleyebilsin
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SeansDetayScreen(session: newSession),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seans oluşturulurken hata oluştu')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Yeni seans formu — bottom sheet olarak açılır
  // Bottom sheet — ekranın altından çıkan modal panel
  void _showNewSessionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Klavye açılınca yukarı kayar
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        // viewInsets.bottom — klavye yüksekliği kadar padding ekler
        padding: EdgeInsets.fromLTRB(
          24, 24, 24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yeni Antrenman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Süre (dakika) *',
                prefixIcon: Icon(Icons.timer_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caloriesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Yakılan Kalori (opsiyonel)',
                prefixIcon: Icon(Icons.local_fire_department_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Not (opsiyonel)',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              // Bottom sheet içinde setState için StatefulBuilder
              builder: (context, setStateSheet) {
                return ElevatedButton(
                  onPressed: _isLoading ? null : _createSession,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Antrenmanı Başlat'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Egzersiz')),
      // FAB — sağ altta yüzen buton, yeni seans için
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewSessionSheet,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Veri yüklenemedi')),
        data: (sessions) {
          if (sessions.isEmpty) {
            // Boş durum — henüz seans yok
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏋️', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz antrenman yok',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sağ alttaki + butonuna tıkla',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          // Seansları listele — en yeni üstte
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              // Ters sıra — en yeni üstte
              final session = sessions[sessions.length - 1 - index];
              return _SessionCard(
                session: session,
                onTap: () {
                  // Detay ekranına git
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SeansDetayScreen(session: session),
                    ),
                  ).then((_) {
                    // Detaydan döndüğünde listeyi yenile
                    ref.invalidate(sessionsProvider);
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Seans listesi kartı
class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onTap;
  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final duration = session['duration_minutes'] as int? ?? 0;
    final calories = (session['calories_burned'] as num?)?.toInt();
    final date = session['date'] as String? ?? '';
    final notes = session['notes'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        // ListTile — icon + başlık + alt başlık + sağ widget
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('🏋️', style: TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(
          '$duration dakika',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date),
            if (calories != null) Text('$calories kcal'),
            if (notes != null) Text(notes),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}