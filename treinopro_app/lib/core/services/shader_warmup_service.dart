import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Serviço para pré-aquecer shaders e evitar travamentos nas animações
class ShaderWarmupService {
  static final ShaderWarmupService _instance = ShaderWarmupService._internal();
  factory ShaderWarmupService() => _instance;
  ShaderWarmupService._internal();

  bool _isWarmedUp = false;

  /// Verifica se os shaders já foram pré-aquecidos
  bool get isWarmedUp => _isWarmedUp;

  /// Pré-aquece os shaders mais comuns usados no app
  Future<void> warmUpShaders() async {
    if (_isWarmedUp) return;

    try {
      debugPrint('🔥 Iniciando pré-aquecimento de shaders...');
      
      // Aguardar alguns frames para garantir que o contexto está disponível
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Usar uma abordagem mais direta: forçar a renderização de widgets comuns
      await _forceRenderCommonWidgets();
      
      // Pré-aquecer shaders customizados
      await warmUpCustomShaders();
      
      _isWarmedUp = true;
      debugPrint('✅ Pré-aquecimento de shaders concluído');
      
    } catch (e) {
      debugPrint('❌ Erro no pré-aquecimento de shaders: $e');
      // Marcar como aquecido mesmo com erro para não tentar novamente
      _isWarmedUp = true;
    }
  }

  /// Força a renderização de widgets comuns para compilar shaders
  Future<void> _forceRenderCommonWidgets() async {
    try {
      // Criar um contexto de pintura temporário
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Simular a renderização de widgets comuns
      final paint = Paint();
      
      // Renderizar retângulos com bordas arredondadas (botões)
      paint.color = Colors.orange;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 200, 50),
          const Radius.circular(8),
        ),
        paint,
      );
      
      // Renderizar círculos (avatars, ícones)
      paint.color = Colors.blue;
      canvas.drawCircle(const Offset(100, 100), 25, paint);
      
      // Renderizar gradientes
      paint.shader = const LinearGradient(
        colors: [Colors.purple, Colors.pink],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
      canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), paint);
      
      // Finalizar e descartar
      final picture = recorder.endRecording();
      await picture.toImage(200, 200);
      picture.dispose();
      
    } catch (e) {
      debugPrint('Erro ao forçar renderização: $e');
    }
  }

  /// Pré-aquece FadeTransition
  Future<void> _warmUpFadeTransition() async {
    return _warmUpWidget(
      const FadeTransition(
        opacity: AlwaysStoppedAnimation(0.5),
        child: SizedBox(width: 100, height: 100, child: ColoredBox(color: Colors.blue)),
      ),
    );
  }

  /// Pré-aquece SlideTransition
  Future<void> _warmUpSlideTransition() async {
    return _warmUpWidget(
      const SlideTransition(
        position: AlwaysStoppedAnimation(Offset(0.5, 0.0)),
        child: SizedBox(width: 100, height: 100, child: ColoredBox(color: Colors.red)),
      ),
    );
  }

  /// Pré-aquece ScaleTransition
  Future<void> _warmUpScaleTransition() async {
    return _warmUpWidget(
      const ScaleTransition(
        scale: AlwaysStoppedAnimation(0.8),
        child: SizedBox(width: 100, height: 100, child: ColoredBox(color: Colors.green)),
      ),
    );
  }

  /// Pré-aquece RotationTransition
  Future<void> _warmUpRotationTransition() async {
    return _warmUpWidget(
      const RotationTransition(
        turns: AlwaysStoppedAnimation(0.1),
        child: SizedBox(width: 100, height: 100, child: ColoredBox(color: Colors.yellow)),
      ),
    );
  }

  /// Pré-aquece BorderRadius (botões arredondados)
  Future<void> _warmUpBorderRadius() async {
    return _warmUpWidget(
      Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  /// Pré-aquece efeito ripple (InkWell)
  Future<void> _warmUpRippleEffect() async {
    return _warmUpWidget(
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 100,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  /// Pré-aquece gradientes
  Future<void> _warmUpGradients() async {
    return _warmUpWidget(
      Container(
        width: 100,
        height: 100,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.pink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  /// Renderiza um widget off-screen para compilar seus shaders
  Future<void> _warmUpWidget(Widget widget) async {
    try {
      // Criar um RepaintBoundary para capturar o widget
      final repaintBoundary = RepaintBoundary(child: widget);
      
      // Criar um elemento temporário
      final element = repaintBoundary.createElement();
      
      // Montar o elemento
      element.mount(null, null);
      
      // Aguardar um frame para garantir que foi renderizado
      await WidgetsBinding.instance.endOfFrame;
      
      // Desmontar o elemento
      element.unmount();
      
    } catch (e) {
      // Ignora erros individuais
      debugPrint('Erro ao pré-aquecer widget: $e');
    }
  }

  /// Força a compilação de shaders específicos usando drawPath
  Future<void> warmUpCustomShaders() async {
    try {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;

      // Desenhar formas comuns para compilar shaders
      canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), paint);
      canvas.drawCircle(const Offset(50, 50), 25, paint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 100, 50),
          const Radius.circular(8),
        ),
        paint,
      );

      // Finalizar a gravação
      final picture = recorder.endRecording();
      
      // Converter para imagem para forçar a renderização
      await picture.toImage(100, 100);
      
      picture.dispose();
      
    } catch (e) {
      debugPrint('Erro ao pré-aquecer shaders customizados: $e');
    }
  }
}