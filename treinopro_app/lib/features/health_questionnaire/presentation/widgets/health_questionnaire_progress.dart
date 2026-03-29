import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Barra de progresso do questionário de saúde
class HealthQuestionnaireProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const HealthQuestionnaireProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Indicador de etapas
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (index) {
            final stepNumber = index + 1;
            final isActive = stepNumber == currentStep;
            final isCompleted = stepNumber < currentStep;
            
            return Row(
              children: [
                // Círculo da etapa
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? AppColors.primaryOrange 
                        : isActive 
                            ? AppColors.primaryOrange 
                            : AppColors.inputBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive || isCompleted 
                          ? AppColors.primaryOrange 
                          : AppColors.secondaryDark.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : Text(
                            stepNumber.toString(),
                            style: TextStyle(
                              color: isActive || isCompleted 
                                  ? Colors.white 
                                  : AppColors.secondaryDark.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                
                // Linha conectora (exceto para a última etapa)
                if (stepNumber < totalSteps)
                  Container(
                    width: 40,
                    height: 2,
                    color: isCompleted 
                        ? AppColors.primaryOrange 
                        : AppColors.inputBackground,
                  ),
              ],
            );
          }),
        ),
        
        const SizedBox(height: 16),
        
        // Texto da etapa atual
        Text(
          _getStepTitle(currentStep),
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Descrição da etapa
        Text(
          _getStepDescription(currentStep),
          style: TextStyle(
            color: AppColors.secondaryDark.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Informações básicas';
      case 2:
        return 'Condições físicas';
      case 3:
        return 'Alimentação';
      default:
        return 'Etapa $step';
    }
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 1:
        return 'Conte-nos sobre suas condições médicas e medicamentos';
      case 2:
        return 'Informe sobre lesões e objetivos de treino';
      case 3:
        return 'Compartilhe suas restrições alimentares';
      default:
        return 'Complete esta etapa para continuar';
    }
  }
}
