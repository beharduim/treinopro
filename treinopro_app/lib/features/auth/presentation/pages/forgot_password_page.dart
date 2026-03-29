import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/helpers/status_bar_helper.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../bloc/forgot_password_bloc.dart';
import '../bloc/forgot_password_state.dart';
import 'steps/forgot_password_email_step.dart';
import 'steps/forgot_password_otp_step.dart';
import 'steps/forgot_password_new_password_step.dart';

/// Página principal do fluxo de recuperação de senha
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  @override
  void initState() {
    super.initState();
    // Define ícones pretos para página clara
    StatusBarHelper.setDarkStatusBar();
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      isDarkBackground: false, // Página clara, ícones pretos
      child: BlocProvider(
        create: (context) => ForgotPasswordBloc(),
        child: Scaffold(
          backgroundColor: const Color(0xFFFCFDFE),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: Color(0xFF2D3748),
                size: 32,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Recuperar senha',
              style: AppTextStyles.h6Semibold.copyWith(
                color: AppColors.secondary,
              ),
            ),
            centerTitle: true,
          ),
          body: BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
            builder: (context, state) {
              return _buildCurrentStep(state);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(ForgotPasswordState state) {
    if (state is ForgotPasswordEmailStep) {
      return const ForgotPasswordEmailStepWidget();
    } else if (state is ForgotPasswordOtpStep) {
      return const ForgotPasswordOtpStepWidget();
    } else if (state is ForgotPasswordNewPasswordStep) {
      return const ForgotPasswordNewPasswordStepWidget();
    } else if (state is ForgotPasswordSuccess) {
      return _buildSuccessStep();
    } else {
      // Estado inicial - mostrar step de email
      return const ForgotPasswordEmailStepWidget();
    }
  }

  Widget _buildSuccessStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: AppColors.primaryOrange,
            ),
            const SizedBox(height: 24),
            Text(
              'Senha alterada com sucesso!',
              style: AppTextStyles.h6Semibold.copyWith(
                color: AppColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Sua senha foi alterada com sucesso. Agora você pode fazer login com sua nova senha.',
              style: AppTextStyles.paragraph.copyWith(
                color: AppColors.secondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Voltar para a página de login
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Fazer login',
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
    );
  }
}
