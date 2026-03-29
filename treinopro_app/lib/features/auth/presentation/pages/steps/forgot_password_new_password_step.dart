import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../bloc/forgot_password_bloc.dart';
import '../../bloc/forgot_password_event.dart';
import '../../bloc/forgot_password_state.dart';

/// Step 3: Criar nova senha para recuperação
class ForgotPasswordNewPasswordStepWidget extends StatefulWidget {
  const ForgotPasswordNewPasswordStepWidget({super.key});

  @override
  State<ForgotPasswordNewPasswordStepWidget> createState() => _ForgotPasswordNewPasswordStepWidgetState();
}

class _ForgotPasswordNewPasswordStepWidgetState extends State<ForgotPasswordNewPasswordStepWidget> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isResetting = false;
  String _email = '';
  String _code = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateData);
    _confirmPasswordController.addListener(_updateData);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateData() {
    setState(() {
      // Força rebuild do widget para atualizar validações visuais
    });
  }

  bool _isPasswordValid(String password) {
    return password.length >= 8 &&
        _hasUppercase(password) &&
        _hasLowercase(password) &&
        _hasDigit(password) &&
        _hasSpecial(password);
  }

  bool _hasUppercase(String s) => RegExp(r'[A-Z]').hasMatch(s);
  bool _hasLowercase(String s) => RegExp(r'[a-z]').hasMatch(s);
  bool _hasDigit(String s) => RegExp(r'[0-9]').hasMatch(s);
  bool _hasSpecial(String s) => RegExp(r'[!@#\$%\^&*(),.?":{}|<>]').hasMatch(s);

  bool _passwordsMatch() {
    return _passwordController.text == _confirmPasswordController.text &&
        _passwordController.text.isNotEmpty;
  }

  Widget _ruleRow(String text, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: ok ? AppColors.primaryOrange : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.small.copyWith(
              color: ok ? AppColors.primaryOrange : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (!_isFormValid()) return;

    // Atualizar os dados no BLoC
    context.read<ForgotPasswordBloc>().add(
      UpdateNewPassword(
        _passwordController.text,
        _confirmPasswordController.text,
      ),
    );

    // Resetar a senha
    context.read<ForgotPasswordBloc>().add(
      ResetPassword(_email, _code, _passwordController.text),
    );
  }

  bool _isFormValid() {
    return _isPasswordValid(_passwordController.text) &&
        _passwordsMatch();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ForgotPasswordNewPasswordStep) {
          setState(() {
            _email = state.email;
            _code = state.code;
            _isResetting = state.isResetting;
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
      child: BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
        builder: (context, state) {
          if (state is ForgotPasswordNewPasswordStep) {
            _email = state.email;
            _code = state.code;
            _isResetting = state.isResetting;
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
                        'Nova senha',
                        style: AppTextStyles.h6Semibold.copyWith(
                          color: AppColors.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crie uma nova senha segura para sua conta',
                        style: AppTextStyles.paragraph.copyWith(
                          color: AppColors.secondaryDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Formulário (scrollável)
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campo senha
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nova senha',
                            style: AppTextStyles.paragraph.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: AppTextStyles.paragraph.copyWith(
                              color: const Color(0xFF2D3748),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Digite sua nova senha',
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: AppColors.secondaryDark,
                                fontFamily: 'Fira Sans',
                              ),
                              filled: true,
                              fillColor: AppColors.inputBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: AppColors.secondaryDark,
                                  width: 0.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: AppColors.secondaryDark,
                                  width: 0.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.secondaryDark,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Requisitos da senha
                      if (_passwordController.text.isNotEmpty) ...[
                        Text(
                          'Sua senha deve conter:',
                          style: AppTextStyles.paragraph.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ruleRow('Pelo menos 8 caracteres', _passwordController.text.length >= 8),
                        _ruleRow('Uma letra maiúscula', _hasUppercase(_passwordController.text)),
                        _ruleRow('Uma letra minúscula', _hasLowercase(_passwordController.text)),
                        _ruleRow('Um número', _hasDigit(_passwordController.text)),
                        _ruleRow('Um caractere especial', _hasSpecial(_passwordController.text)),

                        const SizedBox(height: 16),
                      ],

                      // Campo confirmar senha
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirmar nova senha',
                            style: AppTextStyles.paragraph.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: AppTextStyles.paragraph.copyWith(
                              color: const Color(0xFF2D3748),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Confirme sua nova senha',
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: AppColors.secondaryDark,
                                fontFamily: 'Fira Sans',
                              ),
                              filled: true,
                              fillColor: AppColors.inputBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: _confirmPasswordController.text.isNotEmpty
                                      ? (_passwordsMatch() ? Colors.green : Colors.red)
                                      : AppColors.secondaryDark,
                                  width: _confirmPasswordController.text.isNotEmpty ? 1 : 0.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: _confirmPasswordController.text.isNotEmpty
                                      ? (_passwordsMatch() ? Colors.green : Colors.red)
                                      : AppColors.secondaryDark,
                                  width: _confirmPasswordController.text.isNotEmpty ? 1 : 0.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.secondaryDark,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _ruleRow(
                          'As senhas coincidem',
                          _confirmPasswordController.text.isNotEmpty && _passwordsMatch(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botões fixos no rodapé
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Botão Voltar
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isResetting
                              ? null
                              : () {
                                  context.read<ForgotPasswordBloc>().add(
                                    PreviousStep(),
                                  );
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _isResetting
                                ? AppColors.secondaryDark.withValues(alpha: 0.5)
                                : AppColors.secondary,
                            side: BorderSide(
                              color: _isResetting
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
                              color: _isResetting
                                  ? AppColors.secondaryDark.withValues(alpha: 0.5)
                                  : AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Botão Alterar senha
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isResetting
                              ? null
                              : _isFormValid()
                              ? _resetPassword
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isResetting
                                ? AppColors.primaryOrange.withValues(alpha: 0.5)
                                : _isFormValid()
                                ? AppColors.primaryOrange
                                : AppColors.secondaryDark.withValues(alpha: 0.3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isResetting
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
                                      'Alterando...',
                                      style: AppTextStyles.paragraph.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Alterar senha',
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
