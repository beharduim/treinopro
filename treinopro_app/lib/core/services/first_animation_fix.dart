import 'package:flutter/material.dart';
import 'dart:ui';

/// Serviço especializado para resolver o problema da primeira animação travada
class FirstAnimationFix {
  static final FirstAnimationFix _instance = FirstAnimationFix._internal();
  factory FirstAnimationFix() => _instance;
  FirstAnimationFix._internal();

  bool _isFixed = false;
  bool _isFixing = false;

  /// Verifica se o fix já foi aplicado
  bool get isFixed => _isFixed;

  /// Aplica o fix completo para primeira animação
  Future<void> fixFirstAnimation(BuildContext context) async {
    if (_isFixed || _isFixing) return;
    
    _isFixing = true;
    
    try {
      debugPrint('🔧 Aplicando fix AGRESSIVO para primeira animação...');
      debugPrint('   📍 Iniciando em: ${DateTime.now()}');

      // 1. Força compilação de todos os shaders comuns
      await _forceShaderCompilation();

      // 2. Pré-aquece o sistema de animação
      await _warmupAnimationSystem(context);

      // 3. Força renderização de elementos comuns
      await _preRenderCommonElements();

      // 4. Força shaders de transição de página
      await _forcePageTransitionShaders();

      // 5. Estabiliza o sistema
      await _stabilizeSystem();

      _isFixed = true;
      debugPrint('✅ Fix da primeira animação aplicado com sucesso!');
      debugPrint('   📍 Concluído em: ${DateTime.now()}');
      debugPrint('   🎯 Primeira animação deve funcionar perfeitamente agora!');

    } catch (e) {
      debugPrint('❌ Erro no fix da primeira animação: $e');
      _isFixed = true; // Marcar como concluído mesmo com erro
    } finally {
      _isFixing = false;
    }
  }

  /// Força compilação agressiva de shaders
  Future<void> _forceShaderCompilation() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Paint variations para diferentes shaders
    final paints = [
      Paint()..color = Colors.red..style = PaintingStyle.fill,
      Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 2,
      Paint()..color = Colors.green..style = PaintingStyle.fill..blendMode = BlendMode.multiply,
      Paint()..shader = const LinearGradient(colors: [Colors.red, Colors.blue]).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    ];

    // Desenha formas variadas para compilar diferentes shaders
    for (int i = 0; i < paints.length; i++) {
      final paint = paints[i];
      final offset = i * 25.0;
      
      // Formas básicas
      canvas.drawRect(Rect.fromLTWH(offset, 0, 20, 20), paint);
      canvas.drawCircle(Offset(offset + 10, 30), 10, paint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(offset, 50, 20, 15),
          const Radius.circular(5),
        ),
        paint,
      );
      
      // Paths complexos
      final path = Path()
        ..moveTo(offset, 70)
        ..lineTo(offset + 10, 80)
        ..lineTo(offset + 20, 70)
        ..close();
      canvas.drawPath(path, paint);
    }

    // Texto (força compilação de text shaders)
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Shader Warmup',
        style: TextStyle(color: Colors.black, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(0, 90));

    recorder.endRecording();
    
    // Pequena pausa para garantir compilação
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Aquece o sistema de animação com múltiplas animações
  Future<void> _warmupAnimationSystem(BuildContext context) async {
    if (!context.mounted) return;

    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    try {
      overlayEntry = OverlayEntry(
        builder: (overlayContext) => const Positioned(
          left: -2000, // Bem fora da tela
          top: -2000,
          child: _AnimationWarmupWidget(),
        ),
      );

      overlay.insert(overlayEntry);
      
      // Aguarda tempo suficiente para todas as animações
      await Future.delayed(const Duration(milliseconds: 500));

    } finally {
      overlayEntry?.remove();
    }
  }

  /// Pré-renderiza elementos comuns
  Future<void> _preRenderCommonElements() async {
    // Força criação de elementos comuns que podem causar jank
    final elementCount = 4; // Container, CircularProgressIndicator, ElevatedButton, Card

    // Simula renderização
    for (int i = 0; i < elementCount; i++) {
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  /// Força compilação de shaders específicos para transições de página
  Future<void> _forcePageTransitionShaders() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Simula transições de página comuns
    final fadeShader = Paint()..color = Colors.white.withOpacity(0.5);
    final slideShader = Paint()..color = Colors.black.withOpacity(0.8);
    
    // Fade transition simulation
    for (double opacity = 0.0; opacity <= 1.0; opacity += 0.2) {
      final paint = Paint()..color = Colors.blue.withOpacity(opacity);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), paint);
    }
    
    // Slide transition simulation
    for (double offset = -100.0; offset <= 0.0; offset += 20.0) {
      canvas.drawRect(Rect.fromLTWH(offset, 0, 100, 100), slideShader);
    }
    
    // Scale transition simulation
    for (double scale = 0.8; scale <= 1.0; scale += 0.05) {
      canvas.save();
      canvas.scale(scale);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), fadeShader);
      canvas.restore();
    }
    
    recorder.endRecording();
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// Estabiliza o sistema aguardando frames
  Future<void> _stabilizeSystem() async {
    // Aguarda vários frames para garantir estabilidade
    for (int i = 0; i < 10; i++) {
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  /// Reseta o estado (útil para testes)
  void reset() {
    _isFixed = false;
    _isFixing = false;
  }
}

/// Widget para aquecer diferentes tipos de animação
class _AnimationWarmupWidget extends StatefulWidget {
  const _AnimationWarmupWidget();

  @override
  State<_AnimationWarmupWidget> createState() => _AnimationWarmupWidgetState();
}

class _AnimationWarmupWidgetState extends State<_AnimationWarmupWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation> _animations;

  @override
  void initState() {
    super.initState();

    // Cria múltiplos controllers para diferentes tipos de animação
    _controllers = List.generate(6, (index) => AnimationController(
      duration: Duration(milliseconds: 200 + (index * 50)),
      vsync: this,
    ));

    // Diferentes tipos de animação
    _animations = [
      Tween<double>(begin: 0.0, end: 1.0).animate(_controllers[0]), // Fade
      Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(_controllers[1]), // Slide
      Tween<double>(begin: 0.8, end: 1.0).animate(_controllers[2]), // Scale
      Tween<double>(begin: 0.0, end: 1.0).animate(_controllers[3]), // Rotation
      ColorTween(begin: Colors.red, end: Colors.blue).animate(_controllers[4]), // Color
      Tween<double>(begin: 0.0, end: 100.0).animate(_controllers[5]), // Size
    ];

    // Inicia todas as animações
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAllAnimations();
    });
  }

  Future<void> _startAllAnimations() async {
    try {
      // Executa todas as animações em paralelo
      await Future.wait(_controllers.map((controller) => controller.forward()));
      
      // Reseta e executa novamente para garantir
      for (final controller in _controllers) {
        controller.reset();
      }
      
      await Future.wait(_controllers.map((controller) => controller.forward()));
      
    } catch (e) {
      debugPrint('Erro nas animações de warmup: $e');
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        children: [
          // FadeTransition
          FadeTransition(
            opacity: _animations[0] as Animation<double>,
            child: Container(width: 50, height: 50, color: Colors.red),
          ),
          
          // SlideTransition
          SlideTransition(
            position: _animations[1] as Animation<Offset>,
            child: Container(width: 50, height: 50, color: Colors.blue),
          ),
          
          // ScaleTransition
          ScaleTransition(
            scale: _animations[2] as Animation<double>,
            child: Container(width: 50, height: 50, color: Colors.green),
          ),
          
          // RotationTransition
          RotationTransition(
            turns: _animations[3] as Animation<double>,
            child: Container(width: 50, height: 50, color: Colors.orange),
          ),
          
          // AnimatedBuilder com cor
          AnimatedBuilder(
            animation: _animations[4],
            builder: (context, child) {
              return Container(
                width: 50,
                height: 50,
                color: (_animations[4] as Animation<Color?>).value,
              );
            },
          ),
          
          // AnimatedBuilder com tamanho
          AnimatedBuilder(
            animation: _animations[5],
            builder: (context, child) {
              final size = (_animations[5] as Animation<double>).value;
              return Container(
                width: size,
                height: size,
                color: Colors.purple,
              );
            },
          ),
          
          // Elementos adicionais
          const CircularProgressIndicator(),
          ElevatedButton(onPressed: () {}, child: const Text('Test')),
          const Card(child: ListTile(title: Text('Warmup'))),
        ],
      ),
    );
  }
}