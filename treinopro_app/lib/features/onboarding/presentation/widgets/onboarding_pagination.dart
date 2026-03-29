import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget de paginação para o onboarding
class OnboardingPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const OnboardingPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12, // h-3 = 12px
      width: 56,  // w-14 = 56px
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Evita overflow
        children: List.generate(totalPages, (index) {
          final isActive = index == currentPage;
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2), // Reduzido de 4 para 2
            width: isActive ? 20 : 6, // Reduzido para caber no container
            height: 6, // Reduzido para proporção melhor
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: isActive 
                  ? AppColors.primaryOrange 
                  : AppColors.secondaryDark.withValues(alpha: 0.3),
            ),
          );
        }),
      ),
    );
  }
}
