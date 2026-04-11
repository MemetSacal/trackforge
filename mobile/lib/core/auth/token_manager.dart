// ── token_manager.dart ──────────────────────────────────
// JWT token'larını saklayan ve okuyan sınıf.
// Web'de flutter_secure_storage çalışmaz (Keystore/Keychain yok),
// bu yüzden shared_preferences kullanıyoruz.
// Production'da gerçek cihaza geçince flutter_secure_storage'a döneceğiz.

import 'package:shared_preferences/shared_preferences.dart';

/// Access token ve refresh token'ı depoya kaydeder/okur/siler.
class TokenManager {
  TokenManager._();

  // Depolama anahtarları — bu isimlerle kaydedip okuyoruz
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // ── KAYDET ────────────────────────────────────────────
  /// Login sonrası gelen token'ları depoya kaydeder.
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_accessTokenKey, accessToken),
      prefs.setString(_refreshTokenKey, refreshToken),
    ]);
  }

  // ── OKU ───────────────────────────────────────────────
  /// Access token'ı okur. Token yoksa null döner.
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Refresh token'ı okur. Token yoksa null döner.
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // ── KONTROL ───────────────────────────────────────────
  /// Kullanıcı giriş yapmış mı? Access token var mı diye bakar.
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  // ── SİL ───────────────────────────────────────────────
  /// Logout veya token refresh başarısız olunca çağrılır.
  /// Her iki token'ı da siler.
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
    ]);
  }
}