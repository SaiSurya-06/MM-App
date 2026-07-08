import 'package:flutter/material.dart';

class Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
}

class AppBorderRadius {
  static const double small = 6.0;
  static const double medium = 12.0;
  static const double large = 20.0;
}

class AppTheme {
  // Brand Colors
  static const Color primaryRed = Color(0xFFE53935);
  static const Color accentRedGlow = Color(0x33E53935);

  // Semantic Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color infoBlue = Color(0xFF2196F3);
  static const Color errorRed = Color(0xFFE53935);
  
  // Dark Mode Colors
  static const Color darkBg = Color(0xFF09090E);
  static const Color darkSurface = Color(0xFF151521);
  static const Color darkCardBg = Color(0x14FFFFFF); // Glassmorphism backdrop color (8% opacity)
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFB0B0C0);
  
  // Light Mode Colors
  static const Color lightBg = Color(0xFFF5F5F7);
  static const Color lightSurface = Colors.white;
  static const Color lightCardBg = Color(0x1F000000); // Glassmorphism backdrop color
  static const Color lightTextPrimary = Color(0xFF1A1A26);
  static const Color lightTextSecondary = Color(0xFF6C6C7D);

  // Card Gradients
  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E1E30), Color(0xFF12121F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightCardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFEEEEF0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryRed,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkSurface,
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: primaryRed,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        error: errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryRed,
        unselectedItemColor: darkTextSecondary,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Inter', color: darkTextPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: 'Inter', color: darkTextPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontFamily: 'Inter', color: darkTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: 'Inter', color: darkTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: 'Inter', color: darkTextPrimary, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: darkTextPrimary, fontSize: 16),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: darkTextSecondary, fontSize: 14),
        bodySmall: TextStyle(fontFamily: 'Inter', color: darkTextSecondary, fontSize: 12),
        labelLarge: TextStyle(fontFamily: 'Inter', color: darkTextPrimary, fontSize: 14, fontWeight: FontWeight.bold),
        labelMedium: TextStyle(fontFamily: 'Inter', color: darkTextSecondary, fontSize: 12, fontWeight: FontWeight.bold),
        labelSmall: TextStyle(fontFamily: 'Inter', color: darkTextSecondary, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF101018),
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF20202F), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryRed,
      scaffoldBackgroundColor: lightBg,
      cardColor: lightSurface,
      colorScheme: const ColorScheme.light(
        primary: primaryRed,
        secondary: primaryRed,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        error: errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryRed,
        unselectedItemColor: lightTextSecondary,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Inter', color: lightTextPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: 'Inter', color: lightTextPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontFamily: 'Inter', color: lightTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: 'Inter', color: lightTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: 'Inter', color: lightTextPrimary, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: lightTextPrimary, fontSize: 16),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: lightTextSecondary, fontSize: 14),
        bodySmall: TextStyle(fontFamily: 'Inter', color: lightTextSecondary, fontSize: 12),
        labelLarge: TextStyle(fontFamily: 'Inter', color: lightTextPrimary, fontSize: 14, fontWeight: FontWeight.bold),
        labelMedium: TextStyle(fontFamily: 'Inter', color: lightTextSecondary, fontSize: 12, fontWeight: FontWeight.bold),
        labelSmall: TextStyle(fontFamily: 'Inter', color: lightTextSecondary, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E6), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        ),
      ),
    );
  }
}
