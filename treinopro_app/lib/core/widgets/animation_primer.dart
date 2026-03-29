import 'package:flutter/material.dart';

/// Widget que força uma animação invisível para "acordar" o sistema de animações
class AnimationPrimer extends StatefulWidget {
  final Widget child;
  
  const AnimationPrimer({
    super.key,
    required this.child,
  });

  @override
  State<AnimationPrimer> createState() => _AnimationPrimerState();
}

class _AnimationPrimerState extends State<AnimationPrimer>
    with TickerProviderStateMixin {
  late AnimationController _primerController;
  bool _isPrimed = false;

  @override
  void initState() {
    super.initState();
    
    _primerController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // Executar a animação primer logo após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primeAnimations();
    });
  }

  Future<void> _primeAnimations() async {
    try {
      // Executar uma animação rápida e invisível para "acordar" o sistema
      await _primerController.forward();
      await _primerController.reverse();
      
      // Aguardar um frame adicional
      await WidgetsBinding.instance.endOfFrame;
      
      setState(() {
        _isPrimed = true;
      });
      
      debugPrint('🎬 Sistema de animações ativado');
    } catch (e) {
      debugPrint('Erro no primer de animações: $e');
      setState(() {
        _isPrimed = true;
      });
    }
  }

  @override
  void dispose() {
    _primerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Conteúdo principal
        widget.child,
        
        // Animação primer invisível
        if (!_isPrimed)
          Positioned(
            left: -1000, // Fora da tela
            top: -1000,
            child: AnimatedBuilder(
              animation: _primerController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.5 + (_primerController.value * 0.5),
                  child: Opacity(
                    opacity: _primerController.value,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}