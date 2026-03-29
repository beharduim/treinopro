import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../bloc/registration_bloc.dart';
import '../../bloc/registration_event.dart' as registration_events;
import '../../bloc/registration_state.dart' as registration_states;
import '../../widgets/registration_progress_bar.dart';
import '../../utils/registration_steps_helper.dart';

/// Sexta etapa: Modalidades
class ModalitiesStep extends StatefulWidget {
  final int? customCurrentStep;
  final int? customTotalSteps;

  const ModalitiesStep({
    super.key,
    this.customCurrentStep,
    this.customTotalSteps,
  });

  @override
  State<ModalitiesStep> createState() => _ModalitiesStepState();
}

class _ModalitiesStepState extends State<ModalitiesStep> {
  List<String> _selectedModalities = [];

  @override
  void initState() {
    super.initState();
  }

  void _updateData() {
    context.read<RegistrationBloc>().add(
      registration_events.UpdateModalities(_selectedModalities),
    );
  }

  void _toggleModality(String modality) {
    setState(() {
      if (_selectedModalities.contains(modality)) {
        _selectedModalities.remove(modality);
      } else {
        _selectedModalities.add(modality);
      }
    });
    _updateData();
  }

  @override
  Widget build(BuildContext context) {
    print('ModalitiesStep: Widget build chamado');
    return BlocBuilder<RegistrationBloc, registration_states.RegistrationState>(
      builder: (context, state) {
        print('ModalitiesStep: BlocBuilder - estado: ${state.runtimeType}');

        final isValid = state is registration_states.RegistrationStep
            ? state.isValid
            : false;

        // Calcular etapas usando o helper - Modalidades é step interno 6 (só para Personal Trainer)
        final stepInfo = RegistrationStepsHelper.getStepInfo(
          6, // Modalidades é sempre step interno 6
          state is registration_states.RegistrationStep
              ? state.userType
              : registration_states.UserType.personalTrainer,
          false, // Modalidades só existe para Personal Trainer, não importa se é menor
        );

        // Lista fixa de modalidades disponíveis
        final availableModalities = [
          'Musculação',
          'Cardio',
          'Funcional',
          'HIIT',
          'Alongamento',
          'TAF',
        ];

        if (state is registration_states.RegistrationStep) {
          _selectedModalities = List.from(state.selectedModalities);
        }

        return Column(
          children: [
            // Barra de progresso
            RegistrationProgressBar(
              currentStep: widget.customCurrentStep ?? stepInfo.displayStep,
              totalSteps: widget.customTotalSteps ?? stepInfo.totalSteps,
            ),

            // Espaço flexível para centralizar o título
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Modalidades',
                        style: AppTextStyles.h6Semibold.copyWith(
                          color: AppColors.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Selecione as modalidades que você oferece',
                        style: AppTextStyles.paragraph.copyWith(
                          color: AppColors.secondaryDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Lista de modalidades
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Escolha pelo menos uma modalidade:',
                      style: AppTextStyles.paragraph.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: availableModalities.map((modality) {
                            final isSelected = _selectedModalities.contains(
                              modality,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : AppColors.secondaryDark.withValues(
                                          alpha: 0.3,
                                        ),
                                  width: isSelected ? 2 : 1,
                                ),
                                color: isSelected
                                    ? AppColors.primaryOrange.withValues(
                                        alpha: 0.1,
                                      )
                                    : Colors.transparent,
                              ),
                              child: CheckboxListTile(
                                title: Text(
                                  modality,
                                  style: AppTextStyles.paragraph.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                value: isSelected,
                                onChanged: (value) => _toggleModality(modality),
                                activeColor: AppColors.primaryOrange,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                visualDensity: VisualDensity.compact,
                                side: BorderSide.none,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Contador de selecionadas
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedModalities.isNotEmpty
                            ? AppColors.primaryOrange.withValues(alpha: 0.1)
                            : AppColors.secondaryDark.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedModalities.isNotEmpty
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            color: _selectedModalities.isNotEmpty
                                ? AppColors.primaryOrange
                                : AppColors.secondaryDark,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedModalities.isEmpty
                                  ? 'Selecione pelo menos uma modalidade para continuar'
                                  : '${_selectedModalities.length} modalidade${_selectedModalities.length > 1 ? 's' : ''} selecionada${_selectedModalities.length > 1 ? 's' : ''}',
                              style: AppTextStyles.small.copyWith(
                                color: _selectedModalities.isNotEmpty
                                    ? AppColors.secondary
                                    : AppColors.secondaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botões fixos na parte inferior
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Botão Voltar
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.read<RegistrationBloc>().add(
                            const registration_events.PreviousStep(),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: BorderSide(color: AppColors.secondary),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Voltar',
                          style: AppTextStyles.paragraph.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Botão Continuar
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isValid
                            ? () {
                                context.read<RegistrationBloc>().add(
                                  const registration_events.NextStep(),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isValid
                              ? AppColors.primaryOrange
                              : AppColors.secondaryDark.withValues(alpha: 0.3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Continuar',
                          style: AppTextStyles.paragraph.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
