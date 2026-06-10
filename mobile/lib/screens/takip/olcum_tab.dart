// ── olcum_tab.dart ──────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/date_utils.dart';

final measurementsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
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

// ── Profil gender'ı oku ──────────────────────────────────
final profileGenderProvider = FutureProvider.autoDispose<String>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.preferences);
    return response.data['gender'] as String? ?? 'male';
  } catch (_) { return 'male'; }
});

// Boy profilden otomatik al — Navy Method için
final profileHeightProvider = FutureProvider.autoDispose<double?>((ref) async {
  try {
    final response = await ApiClient.instance.get(Endpoints.preferences);
    return (response.data['height_cm'] as num?)?.toDouble();
  } catch (_) { return null; }
});

class _OC {
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
  static const lBg       = Color(0xFFF0F2F6);
  static const lBgCard   = Color(0xFFFFFFFF);
  static const lBgSoft   = Color(0xFFE8EBF2);
  static const lBorder   = Color(0x12000000);
  static const lText     = Color(0xFF111318);
  static const lTextSoft = Color(0xFF5A6078);
  static const lTextMuted= Color(0xFF9AA0B8);
  static const lAccent   = Color(0xFFFF6B2B);
  static const lAccentDim= Color(0x1AFF6B2B);
  static const lPositive = Color(0xFF059669);
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

  // ── Navy Method yağ oranı hesaplama ──────────────────
  double? _navyBodyFat({
    required bool isMale,
    required double waistCm,
    required double neckCm,
    required double heightCm,
    double? hipCm,
  }) {
    if (waistCm <= neckCm) return null;
    if (!isMale && (hipCm == null || waistCm + hipCm <= neckCm)) return null;

    double val;
    if (isMale) {
      val = 1.0324
          - 0.19077 * (math.log(waistCm - neckCm) / math.log(10))
          + 0.15456 * (math.log(heightCm) / math.log(10));
    } else {
      val = 1.29579
          - 0.35004 * (math.log(waistCm + hipCm! - neckCm) / math.log(10))
          + 0.22100 * (math.log(heightCm) / math.log(10));
    }
    if (val <= 0) return null;
    final result = (495 / val) - 450;
    return result.clamp(1.0, 60.0);
  }

  // ── Navy Method bottom sheet — cinsiyet profilden geliyor ──
  void _showNavySheet(
    BuildContext context,
    String profileGender,
    double? profileHeight,
    Color bgCard, Color border, Color text, Color muted,
    Color accent, Color accentDim, Color danger,
  ) {
    final neckCtrl   = TextEditingController();
    final waistCtrl  = TextEditingController();
    final hipCtrl    = TextEditingController();
    // Boy varsa profilden otomatik doldur
    final heightCtrl = TextEditingController(
      text: profileHeight != null ? profileHeight.toStringAsFixed(0) : '',
    );
    String? result;
    String? error;
    final isMale = profileGender == 'male';
    // heightCtrl profil boy değeriyle doldurulsun

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(99)))),
                const SizedBox(height: 16),
                Text('Yağ Oranı Hesapla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: text)),
                const SizedBox(height: 4),
                Text('Navy Method — Boy + çevre ölçümleriyle tahmin', style: TextStyle(fontSize: 12, color: muted)),
                const SizedBox(height: 4),
                // Cinsiyet bilgisi — profilden otomatik
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(10), border: Border.all(color: accent.withOpacity(0.3))),
                  child: Row(children: [
                    Icon(Icons.person_outline, color: accent, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'Cinsiyet: ${isMale ? "Erkek" : "Kadın"} (profilden alındı)',
                      style: TextStyle(fontSize: 12, color: accent),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                _navyField(heightCtrl, 'Boy (cm)', text, muted),
                const SizedBox(height: 10),
                _navyField(neckCtrl, 'Boyun çevresi (cm)', text, muted),
                const SizedBox(height: 10),
                _navyField(waistCtrl, 'Bel çevresi (cm) — göbek hizası', text, muted),
                if (!isMale) ...[
                  const SizedBox(height: 10),
                  _navyField(hipCtrl, 'Kalça çevresi (cm)', text, muted),
                ],
                const SizedBox(height: 16),

                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(error!, style: TextStyle(color: danger, fontSize: 13)),
                  ),

                if (result != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(14), border: Border.all(color: accent)),
                    child: Column(children: [
                      Text('Tahmini Yağ Oranı', style: TextStyle(fontSize: 12, color: muted)),
                      const SizedBox(height: 4),
                      Text(result!, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: accent)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _bodyFatController.text = result!.replaceAll('%', '').trim();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Bu değeri kullan'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final h  = double.tryParse(heightCtrl.text);
                      final n  = double.tryParse(neckCtrl.text);
                      final w  = double.tryParse(waistCtrl.text);
                      final hi = double.tryParse(hipCtrl.text);
                      if (h == null || n == null || w == null) {
                        setModal(() => error = 'Boy, boyun ve bel zorunludur');
                        return;
                      }
                      if (!isMale && hi == null) {
                        setModal(() => error = 'Kadın için kalça ölçüsü zorunludur');
                        return;
                      }
                      final bf = _navyBodyFat(isMale: isMale, waistCm: w, neckCm: n, heightCm: h, hipCm: hi);
                      if (bf == null) {
                        setModal(() => error = 'Geçersiz ölçüm değerleri');
                        return;
                      }
                      setModal(() { result = '%${bf.toStringAsFixed(1)}'; error = null; });
                    },
                    child: Text(result == null ? 'Hesapla' : 'Tekrar Hesapla'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navyField(TextEditingController c, String label, Color text, Color muted) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: text),
      decoration: InputDecoration(labelText: label, hintStyle: TextStyle(color: muted)),
    );
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

  Future<void> _save({Map<String, dynamic>? existing}) async {
    final err = _validate();
    if (err != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))); return; }
    setState(() => _isLoading = true);
    try {
      final rawData = {
        'weight_kg':      double.tryParse(_weightController.text),
        'body_fat_pct':   double.tryParse(_bodyFatController.text),
        'muscle_mass_kg': double.tryParse(_muscleMassController.text),
        'waist_cm':       double.tryParse(_waistController.text),
        'chest_cm':       double.tryParse(_chestController.text),
        'hip_cm':         double.tryParse(_hipController.text),
        'arm_cm':         double.tryParse(_armController.text),
        'leg_cm':         double.tryParse(_legController.text),
      };
      final data = Map.fromEntries(rawData.entries.where((e) => e.value != null));
      if (existing != null) {
        await ApiClient.instance.put('${Endpoints.measurements}/${existing['id']}', data: data);
      } else {
        await ApiClient.instance.post(Endpoints.measurements, data: {'date': TFDateUtils.today(), ...data});
      }
      setState(() => _showForm = false);
      ref.invalidate(measurementsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(existing != null ? 'Ölçüm güncellendi ✅' : 'Ölçüm kaydedildi ✅')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt sırasında hata oluştu')));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bgCard   = isDark ? _OC.bgCard    : _OC.lBgCard;
    final bgSoft   = isDark ? _OC.bgSoft    : _OC.lBgSoft;
    final border   = isDark ? _OC.border    : _OC.lBorder;
    final text     = isDark ? _OC.text      : _OC.lText;
    final textSoft = isDark ? _OC.textSoft  : _OC.lTextSoft;
    final muted    = isDark ? _OC.textMuted : _OC.lTextMuted;
    final accent   = isDark ? _OC.accent    : _OC.lAccent;
    final accentDim= isDark ? _OC.accentDim : _OC.lAccentDim;
    final positive = isDark ? _OC.positive  : _OC.lPositive;
    final danger   = isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);

    final measurementsAsync = ref.watch(measurementsProvider);
    // Profil gender'ı — loading/error durumunda 'male' fallback
    final profileGender = ref.watch(profileGenderProvider).value ?? 'male';
    final profileHeight = ref.watch(profileHeightProvider).value;

    return measurementsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: accent)),
      error:   (_, __) => Center(child: Text('Veri yüklenemedi', style: TextStyle(color: text))),
      data: (measurements) {
        final latest = measurements.isNotEmpty ? measurements.last : null;
        final prev   = measurements.length > 1 ? measurements[measurements.length - 2] : null;
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

              if (latest != null) ...[
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.6,
                  children: [
                    _MetricCard(label: 'Kilo', bgCard: bgCard, border: border, text: text, textSoft: textSoft, accent: accent, positive: positive,
                      value: latest['weight_kg'] != null ? '${latest['weight_kg']} kg' : '--',
                      delta: weightChange != null ? '${weightChange < 0 ? "↓" : "↑"} ${weightChange.abs().toStringAsFixed(1)}' : null,
                      isPositive: weightChange != null && weightChange <= 0),
                    _MetricCard(label: 'Yağ Oranı', bgCard: bgCard, border: border, text: text, textSoft: textSoft, accent: accent, positive: positive,
                      value: latest['body_fat_pct'] != null ? '${latest['body_fat_pct']}%' : '--'),
                    _MetricCard(label: 'Kas Kütlesi', bgCard: bgCard, border: border, text: text, textSoft: textSoft, accent: accent, positive: positive,
                      value: latest['muscle_mass_kg'] != null ? '${latest['muscle_mass_kg']} kg' : '--'),
                    _MetricCard(label: 'Bel', bgCard: bgCard, border: border, text: text, textSoft: textSoft, accent: accent, positive: positive,
                      value: latest['waist_cm'] != null ? '${latest['waist_cm']} cm' : '--'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Vücut Ölçüleri', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                        GestureDetector(
                          onTap: () {
                            if (!_showForm && latest != null) {
                              _weightController.text     = latest['weight_kg']?.toString() ?? '';
                              _bodyFatController.text    = latest['body_fat_pct']?.toString() ?? '';
                              _muscleMassController.text = latest['muscle_mass_kg']?.toString() ?? '';
                              _waistController.text      = latest['waist_cm']?.toString() ?? '';
                              _chestController.text      = latest['chest_cm']?.toString() ?? '';
                              _hipController.text        = latest['hip_cm']?.toString() ?? '';
                              _armController.text        = latest['arm_cm']?.toString() ?? '';
                              _legController.text        = latest['leg_cm']?.toString() ?? '';
                            }
                            setState(() => _showForm = !_showForm);
                          },
                          child: Text(_showForm ? 'Kapat' : 'Ekle', style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      ...([
                        ['Göğüs', latest['chest_cm'],  88.0],
                        ['Kalça', latest['hip_cm'],    82.0],
                        ['Kol',   latest['arm_cm'],    55.0],
                        ['Bacak', latest['leg_cm'],    65.0],
                      ].map((row) {
                        final val = (row[1] as num?)?.toDouble();
                        final pct = row[2] as double;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(children: [
                            SizedBox(width: 60, child: Text(row[0] as String, style: TextStyle(fontSize: 12, color: textSoft))),
                            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(value: pct / 100, minHeight: 6, backgroundColor: bgSoft, color: accent))),
                            const SizedBox(width: 10),
                            SizedBox(width: 60, child: Text(val != null ? '$val cm' : '--',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text), textAlign: TextAlign.right)),
                          ]),
                        );
                      })),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (_showForm || latest == null) ...[
                Container(
                  decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Yeni Ölçüm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text)),
                      const SizedBox(height: 4),
                      Text('En az bir alan zorunludur', style: TextStyle(fontSize: 11, color: muted)),
                      const SizedBox(height: 16),
                      Padding(padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: text),
                          decoration: InputDecoration(labelText: 'Kilo (kg)', prefixIcon: const Icon(Icons.monitor_weight_outlined, size: 18)))),
                      // Vücut yağı + Navy Method butonu
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Expanded(
                            child: TextField(controller: _bodyFatController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(color: text),
                              decoration: const InputDecoration(labelText: 'Vücut Yağ %', prefixIcon: Icon(Icons.percent, size: 18))),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showNavySheet(context, profileGender, bgCard, border, text, muted, accent, accentDim, danger),
                            child: Container(
                              height: 52, width: 52,
                              decoration: BoxDecoration(color: accentDim, borderRadius: BorderRadius.circular(12), border: Border.all(color: accent)),
                              child: Center(child: Text('?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: accent))),
                            ),
                          ),
                        ]),
                      ),
                      ...[
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
                          decoration: InputDecoration(labelText: f[1] as String, prefixIcon: Icon(f[2] as IconData, size: 18))))),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _save(existing: latest),
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
                    label: Text('Ölçüm Ekle', style: TextStyle(color: accent)),
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
      decoration: BoxDecoration(color: bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: textSoft)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: text)),
        if (delta != null)
          Text(delta!, style: TextStyle(fontSize: 11, color: isPositive ? positive : const Color(0xFFFF5555), fontWeight: FontWeight.w600)),
      ]),
    );
  }
}