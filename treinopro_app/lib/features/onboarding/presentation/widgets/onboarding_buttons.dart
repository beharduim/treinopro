import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Widget para os botões de navegação do onboarding
class OnboardingButtons extends StatelessWidget {
  final bool canGoPrevious;
  final bool canGoNext;
  final bool isLastPage;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onComplete;

  const OnboardingButtons({
    super.key,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.isLastPage,
    this.onPrevious,
    this.onNext,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Botão principal (Próximo/Finalizar)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLastPage ? onComplete : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                isLastPage ? 'Começar' : 'Próximo',
                style: AppTextStyles.h6Semibold.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Botão secundário (Anterior)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: canGoPrevious ? onPrevious : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: canGoPrevious
                    ? AppColors.secondary
                    : AppColors.secondaryDark.withValues(alpha: 0.5),
                side: BorderSide(
                  color: canGoPrevious
                      ? AppColors.secondary
                      : AppColors.secondaryDark.withValues(alpha: 0.3),
                ),
                backgroundColor: canGoPrevious
                    ? Colors.transparent
                    : AppColors.secondaryDark.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Anterior',
                style: AppTextStyles.h6Semibold.copyWith(
                  color: canGoPrevious
                      ? AppColors.secondary
                      : AppColors.secondaryDark.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
