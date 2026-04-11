// TrackForge Tema Sistemi — Dark & Light ThemeData
// app.dart içinde MaterialApp'e bağlanacak

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Uygulamanın dark ve light ThemeData'larını üretir.
/// MaterialApp'in theme ve darkTheme parametrelerine verilir.
class AppTheme {
  AppTheme._();

  // ── DARK THEME ─────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    primaryColor: AppColors.darkAccent,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkAccent,
      surface: AppColors.darkBgCard,
      error: AppColors.darkDanger,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.darkText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Card
    cardTheme: CardTheme(
      color: AppColors.darkBgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
    ),

    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // TextField
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkBgCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkAccent, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.darkTextSub),
      hintStyle: const TextStyle(color: AppColors.darkTextSub),
    ),

    // BottomNavigationBar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkBgCard,
      selectedItemColor: AppColors.darkAccent,
      unselectedItemColor: AppColors.darkTextSub,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.darkText),
      bodyMedium: TextStyle(color: AppColors.darkText),
      bodySmall: TextStyle(color: AppColors.darkTextSub),
    ),
  );

  // ── LIGHT THEME ────────────────────────────────────────
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg,
    primaryColor: AppColors.lightAccent,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightAccent,
      surface: AppColors.lightBgCard,
      error: AppColors.lightDanger,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBg,
      foregroundColor: AppColors.lightText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.lightText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Card
    cardTheme: CardTheme(
      color: AppColors.lightBgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
    ),

    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // TextField
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightBgCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        const BorderSide(color: AppColors.lightAccent, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.lightTextSub),
      hintStyle: const TextStyle(color: AppColors.lightTextSub),
    ),

    // BottomNavigationBar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightBgCard,
      selectedItemColor: AppColors.lightAccent,
      unselectedItemColor: AppColors.lightTextSub,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.lightText),
      bodyMedium: TextStyle(color: AppColors.lightText),
      bodySmall: TextStyle(color: AppColors.lightTextSub),
    ),
  );
}

/*
app_colors.dart sadece renk sabitleri — tüm renkler tek yerde tanımlı,
uygulama boyunca AppColors.darkAccent gibi erişiyoruz.
Dark ve light için ayrı ayrı.

app_theme.dart ise Flutter'ın ThemeData sistemi.
"AppBar şöyle görünsün, Card şöyle görünsün, Button şöyle görünsün" diye
tüm widget'ların görünümünü merkezi olarak tanımlıyoruz. Böylece her widget'ta
tek tek renk yazmak zorunda kalmıyoruz — tema otomatik uygulanıyor.

İkisi birlikte şöyle çalışıyor: MaterialApp'e theme:
AppTheme.light ve darkTheme: AppTheme.dark veriyoruz, Flutter gerisini hallediyor
Kullanıcı telefonda dark moda geçince uygulama otomatik değişiyor.
 */