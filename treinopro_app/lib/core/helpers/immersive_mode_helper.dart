import 'package:flutter/services.dart';

/// Helper para gerenciar o modo imersivo da UI do sistema Android
class ImmersiveModeHelper {
  /// Ativa o modo imersivo sticky (navigation bar oculta)
  /// A navigation bar aparece quando o usuário desliza da borda inferior
  /// e desaparece automaticamente após alguns segundos
  static Future<void> enableImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top], // Mantém apenas a status bar
    );
  }

  /// Ativa o modo imersivo total (oculta tudo)
  /// Tanto status bar quanto navigation bar ficam ocultas
  static Future<void> enableFullImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [], // Oculta tudo
    );
  }

  /// Volta ao modo normal (mostra todas as barras)
  static Future<void> disableImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }

  /// Oculta apenas a navigation bar (mantém status bar)
  static Future<void> hideNavigationBar() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }

  /// Modo edge-to-edge (recomendado para apps modernos)
  /// Navigation bar fica transparente sobreposta ao conteúdo
  static Future<void> enableEdgeToEdgeMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
