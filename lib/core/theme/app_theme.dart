import 'package:flutter/material.dart';
import 'package:stopandgo/core/storage/app_storage.dart';

class AppTheme {
  /// Devuelve los colores actuales según caché (o defaults)
  static (Color primary, Color secondary) get currentColors {
    final org = AppStorage.getOrganization();
    if (org != null) {
      return (_hexToColor(org.primaryColor), _hexToColor(org.secondaryColor));
    }

    // 🔸 fallback por defecto si no hay datos
    return (const Color(0xFF4B69FF), const Color(0xFFFFB703));
  }

  /// Tema principal dinámico
  static ThemeData get light {
    final (primary, secondary) = currentColors;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primary, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Convierte hex -> Color
  static Color _hexToColor(String hex) {
    var clean = hex.replaceAll('#', '').toUpperCase();
    if (clean.length == 6) clean = 'FF$clean';
    final val = int.tryParse(clean, radix: 16) ?? 0xFF000000;
    return Color(val);
  }
}
