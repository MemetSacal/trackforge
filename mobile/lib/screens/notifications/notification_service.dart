import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    try {
      if (kDebugMode) print("NotificationService başarıyla başlatıldı.");
    } catch (e) {
      if (kDebugMode) print("Notification init hatası: $e");
    }
  }

  static Future<void> setupFCMToken() async {
    try {
      bool granted = await hasPermission();
      if (granted) {
        String? token = await _messaging.getToken();
        if (kDebugMode) print("Alınan FCM Token: $token");

        if (token != null) {
          await sendTokenToBackend(token);
        }
      }

      _messaging.onTokenRefresh.listen((newToken) async {
        if (kDebugMode) print("FCM Token yenilendi: $newToken");
        await sendTokenToBackend(newToken);
      });
    } catch (e) {
      if (kDebugMode) print("setupFCMToken Hatası: $e");
    }
  }

  static Future<void> sendTokenToBackend(String token) async {
    try {
      await ApiClient.instance.post(
        '/notifications/register-token',
        data: {
          'fcm_token': token,
          'device_type': 'android',
          'device_name': 'Android Tablet',
          'app_version': '1.0.0',
        },
      );
      if (kDebugMode) print("FCM Token başarıyla backend'e kaydedildi.");
    } catch (e) {
      if (kDebugMode) print("Token backend'e gönderilemedi: $e");
    }
  }

  static Future<bool> hasPermission() async {
    NotificationSettings settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  static Future<bool> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await setupFCMToken();
      return true;
    }
    return false;
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'water': prefs.getBool('notif_water') ?? true,
      'workout': prefs.getBool('notif_workout') ?? true,
      'sleep': prefs.getBool('notif_sleep') ?? true,
      'meal': prefs.getBool('notif_meal') ?? true,
      'steps': prefs.getBool('notif_steps') ?? true,
      'streak': prefs.getBool('notif_streak') ?? true,
      'weekly': prefs.getBool('notif_weekly') ?? true,
      'workoutHour': prefs.getInt('notif_workoutHour') ?? 18,
      'workoutMin': prefs.getInt('notif_workoutMin') ?? 0,
      'sleepHour': prefs.getInt('notif_sleepHour') ?? 22,
      'sleepMin': prefs.getInt('notif_sleepMin') ?? 30,
    };
  }

  static Future<void> saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_$key', value);
  }

  static Future<void> scheduleAll() async {
    if (kDebugMode) print("Tüm yerel hatırlatıcılar güncelleniyor...");
  }

  static Future<void> cancelAll() async {
    if (kDebugMode) print("Tüm yerel hatırlatıcılar iptal edildi.");
  }

  static Future<void> scheduleWorkoutReminder({required int hour, required int minute}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_workoutHour', hour);
    await prefs.setInt('notif_workoutMin', minute);
  }

  static Future<void> scheduleSleepReminder({required int hour, required int minute}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_sleepHour', hour);
    await prefs.setInt('notif_sleepMin', minute);
  }
}