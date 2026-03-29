import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Serviço simples para pré-aquecer animações
class SimpleAnimationWarmup {
  static bool _isWarmedUp = false;

  /// Pré-aquece animações de forma simples e direta
  static Future<void> warmUp() async {
    if (_isWarmedUp) return;

    try {
      debugPrint('🔥 Pré-aquecendo animações...');

      // Aguardar que o scheduler esteja pronto
      await SchedulerBinding.instance.endOfFrame;

      // Forçar a criação de alguns objetos de animação comuns
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: const _DummyTickerProvider(),
      );

      // Criar animações comuns
      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(controller);
      final slideAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(controller);
      final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(controller);

      // Forçar a avaliação das animações
      fadeAnimation.value;
      slideAnimation.value;
      scaleAnimation.value;

      // Executar uma animação rápida
      await controller.forward();
      controller.reset();

      controller.dispose();

      _isWarmedUp = true;
      debugPrint('✅ Animações pré-aquecidas');

    } catch (e) {
      debugPrint('❌ Erro no pré-aquecimento: $e');
      _isWarmedUp = true; // Marcar como concluído mesmo com erro
    }
  }

  /// Reseta o estado (útil para testes)
  static void reset() {
    _isWarmedUp = false;
  }
}

/// TickerProvider dummy para o pré-aquecimento
class _DummyTickerProvider implements TickerProvider {
  const _DummyTickerProvider();

  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}