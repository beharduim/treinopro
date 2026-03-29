import 'package:flutter/material.dart';

/// Cores do aplicativo extraídas do design do Figma
class AppColors {
  AppColors._();

  /// Cor de fundo principal da splash screen
  static const Color background = Color(0xFF0F131A);

  /// Cor de fundo da tela de login
  static const Color loginBackground = Color(0xFFFCFDFE);

  /// Cor azul do texto "TREINO"
  static const Color primaryBlue = Color(0xFF00BFFF);

  /// Cor laranja principal do app (padrão para botões e elementos principais)
  /// Baseada no botão "Criar propostas" - #FF6A00
  static const Color primaryOrange = Color(0xFFFF6A00);

  /// Cor laranja secundária (para gradientes e variações)
  static const Color primaryOrangeLight = Color(0xFFFF8C00);

  /// Cor secundária principal (textos escuros)
  static const Color secondary = Color(0xFF2D3748);

  /// Cor secundária mais escura (bordas, textos)
  static const Color secondaryDark = Color(0xFF42464D);

  /// Cor branca principal
  static const Color white = Color(0xFFF9F9F9);

  /// Cor de fundo dos inputs
  static const Color inputBackground = Color(0xFFF3F3F3);

  /// Cor mais escura para textos secundários
  static const Color secondaryDarkest = Color(0xFF0F131A);

  /// Cor específica do Figma para notificações (#E53D00)
  static const Color notificationRed = Color(0xFFE53D00);

  /// Cor padrão para ícones do app (baseada nos ícones dos cards da home)
  static const Color iconPrimary = Color(0xFF616161); // Colors.grey[700]

  /// Cor para ícones secundários
  static const Color iconSecondary = Color(0xFF9E9E9E); // Colors.grey[500]

  /// Cor para ícones desabilitados
  static const Color iconDisabled = Color(0xFFBDBDBD); // Colors.grey[400]

  /// Cor para item do menu selecionado
  static const Color menuSelected = Color(0xFFFF6A00); // Mesma cor do laranja principal

  /// Cores do gradiente do logo (estimadas com base no visual)
  static const List<Color> logoGradient = [
    Color(0xFFFF9500), // Laranja
    Color(0xFFFFC700), // Amarelo
  ];
}
