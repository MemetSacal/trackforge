import 'package:shared_preferences/shared_preferences.dart';


class TokenManager {
  static const _accessTokenKey  = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _currentUserIdKey = 'current_user_id';
  static const _isPremiumKey = 'is_premium';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    bool isPremium = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_currentUserIdKey, userId);
    await prefs.setBool(_isPremiumKey, isPremium);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // ── YENİ: user_id okuma ──────────────────────────────
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserIdKey);
  }

  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isPremiumKey) ?? false;
  }

  // ── YENİ: token'a dokunmadan SADECE premium durumunu güncelle ──
  // /auth/me'den gelen taze değeri prefs cache'ine yazmak için.
  // set_premium.py DB'yi değiştirdiğinde uygulama açılışında bununla senkronlanır.
  static Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPremiumKey, value);
  }

  // ── YENİ: token'a dokunmadan SADECE user_id güncelle ──
  // Splash'te /auth/me doğrulaması sırasında kimliği teyit/senkron etmek için.
  static Future<void> setCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserIdKey, userId);
  }

  // ── YENİ: /auth/me cevabından kimlik + premium'u tek seferde senkronla ──
  // res.data map'ini alıp 'id' ve 'is_premium' alanlarını cache'e işler.
  // Eksik alan varsa o alanı atlar (mevcut değeri bozmaz).
  static Future<void> syncFromMe(Map<String, dynamic> me) async {
    final prefs = await SharedPreferences.getInstance();
    final id = me['id'];
    if (id != null) {
      await prefs.setString(_currentUserIdKey, id.toString());
    }
    if (me.containsKey('is_premium')) {
      await prefs.setBool(_isPremiumKey, me['is_premium'] == true);
    }
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_currentUserIdKey);
    await prefs.remove(_isPremiumKey);
  }

  // ── YENİ: Kullanıcıya özel TÜM lokal cache anahtarlarının prefix listesi ──
  // Bu anahtarlar diyet_tab / meal_advice_screen tarafında
  // 'last_weekly_meal_plan_<userId>' gibi userId suffix'iyle yazılıyor.
  // Suffix'i ne olursa olsun (geçerli id / 'guest' / boş) hepsini yakalamak
  // için prefix eşleşmesi kullanıyoruz.
  static const _userScopedPrefixes = <String>[
    'last_meal_advice',       // last_meal_advice_<id> + last_meal_advice_date_<id>
    'last_weekly_meal_plan',  // last_weekly_meal_plan_<id>
    'last_shopping_list',     // last_shopping_list_<id>
    'last_recommended_foods', // last_recommended_foods_<id>
    'last_foods_to_avoid',    // last_foods_to_avoid_<id>
  ];

  // ── YENİ: Aktif kullanıcıya ait tüm lokal cache'i sil ──────────
  // Hesap değişiminde (login'de farklı kullanıcı tespit edilince) çağrılır.
  // Önceki kullanıcının diyet/öğün/bildirim cache'inin yeni kullanıcıya
  // sızmasını engeller.
  //
  // ÖNEMLİ: Auth token'larına, user_id'ye, premium / tema / "beni hatırla"
  // tercihlerine DOKUNMAZ — sadece kullanıcıya özel veri cache'ini temizler.
  static Future<void> clearUserScopedCache() async {
    final prefs = await SharedPreferences.getInstance();

    // getKeys() o anki TÜM anahtarları verir. Eski sürümlerden kalmış
    // 'guest' veya boş-suffix'li kalıntılar dahil hepsini prefix ile yakalarız.
    final keys = prefs.getKeys().toList();
    for (final key in keys) {
      final isUserScoped =
          _userScopedPrefixes.any((prefix) => key.startsWith(prefix));
      if (isUserScoped) {
        await prefs.remove(key);
      }
    }

    // Bildirim listesi user-scoped DEĞİL (global 'in_app_notifications'),
    // bu yüzden hesap değişiminde mutlaka sıfırlanmalı — yoksa eski
    // kullanıcının bildirimleri yeni kullanıcıda görünür.
    await prefs.remove('in_app_notifications');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}