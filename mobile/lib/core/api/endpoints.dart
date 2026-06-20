// ── endpoints.dart ──────────────────────────────────────
// Backend API'nin tüm URL sabitlerini tutan dosya.
// Endpoint değişirse sadece burası güncellenir, başka hiçbir yere dokunmak gerekmez.

/// Tüm API endpoint sabitlerini barındıran sınıf.
/// Instantiate edilemez, sadece statik sabitler içerir.
class Endpoints {
  Endpoints._(); // new Endpoints() yapılmasın diye private constructor

  // ── Temel URL ────────────────────────────────────────
  static const String baseUrl = 'https://trackforge-3o2j.onrender.com/api/v1';

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
  static String exerciseSessionComplete(String id) => '/exercises/sessions/$id/complete';

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
  static const String aiFeedback = '/ai/feedback';  // v2: 👍/👎 geri bildirim
  static const String aiRecipeFromPhoto = '/ai/recipe-from-photo';  // v3: buzdolabı→tarif
  static const String aiPlateauStatus = '/ai/plateau-status';       // v3: plato kontrolü (kotasız)
  static const String authLogout             = '/auth/logout';
  static const String authResendVerification = '/auth/resend-verification';                  // v3: sunucu tarafı logout
  static const String authDeleteMe = '/auth/me';                    // v3: hesap silme (DELETE)
  static const String reportsDashboardSummary = '/reports/dashboard-summary'; // v4: tek istekte dashboard
  static const String reportsWrapped = '/reports/wrapped';      // v5: yıl özeti
  static const String socialDuels = '/social/duels';            // v5: adım düellosu
  static const String exerciseCatalog = '/exercises/catalog';   // v5: kanonik egzersiz kataloğu
  static const String aiCalorieFromText = '/ai/calorie-from-text'; // v6: yazıyla/sesle öğün girişi
  static const String aiJobsWorkout = '/ai/jobs/workout-plan';     // v7: arka plan üretim
  static const String aiJobsMeal = '/ai/jobs/meal-advice';         // v7: arka plan üretim
  static const String aiJobs = '/ai/jobs';                          // v7: + /{id} ile durum
  static const String reportsHealthPdf = '/reports/health-report.pdf'; // v7: doktor raporu
  static const String aiChat = '/ai/chat';              // v1.1: sohbet asistanı (POST)
  static const String aiChatHistory = '/ai/chat/history'; // v1.1: geçmiş (GET) + temizle (DELETE)
  static const String bloodValues = '/blood-values';       // v1.1: kan değerleri (GET/POST), /{id} DELETE
  static const String bloodValuesMarkers = '/blood-values/markers'; // v1.1: bilinen marker listesi
  static const String reportsInsights = '/reports/insights'; // v1.1: veri korelasyonları
  static const aiCycleAdvice = '$baseUrl/ai/cycle-advice';
  static const String aiCalorieBankAdvice = '/ai/calorie-bank-advice';

  // ── Notifications (FCM) ──────────────────────────────
  static const String notificationsRegisterToken = '/notifications/register-token';
  static const String notificationsDeactivateToken = '/notifications/token/deactivate';
  static const String notifications = '/notifications/';
  static const String notificationsReadAll = '/notifications/read-all';
  // Tekil okundu işaretleme: '$notifications$notificationId/read' şeklinde kullanılır
}