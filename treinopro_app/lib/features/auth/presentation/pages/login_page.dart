import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/helpers/status_bar_helper.dart';
import '../../../../core/helpers/navigation_helper.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../core/widgets/optimized_loading_indicator.dart';
import '../../../../core/widgets/animated_logo.dart';
import '../../../../core/services/first_animation_fix.dart';
import '../../../../core/services/animation_preloader.dart';
import '../../../../core/services/transition_optimizer.dart';
import '../../../../core/services/performance_monitor.dart';
import '../../../../core/widgets/optimized_button.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import '../widgets/custom_text_field.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/realtime_data_service.dart';
import 'dart:io';
import '../../../../core/services/fcm_token_service.dart';
import '../../../../core/services/live_activity_service.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import '../../../classes/presentation/bloc/classes_event.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../proposals/presentation/bloc/proposal_search_bloc.dart';
import '../../../proposals/presentation/bloc/proposals_bloc.dart';
import '../../../home/data/services/auth_service.dart';
import '../../../home/presentation/pages/student_home_page.dart';
import '../../../home/presentation/pages/personal_home_page.dart';
import '../../../home/presentation/bloc/home_bloc.dart';
import '../../../balance/presentation/bloc/balance_bloc.dart';
import '../../../balance/presentation/bloc/balance_event.dart';
import 'login_initial_page.dart';
import '../bloc/login_initial_bloc.dart';
import 'forgot_password_page.dart';
import 'personal_approval_pending_page.dart';

/// Página de formulário de login seguindo exatamente o design do Figma
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _emailHasError = false;
  bool _passwordHasError = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    // Para o monitoramento de performance
    PerformanceMonitor().stopMonitoring();

    super.dispose();
  }

  /// Inicializa todas as otimizações de performance
  Future<void> _initializeOptimizations() async {
    try {
      debugPrint('🎯 Iniciando otimizações de performance...');
      
      // Inicia monitoramento de performance
      PerformanceMonitor().startMonitoring();

      // Executa otimizações em paralelo
      await Future.wait([
        // Pré-carrega animações
        AnimationPreloader().preloadAnimations(context),
        // Otimiza transições
        TransitionOptimizer().optimizeTransitions(),
        // Aplica fix específico para primeira animação
        FirstAnimationFix().fixFirstAnimation(context),
      ]);

      debugPrint('🎯 Todas as otimizações concluídas');
    } catch (e) {
      debugPrint('⚠️ Erro nas otimizações: $e');
    }
  }

  /// Manipula o sucesso do login com otimizações
  Future<void> _handleLoginSuccess(
    BuildContext context,
    LoginSuccess state,
  ) async {
    try {
      debugPrint('🔐 [LOGIN] Iniciando processo de login para userId: ${state.user.id}');
      
      // CRÍTICO: Aguardar um frame para garantir que o token foi salvo
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Verificar se o token foi realmente salvo
      final authService = sl<AuthService>();
      final savedUserId = authService.currentUserId;
      
      debugPrint('🔐 [LOGIN] UserId salvo no AuthService: $savedUserId');
      debugPrint('🔐 [LOGIN] UserId do login: ${state.user.id}');
      
      if (savedUserId != state.user.id) {
        debugPrint('❌ [LOGIN] ERRO - UserId não corresponde! Aguardando...');
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      // AGORA SIM inicializar serviços após login bem-sucedido
      final classesBloc = context.read<ClassesBloc>();
      classesBloc.add(const ClassesInitialize());
      
      debugPrint('🔌 [LOGIN] Conectando WebSocket com novo token...');
      classesBloc.add(const ClassesConnectWebSocket());


      // ✅ Enviar token FCM para o servidor após login bem-sucedido
      // Aguardar um pouco para garantir que FCM tenha inicializado
      debugPrint('🔥 [LOGIN] Aguardando inicialização do FCM...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('🔥 [LOGIN] Enviando token FCM para o servidor...');
      try {
        final fcmService = FcmTokenService();
        final success = await fcmService.sendTokenToServer(state.user.id);
        if (success) {
          debugPrint('✅ [LOGIN] Token FCM enviado com sucesso');
        } else {
          debugPrint('⚠️ [LOGIN] Token FCM não pôde ser enviado (pode ser que ainda esteja inicializando)');
          // Tentar novamente após mais tempo
          Future.delayed(const Duration(seconds: 2), () async {
            final retrySuccess = await fcmService.sendTokenToServer(state.user.id);
            if (retrySuccess) {
              debugPrint('✅ [LOGIN] Token FCM enviado com sucesso na segunda tentativa');
            } else {
              debugPrint('⚠️ [LOGIN] Token FCM não pôde ser enviado mesmo após retry');
            }
          });
        }
        // Flush any Live Activity token that arrived before login
        if (Platform.isIOS) {
          await LiveActivityService.instance.flushPendingToken();
        }
      } catch (e) {
        debugPrint('⚠️ [LOGIN] Erro ao enviar token FCM: $e');
        // Não bloquear o login se FCM falhar
      }

      // Navegar baseado no tipo de usuário e status de aprovação
      Widget homePage;

      final approvalStatus = state.user.approvalStatus;
      // Treat null approvalStatus as not approved — a personal without explicit
      // 'approved' status must not bypass the pending screen.
      final isPersonalPending = state.user.userType == 'personal' &&
          approvalStatus != 'approved';

      if (isPersonalPending) {
        // Personal com cadastro em análise, rejeitado ou sem status definido
        homePage = PersonalApprovalPendingPage(
          approvalStatus: approvalStatus ?? 'pending_review',
        );
      } else if (state.user.userType == 'student') {
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
        // Personal trainer aprovado
        homePage = MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => sl<HomeBloc>()),
            BlocProvider(create: (context) => sl<ClassesBloc>()),
            BlocProvider(create: (context) => sl<GamificationBloc>()),
            BlocProvider.value(value: sl<RealtimeDataService>().proposalSearchBloc ?? sl<ProposalSearchBloc>()),
            BlocProvider(create: (context) => sl<ProposalsBloc>()),
          ],
          child: const PersonalHomePage(),
        );
      }

      // Otimizar transição antes da navegação
      await TransitionOptimizer().optimizeForNavigation();

      if (context.mounted) {
        NavigationHelper.pushReplacementWithFade(context, homePage);
      }
    } catch (e) {
      debugPrint('⚠️ Erro no login success: $e');
      // Navegar mesmo com erro de otimização
      if (context.mounted) {
        final approvalStatus = state.user.approvalStatus;
        final isPersonalPending = state.user.userType == 'personal' &&
            approvalStatus != 'approved';

        Widget homePage;
        if (isPersonalPending) {
          homePage = PersonalApprovalPendingPage(
            approvalStatus: approvalStatus ?? 'pending_review',
          );
        } else if (state.user.userType == 'student') {
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
        NavigationHelper.pushReplacementWithFade(context, homePage);
      }
    }
  }

  void _validateAndSubmit(BuildContext context) {
    setState(() {
      _emailHasError = false;
      _passwordHasError = false;
    });

    String? emailError;
    String? passwordError;

    // Validação de email
    if (_emailController.text.isEmpty) {
      emailError = 'Por favor, digite seu email';
      _emailHasError = true;
    } else if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(_emailController.text)) {
      emailError = 'Por favor, digite um email válido';
      _emailHasError = true;
    }

    // Validação de senha
    if (_passwordController.text.isEmpty) {
      passwordError = 'Por favor, digite sua senha';
      _passwordHasError = true;
    } else if (_passwordController.text.length < 6) {
      passwordError = 'A senha deve ter pelo menos 6 caracteres';
      _passwordHasError = true;
    }

    setState(() {});

    // Mostrar erros em SnackBar
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(passwordError),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Se chegou até aqui, os dados são válidos
    context.read<LoginBloc>().add(
      LoginWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Define ícones pretos para página clara
    StatusBarHelper.setDarkStatusBar();

    // Pré-carregar animações e otimizar transições após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeOptimizations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Detecta se o teclado está visível
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return StatusBarWrapper(
      isDarkBackground: false, // Página clara, ícones pretos
      child: BlocProvider(
        create: (_) => sl<LoginBloc>(),
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: const Color(0xFFFCFDFE),
            body: BlocListener<LoginBloc, LoginState>(
              listener: (context, state) {
                if (state is LoginSuccess) {
                  _handleLoginSuccess(context, state);
                } else if (state is LoginError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Stack(
                children: [
                  // Botão de voltar otimizado
                  Positioned(
                    top: 16,
                    left: 16,
                    child: SafeArea(
                      child: OptimizedInkWell(
                        onTap: () => NavigationHelper.pushReplacementWithFade(
                          context,
                          BlocProvider(
                            create: (context) => sl<LoginInitialBloc>(),
                            child: const LoginInitialPage(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.chevron_left,
                            color: const Color(0xFF2D3748),
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Conteúdo centralizado
                  Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo animado - só aparece quando o teclado não está visível
                          AnimatedLogo(
                            size: 160,
                            isVisible: !isKeyboardVisible,
                            animationDuration: const Duration(
                              milliseconds: 400,
                            ),
                          ),

                          // Espaçamento dinâmico
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            height: isKeyboardVisible ? 24 : 48,
                          ),

                          // Container principal
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Campo de email
                                  CustomTextField(
                                    controller: _emailController,
                                    placeholder: 'E-mail',
                                    keyboardType: TextInputType.emailAddress,
                                    hasError: _emailHasError,
                                  ),

                                  const SizedBox(height: 16),

                                  // Campo de senha
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFF3F3F3,
                                      ), // Mesma cor do CustomTextField
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: _passwordHasError
                                            ? Colors.red
                                            : const Color(0xFF42464D),
                                        width: _passwordHasError ? 2.0 : 0.5,
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: AppTextStyles.paragraph.copyWith(
                                        color: const Color(
                                          0xFF2D3748,
                                        ), // Cor preta padrão
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Senha',
                                        hintStyle: AppTextStyles.paragraph
                                            .copyWith(
                                              color: const Color(
                                                0xFF9CA3AF,
                                              ), // Mesmo tom do CustomTextField
                                            ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal:
                                              16, // Mesmo padding do CustomTextField
                                          vertical:
                                              24, // Mesmo padding do CustomTextField
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        focusedErrorBorder: InputBorder.none,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: AppColors.secondaryDark,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Link "Esqueci minha senha"
                                  BlocBuilder<LoginBloc, LoginState>(
                                    builder: (context, state) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: GestureDetector(
                                          onTap: state is LoginLoading
                                              ? null
                                              : () {
                                                  NavigationHelper.pushWithSlide(
                                                    context,
                                                    const ForgotPasswordPage(),
                                                  );
                                                },
                                          child: Text(
                                            'Esqueci minha senha',
                                            style: AppTextStyles.h6.copyWith(
                                              color: AppColors.primaryOrange,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 24),

                                  // Botão "Entrar" otimizado
                                  BlocBuilder<LoginBloc, LoginState>(
                                    builder: (context, state) {
                                      return SizedBox(
                                        height: 56,
                                        child: OptimizedButton(
                                          onPressed: state is LoginLoading
                                              ? null
                                              : () =>
                                                    _validateAndSubmit(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryOrange,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: state is LoginLoading
                                              ? const OptimizedLoadingIndicator(
                                                  size: 20,
                                                  strokeWidth: 2,
                                                  color: Color(0xFF2D3748),
                                                )
                                              : Text(
                                                  'Entrar',
                                                  style: AppTextStyles
                                                      .h6Semibold
                                                      .copyWith(
                                                        color: AppColors.white,
                                                      ),
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}