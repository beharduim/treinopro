import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/otp_pin_input.dart';
import '../../bloc/forgot_password_bloc.dart';
import '../../bloc/forgot_password_event.dart';
import '../../bloc/forgot_password_state.dart';

/// Step 2: Verificação do código OTP para recuperação de senha
class ForgotPasswordOtpStepWidget extends StatefulWidget {
  const ForgotPasswordOtpStepWidget({super.key});

  @override
  State<ForgotPasswordOtpStepWidget> createState() => _ForgotPasswordOtpStepWidgetState();
}

class _ForgotPasswordOtpStepWidgetState extends State<ForgotPasswordOtpStepWidget> {
  final OtpPinInputController _otpController = OtpPinInputController();

  bool _isCodeComplete = false;
  bool _isVerifying = false;
  bool _canResend = false;
  String _email = '';

  void _onCodeChanged(String code) {
    setState(() {
      _isCodeComplete = code.length == 6;
    });
  }

  Future<void> _verifyCode() async {
    if (!_isCodeComplete || _isVerifying) return;

    final code = _otpController.code;
    print('ForgotPasswordOtpStep: Enviando código para verificação: $code');

    // Previne múltiplas chamadas
    setState(() {
      _isVerifying = true;
    });

    // Chama o evento do BLoC
    context.read<ForgotPasswordBloc>().add(
      VerifyResetCode(_email, code),
    );
  }

  void _clearCode() {
    _otpController.clear();
    setState(() {
      _isCodeComplete = false;
    });
  }

  Future<void> _resendCode() async {
    context.read<ForgotPasswordBloc>().add(
      ResendCode(_email),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Novo código enviado!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryOrange,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    _clearCode();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ForgotPasswordOtpStep) {
          setState(() {
            _email = state.email;
            _isVerifying = state.isVerifying;
            _canResend = state.remainingTime <= 0;
          });
          
          // Mostrar erro se houver
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
            // Limpar código e resetar estado em caso de erro
            setState(() {
              _isVerifying = false;
            });
            _clearCode();
          }
        }
      },
      child: BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
        builder: (context, state) {
          if (state is ForgotPasswordOtpStep) {
            _email = state.email;
            _isVerifying = state.isVerifying;
            _canResend = state.remainingTime <= 0;
          }

          return Column(
            children: [
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
                              'Código expira em ${_formatTime(state is ForgotPasswordOtpStep ? state.remainingTime : 600)}',
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
                                  context.read<ForgotPasswordBloc>().add(
                                    PreviousStep(),
                                  );
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _isVerifying
                                ? AppColors.secondaryDark.withValues(alpha: 0.5)
                                : AppColors.secondary,
                            side: BorderSide(
                              color: _isVerifying
                                  ? AppColors.secondaryDark.withValues(alpha: 0.5)
                                  : AppColors.secondary,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Voltar',
                            style: AppTextStyles.paragraph.copyWith(
                              color: _isVerifying
                                  ? AppColors.secondaryDark.withValues(alpha: 0.5)
                                  : AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Botão Verificar
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isVerifying
                              ? null
                              : _isCodeComplete
                              ? _verifyCode
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isVerifying
                                ? AppColors.primaryOrange.withValues(alpha: 0.5)
                                : _isCodeComplete
                                ? AppColors.primaryOrange
                                : AppColors.secondaryDark.withValues(alpha: 0.3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                                  'Verificar',
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
