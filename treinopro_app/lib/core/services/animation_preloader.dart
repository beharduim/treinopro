import 'package:flutter/material.dart';

/// Serviço para pré-carregar animações e evitar travamentos
class AnimationPreloader {
  static final AnimationPreloader _instance = AnimationPreloader._internal();
  factory AnimationPreloader() => _instance;
  AnimationPreloader._internal();

  bool _isPreloaded = false;

  /// Verifica se as animações já foram pré-carregadas
  bool get isPreloaded => _isPreloaded;

  /// Pré-carrega animações forçando a renderização
  Future<void> preloadAnimations(BuildContext context) async {
    if (_isPreloaded) return;

    try {
      debugPrint('🎬 Iniciando pré-carregamento de animações...');

      // Aguardar que o sistema esteja pronto
      await WidgetsBinding.instance.endOfFrame;
      
      // Forçar a renderização de widgets com animações
      await _forceRenderAnimations(context);
      
      // Aguardar alguns frames para garantir que tudo foi renderizado
      for (int i = 0; i < 3; i++) {
        await WidgetsBinding.instance.endOfFrame;
      }

      _isPreloaded = true;
      debugPrint('✅ Pré-carregamento de animações concluído');

    } catch (e) {
      debugPrint('❌ Erro no pré-carregamento de animações: $e');
      _isPreloaded = true; // Marcar como concluído mesmo com erro
    }
  }

  /// Força a renderização de animações off-screen
  Future<void> _forceRenderAnimations(BuildContext context) async {
    if (!context.mounted) return;
    
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    try {
      // Criar um overlay invisível com animações
      overlayEntry = OverlayEntry(
        builder: (overlayContext) => const Positioned(
          left: -1000, // Fora da tela
          top: -1000,
          child: _AnimationPreloadWidget(),
        ),
      );

      // Inserir o overlay
      overlay.insert(overlayEntry);

      // Aguardar alguns frames para renderização
      await Future.delayed(const Duration(milliseconds: 200));

    } finally {
      // Remover o overlay
      overlayEntry?.remove();
    }
  }
}

/// Widget invisível para pré-carregar animações
class _AnimationPreloadWidget extends StatefulWidget {
  const _AnimationPreloadWidget();

  @override
  State<_AnimationPreloadWidget> createState() => _AnimationPreloadWidgetState();
}

class _AnimationPreloadWidgetState extends State<_AnimationPreloadWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();

    _controller1 = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _controller2 = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _controller3 = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Iniciar animações imediatamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations();
    });
  }

  void _startAnimations() async {
    try {
      // Executar animações em paralelo
      await Future.wait([
        _controller1.forward(),
        _controller2.forward(),
        _controller3.forward(),
      ]);

      // Resetar
      _controller1.reset();
      _controller2.reset();
      _controller3.reset();

      // Executar novamente para garantir
      await Future.wait([
        _controller1.forward(),
        _controller2.forward(),
        _controller3.forward(),
      ]);

    } catch (e) {
      debugPrint('Erro nas animações de pré-carregamento: $e');
    }
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        children: [
          // FadeTransition
          FadeTransition(
            opacity: _controller1,
            child: Container(
              width: 100,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // SlideTransition
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(_controller2),
            child: Container(
              width: 100,
              height: 50,
              color: Colors.blue,
            ),
          ),

          // ScaleTransition
          ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(_controller3),
            child: Container(
              width: 100,
              height: 50,
              color: Colors.green,
            ),
          ),

          // Material com InkWell
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 100,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // ElevatedButton
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Test'),
          ),

          // Container com fundo para simular navegação
          Container(
            width: 200,
            height: 200,
            color: const Color(0xFFFCFDFE), // Mesmo fundo das páginas
            child: FadeTransition(
              opacity: _controller1,
              child: Container(
                width: 150,
                height: 150,
                color: Colors.white,
                child: const Center(
                  child: Text('Navigation Test'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}