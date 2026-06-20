import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app.dart';
import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await NotificationService.init();

  // v8.1 FIX (TC-001): remove() burada (runApp'tan ÖNCE) çağrılıyordu —
  // native splash hemen kapanıp Flutter'ın kendi SplashScreen widget'ı
  // mount olana kadar bir render boşluğu/çakışması oluyordu, "TrackForge"
  // ismi+sloganı üst üste iki kez görünüyordu. remove() artık SplashScreen
  // widget'ının ilk frame'i çizildikten SONRA çağrılıyor (bkz. splash_screen.dart).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    const ProviderScope(
      child: TrackForgeApp(),
    ),
  );
}