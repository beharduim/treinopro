import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../auth/data/datasources/auth_api_datasource.dart';
import '../../../auth/presentation/pages/login_initial_page.dart';
import '../../../auth/presentation/bloc/login_initial_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tela exibida quando o cadastro do personal trainer está em análise ou rejeitado.
class PersonalApprovalPendingPage extends StatelessWidget {
  final String approvalStatus;

  const PersonalApprovalPendingPage({
    super.key,
    required this.approvalStatus,
  });

  bool get isRejected => approvalStatus == 'rejected';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isRejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
                size: 80,
                color: isRejected ? Colors.red[400] : AppColors.primaryOrange,
              ),
              const SizedBox(height: 32),
              Text(
                isRejected ? 'Cadastro não aprovado' : 'Cadastro em análise',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                isRejected
                    ? 'Infelizmente seu cadastro como Personal Trainer não foi aprovado. Entre em contato com o suporte para mais informações.'
                    : 'Seu cadastro como Personal Trainer está sendo analisado pela nossa equipe. Você será notificado quando a aprovação for concluída.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _logout(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Sair da conta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final dataSource = sl<AuthApiDataSource>();
      await dataSource.logout();
    } catch (_) {}

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
          create: (context) => sl<LoginInitialBloc>(),
          child: const LoginInitialPage(),
        ),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
      (route) => false,
    );
  }
}
