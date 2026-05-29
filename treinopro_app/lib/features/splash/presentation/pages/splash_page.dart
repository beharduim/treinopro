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
import '../../../../core/services/fcm_token_service.dart';
import '../../../../core/services/live_activity_service.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/utils/approval_grace_period.dart';

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

    // Aguarda o primeiro frame para garantir que o contexto está pronto
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Aplica fix agressivo para primeira animação
      await FirstAnimationFix().fixFirstAnimation(context);
      
      // Pré-carregar animações de forma simples (backup)
      await SimpleAnimationWarmup.warmUp();

      // Inicia a inicialização da aplicação
      if (mounted) {
        context.read<SplashBloc>().add(const InitializeApp());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      isDarkBackground: true, // Splash tem fundo escuro
      child: BlocListener<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is SplashLoaded) {
            // Navegar para a próxima tela quando a inicialização terminar
            _navigateToNextScreen(
              state.isAuthenticated,
              state.userType,
              state.approvalStatus,
              state.userCreatedAt,
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
  ) {
    if (!mounted) return;

    if (isAuthenticated) {
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
      // Usuário já está logado, navegar para a home baseada no tipo
      _navigateToHome(userType);
    } else {
      // Usuário não está logado, navegar para login
      _navigateToLogin();
    }
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
  void _navigateToLogin() async {
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
    if (!mounted) return; // Verificar se o widget ainda está montado

    // ✅ CORREÇÃO CRÍTICA: Enviar token FCM se usuário já está autenticado
    // Isso garante que o backend tenha o token atualizado para enviar notificações
    try {
      final authService = sl<AuthService>();
      final userId = authService.currentUserId;
      
      if (userId != null && userId.isNotEmpty) {
        debugPrint('🔥 [SPLASH] ===== ENVIANDO TOKEN FCM =====');
        debugPrint('🔥 [SPLASH] Usuário autenticado: $userId');
        
        // Aguardar um pouco mais para garantir que FCM tenha inicializado completamente
        await Future.delayed(const Duration(milliseconds: 1000));
        
        final fcmService = FcmTokenService();
        
        // ✅ CORREÇÃO: Verificar se token está disponível antes de enviar
        final currentToken = fcmService.currentToken;
        if (currentToken == null || currentToken.isEmpty) {
          debugPrint('⚠️ [SPLASH] Token FCM não disponível ainda, aguardando...');
          // Aguardar mais um pouco e tentar obter token novamente
          await Future.delayed(const Duration(milliseconds: 1000));
        }
        
        debugPrint('🔥 [SPLASH] Enviando token FCM para backend...');
        final success = await fcmService.sendTokenToServer(userId);
        
        if (success) {
          debugPrint('✅ [SPLASH] Token FCM enviado com sucesso para backend');
        } else {
          debugPrint('⚠️ [SPLASH] Token FCM não pôde ser enviado agora');
          debugPrint('⚠️ [SPLASH] Tentando novamente após mais tempo...');
          // Tentar novamente após mais tempo (não bloquear navegação)
          Future.delayed(const Duration(seconds: 3), () async {
            try {
              final retrySuccess = await fcmService.sendTokenToServer(userId);
              if (retrySuccess) {
                debugPrint('✅ [SPLASH] Token FCM enviado com sucesso na segunda tentativa');
              } else {
                debugPrint('❌ [SPLASH] Token FCM não pôde ser enviado mesmo após retry');
              }
            } catch (e) {
              debugPrint('❌ [SPLASH] Erro ao reenviar token FCM: $e');
            }
          });
        }
        debugPrint('🔥 [SPLASH] ===== FIM DO ENVIO DE TOKEN FCM =====');
        // Flush any Live Activity token that arrived before this session
        if (Platform.isIOS) {
          await LiveActivityService.instance.flushPendingToken();
        }
      } else {
        debugPrint('ℹ️ [SPLASH] Usuário não autenticado - token FCM não será enviado');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [SPLASH] Erro ao enviar token FCM: $e');
      debugPrint('📍 [SPLASH] Stack trace: $stackTrace');
      // Não bloquear navegação se FCM falhar
    }

    // Preparar a status bar para a home
    StatusBarHelper.setDarkStatusBar();

    // Otimizar transições antes da navegação
    await TransitionOptimizer().optimizeForNavigation();

    if (!mounted) return;

    // Navegar para a home baseada no tipo de usuário
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
      // Personal trainer ou tipo não identificado (fallback para personal)
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

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => homePage,
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((_) async {
      // Deep link será processado pela PersonalHomePage/StudentHomePage
      // Não processar aqui para evitar race condition
      debugPrint('🔗 [SPLASH] Navegação concluída. Deep link pendente: ${DeepLinkService.hasPendingDeepLink}');
    });

    // Opção 2: Slide Transition (deslizar da direita)
    /*
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
          create: (context) => sl<LoginInitialBloc>(),
          child: const LoginInitialPage(),
        ),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
    */

    // Opção 3: Scale + Fade Transition (zoom suave)
    /*
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
          create: (context) => sl<LoginInitialBloc>(),
          child: const LoginInitialPage(),
        ),
        transitionDuration: const Duration(milliseconds: 700),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              )),
              child: child,
            ),
          );
        },
      ),
    );
    */

    // Opção 4: Rotation + Fade (rotação suave)
    /*
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
          create: (context) => sl<LoginInitialBloc>(),
          child: const LoginInitialPage(),
        ),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: RotationTransition(
              turns: Tween<double>(
                begin: 0.1,
                end: 0.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              )),
              child: child,
            ),
          );
        },
      ),
    );
    */
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
