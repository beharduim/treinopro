import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../bloc/registration_bloc.dart';
import '../../bloc/registration_event.dart' as registration_events;
import '../../bloc/registration_state.dart' as registration_states;
import '../../widgets/registration_progress_bar.dart';
import '../../utils/registration_steps_helper.dart';

/// Quinta etapa: Verificação do código
class VerificationStep extends StatefulWidget {
  final int? customCurrentStep;
  final int? customTotalSteps;

  const VerificationStep({
    super.key,
    this.customCurrentStep,
    this.customTotalSteps,
  });

  @override
  State<VerificationStep> createState() => _VerificationStepState();
}

class _VerificationStepState extends State<VerificationStep> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  Timer? _timer;
  int _remainingTime = 300; // 5 minutos em segundos
  bool _isCodeComplete = false;
  bool _isVerifying = false;
  bool _canResend = false;
  bool _isMinor = false;
  String? _lastErrorShown; // Controla qual foi o último erro mostrado

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Adicionar listeners para cada campo
    for (int i = 0; i < 6; i++) {
      _controllers[i].addListener(() => _onCodeChanged());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingTime = 300;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _onCodeChanged() {
    final code = _controllers.map((c) => c.text).join();
    final isComplete = code.length == 6;

    setState(() {
      _isCodeComplete = isComplete;
    });

    // Não chama automaticamente, deixa o usuário pressionar o botão
    // if (isComplete) {
    //   _verifyCode();
    // }
  }

  void _onDigitChanged(String value, int index) {
    if (value.length > 1) {
      // Usuário colou um código completo ou parcial
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '').split('');
      int currIndex = index;
      for (int i = 0; i < digits.length && currIndex < 6; i++) {
        _controllers[currIndex].text = digits[i];
        currIndex++;
      }
      if (currIndex < 6) {
        _focusNodes[currIndex].requestFocus();
      } else {
        _focusNodes[5].unfocus();
      }
    } else if (value.length == 1) {
      // Move para o próximo campo
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      // Move para o campo anterior se apagar
      _focusNodes[index - 1].requestFocus();
    }

    _onCodeChanged();
    setState(() {});
  }

  Future<void> _verifyCode() async {
    if (!_isCodeComplete || _isVerifying) return;

    final code = _controllers.map((c) => c.text).join();
    print('VerificationStep: Enviando código para verificação: $code');

    // Previne múltiplas chamadas
    setState(() {
      _isVerifying = true;
    });

    // Pegar o email do estado atual do BLoC
    final currentState = context.read<RegistrationBloc>().state;
    if (currentState is registration_states.RegistrationStep) {
      // Chama o evento do BLoC - o BlocListener irá lidar com a resposta
      context.read<RegistrationBloc>().add(registration_events.VerifyCode(currentState.email, code));
    }
  }

  void _clearCode() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {
      _isCodeComplete = false;
    });
  }

  Future<void> _resendCode() async {
    // Pegar o email do estado atual do BLoC
    final currentState = context.read<RegistrationBloc>().state;
    if (currentState is registration_states.RegistrationStep) {
      // Disparar evento real de reenvio de código
      context.read<RegistrationBloc>().add(
        registration_events.SendVerificationCode(currentState.email),
      );

      _clearCode();
      _startTimer();
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      RegistrationBloc,
      registration_states.RegistrationState
    >(
      listener: (context, state) {
        if (state is registration_states.RegistrationStep) {
          // Atualizar estado de loading
          if (state.isVerifyingCode != _isVerifying) {
            setState(() {
              _isVerifying = state.isVerifyingCode;
            });
          }
          
          // Mostrar erro se houver (evita duplicatas)
          if (state.emailVerificationError != null && 
              _lastErrorShown != state.emailVerificationError) {
            _lastErrorShown = state.emailVerificationError;
            
            ScaffoldMessenger.of(context).clearSnackBars(); // Limpa SnackBars anteriores
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.emailVerificationError!,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
            // Limpar código em caso de erro
            _clearCode();
          }
          
          // Code verified successfully
          if (state.isEmailVerified && state.isCodeVerified) {
            // Limpar erro anterior e mostrar sucesso
            _lastErrorShown = null;
            ScaffoldMessenger.of(context).clearSnackBars();
            
            // Código verificado com sucesso, mostrar feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Código verificado com sucesso! Redirecionando...',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        }
        
        if (state is registration_states.RegistrationError) {
          // Código inválido
          _clearCode();
          setState(() {
            _isVerifying = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro ao verificar código',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
        
        if (state is registration_states.RegistrationLoading) {
          setState(() {
            _isVerifying = true;
          });
        }
      },
      child: BlocBuilder<RegistrationBloc, registration_states.RegistrationState>(
        builder: (context, state) {
          if (state is registration_states.RegistrationStep) {
            _isMinor = state.isMinor;
          }

          // Calcular etapas usando o helper
          final int internalStep;
          if (state is registration_states.RegistrationStep) {
            if (state.userType == registration_states.UserType.personalTrainer) {
              internalStep = 5;
            } else {
              internalStep = _isMinor ? 6 : 5;
            }
          } else {
            internalStep = 5;
          }

          final stepInfo = RegistrationStepsHelper.getStepInfo(
            internalStep,
            state is registration_states.RegistrationStep
                ? state.userType
                : registration_states.UserType.student,
            _isMinor,
          );

          return Column(
            children: [
              // Barra de progresso
              RegistrationProgressBar(
                currentStep: widget.customCurrentStep ?? stepInfo.displayStep,
                totalSteps: widget.customTotalSteps ?? stepInfo.totalSteps,
              ),

              // Título e subtítulo centralizados
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Verificação',
                        style: AppTextStyles.h6Semibold.copyWith(
                          color: AppColors.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Digite o código de 6 dígitos enviado para seu e-mail',
                        style: AppTextStyles.paragraph.copyWith(
                          color: AppColors.secondaryDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Formulário
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                      // Campos do código
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return Container(
                            width: 45,
                            height: 55,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _controllers[index].text.isNotEmpty
                                    ? AppColors.primaryOrange
                                    : AppColors.secondaryDark.withValues(
                                        alpha: 0.3,
                                      ),
                                width: _controllers[index].text.isNotEmpty
                                    ? 2
                                    : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextFormField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              style: AppTextStyles.h6Semibold.copyWith(
                                color: AppColors.secondary,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) =>
                                  _onDigitChanged(value, index),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 32),

                      // Timer e reenvio
                      if (!_canResend) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time,
                              color: AppColors.secondaryDark,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Código expira em ${_formatTime(_remainingTime)}',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.secondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        GestureDetector(
                          onTap: _resendCode,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.refresh,
                                color: AppColors.primaryOrange,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reenviar código',
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.primaryOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Informação sobre o código
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.primaryOrange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dica',
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
                              'Verifique sua caixa de spam se não encontrar o e-mail.',
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ),

              // Botões fixos na parte inferior
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child:
                      BlocBuilder<
                        RegistrationBloc,
                        registration_states.RegistrationState
                      >(
                        builder: (context, state) {
                          bool isCodeVerified = false;
                          if (state is registration_states.RegistrationStep) {
                            isCodeVerified = state.isCodeVerified;
                          }

                          return Row(
                            children: [
                              // Botão Voltar
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isVerifying
                                      ? null
                                      : () {
                                          context.read<RegistrationBloc>().add(
                                            const registration_events.PreviousStep(),
                                          );
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _isVerifying
                                        ? AppColors.secondaryDark.withValues(
                                            alpha: 0.5,
                                          )
                                        : AppColors.secondary,
                                    side: BorderSide(
                                      color: _isVerifying
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
                                      color: _isVerifying
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

                              // Botão Verificar/Continuar
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: _isVerifying
                                      ? null
                                      : isCodeVerified
                                      ? () {
                                          // Avançar para próxima etapa
                                          context.read<RegistrationBloc>().add(
                                            const registration_events.NextStep(),
                                          );
                                        }
                                      : _isCodeComplete
                                      ? _verifyCode
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isVerifying
                                        ? AppColors.primaryOrange.withValues(
                                            alpha: 0.5,
                                          )
                                        : (isCodeVerified || _isCodeComplete)
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
                                  child: _isVerifying
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Verificando...',
                                              style: AppTextStyles.paragraph
                                                  .copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          isCodeVerified
                                              ? 'Continuar'
                                              : 'Verificar',
                                          style: AppTextStyles.paragraph
                                              .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
