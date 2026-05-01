import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Barra de progresso para as etapas da proposta
class ProposalProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;

  const ProposalProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Títulos das etapas com ícones
        Row(
          children: List.generate(totalSteps, (index) {
            final stepNumber = index + 1;
            final isCompleted = stepNumber < currentStep;
            final isCurrent = stepNumber == currentStep;
            final title = index < stepTitles.length
                ? stepTitles[index]
                : 'Etapa $stepNumber';

            return Expanded(
              child: Column(
                children: [
                  // Ícone e título da etapa
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ícone da etapa
                      Icon(
                        isCompleted
                            ? Icons.check_circle
                            : _getStepIcon(stepNumber),
                        color: isCompleted || isCurrent
                            ? AppColors.primaryOrange
                            : AppColors.secondaryDark.withOpacity(0.4),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      // Título da etapa
                      Flexible(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.small.copyWith(
                            color: isCompleted || isCurrent
                                ? AppColors.secondary
                                : AppColors.secondaryDark.withOpacity(0.6),
                            fontWeight: isCurrent
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Indicador de etapa ativa (borda laranja)
                  if (isCurrent)
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    )
                  else
                    const SizedBox(height: 3),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  /// Retorna o ícone temático para cada etapa
  IconData _getStepIcon(int stepNumber) {
    switch (stepNumber) {
      case 1:
        return Icons.location_on; // Onde e Quando
      case 2:
        return Icons.fitness_center; // Como será
      case 3:
        return Icons.attach_money; // Quanto custa
      case 4:
        return Icons.description; // Revisão
      default:
        return Icons.circle;
    }
  }
}
