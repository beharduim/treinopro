import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
// domain models are used via shared helpers
// time helpers moved to Step1; Step2 does not handle time selection anymore
import '../bloc/proposals_bloc.dart';
import '../bloc/proposals_event.dart';
import '../bloc/proposals_state.dart';
import '../widgets/modality_selector.dart';
// time selector removed from Step2

/// Etapa 2: Como será o treino
class ProposalStep2Page extends StatelessWidget {
  const ProposalStep2Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProposalsBloc, ProposalsState>(
      builder: (context, state) {
        if (state is! ProposalsLoaded) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryOrange,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título da etapa
              Text(
                'Defina o tipo de treino',
                style: AppTextStyles.h6Semibold.copyWith(
                  color: AppColors.secondary,
                ),
              ),

              // const SizedBox(height: 8),

              // Text(
              //   'Agora vamos definir a modalidade do seu treino.',
              //   style: AppTextStyles.paragraph.copyWith(
              //     color: AppColors.secondaryDark,
              //   ),
              // ),
              const SizedBox(height: 32),

              // Modalidade do treino
              _buildModalitySection(context, state),

              const SizedBox(height: 32),

              // Horário removido desta etapa — agora definido no Step1
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalitySection(BuildContext context, ProposalsLoaded state) {
    // Debug para verificar o estado das modalidades
    print(
      'DEBUG Step2: Modalidades disponíveis: ${state.availableModalities.length}',
    );
    print('DEBUG Step2: isLoadingModalities: ${state.isLoadingModalities}');
    if (state.availableModalities.isNotEmpty) {
      print(
        'DEBUG Step2: Primeira modalidade: ${state.availableModalities.first.name}',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: AppColors.primaryOrange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Escolha a qual modalidade que você quer praticar:',
                    style: AppTextStyles.paragraph.copyWith(
                      color: AppColors.secondaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Text(
                  //   'Que tipo de treino você quer fazer?',
                  //   style: AppTextStyles.small.copyWith(
                  //     color: AppColors.secondaryDark.withValues(alpha: 0.7),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Seletor de modalidades
        ModalitySelector(
          selectedModality:
              state.availableModalities
                  .where((m) => m.id == state.proposal.modalityId)
                  .isNotEmpty
              ? state.availableModalities.firstWhere(
                  (m) => m.id == state.proposal.modalityId,
                )
              : null,
          modalities: state.availableModalities,
          isLoading: state.isLoadingModalities,
          onModalitySelected: (modality) {
            context.read<ProposalsBloc>().add(
              ProposalsUpdateModality(modality),
            );
          },
        ),
      ],
    );
  }

  // Time UI removed: selection and end-time display are handled in Step1

  // end display is provided by shared helper buildEndTimeDisplay
}
