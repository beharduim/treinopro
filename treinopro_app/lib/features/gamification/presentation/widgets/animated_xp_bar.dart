import 'package:flutter/material.dart';

/// Widget de barra de XP animada
class AnimatedXPBar extends StatefulWidget {
  final double currentXP;
  final double maxXP;
  final double? previousXP;
  final Color? color;
  final Color? trackColor;
  final double height;
  final BorderRadius? borderRadius;

  const AnimatedXPBar({
    super.key,
    required this.currentXP,
    required this.maxXP,
    this.previousXP,
    this.color,
    this.trackColor,
    this.height = 8.0,
    this.borderRadius,
  });

  @override
  State<AnimatedXPBar> createState() => _AnimatedXPBarState();
}

class _AnimatedXPBarState extends State<AnimatedXPBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  
  double _displayedXP = 0.0;
  double _startXP = 0.0;
  double _targetXP = 0.0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _displayedXP = widget.previousXP ?? widget.currentXP;
    _startXP = _displayedXP;
    _targetXP = widget.currentXP;
    
    // Iniciar animação se há diferença entre XP anterior e atual
    if (widget.previousXP != null && widget.previousXP != widget.currentXP) {
      _animateXPChange();
    }
  }

  @override
  void didUpdateWidget(AnimatedXPBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Se o XP mudou, animar a transição
    if (oldWidget.currentXP != widget.currentXP) {
      _animateXPChange();
    }
  }

  void _animateXPChange() {
    if (_isAnimating) return;
    
    setState(() {
      _isAnimating = true;
      _startXP = _displayedXP;
      _targetXP = widget.currentXP;
    });
    
    _animationController.forward().then((_) {
      setState(() {
        _displayedXP = widget.currentXP;
        _isAnimating = false;
      });
      
      _animationController.reverse();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double startProgress = widget.maxXP > 0 ? (_startXP / widget.maxXP).clamp(0.0, 1.0) : 0.0;
    final double endProgress = widget.maxXP > 0
        ? ((_isAnimating ? _targetXP : _displayedXP) / widget.maxXP).clamp(0.0, 1.0)
        : 0.0;
    final double t = _isAnimating ? _progressAnimation.value : 1.0;
    final double effectiveFactor = startProgress + (endProgress - startProgress) * t;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.trackColor ?? Colors.white.withOpacity(0.18),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1,
            ),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: effectiveFactor.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: widget.color ?? Colors.white,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
                boxShadow: _isAnimating ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.45),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ] : null,
              ),
              child: _isAnimating ? _buildSparkleEffect() : null,
            ),
          ),
        );
      },
    );
  }

  /// Efeito de brilho durante a animação
  Widget _buildSparkleEffect() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.8),
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

/// Widget de texto de XP animado
class AnimatedXPText extends StatefulWidget {
  final double currentXP;
  final double? previousXP;
  final TextStyle? style;
  final Duration animationDuration;

  const AnimatedXPText({
    super.key,
    required this.currentXP,
    this.previousXP,
    this.style,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedXPText> createState() => _AnimatedXPTextState();
}

class _AnimatedXPTextState extends State<AnimatedXPText>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _valueAnimation;
  late Animation<double> _scaleAnimation;
  
  double _displayedXP = 0.0;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _valueAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _displayedXP = widget.previousXP ?? widget.currentXP;
    
    // Iniciar animação se há diferença entre XP anterior e atual
    if (widget.previousXP != null && widget.previousXP != widget.currentXP) {
      _animateXPChange();
    }
  }

  @override
  void didUpdateWidget(AnimatedXPText oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Se o XP mudou, animar a transição
    if (oldWidget.currentXP != widget.currentXP) {
      _animateXPChange();
    }
  }

  void _animateXPChange() {
    _animationController.forward().then((_) {
      setState(() {
        _displayedXP = widget.currentXP;
      });
      
      _animationController.reverse();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animatedXP = _displayedXP + (_valueAnimation.value * (widget.currentXP - _displayedXP));
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Text(
            '${animatedXP.round()} XP',
            style: widget.style,
          ),
        );
      },
    );
  }
}
