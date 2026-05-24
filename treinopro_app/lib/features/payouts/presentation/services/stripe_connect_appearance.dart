import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Aparência do Stripe Connect Embedded Components alinhada ao design do TreinoPro.
class StripeConnectAppearance {
  StripeConnectAppearance._();

  static const String locale = 'pt-BR';
  static const String onboardingTitle = 'Configurar recebimento';

  static Map<String, dynamic> toNativeMap() {
    return {
      'locale': locale,
      'title': onboardingTitle,
      'primaryColor': _toHex(AppColors.primaryOrange),
      'secondaryColor': _toHex(AppColors.primaryBlue),
      'backgroundColor': _toHex(AppColors.loginBackground),
      'textColor': _toHex(AppColors.secondaryDarkest),
      'secondaryTextColor': _toHex(AppColors.iconPrimary),
      'dangerColor': _toHex(AppColors.notificationRed),
      'borderColor': '#E2E8F0',
      'formBackgroundColor': _toHex(AppColors.inputBackground),
      'formAccentColor': _toHex(AppColors.primaryOrange),
      'borderRadius': 12.0,
      'spacingUnit': 8.0,
    };
  }

  static String _toHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}
