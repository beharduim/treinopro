import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../bloc/forgot_password_bloc.dart';
import '../../bloc/forgot_password_event.dart';
import '../../bloc/forgot_password_state.dart';

/// Step 1: Inserir email para recuperação de senha
class ForgotPasswordEmailStepWidget extends StatefulWidget {
  const ForgotPasswordEmailStepWidget({super.key});

  @override
  State<ForgotPasswordEmailStepWidget> createState() => _ForgotPasswordEmailStepWidgetState();
}

class _ForgotPasswordEmailStepWidgetState extends State<ForgotPasswordEmailStepWidget> {
  final _emailController = TextEditingController();
  bool _isCodeSent = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateData);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _updateData() {
    setState(() {
      // Forçar rebuild para validações visuais
    });
  }

  bool _isFormValid() {
    return _emailController.text.trim().isNotEmpty &&
        _isValidEmail(_emailController.text.trim());
  }

  Future<void> _sendResetCode() async {
    if (_emailController.text.isNotEmpty &&
        _isValidEmail(_emailController.text)) {
      print('ForgotPasswordEmailStep: Enviando código para ${_emailController.text}');

      // Disparar o evento para enviar o código
      context.read<ForgotPasswordBloc>().add(
        SendResetCode(_emailController.text),
      );

      // Mostrar feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Código de recuperação enviado para ${_emailController.text}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryOrange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      print('ForgotPasswordEmailStep: Email inválido ou vazio: ${_emailController.text}');
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ForgotPasswordEmailStep) {
          setState(() {
            _isCodeSent = state.isCodeSent;
          });
          
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
          }
        }
      },
      child: Column(
        children: [
          // Título e subtítulo centralizados
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Recuperar senha',
                    style: AppTextStyles.h6Semibold.copyWith(
                      color: AppColors.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Digite seu e-mail para receber um código de recuperação',
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
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isCodeSent,
                        style: AppTextStyles.paragraph.copyWith(
                          color: AppColors.secondaryDarkest,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Digite seu email',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: AppColors.secondaryDark,
                            fontFamily: 'Fira Sans',
                          ),
                          filled: true,
                          fillColor: _isCodeSent
                              ? AppColors.secondaryDark.withValues(alpha: 0.1)
                              : AppColors.inputBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: _isCodeSent
                                  ? AppColors.primaryOrange
                                  : AppColors.secondaryDark,
                              width: _isCodeSent ? 1 : 0.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: _isCodeSent
                                  ? AppColors.primaryOrange
                                  : AppColors.secondaryDark,
                              width: _isCodeSent ? 1 : 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: AppColors.primaryOrange,
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 18,
                          ),
                          suffixIcon: _isCodeSent
                              ? Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryOrange,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Informação sobre verificação
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
                              Icons.mail_outline,
                              color: AppColors.primaryOrange,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isCodeSent
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
                          _isCodeSent
                              ? 'Um código de recuperação foi enviado para o seu e-mail. Você será redirecionado para a próxima etapa em instantes.'
                              : 'Enviaremos um código de recuperação de 6 dígitos para o e-mail informado. Certifique-se de que o e-mail está correto.',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer adaptativo
                  Container(
                    child: _isCodeSent
                        ? Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
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

          // Botões fixos na parte inferior
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Botão Voltar
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCodeSent
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isCodeSent
                            ? AppColors.secondaryDark.withValues(alpha: 0.5)
                            : AppColors.secondary,
                        side: BorderSide(
                          color: _isCodeSent
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
                          color: _isCodeSent
                              ? AppColors.secondaryDark.withValues(alpha: 0.5)
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
                      onPressed: _isCodeSent
                          ? null
                          : _isFormValid()
                          ? _sendResetCode
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCodeSent
                            ? AppColors.primaryOrange.withValues(alpha: 0.5)
                            : _isValidEmail(_emailController.text)
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
                        _isCodeSent
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
      ),
    );
  }
}
