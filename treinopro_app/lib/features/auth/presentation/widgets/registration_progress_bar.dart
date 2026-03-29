import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';

/// Widget da barra de progresso para o cadastro
class RegistrationProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const RegistrationProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Texto do progresso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Etapa $currentStep de $totalSteps',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.secondaryDark,
                  fontSize: 14,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Barra de progresso
          Container(
            width: double.infinity,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
