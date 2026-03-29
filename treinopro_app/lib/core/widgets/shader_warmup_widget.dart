import 'package:flutter/material.dart';

/// Widget invisível para pré-aquecer shaders específicos
class ShaderWarmupWidget extends StatefulWidget {
  const ShaderWarmupWidget({super.key});

  @override
  State<ShaderWarmupWidget> createState() => _ShaderWarmupWidgetState();
}

class _ShaderWarmupWidgetState extends State<ShaderWarmupWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    
    // Criar controladores de animação reais
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Iniciar as animações para forçar a compilação dos shaders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warmUpAnimations();
    });
  }

  void _warmUpAnimations() async {
    try {
      // Executar animações rapidamente para compilar shaders
      await Future.wait([
        _fadeController.forward(),
        _slideController.forward(),
        _scaleController.forward(),
      ]);
      
      // Resetar para o estado inicial
      _fadeController.reset();
      _slideController.reset();
      _scaleController.reset();
    } catch (e) {
      debugPrint('Erro no pré-aquecimento de animações: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.0, // Invisível
      child: SizedBox(
        width: 1,
        height: 1,
        child: Stack(
          children: [
            // Pré-aquece FadeTransition com animação real
            FadeTransition(
              opacity: _fadeController,
              child: Container(
                width: 100,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            // Pré-aquece SlideTransition com animação real
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(_slideController),
              child: Container(
                width: 100,
                height: 50,
                color: Colors.blue,
              ),
            ),
            
            // Pré-aquece ScaleTransition com animação real
            ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(_scaleController),
              child: Container(
                width: 100,
                height: 50,
                color: Colors.green,
              ),
            ),
            
            // Pré-aquece Material com InkWell
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
            
            // Pré-aquece gradientes
            Container(
              width: 100,
              height: 50,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.pink],
                ),
              ),
            ),
            
            // Pré-aquece ElevatedButton
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Test'),
            ),
          ],
        ),
      ),
    );
  }
}