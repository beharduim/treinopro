import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Widget com botões de navegação do onboarding
class OnboardingNavigationButtons extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onComplete;

  const OnboardingNavigationButtons({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onNext,
    this.onPrevious,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isFirstPage = currentPage == 0;
    final isLastPage = currentPage == totalPages - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16), // left-4 = 16px
      child: Column(
        children: [
          // Botão principal (Próximo/Concluir) - top-[765px] do Figma
          SizedBox(
            width: 380, // w-[380px] do Figma
            child: ElevatedButton(
              onPressed: isLastPage ? onComplete : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange, // #ff8c00
                foregroundColor: Colors.white, // texto branco
                padding: const EdgeInsets.symmetric(vertical: 16), // p-[16px]
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // rounded-lg
                ),
                elevation: 0,
              ),
              child: Text(
                isLastPage ? 'Concluir' : 'Próximo',
                style: AppTextStyles.buttonPrimary.copyWith(
                  color: Colors.white,
                  fontSize: 20, // text-[20px]
                  height: 1.2, // leading-[0]
                ),
              ),
            ),
          ),
          
          // Botão secundário (Anterior) - top-[837px] do Figma
          if (!isFirstPage) ...[
            const SizedBox(height: 16), // Espaçamento entre botões
            SizedBox(
              width: 380, // w-[380px] do Figma
              child: ElevatedButton(
                onPressed: onPrevious,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA4A4A4), // #a4a4a4 do Figma
                  foregroundColor: AppColors.white, // #fffefe
                  padding: const EdgeInsets.symmetric(vertical: 16), // p-[16px]
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // rounded-lg
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Anterior',
                  style: AppTextStyles.buttonSecondary.copyWith(
                    fontSize: 20, // text-[20px]
                    height: 1.2, // leading-[0]
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
