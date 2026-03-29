import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget para indicador de páginas do onboarding
class OnboardingPageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPreviousPage;

  const OnboardingPageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPreviousPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppColors.primaryOrange
                : AppColors.secondaryDark.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }
}
