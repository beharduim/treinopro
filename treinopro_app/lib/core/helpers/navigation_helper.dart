import 'package:flutter/material.dart';

/// Helper para navegação otimizada
/// 
/// IMPORTANTE: Para resolver o problema da primeira animação do botão "Já tenho conta",
/// use o método pushToLogin() que replica exatamente a implementação que funciona.
/// 
/// Exemplo de uso:
/// ```dart
/// // Em vez de:
/// Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage()));
/// 
/// // Use:
/// NavigationHelper.pushToLogin(context, const LoginPage());
/// ```
class NavigationHelper {
  /// Navegação com fade otimizada (implementação robusta)
  static Future<T?> pushWithFade<T extends Object?>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 450),
    Color? backgroundColor,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        opaque: false, // Mantém a tela anterior visível durante a transição
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: Container(
              color: backgroundColor ?? const Color(0xFFFCFDFE), // Fundo explícito
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Navegação com replacement e fade (implementação robusta)
  static Future<T?> pushReplacementWithFade<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 450),
    Color? backgroundColor,
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        opaque: false, // Mantém a tela anterior visível durante a transição
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: Container(
              color: backgroundColor ?? const Color(0xFFFCFDFE), // Fundo explícito
              child: child,
            ),
          );
        },
      ),
      result: result,
    );
  }

  /// Navegação com slide otimizada (implementação robusta)
  static Future<T?> pushWithSlide<T extends Object?>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 450),
    Offset begin = const Offset(1.0, 0.0),
    Color? backgroundColor,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        opaque: false, // Mantém a tela anterior visível durante a transição
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeInOutCubic; // Curva mais suave e consistente

          var tween = Tween(
            begin: begin,
            end: Offset.zero,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: Container(
              color: backgroundColor ?? const Color(0xFFFCFDFE), // Fundo explícito
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Navegação com scale otimizada (implementação robusta)
  static Future<T?> pushWithScale<T extends Object?>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 450),
    Color? backgroundColor,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        opaque: false, // Mantém a tela anterior visível durante a transição
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: Container(
                color: backgroundColor ?? const Color(0xFFFCFDFE), // Fundo explícito
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Navegação específica para "Já tenho conta" - replica exatamente a implementação que funciona
  static Future<T?> pushToLogin<T extends Object?>(
    BuildContext context,
    Widget page,
  ) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 450),
        opaque: false, // Mantém a tela anterior visível durante a transição
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic; // Curva mais suave e consistente

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: Container(
              color: const Color(0xFFFCFDFE), // Fundo da nova tela
              child: child,
            ),
          );
        },
      ),
    );
  }
}