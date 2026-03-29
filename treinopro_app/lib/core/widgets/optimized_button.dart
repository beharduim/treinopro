import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/transition_optimizer.dart';

/// Botão otimizado com micro-animações para preparar o sistema
class OptimizedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool enableOptimizations;

  const OptimizedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.enableOptimizations = true,
  });

  @override
  State<OptimizedButton> createState() => _OptimizedButtonState();
}

class _OptimizedButtonState extends State<OptimizedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.onPressed == null) return;

    try {
      // Micro-animação de feedback
      await _animationController.forward();
      await _animationController.reverse();

      // Feedback háptico
      await HapticFeedback.lightImpact();

      // Otimizar para navegação se habilitado
      if (widget.enableOptimizations) {
        await TransitionOptimizer().optimizeForNavigation();
      }

      // Executar callback
      widget.onPressed!();

    } catch (e) {
      debugPrint('Erro no OptimizedButton: $e');
      // Executar callback mesmo com erro
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ElevatedButton(
            onPressed: widget.onPressed == null ? null : _handleTap,
            style: widget.style,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// InkWell otimizado com micro-animações
class OptimizedInkWell extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius? borderRadius;
  final bool enableOptimizations;

  const OptimizedInkWell({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
    this.enableOptimizations = true,
  });

  @override
  State<OptimizedInkWell> createState() => _OptimizedInkWellState();
}

class _OptimizedInkWellState extends State<OptimizedInkWell>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.onTap == null) return;

    try {
      // Micro-animação de feedback
      await _animationController.forward();
      await _animationController.reverse();

      // Feedback háptico leve
      await HapticFeedback.selectionClick();

      // Otimizar para navegação se habilitado
      if (widget.enableOptimizations) {
        await TransitionOptimizer().optimizeForNavigation();
      }

      // Executar callback
      widget.onTap!();

    } catch (e) {
      debugPrint('Erro no OptimizedInkWell: $e');
      // Executar callback mesmo com erro
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap == null ? null : _handleTap,
              borderRadius: widget.borderRadius,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}