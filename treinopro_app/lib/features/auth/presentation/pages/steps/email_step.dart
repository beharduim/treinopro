import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../bloc/registration_bloc.dart';
import '../../bloc/registration_event.dart' as registration_events;
import '../../bloc/registration_state.dart' as registration_states;
import '../../widgets/registration_progress_bar.dart';
import '../../utils/registration_steps_helper.dart';

/// Quarta etapa: E-mail
class EmailStep extends StatefulWidget {
  final int? customCurrentStep;
  final int? customTotalSteps;
  final bool showButtons;

  const EmailStep({
    super.key,
    this.customCurrentStep,
    this.customTotalSteps,
    this.showButtons = true,
  });

  @override
  State<EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends State<EmailStep> {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Recuperar email inicial se existir no BLoC
    final currentState = context.read<RegistrationBloc>().state;
    if (currentState is registration_states.RegistrationStep) {
      _emailController.text = currentState.email;
    }
    _emailFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.removeListener(_onFocusChange);
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_emailFocusNode.hasFocus) {
      // Perdeu o foco - validar existência do email
      final email = _emailController.text.trim();
      if (_isValidEmail(email)) {
        context.read<RegistrationBloc>().add(
          registration_events.ValidateEmail(email),
        );
      }
    }
  }

  bool _isFormValid(registration_states.RegistrationState state) {
    if (state is! registration_states.RegistrationStep) return false;
    
    final email = _emailController.text.trim();
    final hasError = state.emailExistsError != null;
    final isChecking = state.isEmailChecking;
    
    return email.isNotEmpty && _isValidEmail(email) && !hasError && !isChecking;
  }

  Future<void> _sendVerificationCode() async {
    final state = context.read<RegistrationBloc>().state;
    final hasError = state is registration_states.RegistrationStep &&
                    state.emailExistsError != null;

    if (_emailController.text.isNotEmpty &&
        _isValidEmail(_emailController.text) &&
        !hasError) {
      // Primeiro, atualizar o email no BLoC
      context.read<RegistrationBloc>().add(
        registration_events.UpdateEmail(_emailController.text),
      );

      // Depois, disparar o evento para enviar o código
      context.read<RegistrationBloc>().add(
        registration_events.SendVerificationCode(_emailController.text),
      );

      // O estado será atualizado pelo BLoC após o envio real do código
      // O BLoC já chama NextStep() automaticamente em _onSendVerificationCode
      // Feedback de sucesso será mostrado apenas após confirmação da API via listener
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegistrationBloc, registration_states.RegistrationState>(
      listener: (context, state) {
        if (state is registration_states.RegistrationStep) {
          // Mostrar erro apenas se houver
          if (state.verificationCodeError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.verificationCodeError!),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }

          // Mostrar sucesso apenas após confirmação da API
          if (state.verificationCodeSent && state.verificationCodeError == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Código de verificação enviado para ${state.email}',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: AppColors.primaryOrange,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }
        }
      },
      builder: (context, state) {
        bool isMinor = false;
        bool isCodeSent = false;

        if (state is registration_states.RegistrationStep) {
          isMinor = state.isMinor;
          isCodeSent = state.isCodeSent;
        }

        // Calcular etapas usando o helper
        late final StepInfo stepInfo;

        if (state is registration_states.RegistrationStep) {
          if (state.userType == registration_states.UserType.personalTrainer) {
            stepInfo = RegistrationStepsHelper.getStepInfo(4, state.userType, false);
          } else {
            // Estudante: maior = 4, menor = 5
            stepInfo = RegistrationStepsHelper.getStepInfo(isMinor ? 5 : 4, state.userType, isMinor);
          }
        } else {
          // Valores padrão
          stepInfo = RegistrationStepsHelper.getStepInfo(4, registration_states.UserType.student, isMinor);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Define espaçamentos baseados no espaço disponível
            // final headerFlex = availableHeight > 600 ? 30 : 25;
            // final contentFlex = 50;
            // final footerFlex = availableHeight > 600 ? 20 : 25;

            return Column(
              children: [
                // Barra de progresso
                RegistrationProgressBar(
                  currentStep: widget.customCurrentStep ?? stepInfo.displayStep,
                  totalSteps: widget.customTotalSteps ?? stepInfo.totalSteps,
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'E-mail',
                          style: AppTextStyles.h6Semibold.copyWith(
                            color: AppColors.secondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Informe seu e-mail para verificação',
                          style: AppTextStyles.paragraph.copyWith(
                            color: AppColors.secondaryDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Conteúdo principal
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                        // Campo de e-mail
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'E-mail',
                              style: AppTextStyles.paragraph.copyWith(
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !isCodeSent,
                              style: AppTextStyles.paragraph.copyWith(
                                color: AppColors.secondaryDarkest,
                              ),
                              onChanged: (value) {
                                context.read<RegistrationBloc>().add(
                                  registration_events.UpdateEmail(value),
                                );
                              },
                              decoration: InputDecoration(
                                hintText: 'Digite seu email',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.secondaryDark,
                                  fontFamily: 'Fira Sans',
                                ),
                                errorText: (state is registration_states.RegistrationStep)
                                    ? state.emailExistsError
                                    : null,
                                filled: true,
                                fillColor: isCodeSent
                                    ? AppColors.secondaryDark.withValues(
                                        alpha: 0.1,
                                      )
                                    : AppColors.inputBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: isCodeSent
                                        ? AppColors.primaryOrange
                                        : (state is registration_states.RegistrationStep && state.emailExistsError != null)
                                            ? Colors.red
                                            : AppColors.secondaryDark,
                                    width: isCodeSent ? 1 : 0.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: isCodeSent
                                        ? AppColors.primaryOrange
                                        : (state is registration_states.RegistrationStep && state.emailExistsError != null)
                                            ? Colors.red
                                            : AppColors.secondaryDark,
                                    width: isCodeSent ? 1 : 0.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: (state is registration_states.RegistrationStep && state.emailExistsError != null)
                                        ? Colors.red
                                        : AppColors.primaryOrange,
                                    width: 1,
                                  ),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: AppColors.primaryOrange,
                                    width: 1,
                                  ),
                                ),
                                suffixIcon: isCodeSent
                                    ? Icon(
                                        Icons.check_circle,
                                        color: AppColors.primaryOrange,
                                      )
                                    : (state is registration_states.RegistrationStep && state.isEmailChecking)
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Padding(
                                              padding: EdgeInsets.all(12),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : null,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 18,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Informação sobre verificação
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.mail_outline,
                                    color: AppColors.primaryOrange,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isCodeSent
                                          ? 'Código enviado!'
                                          : 'Verificação de e-mail',
                                      style: AppTextStyles.paragraph.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isCodeSent
                                    ? 'Um código de verificação foi enviado para o seu e-mail. Você será redirecionado para a próxima etapa em instantes.'
                                    : 'Enviaremos um código de verificação de 6 dígitos para o e-mail informado. Certifique-se de que o e-mail está correto.',
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Footer adaptativo
                        Container(
                          child: isCodeSent
                              ? Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.primaryOrange,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Redirecionando...',
                                        style: AppTextStyles.small.copyWith(
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(),
                        ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Botões fixos na parte inferior (condicionais)
                if (widget.showButtons)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          // Botão Voltar
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isCodeSent
                                  ? null
                                  : () {
                                      context.read<RegistrationBloc>().add(
                                        const registration_events.PreviousStep(),
                                      );
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isCodeSent
                                    ? AppColors.secondaryDark.withValues(
                                        alpha: 0.5,
                                      )
                                    : AppColors.secondary,
                                side: BorderSide(
                                  color: isCodeSent
                                      ? AppColors.secondaryDark.withValues(
                                          alpha: 0.5,
                                        )
                                      : AppColors.secondary,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Voltar',
                                style: AppTextStyles.paragraph.copyWith(
                                  color: isCodeSent
                                      ? AppColors.secondaryDark.withValues(
                                          alpha: 0.5,
                                        )
                                      : AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Botão Enviar código
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: (isCodeSent ||
                                         (state is registration_states.RegistrationStep &&
                                          (state.isEmailChecking || state.isSendingVerificationCode)))
                                  ? null
                                  : _isFormValid(state)
                                  ? _sendVerificationCode
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCodeSent
                                    ? AppColors.primaryOrange.withValues(
                                        alpha: 0.5,
                                      )
                                    : (_isValidEmail(_emailController.text) && (state is! registration_states.RegistrationStep || state.emailExistsError == null))
                                    ? AppColors.primaryOrange
                                    : AppColors.secondaryDark.withValues(
                                        alpha: 0.3,
                                      ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: (state is registration_states.RegistrationStep && state.isSendingVerificationCode)
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      isCodeSent
                                          ? 'Código enviado'
                                          : 'Enviar código',
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
      },
    );
  }
}
