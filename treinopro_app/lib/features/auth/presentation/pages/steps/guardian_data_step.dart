import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../bloc/registration_bloc.dart';
import '../../bloc/registration_event.dart' as registration_events;
import '../../bloc/registration_state.dart' as registration_states;
import '../../widgets/custom_text_field.dart';
import '../../widgets/registration_progress_bar.dart';
import '../../utils/registration_steps_helper.dart';

/// Segunda etapa: Dados do Responsável (apenas para menores de 18)
class GuardianDataStep extends StatefulWidget {
  final int? customCurrentStep;
  final int? customTotalSteps;

  const GuardianDataStep({
    super.key,
    this.customCurrentStep,
    this.customTotalSteps,
  });

  @override
  State<GuardianDataStep> createState() => _GuardianDataStepState();
}

class _GuardianDataStepState extends State<GuardianDataStep> {
  final _guardianNameController = TextEditingController();
  final _guardianEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _guardianNameController.addListener(_updateData);
    _guardianEmailController.addListener(_updateData);
  }

  @override
  void dispose() {
    _guardianNameController.dispose();
    _guardianEmailController.dispose();
    super.dispose();
  }

  void _updateData() {
    // Agenda a atualização para depois do build para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final guardianName = _guardianNameController.text;
      final guardianEmail = _guardianEmailController.text;

      context.read<RegistrationBloc>().add(
        registration_events.UpdateGuardianData(
          guardianName: guardianName,
          guardianEmail: guardianEmail,
        ),
      );
    });
  }

  void _sendAuthorizationEmail() {
    final state = context.read<RegistrationBloc>().state;
    if (state is registration_states.RegistrationStep) {
      // Enviar email de autorização (assíncrono)
      context.read<RegistrationBloc>().add(
        registration_events.SendGuardianAuthorizationEmail(
          guardianName: state.guardianName,
          guardianEmail: state.guardianEmail,
          studentName: '${state.firstName} ${state.lastName}',
        ),
      );
      
      // Navegar imediatamente para o próximo step
      context.read<RegistrationBloc>().add(
        const registration_events.NextStep(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationBloc, registration_states.RegistrationState>(
      builder: (context, state) {
        final isValid = state is registration_states.RegistrationStep
            ? state.isValid
            : false;

        // Calcular etapas usando o helper
        final stepInfo = RegistrationStepsHelper.getStepInfo(
          2, // Dados do responsável é sempre o segundo passo para menores
          registration_states.UserType.student,
          true,
        );

        return Column(
          children: [
            // Barra de progresso
            RegistrationProgressBar(
              currentStep: widget.customCurrentStep ?? stepInfo.displayStep,
              totalSteps: widget.customTotalSteps ?? stepInfo.totalSteps,
            ),

            const SizedBox(height: 32),

            // Título
            Text(
              'Dados do Responsável',
              style: AppTextStyles.h6Semibold.copyWith(
                color: AppColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Precisamos das informações do seu responsável',
              style: AppTextStyles.paragraph.copyWith(
                color: AppColors.secondaryDark,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Formulário
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Nome do Responsável
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nome completo do responsável',
                          style: AppTextStyles.paragraph.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _guardianNameController,
                          placeholder: 'Digite o nome completo',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Email do Responsável
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'E-mail do responsável',
                          style: AppTextStyles.paragraph.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _guardianEmailController,
                          placeholder: 'Digite o e-mail',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Informação adicional
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryOrange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primaryOrange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'O responsável receberá uma confirmação por e-mail sobre o cadastro.',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32), // Espaçamento extra
                  ],
                ),
              ),
            ),

            // Botões fixos na parte inferior
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
                                _sendAuthorizationEmail();
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
