// ── endpoints.dart ──────────────────────────────────────
// Backend API'nin tüm URL sabitlerini tutan dosya.
// Endpoint değişirse sadece burası güncellenir, başka hiçbir yere dokunmak gerekmez.

/// Tüm API endpoint sabitlerini barındıran sınıf.
/// Instantiate edilemez, sadece statik sabitler içerir.
class Endpoints {
  Endpoints._(); // new Endpoints() yapılmasın diye private constructor

  // ── Temel URL ────────────────────────────────────────
  // Geliştirme ortamında local backend'e bağlanıyoruz.
  // Android emülatörde localhost yerine 10.0.2.2 kullanılır —
  // çünkü emülatör kendi sanal makinesinde çalışır,
  // bilgisayarın localhost'una 10.0.2.2 üzerinden erişir.
  static const String baseUrl = 'http://localhost:8000/api/v1';
  
  // ── Auth ─────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';

  // ── Onboarding ───────────────────────────────────────
  static const String onboarding = '/onboarding';
  static const String onboardingComplete = '/onboarding/complete';

  // ── Measurements ─────────────────────────────────────
  static const String measurements = '/measurements';

  // ── Notes ────────────────────────────────────────────
  static const String notes = '/notes';

  // ── Meal Compliance ──────────────────────────────────
  static const String mealCompliance = '/meal-compliance';

  // ── Water ────────────────────────────────────────────
  static const String water = '/water';

  // ── Sleep ────────────────────────────────────────────
  static const String sleep = '/sleep';

  // ── Steps ────────────────────────────────────────────
  static const String steps = '/steps';

  // ── Exercises ────────────────────────────────────────
  static const String exerciseSessions = '/exercises/sessions';

  // ── Files ────────────────────────────────────────────
  static const String photos = '/files/photos';
  static const String dietPlans = '/files/diet-plans';

  // ── Preferences ──────────────────────────────────────
  static const String preferences = '/preferences';

  // ── Shopping ─────────────────────────────────────────
  static const String shopping = '/shopping';

  // ── Reports ──────────────────────────────────────────
  static const String reportsWeekly = '/reports/weekly';
  static const String reportsMonthly = '/reports/monthly';

  // ── Barcode ──────────────────────────────────────────
  static const String barcode = '/barcode';

  // ── Cycle ────────────────────────────────────────────
  static const String cycle = '/cycle';

  // ── Gamification ─────────────────────────────────────
  static const String gamificationSummary = '/gamification/summary';
  static const String gamificationStreaks = '/gamification/streaks';
  static const String gamificationBadges = '/gamification/badges';
  static const String gamificationLevel = '/gamification/level';

  // ── Social ───────────────────────────────────────────
  static const String friendRequest = '/social/friends/request';
  static const String friends = '/social/friends';
  static const String leaderboard = '/social/leaderboard';

  // ── AI ───────────────────────────────────────────────
  static const String aiWeeklySummary = '/ai/weekly-summary';
  static const String aiWorkoutPlan = '/ai/workout-plan';
  static const String aiMealAdvice = '/ai/meal-advice';
  static const String aiRecipe = '/ai/recipe';
  static const String aiCalorieFromPhoto = '/ai/calorie-from-photo';
}