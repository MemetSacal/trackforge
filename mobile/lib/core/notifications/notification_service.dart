// ── notification_service.dart ───────────────────────────
// lib/core/notifications/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── Notification ID'leri ────────────────────────────
  static const int _waterBaseId     = 100; // 100-108 arası su bildirimleri
  static const int _workoutId       = 200;
  static const int _sleepId         = 300;
  static const int _mealId          = 400;
  static const int _stepsId         = 500;
  static const int _streakId        = 600;
  static const int _weeklyReportId  = 700;

  // ── SharedPrefs Key'leri ────────────────────────────
  static const String _keyWaterEnabled    = 'notif_water_enabled';
  static const String _keyWorkoutEnabled  = 'notif_workout_enabled';
  static const String _keyWorkoutHour     = 'notif_workout_hour';
  static const String _keyWorkoutMin      = 'notif_workout_min';
  static const String _keySleepEnabled    = 'notif_sleep_enabled';
  static const String _keySleepHour       = 'notif_sleep_hour';
  static const String _keySleepMin        = 'notif_sleep_min';
  static const String _keyMealEnabled     = 'notif_meal_enabled';
  static const String _keyStepsEnabled    = 'notif_steps_enabled';
  static const String _keyStreakEnabled   = 'notif_streak_enabled';
  static const String _keyWeeklyEnabled   = 'notif_weekly_enabled';

  // ── Init ────────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  // ── İzin iste ───────────────────────────────────────
  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // ── Kanal oluştur (Android 8+) ──────────────────────
  static AndroidNotificationDetails _channel({
    required String channelId,
    required String channelName,
    String? channelDesc,
    Importance importance = Importance.high,
  }) {
    return AndroidNotificationDetails(
      channelId, channelName,
      channelDescription: channelDesc,
      importance: importance,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
  }

  // ════════════════════════════════════════════════════
  // SU HATIRLATICILARı — her 2 saatte bir 09:00-21:00
  // ════════════════════════════════════════════════════
  static Future<void> scheduleWaterReminders() async {
    await cancelWaterReminders();
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyWaterEnabled) ?? true)) return;

    final hours = [9, 11, 13, 15, 17, 19, 21];
    for (int i = 0; i < hours.length; i++) {
      final scheduledTime = _nextTime(hours[i], 0);
      await _plugin.zonedSchedule(
        _waterBaseId + i,
        '💧 Su İçme Vakti',
        'Bugün yeterli su içiyor musun? Hedefine ulaşmak için şimdi bir bardak iç!',
        scheduledTime,
        NotificationDetails(
          android: _channel(channelId: 'water', channelName: 'Su Hatırlatıcısı'),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> cancelWaterReminders() async {
    for (int i = 0; i < 9; i++) {
      await _plugin.cancel(_waterBaseId + i);
    }
  }

  // ════════════════════════════════════════════════════
  // ANTRENMAN HATIRLATICISı
  // ════════════════════════════════════════════════════
  static Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(_workoutId);
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyWorkoutEnabled) ?? true)) return;

    await prefs.setInt(_keyWorkoutHour, hour);
    await prefs.setInt(_keyWorkoutMin, minute);

    await _plugin.zonedSchedule(
      _workoutId,
      '🏋️ Antrenman Zamanı!',
      'Bugün antrenman günün. Hazır mısın? Hadi başlayalım!',
      _nextTime(hour, minute),
      NotificationDetails(
        android: _channel(channelId: 'workout', channelName: 'Antrenman Hatırlatıcısı'),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelWorkoutReminder() async {
    await _plugin.cancel(_workoutId);
  }

  // ════════════════════════════════════════════════════
  // UYKU HATIRLATICISı
  // ════════════════════════════════════════════════════
  static Future<void> scheduleSleepReminder({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(_sleepId);
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keySleepEnabled) ?? true)) return;

    await prefs.setInt(_keySleepHour, hour);
    await prefs.setInt(_keySleepMin, minute);

    await _plugin.zonedSchedule(
      _sleepId,
      '😴 Uyku Vakti Yaklaşıyor',
      'Kaliteli uyku sağlığın için kritik. Ekranları kapat, uykuya hazırlan!',
      _nextTime(hour, minute),
      NotificationDetails(
        android: _channel(channelId: 'sleep', channelName: 'Uyku Hatırlatıcısı'),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelSleepReminder() async {
    await _plugin.cancel(_sleepId);
  }

  // ════════════════════════════════════════════════════
  // ÖĞÜN / KALORİ HATIRLATICISı — 12:00 ve 19:00
  // ════════════════════════════════════════════════════
  static Future<void> scheduleMealReminders() async {
    await cancelMealReminders();
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyMealEnabled) ?? true)) return;

    final meals = [
      {'hour': 12, 'msg': 'Öğle yemeğini yedin mi? Kalori takibini unutma!'},
      {'hour': 19, 'msg': 'Akşam yemeği vakti. Bugünkü kalorini kaydetmeyi unutma!'},
    ];

    for (int i = 0; i < meals.length; i++) {
      await _plugin.zonedSchedule(
        _mealId + i,
        '🍽️ Öğün Hatırlatıcısı',
        meals[i]['msg'] as String,
        _nextTime(meals[i]['hour'] as int, 0),
        NotificationDetails(
          android: _channel(channelId: 'meal', channelName: 'Öğün Hatırlatıcısı'),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  static Future<void> cancelMealReminders() async {
    await _plugin.cancel(_mealId);
    await _plugin.cancel(_mealId + 1);
  }

  // ════════════════════════════════════════════════════
  // ADIM HEDEFİ — her gün 20:00
  // ════════════════════════════════════════════════════
  static Future<void> scheduleStepsReminder() async {
    await _plugin.cancel(_stepsId);
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyStepsEnabled) ?? true)) return;

    await _plugin.zonedSchedule(
      _stepsId,
      '👟 Adım Hedefin!',
      'Günün bitmeden adım hedefini kontrol et. Biraz yürüyüş yapabilirsin!',
      _nextTime(20, 0),
      NotificationDetails(
        android: _channel(channelId: 'steps', channelName: 'Adım Hatırlatıcısı'),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ════════════════════════════════════════════════════
  // SERİ KORUMA — her gün 21:00
  // ════════════════════════════════════════════════════
  static Future<void> scheduleStreakReminder() async {
    await _plugin.cancel(_streakId);
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyStreakEnabled) ?? true)) return;

    await _plugin.zonedSchedule(
      _streakId,
      '🔥 Serinizi Koruyun!',
      'Bugün henüz veri girmediniz. Serinizi kırmamak için hemen giriş yapın!',
      _nextTime(21, 0),
      NotificationDetails(
        android: _channel(channelId: 'streak', channelName: 'Seri Hatırlatıcısı'),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ════════════════════════════════════════════════════
  // HAFTALIK RAPOR — Pazartesi 09:00
  // ════════════════════════════════════════════════════
  static Future<void> scheduleWeeklyReport() async {
    await _plugin.cancel(_weeklyReportId);
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyWeeklyEnabled) ?? true)) return;

    // Bir sonraki Pazartesi 09:00
    final now  = tz.TZDateTime.now(tz.local);
    var monday = now;
    while (monday.weekday != DateTime.monday) {
      monday = monday.add(const Duration(days: 1));
    }
    final scheduled = tz.TZDateTime(tz.local, monday.year, monday.month, monday.day, 9, 0);

    await _plugin.zonedSchedule(
      _weeklyReportId,
      '📊 Haftalık AI Raporu Hazır!',
      'Bu haftanın analizi seni bekliyor. AI Koç ne diyor?',
      scheduled,
      NotificationDetails(
        android: _channel(channelId: 'weekly', channelName: 'Haftalık Rapor'),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ════════════════════════════════════════════════════
  // TÜM BİLDİRİMLERİ ZAMANLA (uygulama açılışında çağır)
  // ════════════════════════════════════════════════════
  static Future<void> scheduleAll() async {
    final prefs = await SharedPreferences.getInstance();
    await scheduleWaterReminders();
    await scheduleMealReminders();
    await scheduleStepsReminder();
    await scheduleStreakReminder();
    await scheduleWeeklyReport();

    // Antrenman — kaydedilmiş saat varsa uygula
    final workoutHour = prefs.getInt(_keyWorkoutHour) ?? 18;
    final workoutMin  = prefs.getInt(_keyWorkoutMin)  ?? 0;
    await scheduleWorkoutReminder(hour: workoutHour, minute: workoutMin);

    // Uyku — kaydedilmiş saat varsa uygula, yoksa 22:30
    final sleepHour = prefs.getInt(_keySleepHour) ?? 22;
    final sleepMin  = prefs.getInt(_keySleepMin)  ?? 30;
    await scheduleSleepReminder(hour: sleepHour, minute: sleepMin);
  }

  // ── Tümünü iptal et ─────────────────────────────────
  static Future<void> cancelAll() async => _plugin.cancelAll();

  // ── Yardımcı: bir sonraki saat:dakika anı ───────────
  static tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // ── Ayarları oku ────────────────────────────────────
  static Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'water':    prefs.getBool(_keyWaterEnabled)   ?? true,
      'workout':  prefs.getBool(_keyWorkoutEnabled) ?? true,
      'workoutHour': prefs.getInt(_keyWorkoutHour)  ?? 18,
      'workoutMin':  prefs.getInt(_keyWorkoutMin)   ?? 0,
      'sleep':    prefs.getBool(_keySleepEnabled)   ?? true,
      'sleepHour':   prefs.getInt(_keySleepHour)    ?? 22,
      'sleepMin':    prefs.getInt(_keySleepMin)     ?? 30,
      'meal':     prefs.getBool(_keyMealEnabled)    ?? true,
      'steps':    prefs.getBool(_keyStepsEnabled)   ?? true,
      'streak':   prefs.getBool(_keyStreakEnabled)  ?? true,
      'weekly':   prefs.getBool(_keyWeeklyEnabled)  ?? true,
    };
  }

  // ── Ayarları kaydet ─────────────────────────────────
  static Future<void> saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool('notif_${key}_enabled', value);
    if (value is int)  await prefs.setInt('notif_$key', value);
  }
}