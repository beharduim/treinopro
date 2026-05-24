import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/otp_pin_input.dart';
import '../../bloc/registration_bloc.dart';
import '../../bloc/registration_event.dart' as registration_events;
import '../../bloc/registration_state.dart' as registration_states;
import '../../widgets/registration_progress_bar.dart';
import '../../utils/registration_steps_helper.dart';

/// Step de validação do OTP do responsável (apenas para menores de 18)
class GuardianOtpStep extends StatefulWidget {
  final int? customCurrentStep;
  final int? customTotalSteps;

  const GuardianOtpStep({
    super.key,
    this.customCurrentStep,
    this.customTotalSteps,
  });

  @override
  State<GuardianOtpStep> createState() => _GuardianOtpStepState();
}

class _GuardianOtpStepState extends State<GuardianOtpStep> {
  final OtpPinInputController _otpController = OtpPinInputController();

  Timer? _timer;
  int _remainingTime = 1440; // 24 horas em minutos (1440 minutos)
  bool _isCodeComplete = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _onCodeChanged(String code) {
    setState(() {
      _isCodeComplete = code.length == 6;
    });

    // Limpar erro anterior quando usuário começar a digitar
    if (code.isNotEmpty) {
      final currentState = context.read<RegistrationBloc>().state;
      if (currentState is registration_states.RegistrationStep &&
          currentState.guardianOtpError != null) {
        context.read<RegistrationBloc>().add(
          const registration_events.ClearGuardianOtpError(),
        );
      }
    }
  }

  void _verifyCode() {
    final code = _otpController.code;
    
    print('GuardianOtpStep: _verifyCode chamado - code=$code, _isVerifying=$_isVerifying');
    
    if (code.length == 6 && !_isVerifying) {
      print('GuardianOtpStep: Iniciando verificação do código $code');
      setState(() {
        _isVerifying = true;
      });
      
      context.read<RegistrationBloc>().add(
        registration_events.VerifyGuardianOtp(code),
      );
    } else {
      print('GuardianOtpStep: Verificação bloqueada - code.length=${code.length}, _isVerifying=$_isVerifying');
    }
  }

  void _clearCode() {
    _otpController.clear();
    setState(() {
      _isCodeComplete = false;
    });
  }

  void _resendCode() {
    final state = context.read<RegistrationBloc>().state;
    if (state is registration_states.RegistrationStep) {
      context.read<RegistrationBloc>().add(
        registration_events.SendGuardianAuthorizationEmail(
          guardianName: state.guardianName,
          guardianEmail: state.guardianEmail,
          studentName: '${state.firstName} ${state.lastName}',
        ),
      );
      
      // Reiniciar timer
      setState(() {
        _remainingTime = 1440; // 24 horas
      });
      _startTimer();
    }
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistrationBloc, registration_states.RegistrationState>(
      listener: (context, state) {
        print('GuardianOtpStep: BlocListener chamado - state=${state.runtimeType}');
        if (state is registration_states.RegistrationStep) {
          print('GuardianOtpStep: BlocListener - isVerifyingGuardianOtp=${state.isVerifyingGuardianOtp}, isGuardianOtpVerified=${state.isGuardianOtpVerified}');
          
          // Atualizar estado de loading
          if (state.isVerifyingGuardianOtp != _isVerifying) {
            print('GuardianOtpStep: Atualizando _isVerifying de $_isVerifying para ${state.isVerifyingGuardianOtp}');
            if (!mounted) return;
            setState(() {
              _isVerifying = state.isVerifyingGuardianOtp;
            });
          }
          
          // Mostrar erro se houver
          if (state.guardianOtpError != null) {
            print('GuardianOtpStep: Mostrando erro: ${state.guardianOtpError}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.guardianOtpError!,
                  style: AppTextStyles.paragraph.copyWith(
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
            // Limpar código em caso de erro
            if (!mounted) return;
            _clearCode();
          }
          
          // OTP verificado com sucesso
          if (state.isGuardianOtpVerified) {
            print('GuardianOtpStep: OTP verificado com sucesso! Navegando automaticamente...');
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
            // Navegação já é feita pelo BLoC ao atualizar o currentStep
          }
        }
      },
      child: BlocBuilder<RegistrationBloc, registration_states.RegistrationState>(
        builder: (context, state) {
          // Calcular etapas usando o helper
          final stepInfo = RegistrationStepsHelper.getStepInfo(
            3, // OTP do responsável é step interno 3
            state is registration_states.RegistrationStep
                ? state.userType
                : registration_states.UserType.student,
            true, // Sempre menor de idade neste step
          );

          // Extrair variáveis do estado
          final isSendingEmail = state is registration_states.RegistrationStep
              ? state.isSendingGuardianEmail
              : false;
          final isOtpVerified = state is registration_states.RegistrationStep
              ? state.isGuardianOtpVerified
              : false;

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
                        'Autorização do Responsável',
                        style: AppTextStyles.h6Semibold.copyWith(
                          color: AppColors.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Digite o código de 6 dígitos enviado para o e-mail do seu responsável',
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      OtpPinInput(
                        controller: _otpController,
                        onChanged: _onCodeChanged,
                        enabled: !_isVerifying,
                      ),

                      const SizedBox(height: 32),

                      // Timer e reenvio
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

                      const SizedBox(height: 16),

                      // Opção de reenvio sempre visível
                      GestureDetector(
                        onTap: isSendingEmail ? null : _resendCode,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSendingEmail) ...[
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryOrange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ] else ...[
                              Icon(
                                Icons.refresh,
                                color: AppColors.primaryOrange,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              isSendingEmail ? 'Reenviando...' : 'Não recebeu o código? Reenviar',
                              style: AppTextStyles.small.copyWith(
                                color: isSendingEmail 
                                    ? AppColors.secondaryDark.withValues(alpha: 0.6)
                                    : AppColors.primaryOrange,
                                fontWeight: FontWeight.w600,
                                decoration: isSendingEmail ? null : TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),

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
                              'Peça para seu responsável verificar a caixa de spam se não encontrar o e-mail.',
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

              // Botões fixos na parte inferior
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
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
                                  : isOtpVerified
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
                                    : (isOtpVerified || _isCodeComplete)
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Verificando...',
                                          style: AppTextStyles.paragraph.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      isOtpVerified ? 'Continuar' : 'Verificar',
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
      ),
    );
  }
}