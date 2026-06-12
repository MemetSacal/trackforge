// ── core/utils/rate_limiter.dart (v2) ───────────────────
// ROL DEĞİŞİKLİĞİ — ÖNEMLİ:
//   v1'de bu dosya "güvenlik sınırı"ydı. Bu yanlıştı: SharedPreferences
//   silinerek/modifiye APK ile aşılabilirdi ve esas limit hiçbir yerde
//   zorlanmamış olurdu.
//   v2'de ESAS OTORİTE BACKEND'dir (ai_rate_limiter.py). Bu sınıf artık
//   sadece UX iyileştirmesidir: butonu önceden griye çekmek ve gereksiz
//   istek atmamak için. Sunucu 429 dönerse ekranlar QuotaException ile
//   yakalar (api_exceptions.dart).
//
// v2 DEĞİŞİKLİKLERİ:
//   1. Haftalık özellikler bool yerine SAYAÇ tutar. v1'de meal/workout
//      lokalde 1/hafta'ya kilitliydi ama backend 2/hafta'ya izin
//      veriyordu — kullanıcı 2. hakkını hiç kullanamıyordu (mantık hatası).
//      Limitler artık backend QUOTAS free tier ile birebir aynı.
//   2. syncFromServer(): her AI yanıtındaki "quota" objesiyle lokal
//      sayaç sunucu gerçeğine eşitlenir (cache isabetinde kota yanmaz,
//      lokal sayaç da şişmez).
//   3. Key'ler "v2_" önekiyle — eski bool key'lerle tip çakışması olmaz,
//      eski key'ler tarih bazlı oldukları için kendiliğinden ölür.

import 'package:shared_preferences/shared_preferences.dart';
import '../auth/token_manager.dart';

class RateLimiter {
  RateLimiter._();

  // ── Backend QUOTAS (free tier) ile senkron limitler ──
  static const int visionDailyLimit   = 3;
  static const int weeklyAnalysisLimit = 1;
  static const int mealAdviceLimit    = 2;
  static const int workoutPlanLimit   = 2;

  static const String _visionFeature  = 'vision';
  static const String _weeklyFeature  = 'weekly_summary';
  static const String _mealFeature    = 'meal_advice';
  static const String _workoutFeature = 'workout_plan';

  // ── User ID yardımcısı ────────────────────────────────
  static Future<String> _userId() async {
    return await TokenManager.getCurrentUserId() ?? 'guest';
  }

  // ── Key üreticiler (v2 öneki — eski bool key'lerle çakışmaz) ──
  static Future<String> _dayKey(String feature) async {
    final uid = await _userId();
    final now = DateTime.now();
    return 'v2_${feature}_${uid}_${now.year}_${now.month}_${now.day}';
  }

  static Future<String> _weekKey(String feature) async {
    final uid     = await _userId();
    final now     = DateTime.now();
    final weekNum = _weekOfYear(now);
    return 'v2_${feature}_${uid}_${now.year}_w$weekNum';
  }

  static int _weekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final daysDiff    = date.difference(startOfYear).inDays;
    return ((daysDiff + startOfYear.weekday - 1) / 7).ceil();
  }

  // ── Genel sayaç işlemleri ─────────────────────────────
  static Future<String> _keyFor(String feature) async {
    final isDaily = feature == _visionFeature;
    return isDaily ? await _dayKey(feature) : await _weekKey(feature);
  }

  static Future<int> _used(String feature) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(await _keyFor(feature)) ?? 0;
  }

  static Future<void> _increment(String feature) async {
    final prefs = await SharedPreferences.getInstance();
    final key   = await _keyFor(feature);
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }

  /// ── v2: Sunucudan dönen gerçek kullanımla senkronla ──
  /// Her başarılı AI yanıtındaki quota objesinden çağrılır:
  ///   RateLimiter.syncFromServer('workout_plan', quota['used']);
  /// Böylece: sunucu cache'den döndüyse sayaç şişmez; başka cihazdan
  /// kullanım olduysa bu cihazın sayacı da doğruyu gösterir.
  static Future<void> syncFromServer(String feature, int used) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(await _keyFor(feature), used);
  }

  // ── Vision: günde 3 ───────────────────────────────────
  static Future<int> getVisionUsedToday() async => _used(_visionFeature);

  static Future<bool> canUseVision() async {
    if (await TokenManager.isPremium()) return true; // PRO tavanını sunucu zorlar
    return (await _used(_visionFeature)) < visionDailyLimit;
  }

  static Future<void> recordVisionUse() async => _increment(_visionFeature);

  // ── Haftalık analiz: haftada 1 ────────────────────────
  static Future<bool> canUseWeeklyAnalysis() async {
    if (await TokenManager.isPremium()) return true;
    return (await _used(_weeklyFeature)) < weeklyAnalysisLimit;
  }

  static Future<void> recordWeeklyAnalysisUse() async => _increment(_weeklyFeature);

  // ── Diyet tavsiyesi: haftada 2 (v1'de yanlışlıkla 1'di) ──
  static Future<bool> canUseMealAdvice() async {
    if (await TokenManager.isPremium()) return true;
    return (await _used(_mealFeature)) < mealAdviceLimit;
  }

  static Future<void> recordMealAdviceUse() async => _increment(_mealFeature);

  // ── Antrenman planı: haftada 2 (v1'de yanlışlıkla 1'di) ──
  static Future<bool> canUseWorkoutPlan() async {
    if (await TokenManager.isPremium()) return true;
    return (await _used(_workoutFeature)) < workoutPlanLimit;
  }

  static Future<void> recordWorkoutPlanUse() async => _increment(_workoutFeature);

  // ── UI için kalan hak metni ───────────────────────────
  static Future<String> visionRemainingText() async {
    final used      = await getVisionUsedToday();
    final remaining = visionDailyLimit - used;
    return remaining > 0
        ? 'Bugün $remaining kullanım hakkın kaldı'
        : 'Bugünlük limitine ulaştın (${visionDailyLimit}x)';
  }

  static Future<String> weeklyRemainingText(String feature) async {
    final limits = {
      _weeklyFeature: weeklyAnalysisLimit,
      _mealFeature: mealAdviceLimit,
      _workoutFeature: workoutPlanLimit,
    };
    // Geriye uyum: eski feature adı 'weekly_analysis' ile çağrılırsa da çalışsın
    final f = feature == 'weekly_analysis' ? _weeklyFeature : feature;
    final limit = limits[f] ?? 1;
    final remaining = limit - await _used(f);
    return remaining > 0
        ? 'Bu hafta $remaining kullanım hakkın kaldı'
        : 'Bu haftaki hakkını kullandın';
  }

  // ── Logout temizleme ─────────────────────────────────
  static Future<void> clearUserLimits() async {
    final uid   = await _userId();
    final prefs = await SharedPreferences.getInstance();
    final keys  = prefs.getKeys().where((k) => k.contains('_${uid}_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
