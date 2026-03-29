import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Logo animado otimizado para melhor performance
class AnimatedLogo extends StatefulWidget {
  final double size;
  final bool isVisible;
  final Duration animationDuration;

  const AnimatedLogo({
    super.key,
    this.size = 160,
    this.isVisible = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Image.asset(
                  AppAssets.logo,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'TreinoPro',
                          style: AppTextStyles.h6Semibold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}