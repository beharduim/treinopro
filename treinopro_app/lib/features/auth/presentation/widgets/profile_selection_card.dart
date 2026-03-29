import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Widget para o card de seleção de perfil
class ProfileSelectionCard extends StatefulWidget {
  final String imagePath;
  final String title;
  final String description;
  final VoidCallback onTap;

  const ProfileSelectionCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  State<ProfileSelectionCard> createState() => _ProfileSelectionCardState();
}

class _ProfileSelectionCardState extends State<ProfileSelectionCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
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
    widget.onTap();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 144, // Mantém o visual do Figma sem travar layout
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondaryDark, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.32),
                    offset: const Offset(-1, 1),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Imagem do perfil
                  ClipOval(
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.asset(
                        widget.imagePath,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        alignment: widget.imagePath.contains('student')
                            ? Alignment
                                  .center // Centralizado para aluno
                            : Alignment
                                  .topCenter, // Parte superior para personal trainer
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Textos
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTextStyles.h6Semibold.copyWith(
                            color: AppColors.secondaryDarkest,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          widget.description,
                          style: AppTextStyles.paragraph.copyWith(
                            color: AppColors.secondaryDarkest,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
