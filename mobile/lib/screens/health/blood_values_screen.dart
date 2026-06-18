// ── blood_values_screen.dart (v1.1) — Kan Değerleri ──
// Tahlil sonuçlarını gir, marker bazında zaman serisi trendi gör.
// Veriler context_builder üzerinden AI'a da gider (beslenme önerisi).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';

final bloodMarkersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ApiClient.instance.get(Endpoints.bloodValuesMarkers);
    return (res.data as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) { return []; }
});

final bloodValuesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final res = await ApiClient.instance.get(Endpoints.bloodValues);
    // {"grouped": {marker: [ {id, marker, value, unit, test_date, label} ]}}
    return Map<String, dynamic>.from(res.data['grouped'] ?? {});
  } catch (_) { return {}; }
});

class BloodValuesScreen extends ConsumerStatefulWidget {
  const BloodValuesScreen({super.key});
  @override
  ConsumerState<BloodValuesScreen> createState() => _BloodValuesScreenState();
}

class _BloodValuesScreenState extends ConsumerState<BloodValuesScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark   = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg       = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard   = isDark ? const Color(0xFF141620) : Colors.white;
    final border   = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text     = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final muted    = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent   = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);

    final groupedAsync = ref.watch(bloodValuesProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: text,
        title: const Text('Kan Değerleri'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        foregroundColor: Colors.black,
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Tahlil Ekle'),
      ),
      body: groupedAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: accent)),
        error: (_, __) => Center(child: Text('Yüklenemedi', style: TextStyle(color: muted))),
        data: (grouped) {
          if (grouped.isEmpty) {
            return _emptyState(text, muted, accent);
          }
          final markers = grouped.keys.toList();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            itemCount: markers.length,
            itemBuilder: (_, i) {
              final marker = markers[i];
              final values = (grouped[marker] as List).map((e) => Map<String, dynamic>.from(e)).toList();
              return _markerCard(marker, values, bgCard, border, text, muted, accent);
            },
          );
        },
      ),
    );
  }

  Widget _emptyState(Color text, Color muted, Color accent) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🩸', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('Henüz tahlil kaydın yok',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: text)),
        const SizedBox(height: 8),
        Text('Kan tahlili sonuçlarını ekle; zamanla nasıl değiştiklerini '
             'grafikte gör, koçun da beslenme önerilerini buna göre ayarlasın.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.5, color: muted)),
      ]),
    ),
  );

  Widget _markerCard(String marker, List<Map<String, dynamic>> values,
      Color bgCard, Color border, Color text, Color muted, Color accent) {
    final label = values.isNotEmpty && values.last['label'] != null
        ? values.last['label'].toString() : marker;
    final unit = values.isNotEmpty && values.last['unit'] != null
        ? values.last['unit'].toString() : '';
    final latest = values.isNotEmpty ? values.last['value'] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: text))),
          if (latest != null)
            Text('$latest $unit',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: accent)),
        ]),
        const SizedBox(height: 4),
        Text('${values.length} ölçüm', style: TextStyle(fontSize: 11, color: muted)),
        if (values.length >= 2) ...[
          const SizedBox(height: 12),
          SizedBox(height: 90, child: _miniLine(values, accent, muted)),
        ],
        const SizedBox(height: 4),
        // Kayıt listesi (sil özelliğiyle)
        ...values.reversed.take(3).map((v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Text('${v['test_date']}', style: TextStyle(fontSize: 11, color: muted)),
            const Spacer(),
            Text('${v['value']} $unit', style: TextStyle(fontSize: 12, color: text)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _delete(v['id'].toString()),
              child: Icon(Icons.close, size: 14, color: muted),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _miniLine(List<Map<String, dynamic>> values, Color accent, Color muted) {
    final spots = <FlSpot>[];
    for (var i = 0; i < values.length; i++) {
      final v = (values[i]['value'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), v));
    }
    return LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: accent,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: accent.withOpacity(0.12)),
        ),
      ],
    ));
  }

  Future<void> _delete(String id) async {
    try {
      await ApiClient.instance.delete('${Endpoints.bloodValues}/$id');
      ref.invalidate(bloodValuesProvider);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silinemedi')));
    }
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final markers = await ref.read(bloodMarkersProvider.future);
    if (!context.mounted) return;
    final valueCtrl = TextEditingController();
    String? selectedMarker = markers.isNotEmpty ? markers.first['marker'].toString() : null;
    DateTime selectedDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        Future<void> save() async {
          final val = double.tryParse(valueCtrl.text.replaceAll(',', '.'));
          if (selectedMarker == null || val == null) return;
          try {
            await ApiClient.instance.post(Endpoints.bloodValues, data: {
              'marker': selectedMarker,
              'value': val,
              'test_date': selectedDate.toIso8601String().split('T').first,
            });
            ref.invalidate(bloodValuesProvider);
            if (ctx.mounted) Navigator.pop(ctx);
          } on DioException catch (_) {
            if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Kaydedilemedi, tekrar dene')));
          }
        }

        return Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, top: 4,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Tahlil Ekle 🩸', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: selectedMarker,
              decoration: const InputDecoration(labelText: 'Değer', border: OutlineInputBorder()),
              items: markers.map((m) => DropdownMenuItem(
                value: m['marker'].toString(),
                child: Text('${m['label']} (${m['unit']})'),
              )).toList(),
              onChanged: (v) => setSheet(() => selectedMarker = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Sonuç', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text('Tarih: ${selectedDate.toIso8601String().split('T').first}')),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setSheet(() => selectedDate = picked);
                },
                child: const Text('Değiştir'),
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: save, child: const Text('Kaydet')),
            ),
          ]),
        );
      }),
    );
  }
}
