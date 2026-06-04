import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app.dart';
import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await NotificationService.init();

  FlutterNativeSplash.remove();

  runApp(
    const ProviderScope(
      child: TrackForgeApp(),
    ),
  );
}