import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Mixin para otimizar animações e evitar travamentos
mixin AnimationOptimizationMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  final List<AnimationController> _controllers = [];
  bool _isDisposed = false;

  /// Cria um AnimationController otimizado
  AnimationController createOptimizedController({
    required Duration duration,
    Duration? reverseDuration,
    String? debugLabel,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    final controller = AnimationController(
      duration: duration,
      reverseDuration: reverseDuration,
      debugLabel: debugLabel,
      lowerBound: lowerBound,
      upperBound: upperBound,
      vsync: this,
      animationBehavior: animationBehavior,
    );
    
    _controllers.add(controller);
    return controller;
  }

  /// Executa animação apenas se o widget ainda estiver montado
  void safeAnimate(VoidCallback animation) {
    if (!_isDisposed && mounted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed && mounted) {
          animation();
        }
      });
    }
  }

  /// Para todas as animações de forma segura
  void stopAllAnimations() {
    for (final controller in _controllers) {
      if (!controller.isCompleted && !controller.isDismissed) {
        controller.stop();
      }
    }
  }

  /// Pausa todas as animações
  void pauseAllAnimations() {
    for (final controller in _controllers) {
      if (controller.isAnimating) {
        controller.stop();
      }
    }
  }

  /// Retoma todas as animações pausadas
  void resumeAllAnimations() {
    for (final controller in _controllers) {
      if (!controller.isCompleted && !controller.isDismissed) {
        controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    stopAllAnimations();
    
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    
    super.dispose();
  }

  /// Verifica se as animações devem ser reduzidas (acessibilidade)
  bool get shouldReduceAnimations {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  /// Duração ajustada baseada nas configurações de acessibilidade
  Duration getAdjustedDuration(Duration original) {
    if (shouldReduceAnimations) {
      return Duration(milliseconds: (original.inMilliseconds * 0.3).round());
    }
    return original;
  }
}