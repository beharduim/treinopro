import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Modal de aviso "Gamificação em Desenvolvimento".
///
/// Exibe título, descrição e botão "Entendi". A regra de
/// exibição (1x por sessão) é controlada externamente pelo
/// [GamificationDevNoticeCoordinator].
class GamificationDevNoticeModal extends StatefulWidget {
  const GamificationDevNoticeModal({super.key});

  // Textos centralizados — única fonte de verdade para o contrato de UX.
  static const String title = 'Gamificação em Desenvolvimento';
  static const String body =
      'Missões semanais, XP e benefícios estão em desenvolvimento e serão liberados em breve.';
  static const String cta = 'Entendi';

  @override
  State<GamificationDevNoticeModal> createState() =>
      _GamificationDevNoticeModalState();
}

class _GamificationDevNoticeModalState extends State<GamificationDevNoticeModal>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _iconScaleAnimation;
  late final Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );
    // Ícone com bounce mais evidente.
    _iconScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.72,
          end: 1.20,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.20,
          end: 0.93,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.93,
          end: 1.00,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_entryController);

    // Pequena rotação para reforçar sensação de movimento.
    _iconRotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -0.10,
          end: 0.09,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.09,
          end: -0.04,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -0.04,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(_entryController);

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone decorativo com pulso suave.
                  AnimatedBuilder(
                    animation: _entryController,
                    builder: (_, child) => Transform.scale(
                      scale: _iconScaleAnimation.value,
                      child: Transform.rotate(
                        angle: _iconRotationAnimation.value,
                        child: child,
                      ),
                    ),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withOpacity(0.20),
                            blurRadius: 18,
                            spreadRadius: 1.5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.construction_rounded,
                        color: AppColors.primaryOrange,
                        size: 36,
                        semanticLabel: 'Em desenvolvimento',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    GamificationDevNoticeModal.title,
                    style: AppTextStyles.h6Semibold.copyWith(
                      fontSize: 18,
                      color: const Color(0xFF1A202C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    GamificationDevNoticeModal.body,
                    style: AppTextStyles.paragraph.copyWith(
                      color: const Color(0xFF4A5568),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        GamificationDevNoticeModal.cta,
                        style: TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
