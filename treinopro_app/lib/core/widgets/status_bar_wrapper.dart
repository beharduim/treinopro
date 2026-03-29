import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget wrapper para facilitar o controle da status bar
class StatusBarWrapper extends StatelessWidget {
  final Widget child;
  final bool isDarkBackground;

  const StatusBarWrapper({
    super.key,
    required this.child,
    required this.isDarkBackground,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDarkBackground
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light, // Ícones brancos
              statusBarBrightness: Brightness.dark, // iOS
              systemNavigationBarColor: Colors.black,
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark, // Ícones pretos
              statusBarBrightness: Brightness.light, // iOS
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
      child: child,
    );
  }
}
