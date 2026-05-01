import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/training_modality.dart';

/// Seletor de modalidade de treino com ícones visuais
class ModalitySelector extends StatelessWidget {
  final TrainingModality? selectedModality;
  final List<TrainingModality> modalities;
  final ValueChanged<TrainingModality> onModalitySelected;
  final bool isLoading;

  const ModalitySelector({
    super.key,
    this.selectedModality,
    required this.modalities,
    required this.onModalitySelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 modalidades por linha
        childAspectRatio: 0.9, // Ajustado para cards maiores
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: modalities.length,
      itemBuilder: (context, index) {
        final modality = modalities[index];
        final isSelected = selectedModality?.id == modality.id;

        return _ModalityCard(
          modality: modality,
          isSelected: isSelected,
          onTap: () => onModalitySelected(modality),
        );
      },
    );
  }
}

/// Card individual de modalidade
class _ModalityCard extends StatelessWidget {
  final TrainingModality modality;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModalityCard({
    required this.modality,
    required this.isSelected,
    required this.onTap,
  });

  Color get _cardColor {
    try {
      final colorString = modality.color.replaceAll('#', '');
      return Color(int.parse('FF$colorString', radix: 16));
    } catch (e) {
      return AppColors.primaryOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withOpacity(0.12)
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryOrange
                : AppColors.secondaryDark.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12), // Ajustado para 3 por linha
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Evita overflow
            children: [
              // Ícone da modalidade
              Container(
                width: 36, // Ajustado para 3 por linha
                height: 36, // Ajustado para 3 por linha
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryOrange
                      : _cardColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(child: _getModalityIcon(modality.id)),
              ),

              const SizedBox(height: 8), // Ajustado para 3 por linha
              // Nome da modalidade
              Flexible(
                // Usa Flexible para evitar overflow
                child: Text(
                  modality.name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.secondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Indicador de seleção
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 4,
                  ), // Ajustado para 3 por linha
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.primaryOrange,
                    size: 16, // Ajustado para 3 por linha
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Retorna o ícone apropriado para cada modalidade
  Widget _getModalityIcon(String modalityId) {
    final iconColor = isSelected ? Colors.white : _cardColor;

    switch (modalityId) {
      case 'musculacao':
        return Icon(Icons.fitness_center, size: 18, color: iconColor);
      case 'cardio':
        return Icon(Icons.directions_run, size: 18, color: iconColor);
      case 'funcional':
        return Icon(Icons.accessibility_new, size: 18, color: iconColor);
      case 'hiit':
        return Icon(Icons.local_fire_department, size: 18, color: iconColor);
      case 'alongamento':
        return Icon(Icons.self_improvement, size: 18, color: iconColor);
      case 'taf':
        return Icon(Icons.check_circle_outline, size: 18, color: iconColor);
      default:
        return Icon(Icons.fitness_center, size: 18, color: iconColor);
    }
  }
}
