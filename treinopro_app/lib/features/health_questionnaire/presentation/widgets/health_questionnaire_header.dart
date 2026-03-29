import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Header informativo do questionário de saúde
class HealthQuestionnaireHeader extends StatelessWidget {
  const HealthQuestionnaireHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Ícone e título
          Row(
            children: [
              Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.shield,
                  color: AppColors.secondary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sua segurança é nossa prioridade',
                  style: AppTextStyles.paragraphBold.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Descrição
          Text(
            'Este questionário nos ajuda a entender melhor seu perfil de saúde para garantir que você tenha a experiência de treino mais segura e personalizada possível.',
            style: AppTextStyles.small.copyWith(
              color: AppColors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
