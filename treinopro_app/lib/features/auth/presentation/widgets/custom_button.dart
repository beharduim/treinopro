import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Widget de botão customizado seguindo o design do Figma
class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isPrimary
                      ? AppColors.primaryOrange
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: widget.isPrimary
                      ? null
                      : Border.all(color: AppColors.white, width: 2),
                ),
                child: Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: widget.isPrimary
                      ? AppTextStyles.buttonPrimary
                      : AppTextStyles.buttonSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
