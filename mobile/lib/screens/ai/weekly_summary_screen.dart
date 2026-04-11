// ── weekly_summary_screen.dart ──────────────────────────
// Haftalık AI özet ekranı.
// POST /ai/weekly-summary → Claude API haftalık verileri analiz eder
// Yükleme sırasında animasyonlu loading gösterilir
// Sonuç markdown benzeri formatta gösterilir

import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';

class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  String? _summary;      // AI'dan gelen özet metni
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Ekran açılınca otomatik özet getir
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance.post(
        Endpoints.aiWeeklySummary,
        data: {'reference_date': TFDateUtils.today()},
      );
      setState(() {
        _summary = response.data['summary'] as String?;
      });
    } catch (e) {
      setState(() => _error = 'Özet alınırken hata oluştu. Tekrar dene.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haftalık Özet'),
        actions: [
          // Yenile butonu
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchSummary,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Yüklenirken
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              '🤖 Claude verilerini analiz ediyor...',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu 10-20 saniye sürebilir',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    // Hata durumunda
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchSummary,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    // Özet geldi
    if (_summary != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('📊', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bu Haftanın Analizi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            TFDateUtils.today(),
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

            // AI özet metni
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  // SelectableText — kullanıcı metni seçip kopyalayabilir
                  _summary!,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6, // Satır yüksekliği — okunabilirlik için
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Yeniden oluştur butonu
            OutlinedButton.icon(
              onPressed: _fetchSummary,
              icon: const Icon(Icons.refresh),
              label: const Text('Yeniden Analiz Et'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }
}