import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper para controle da status bar
class StatusBarHelper {
  /// Define ícones brancos (para telas com fundo escuro)
  static void setLightStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Ícones brancos no Android
        statusBarBrightness: Brightness.dark, // iOS (invertido)
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  /// Define ícones pretos (para telas com fundo claro)
  static void setDarkStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Ícones pretos no Android
        statusBarBrightness: Brightness.light, // iOS (invertido)
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Restaura o padrão do sistema
  static void resetStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }
}
