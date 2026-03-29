import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Tema principal da aplicação baseado no design do Figma
class AppTheme {
  AppTheme._();

  /// Tema claro da aplicação
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      // Otimizações de performance para animações
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      // Configurações de splash otimizadas
      splashFactory: InkRipple.splashFactory,
      // Força animações mesmo na primeira execução
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: null, // IMPORTANTE: deixe null para não interferir
      ),
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryOrange,
        surface: Colors.white,
        onSurface: Colors.black,
        onPrimary: Colors.white,
        onSecondary: AppColors.secondary,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black),
      ),
    );
  }
}
