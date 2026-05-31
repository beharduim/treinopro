import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/realtime_data_service.dart';
import '../../../../core/helpers/status_bar_helper.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../auth/presentation/bloc/login_initial_bloc.dart';
import '../../../auth/presentation/pages/login_initial_page.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../home/presentation/pages/student_home_page.dart';
import '../../../home/presentation/pages/personal_home_page.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../proposals/presentation/bloc/proposal_search_bloc.dart';
import '../../../proposals/presentation/bloc/proposals_bloc.dart';
import '../../../balance/presentation/bloc/balance_bloc.dart';
import '../../../balance/presentation/bloc/balance_event.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';
import '../widgets/treino_pro_logo.dart';
import '../../../../core/widgets/shader_warmup_widget.dart';
import '../../../../core/services/first_animation_fix.dart';
import '../../../../core/services/simple_animation_warmup.dart';
import '../../../../core/services/transition_optimizer.dart';
import 'dart:io';
import 'dart:async';
import '../../../../core/services/fcm_token_service.dart';
import '../../../../core/services/live_activity_service.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/account_access_handler.dart';
import '../../../../core/errors/account_access_denied_exception.dart';
import '../../../../core/utils/approval_grace_period.dart';
import '../../../home/data/services/auth_service.dart';
import '../../../auth/presentation/pages/personal_approval_pending_page.dart';

/// Página da splash screen seguindo exatamente o design do Figma
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    // Define ícones brancos para a splash (fundo escuro)
    StatusBarHelper.setLightStatusBar();

    // Não bloquear a splash em warmup pesado de animação
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapSplash());
    });
  }

  Future<void> _bootstrapSplash() async {
    try {
      await Future.any([
        Future.wait([
          FirstAnimationFix().fixFirstAnimation(context),
          SimpleAnimationWarmup.warmUp(),
        ]),
        Future.delayed(const Duration(seconds: 4)),
      ]);
    } catch (e) {
      debugPrint('⚠️ [SPLASH] Warmup falhou, continuando: $e');
    }

    if (!mounted) return;
    context.read<SplashBloc>().add(const InitializeApp());
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      isDarkBackground: true, // Splash tem fundo escuro
      child: BlocListener<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is SplashLoaded) {
            _navigateToNextScreen(
              state.isAuthenticated,
              state.userType,
              state.approvalStatus,
              state.userCreatedAt,
              state.pendingAccountAccess,
            );
          } else if (state is SplashError) {
            // Mostrar erro se algo der errado
            _showErrorDialog(state.message);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Widget invisível para pré-aquecer shaders
              const ShaderWarmupWidget(),

              // Conteúdo principal
              Center(
                child: Container(
                  // Posicionamento exato conforme o Figma:
                  // Centralizado horizontal e verticalmente
                  alignment: Alignment.center,
                  child: const TreinoProLogo(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navega para a próxima tela baseado no status de autenticação e tipo de usuário
  void _navigateToNextScreen(
    bool isAuthenticated,
    String? userType,
    String? approvalStatus,
    String? userCreatedAt,
    AccountAccessDeniedException? pendingAccountAccess,
  ) {
    if (!mounted) return;

    if (!isAuthenticated) {
      _navigateToLogin().then((_) {
        if (pendingAccountAccess != null) {
          AccountAccessHandler.present(pendingAccountAccess);
        }
      });
      return;
    }

    final createdAt = userCreatedAt != null && userCreatedAt.isNotEmpty
        ? DateTime.tryParse(userCreatedAt)
        : null;
    if (userType == 'personal' &&
        shouldBlockPersonalForApproval(
          approvalStatus: approvalStatus,
          createdAt: createdAt,
        )) {
      _navigateToApprovalPending(approvalStatus ?? 'pending_review');
      return;
    }

    _navigateToHome(userType);
  }

  /// Navega para a tela de cadastro em análise (personal não aprovado)
  void _navigateToApprovalPending(String approvalStatus) {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PersonalApprovalPendingPage(approvalStatus: approvalStatus),
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Navega para a tela de login
  Future<void> _navigateToLogin() async {
    if (!mounted) return; // Verificar se o widget ainda está montado

    // Preparar a status bar para a próxima tela (também escura)
    StatusBarHelper.setLightStatusBar();

    // Otimizar transições antes da navegação
    await TransitionOptimizer().optimizeForNavigation();

    if (!mounted) return;

    // Opção 1: Fade Transition (suave)
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
          create: (context) => sl<LoginInitialBloc>(),
          child: const LoginInitialPage(),
        ),
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Navega para a tela home (usuário autenticado)
  void _navigateToHome(String? userType) async {
    if (!mounted) return;

    StatusBarHelper.setDarkStatusBar();
    await TransitionOptimizer().optimizeForNavigation();
    if (!mounted) return;

    Widget homePage;
    if (userType == 'student') {
      homePage = MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => sl<HomeBloc>()),
          BlocProvider(create: (context) => sl<ClassesBloc>()),
          BlocProvider(create: (context) => sl<GamificationBloc>()),
          BlocProvider.value(value: sl<RealtimeDataService>().proposalSearchBloc ?? sl<ProposalSearchBloc>()),
          BlocProvider(create: (context) => sl<ProposalsBloc>()),
        ],
        child: const StudentHomePage(),
      );
    } else {
      homePage = MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => sl<HomeBloc>()),
          BlocProvider(create: (context) => sl<ClassesBloc>()),
          BlocProvider(create: (context) => sl<GamificationBloc>()),
          BlocProvider.value(value: sl<RealtimeDataService>().proposalSearchBloc ?? sl<ProposalSearchBloc>()),
          BlocProvider(create: (context) => sl<ProposalsBloc>()),
          BlocProvider(create: (context) => sl<BalanceBloc>()..add(const LoadBalance())),
        ],
        child: const PersonalHomePage(),
      );
    }

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => homePage,
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    unawaited(_sendFcmTokenInBackground());
  }

  Future<void> _sendFcmTokenInBackground() async {
    try {
      final authService = sl<AuthService>();
      final userId = authService.currentUserId;

      if (userId == null || userId.isEmpty) {
        debugPrint('ℹ️ [SPLASH] Usuário não autenticado - token FCM não será enviado');
        return;
      }

      debugPrint('🔥 [SPLASH] Enviando token FCM em background para: $userId');
      await Future.delayed(const Duration(milliseconds: 1000));

      final fcmService = FcmTokenService();
      final success = await fcmService.ensureRegisteredForUser(userId);

      if (!success) {
        Future.delayed(const Duration(seconds: 3), () async {
          try {
            await fcmService.sendTokenToServer(userId);
          } catch (e) {
            debugPrint('❌ [SPLASH] Erro ao reenviar token FCM: $e');
          }
        });
      }

      if (Platform.isIOS) {
        await LiveActivityService.instance.flushPendingToken();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [SPLASH] Erro ao enviar token FCM: $e');
      debugPrint('📍 [SPLASH] Stack trace: $stackTrace');
    }
  }

  /// Mostra diálogo de erro
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Tenta inicializar novamente
              context.read<SplashBloc>().add(const InitializeApp());
            },
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
