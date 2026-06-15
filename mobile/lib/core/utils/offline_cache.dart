// ── core/utils/offline_cache.dart (v7) ──────────────────
// Offline OKUMA cache'i — spor salonu senaryosu:
// internet yokken uygulama bomboş açılmasın, son bilinen veriler görünsün.
//
// Desen: network-first, cache-fallback.
//   1. İstek dene → başarılıysa yanıtı kaydet ve döndür
//   2. Bağlantı hatasıysa → son kayıtlı yanıtı döndür (varsa)
// Yazma işlemleri kapsam dışı (offline kuyruk v1.1+ işi) —
// bu katman sadece OKUMA deneyimini kurtarır.
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../auth/token_manager.dart';

class OfflineCache {
  OfflineCache._();

  static bool _isConnectionError(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.unknown;

  static Future<String> _key(String path) async {
    final uid = await TokenManager.getCurrentUserId() ?? 'guest';
    return 'offline_${uid}_${path.replaceAll('/', '_')}';
  }

  /// GET isteği — başarıda cache'e yazar, bağlantı hatasında cache'ten okur.
  /// Dönen map'e `_offline: true` eklenirse veri bayat demektir;
  /// ekran isterse "çevrimdışı veri" rozeti gösterebilir.
  static Future<Map<String, dynamic>> getJson(String path,
      {Map<String, dynamic>? queryParameters}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key(path);
    try {
      final res = await ApiClient.instance
          .get(path, queryParameters: queryParameters);
      final data = Map<String, dynamic>.from(res.data);
      await prefs.setString(key, jsonEncode(data));
      return data;
    } on DioException catch (e) {
      if (_isConnectionError(e)) {
        final cached = prefs.getString(key);
        if (cached != null) {
          final data = Map<String, dynamic>.from(jsonDecode(cached));
          data['_offline'] = true; // bayat veri işareti
          return data;
        }
      }
      rethrow;
    }
  }
}
