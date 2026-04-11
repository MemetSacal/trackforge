// ── main.dart ───────────────────────────────────────────
// Uygulamanın giriş noktası.
// Dart'ta her uygulama main() fonksiyonundan başlar — Java'daki gibi.
// ProviderScope — Riverpod'un tüm provider'ları yönetebilmesi için
// uygulamayı sarmalıyor. Bu olmadan provider'lar çalışmaz.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  // Flutter engine'i başlat — native kodla iletişim için gerekli
  // async işlem yapmadan önce mutlaka çağrılmalı
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // ProviderScope: Riverpod'un state yönetimi için kök widget
    // Tüm provider'lar bu scope içinde yaşar
    const ProviderScope(
      child: TrackForgeApp(),
    ),
  );
}