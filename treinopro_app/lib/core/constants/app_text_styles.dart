import 'package:flutter/material.dart';

/// Estilos de texto extraídos do design do Figma
class AppTextStyles {
  AppTextStyles._();

  /// Estilo H6 (Outfit, Regular, 20px)
  static const TextStyle h6 = TextStyle(
    fontFamily: 'Outfit',
    fontWeight: FontWeight.w400,
    fontSize: 20,
    height: 1.2,
  );

  /// Estilo H6 Semibold (Outfit, SemiBold, 20px)
  static const TextStyle h6Semibold = TextStyle(
    fontFamily: 'Outfit',
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.2,
  );

  /// Estilo P (Fira Sans, Regular, 16px)
  static const TextStyle paragraph = TextStyle(
    fontFamily: 'Fira Sans',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.3,
  );

  /// Estilo P Bold (Fira Sans, Bold, 16px)
  static const TextStyle paragraphBold = TextStyle(
    fontFamily: 'Fira Sans',
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 1.3,
  );

  /// Estilo Small (Fira Sans, Regular, 12px)
  static const TextStyle small = TextStyle(
    fontFamily: 'Fira Sans',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.3,
  );

  /// Estilo para botão primário
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: 'Outfit',
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.2,
    color: Color(0xFFFFFFFF), // Branco
  );

  /// Estilo para botão secundário
  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: 'Outfit',
    fontWeight: FontWeight.w600,
    fontSize: 20,
    height: 1.2,
    color: Color(0xFFF9F9F9), // Help/White 1
  );

  /// Estilo para texto de ajuda/links
  static const TextStyle helpText = TextStyle(
    fontFamily: 'Fira Sans',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.3,
    color: Color(0xFFF9F9F9), // Help/White 1
    decoration: TextDecoration.underline,
  );

  /// Estilo para placeholder de inputs
  static const TextStyle inputPlaceholder = TextStyle(
    fontFamily: 'Fira Sans',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.3,
    color: Color(0xFF42464D), // Secondary / -1
  );

  /// Estilo para links (sublinhado)
  static const TextStyle link = TextStyle(
    fontFamily: 'Outfit',
    fontWeight: FontWeight.w400,
    fontSize: 20,
    height: 1.2,
    color: Color(0xFF2D3748), // Secondary / 0
    decoration: TextDecoration.underline,
  );
}
