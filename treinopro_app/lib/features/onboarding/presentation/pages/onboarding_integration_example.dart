import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/dependency_injection.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import 'student_onboarding_page.dart';

/// Exemplo de como integrar o onboarding no fluxo de login
/// Esta página demonstra como verificar se o usuário precisa de onboarding
/// e como navegar para ele quando necessário
class OnboardingIntegrationExample extends StatefulWidget {
  const OnboardingIntegrationExample({super.key});

  @override
  State<OnboardingIntegrationExample> createState() => _OnboardingIntegrationExampleState();
}

class _OnboardingIntegrationExampleState extends State<OnboardingIntegrationExample> {
  bool _isCheckingOnboarding = false;
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    // Simular verificação de onboarding ao inicializar
    _checkOnboardingStatus();
  }

  /// Verifica se o usuário precisa de onboarding
  Future<void> _checkOnboardingStatus() async {
    setState(() {
      _isCheckingOnboarding = true;
    });

    try {
      final onboardingBloc = sl<OnboardingBloc>();
      onboardingBloc.add(const InitializeOnboarding());
      
      // Aguardar um pouco para simular a verificação
      await Future.delayed(const Duration(seconds: 1));
      
      // Em um caso real, você usaria o BLoC para verificar o estado
      // Por enquanto, vamos simular um resultado
      setState(() {
        _onboardingCompleted = false; // Simular que precisa de onboarding
        _isCheckingOnboarding = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingOnboarding = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao verificar onboarding: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navega para o onboarding
  void _navigateToOnboarding() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => sl<OnboardingBloc>(),
          child: const StudentOnboardingPage(),
        ),
      ),
    );
  }

  /// Simula login bem-sucedido
  void _simulateSuccessfulLogin() {
    // Em um caso real, aqui você faria o login
    // e depois verificaria se precisa de onboarding
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Simulado'),
        content: const Text('Login realizado com sucesso! Verificando se você precisa de onboarding...'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkOnboardingStatus();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      appBar: AppBar(
        backgroundColor: AppColors.loginBackground,
        elevation: 0,
        title: Text(
          'Integração do Onboarding',
          style: AppTextStyles.h6Semibold.copyWith(
            color: AppColors.secondary,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status do onboarding
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Status do Onboarding',
                      style: AppTextStyles.h6Semibold.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isCheckingOnboarding)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryOrange,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text('Verificando...'),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _onboardingCompleted 
                                ? Icons.check_circle 
                                : Icons.info,
                            color: _onboardingCompleted 
                                ? Colors.green 
                                : AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _onboardingCompleted 
                                ? 'Onboarding já foi completado'
                                : 'Usuário precisa de onboarding',
                            style: AppTextStyles.paragraph.copyWith(
                              color: AppColors.secondaryDark,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botão para simular login
            ElevatedButton(
              onPressed: _simulateSuccessfulLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Simular Login',
                style: AppTextStyles.buttonPrimary.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botão para abrir onboarding diretamente
            ElevatedButton(
              onPressed: _navigateToOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Abrir Onboarding',
                style: AppTextStyles.buttonSecondary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instruções
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como Integrar:',
                      style: AppTextStyles.h6Semibold.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '1. Após login bem-sucedido, verifique se o usuário precisa de onboarding\n'
                      '2. Use CheckOnboardingCompletedUseCase para verificar\n'
                      '3. Se necessário, navegue para StudentOnboardingPage\n'
                      '4. Após conclusão, o usuário vai para a tela principal',
                      style: AppTextStyles.paragraph.copyWith(
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
