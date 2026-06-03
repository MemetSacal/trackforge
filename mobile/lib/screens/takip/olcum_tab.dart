// ── olcum_tab.dart ──────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';

final measurementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ApiClient.instance.get(
      Endpoints.measurements,
      queryParameters: {
        'from': TFDateUtils.toApiDate(DateTime.now().subtract(const Duration(days: 30))),
        'to': TFDateUtils.today(),
      },
    );
    final list = response.data as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) { return []; }
});

// ── RENKLER ─────────────────────────────────────────────
class _OC {
  static const bg       = Color(0xFF0C0D10);
  static const bgCard   = Color(0xFF141620);
  static const bgSoft   = Color(0xFF0F1016);
  static const border   = Color(0x12FFFFFF);
  static const text     = Color(0xFFF0EEF8);
  static const textSoft = Color(0xFF8A88A8);
  static const textMuted= Color(0xFF4A4860);
  static const accent   = Color(0xFFFFB020);
  static const accentDim= Color(0x1FFFB020);
  static const positive = Color(0xFF34D399);
  static const lBg      = Color(0xFFF0F2F6);
  static const lBgCard  = Color(0xFFFFFFFF);
  static const lBgSoft  = Color(0xFFE8EBF2);
  static const lBorder  = Color(0x12000000);
  static const lText    = Color(0xFF111318);
  static const lTextSoft= Color(0xFF5A6078);
  static const lTextMuted=Color(0xFF9AA0B8);
  static const lAccent  = Color(0xFFFF6B2B);
  static const lAccentDim=Color(0x1AFF6B2B);
  static const lPositive= Color(0xFF059669);
}

class OlcumTab extends ConsumerStatefulWidget {
  const OlcumTab({super.key});
  @override
  ConsumerState<OlcumTab> createState() => _OlcumTabState();
}

class _OlcumTabState extends ConsumerState<OlcumTab> {
  final _weightController      = TextEditingController();
  final _bodyFatController     = TextEditingController();
  final _muscleMassController  = TextEditingController();
  final _waistController       = TextEditingController();
  final _chestController       = TextEditingController();
  final _hipController         = TextEditingController();
  final _armController         = TextEditingController();
  final _legController         = TextEditingController();
  bool _isLoading = false;
  bool _showForm  = false;

  @override
  void dispose() {
    _weightController.dispose(); _bodyFatController.dispose();
    _muscleMassController.dispose(); _waistController.dispose();
    _chestController.dispose(); _hipController.dispose();
    _armController.dispose(); _legController.dispose();
    super.dispose();
  }

  String? _validate() {
    final allEmpty = [_weightController, _bodyFatController, _muscleMassController,
      _waistController, _chestController, _hipController, _armController, _legController]
        .every((c) => c.text.isEmpty);
    if (allEmpty) return 'En az bir ölçüm girmelisin';
    final checks = [
      [_weightController,     30.0, 300.0,  'Kilo 30–300 kg'],
      [_bodyFatController,     1.0,  60.0,  'Vücut yağı %1–60'],
      [_muscleMassController, 10.0, 150.0,  'Kas kütlesi 10–150 kg'],
      [_waistController,      30.0, 200.0,  'Bel 30–200 cm'],
      [_chestController,      30.0, 200.0,  'Göğüs 30–200 cm'],
      [_hipController,        30.0, 200.0,  'Kalça 30–200 cm'],
      [_armController,        10.0, 100.0,  'Kol 10–100 cm'],
      [_legController,        10.0, 120.0,  'Bacak 10–120 cm'],
    ];
    for (final c in checks) {
      final ctrl = c[0] as TextEditingController;
      if (ctrl.text.isEmpty) continue;
      final v = double.tryParse(ctrl.text);
      if (v == null || v < (c[1] as double) || v > (c[2] as double)) return c[3] as String;
    }
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))); return; }
    setState(() => _isLoading = true);
    try {
      await ApiClient.instance.post(Endpoints.measurements, data: {
        'date': TFDateUtils.today(),
        'weight_kg':      double.tryParse(_weightController.text),
        'body_fat_pct':   double.tryParse(_bodyFatController.text),
        'muscle_mass_kg': double.tryParse(_muscleMassController.text),
        'waist_cm':       double.tryParse(_waistController.text),
        'chest_cm':       double.tryParse(_chestController.text),
        'hip_cm':         double.tryParse(_hipController.text),
        'arm_cm':         double.tryParse(_armController.text),
        'leg_cm':         double.tryParse(_legController.text),
      });
      setState(() => _showForm = false);
      ref.invalidate(measurementsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ölçüm kaydedildi ✅')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt sırasında hata oluştu')));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? _OC.bg       : _OC.lBg;
    final bgCard  = isDark ? _OC.bgCard   : _OC.lBgCard;
    final bgSoft  = isDark ? _OC.bgSoft   : _OC.lBgSoft;
    final border  = isDark ? _OC.border   : _OC.lBorder;
    final text    = isDark ? _OC.text     : _OC.lText;
    final textSoft= isDark ? _OC.textSoft : _OC.lTextSoft;
    final muted   = isDark ? _OC.textMuted: _OC.lTextMuted;
    final accent  = isDark ? _OC.accent   : _OC.lAccent;
    final accentDim=isDark ? _OC.accentDim: _OC.lAccentDim;
    final positive= isDark ? _OC.positive : _OC.lPositive;

    final measurementsAsync = ref.watch(measurementsProvider);

    return measurementsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: accent)),
      error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
      data: (measurements) {
        final latest = measurements.isNotEmpty ? measurements.last : null;

        // Son ölçümden önceki ile fark hesapla
        final prev = measurements.length > 1 ? measurements[measurements.length - 2] : null;
        double? weightChange;
        if (latest != null && prev != null) {
          final lw = (latest['weight_kg'] as num?)?.toDouble();
          final pw = (prev['weight_kg']   as num?)?.toDouble();
          if (lw != null && pw != null) weightChange = lw - pw;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── ÖZET GRID ─────────────────────────────
              if (latest != null) ...[
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.6,
                  children: [
                    _MetricCard(
                      label: 'Kilo', bgCard: bgCard, border: border, text: text,
                      textSoft: textSoft, accent: accent, positive: positive,
                      value: latest['weight_kg'] != null ? '${latest['weight_kg']} kg' : '--',
                      delta: weightChange != null ? '${weightChange < 0 ? "↓" : "↑"} ${weightChange.abs().toStringAsFixed(1)}' : null,
                      isPositive: weightChange != null && weightChange <= 0,
                    ),
                    _MetricCard(
                      label: 'Yağ Oranı', bgCard: bgCard, border: border, text: text,
                      textSoft: textSoft, accent: accent, positive: positive,
                      value: latest['body_fat_pct'] != null ? '${latest['body_fat_pct']}%' : '--',
                    ),
                    _MetricCard(
                      label: 'Kas Kitlesi', bgCard: bgCard, border: border, text: text,
                      textSoft: textSoft, accent: accent, positive: positive,
                      value: latest['muscle_mass_kg'] != null ? '${latest['muscle_mass_kg']} kg' : '--',
                    ),
                    _MetricCard(
                      label: 'Bel', bgCard: bgCard, border: border, text: text,
                      textSoft: textSoft, accent: accent, positive: positive,
                      value: latest['waist_cm'] != null ? '${latest['waist_cm']} cm' : '--',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── VÜCUT ÖLÇÜLERİ ────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Vücut Ölçüleri', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                          GestureDetector(
                            onTap: () => setState(() => _showForm = !_showForm),
                            child: Text(_showForm ? 'Kapat' : 'Ekle', style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...([
                        ['Göğüs', latest['chest_cm'],  88.0],
                        ['Kalça', latest['hip_cm'],     82.0],
                        ['Kol',   latest['arm_cm'],     55.0],
                        ['Bacak', latest['leg_cm'],     65.0],
                      ].map((row) {
                        final val = (row[1] as num?)?.toDouble();
                        final pct = row[2] as double;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              SizedBox(width: 60, child: Text(row[0] as String, style: TextStyle(fontSize: 12, color: textSoft))),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: pct / 100,
                                    minHeight: 6,
                                    backgroundColor: bgSoft,
                                    color: accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  val != null ? '$val cm' : '--',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      })),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── FORM ──────────────────────────────────
              if (_showForm || latest == null) ...[
                Container(
                  decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Yeni Ölçüm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                      const SizedBox(height: 4),
                      Text('En az bir alan zorunludur', style: TextStyle(fontSize: 11, color: muted)),
                      const SizedBox(height: 16),
                      ...[
                        [_weightController,     'Kilo (kg)',        Icons.monitor_weight_outlined],
                        [_bodyFatController,    'Vücut Yağ %',      Icons.percent],
                        [_muscleMassController, 'Kas Kütlesi (kg)', Icons.fitness_center],
                        [_waistController,      'Bel (cm)',         Icons.straighten],
                        [_chestController,      'Göğüs (cm)',       Icons.straighten],
                        [_hipController,        'Kalça (cm)',       Icons.straighten],
                        [_armController,        'Kol (cm)',         Icons.straighten],
                        [_legController,        'Bacak (cm)',       Icons.straighten],
                      ].map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                          controller: f[0] as TextEditingController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: text),
                          decoration: InputDecoration(
                            labelText: f[1] as String,
                            prefixIcon: Icon(f[2] as IconData, size: 18),
                          ),
                        ),
                      )),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _save,
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Text('Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _showForm = true),
                    icon: Icon(Icons.add, color: accent),
                    label: Text('+ Ölçüm Ekle', style: TextStyle(color: accent)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: accent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final String? delta;
  final bool isPositive;
  final Color bgCard, border, text, textSoft, accent, positive;
  const _MetricCard({
    required this.label, required this.value, required this.bgCard,
    required this.border, required this.text, required this.textSoft,
    required this.accent, required this.positive,
    this.delta, this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: textSoft)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: text)),
          if (delta != null)
            Text(delta!, style: TextStyle(fontSize: 11, color: isPositive ? positive : const Color(0xFFFF5555), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}