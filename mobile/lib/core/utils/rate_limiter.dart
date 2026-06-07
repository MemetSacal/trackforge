// ── core/utils/rate_limiter.dart ────────────────────────
// Tüm AI özelliklerinin kullanım limitlerini yöneten merkezi sınıf.
// shared_preferences ile persist edilir — backend'e gerek yok.
//
// Limitler:
//   Vision kalori    → günde 3
//   Haftalık analiz  → haftada 1
//   Diyet tavsiyesi  → haftada 1
//   Antrenman planı  → haftada 1
//
// ✅ FIX: Tüm key'ler artık user_id bazlı.
//         Hesap değişince limitler birbirini etkilemez.

import 'package:shared_preferences/shared_preferences.dart';
import '../auth/token_manager.dart';

class RateLimiter {
  RateLimiter._();

  // ── User ID yardımcısı ────────────────────────────────
  // User ID yoksa (logout sonrası vb.) 'guest' kullanır — güvenli fallback.
  static Future<String> _userId() async {
    return await TokenManager.getCurrentUserId() ?? 'guest';
  }

  // ── Key üreticiler ────────────────────────────────────
  static Future<String> _dayKey(String feature) async {
    final uid = await _userId();
    final now = DateTime.now();
    return '${feature}_${uid}_${now.year}_${now.month}_${now.day}';
  }

  static Future<String> _weekKey(String feature) async {
    final uid    = await _userId();
    final now    = DateTime.now();
    final weekNum = _weekOfYear(now);
    return '${feature}_${uid}_${now.year}_w$weekNum';
  }

  // ISO week number hesabı
  static int _weekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final daysDiff    = date.difference(startOfYear).inDays;
    return ((daysDiff + startOfYear.weekday - 1) / 7).ceil();
  }

  // ── Vision: günde 3 ───────────────────────────────────
  static const int visionDailyLimit = 3;
  static const String _visionFeature = 'vision_count';

  static Future<int> getVisionUsedToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(await _dayKey(_visionFeature)) ?? 0;
  }

  static Future<bool> canUseVision() async {
    final used = await getVisionUsedToday();
    return used < visionDailyLimit;
  }

  static Future<void> recordVisionUse() async {
    final prefs = await SharedPreferences.getInstance();
    final key   = await _dayKey(_visionFeature);
    final used  = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, used + 1);
  }

  // ── Haftalık analiz: haftada 1 ───────────────────────
  static const String _weeklyFeature = 'weekly_analysis';

  static Future<bool> canUseWeeklyAnalysis() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(await _weekKey(_weeklyFeature)) ?? false);
  }

  static Future<void> recordWeeklyAnalysisUse() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(await _weekKey(_weeklyFeature), true);
  }

  // ── Diyet tavsiyesi: haftada 1 ───────────────────────
  static const String _mealFeature = 'meal_advice';

  static Future<bool> canUseMealAdvice() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(await _weekKey(_mealFeature)) ?? false);
  }

  static Future<void> recordMealAdviceUse() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(await _weekKey(_mealFeature), true);
  }

  // ── Antrenman planı: haftada 1 ────────────────────────
  static const String _workoutFeature = 'workout_plan';

  static Future<bool> canUseWorkoutPlan() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(await _weekKey(_workoutFeature)) ?? false);
  }

  static Future<void> recordWorkoutPlanUse() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(await _weekKey(_workoutFeature), true);
  }

  // ── UI için kalan hak metni ───────────────────────────
  static Future<String> visionRemainingText() async {
    final used      = await getVisionUsedToday();
    final remaining = visionDailyLimit - used;
    return remaining > 0
        ? 'Bugün $remaining kullanım hakkın kaldı'
        : 'Bugünlük limitine ulaştın (${visionDailyLimit}x)';
  }

  static Future<String> weeklyRemainingText(String feature) async {
    final can = feature == _weeklyFeature
        ? await canUseWeeklyAnalysis()
        : feature == _mealFeature
            ? await canUseMealAdvice()
            : await canUseWorkoutPlan();
    return can ? 'Bu hafta 1 kullanım hakkın var' : 'Bu haftaki hakkını kullandın';
  }

  // ── Logout temizleme ─────────────────────────────────
  // Profil ekranında logout sırasında çağrılır.
  // Mevcut kullanıcıya ait tüm limit key'lerini siler.
  static Future<void> clearUserLimits() async {
    final uid   = await _userId(); // logout öncesi çağrılmalı, userId hâlâ var
    final prefs = await SharedPreferences.getInstance();
    final keys  = prefs.getKeys().where((k) => k.contains('_${uid}_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}