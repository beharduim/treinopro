import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:treinopro_app/core/services/notification_service.dart';
import 'package:treinopro_app/core/services/notification_foreground_service.dart';
import 'package:treinopro_app/core/services/fcm_workmanager_service.dart';
import 'core/services/class_presence_snapshot_service.dart';
import 'package:treinopro_app/firebase_options.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'core/di/dependency_injection.dart' as di;
import 'core/theme/app_theme.dart';
import 'core/helpers/status_bar_helper.dart';
import 'core/config/app_config.dart';
import 'features/splash/presentation/bloc/splash_bloc.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/classes/presentation/bloc/classes_bloc.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/home/presentation/pages/personal_home_page.dart';
import 'features/home/presentation/pages/student_home_page.dart';
import 'features/classes/presentation/pages/classes_page.dart';
import 'features/classes/presentation/pages/my_disputes_page.dart';
import 'features/classes/presentation/widgets/global_timer_widget.dart';
import 'features/profile/presentation/pages/personal_profile_page.dart';
import 'features/profile/presentation/pages/student_profile_page.dart';
import 'features/proposals/presentation/pages/proposals_page.dart';
import 'core/navigation/app_navigator.dart';
import 'features/chat/presentation/pages/chat_page.dart';
import 'features/gamification/presentation/bloc/gamification_bloc.dart';
import 'features/proposals/presentation/bloc/proposals_bloc.dart';
import 'features/proposals/presentation/bloc/proposal_search_bloc.dart';
import 'core/services/realtime_data_service.dart';
import 'core/services/websocket_service.dart';
import 'core/services/live_activity_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/api_service.dart';
import 'features/home/data/services/auth_service.dart';
import 'package:get_it/get_it.dart' show GetIt;
import 'package:flutter/services.dart';
import 'features/balance/presentation/bloc/balance_bloc.dart';
import 'features/balance/presentation/bloc/balance_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ CRÍTICO: Inicializar port de comunicação para foreground service
  // DEVE ser chamado ANTES de runApp() para permitir comunicação entre isolates
  if (Platform.isAndroid) {
    FlutterForegroundTask.initCommunicationPort();
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ CRÍTICO: Registrar background handler ANTES de qualquer outra coisa
  // Este handler é executado quando app está em background ou terminado
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
  debugPrint('✅ [MAIN] Background message handler registrado');

  // Inicializar notificações e obter FCM Token
  await NotificationService.initializeNotification();

  // ✅ NOVO: Configurar listener de token refresh
  await NotificationService.setupTokenRefreshListener();
  debugPrint('✅ [MAIN] Token refresh listener configurado');

  // ✅ Inicializar Live Activity Service (iOS only)
  if (Platform.isIOS) {
    LiveActivityService.instance.initialize();
    LiveActivityService.instance.onTokenReceived = _sendLiveActivityToken;
    debugPrint('✅ [MAIN] LiveActivityService inicializado');

    // Processa tentativas pendentes salvas quando push chegou em background isolate.
    await NotificationService.processPendingLiveActivities();
  }

  // ✅ REMOVIDO: Solicitação de permissão de bateria agora é feita pelo AppPermissionsService
  // na SplashPage junto com as outras permissões (localização e background location)
  // Isso garante que todas as permissões sejam solicitadas na primeira vez que o app abre
  // await BatteryOptimizationService.ensureBatteryOptimizationDisabled();

  // ✅ NOVO: Inicializar WorkManager para health checks periódicos
  // Garante wake-up a cada 15 minutos para verificar FCM
  if (Platform.isAndroid) {
    await FcmWorkManagerService.initialize();
    debugPrint(
      '✅ [MAIN] WorkManager inicializado - Health checks periódicos ativos',
    );
  }

  // ✅ NOVO: Inicializar foreground service (Android only)
  // Previne Doze Mode e garante entrega de notificações mesmo após horas em background
  // NOTA: O serviço será iniciado APÓS as permissões serem concedidas (no AppPermissionsService)
  // NOTA: Se falhar, WorkManager fornece camada adicional de proteção
  if (Platform.isAndroid) {
    // Apenas inicializar - NÃO iniciar ainda (precisa de permissões primeiro)
    await NotificationForegroundService.initialize();
    debugPrint(
      '✅ [MAIN] Foreground service inicializado (será iniciado após permissões serem concedidas)',
    );
  }

  // Otimizações de performance para animações
  _setupPerformanceOptimizations();

  // Carrega as configurações de ambiente
  await AppConfig.load();
  if (AppConfig.stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = AppConfig.stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  // Inicializa SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Configura as dependências
  await di.setupDependencyInjection(prefs);

  // Configura o estilo inicial da status bar
  StatusBarHelper.setLightStatusBar(); // Começar com ícones brancos (splash)

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.sl<SplashBloc>()),
        BlocProvider(create: (context) => di.sl<HomeBloc>()),
        BlocProvider(create: (context) => di.sl<ClassesBloc>()),
      ],
      child: const TreinoProApp(),
    ),
  );
}

/// Envia token de Live Activity ao backend.
/// Lançar exceção faz o LiveActivityService persistir para retry posterior.
Future<void> _sendLiveActivityToken(String proposalId, String token) async {
  final sl = GetIt.instance;
  final userId = sl.isRegistered<AuthService>()
      ? sl<AuthService>().currentUserId
      : null;

  if (userId == null || userId.isEmpty) {
    throw Exception('userId indisponível — token será reenviado após login');
  }

  await sl<ApiService>().dio.put(
    '/users/$userId/live-activity-token',
    data: {'token': token, 'proposalId': proposalId},
  );
  debugPrint('[LiveActivity] Token enviado ao backend: proposal=$proposalId');
}

/// Configura otimizações de performance para animações suaves
void _setupPerformanceOptimizations() {
  // Força o sistema a estar pronto para animações
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _warmUpRenderer();
  });

  // Adiciona um delay mínimo para garantir que o sistema esteja pronto
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 100), () {
      _performAdditionalWarmUp();
    });
  });
}

/// Aquece o renderer para evitar travamentos na primeira animação
void _warmUpRenderer() {
  // Força múltiplos frames para aquecer o sistema de animações
  SchedulerBinding.instance.addPostFrameCallback((_) {
    _performWarmUpAnimations();
  });
}

/// Executa animações invisíveis para aquecer o sistema
void _performWarmUpAnimations() {
  // Cria um AnimationController temporário para aquecer o sistema
  final vsync = _WarmUpTickerProvider();
  final controller = AnimationController(
    duration: const Duration(milliseconds: 1),
    vsync: vsync,
  );

  // Executa uma animação rápida e invisível
  controller.forward().then((_) {
    controller.dispose();
    vsync.dispose();
  });

  // Força a criação de objetos de renderização comuns
  final paint = Paint()
    ..color = Colors.transparent
    ..style = PaintingStyle.fill
    ..strokeWidth = 1.0;

  // Aquece shaders de bordas arredondadas
  RRect.fromRectAndRadius(
    const Rect.fromLTWH(0, 0, 1, 1),
    const Radius.circular(4),
  );

  // Limpa referências
  paint.color = Colors.transparent;
}

/// Executa aquecimento adicional do sistema de animações
void _performAdditionalWarmUp() {
  // Força la criação de múltiplos objetos de animação
  final vsync = _WarmUpTickerProvider();

  // Cria múltiplos controllers para diferentes tipos de animação
  final controllers = [
    AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    ),
    AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: vsync,
    ),
    AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: vsync,
    ),
  ];

  // Executa animações rápidas para aquecer o sistema
  for (int i = 0; i < controllers.length; i++) {
    final controller = controllers[i];
    Future.delayed(Duration(milliseconds: i * 10), () {
      controller.forward().then((_) {
        controller.dispose();
      });
    });
  }

  // Limpa o ticker provider após um tempo
  Future.delayed(const Duration(milliseconds: 500), () {
    vsync.dispose();
  });
}

/// TickerProvider temporário para warm-up
class _WarmUpTickerProvider implements TickerProvider {
  final List<Ticker> _tickers = [];

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = Ticker(onTick);
    _tickers.add(ticker);
    return ticker;
  }

  void dispose() {
    for (final ticker in _tickers) {
      ticker.dispose();
    }
    _tickers.clear();
  }
}

class TreinoProApp extends StatefulWidget {
  const TreinoProApp({super.key});

  @override
  State<TreinoProApp> createState() => _TreinoProAppState();
}

class _TreinoProAppState extends State<TreinoProApp>
    with WidgetsBindingObserver {
  static const _deepLinkChannel = MethodChannel(
    'com.treinopro.oficial/deep_link',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isIOS) {
      _deepLinkChannel.setMethodCallHandler(_handleDeepLinkFromNative);
    }
  }

  Future<void> _handleDeepLinkFromNative(MethodCall call) async {
    if (call.method == 'onDeepLink') {
      final url = call.arguments as String?;
      if (url != null && url.isNotEmpty) {
        debugPrint('🔗 [MAIN] Deep link recebido do nativo: $url');
        await DeepLinkService().handleDeepLink(url);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    // LOG DETALHADO para debug
    debugPrint('🔄 [MAIN] didChangeAppLifecycleState chamado: $state');

    // ✅ Atualizar estado no NotificationService
    NotificationService.updateAppLifecycleState(state);

    // Converter AppLifecycleState para String para o WebSocketService
    String stateString = '';
    switch (state) {
      case AppLifecycleState.resumed:
        stateString = 'resumed';
        debugPrint('✅ [MAIN] App voltou ao FOREGROUND');
        break;
      case AppLifecycleState.inactive:
        stateString = 'inactive';
        debugPrint('⚠️ [MAIN] App em INACTIVE (transição)');
        break;
      case AppLifecycleState.paused:
        stateString = 'paused';
        debugPrint('⏸️ [MAIN] App em PAUSED (background)');
        break;
      case AppLifecycleState.detached:
        stateString = 'detached';
        debugPrint('❌ [MAIN] App DETACHED (quase fechado)');
        break;
      case AppLifecycleState.hidden:
        stateString = 'paused'; // Tratar como paused
        debugPrint('👁️ [MAIN] App HIDDEN (tratado como paused)');
        break;
    }

    // Gerenciar WebSocket baseado no lifecycle
    try {
      final wsService = di.sl<WebSocketService>();
      debugPrint(
        '📱 [MAIN] Chamando handleAppLifecycleChange com: $stateString',
      );
      wsService.handleAppLifecycleChange(stateString);
      debugPrint(
        '📱 [MAIN] App lifecycle: $stateString - WebSocket gerenciado',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [MAIN] Erro ao gerenciar WebSocket no lifecycle: $e');
      debugPrint('📍 [MAIN] Stack: $stackTrace');
    }

    // Tentar capturar snapshots de presença pendentes ao retornar ao foreground
    if (state == AppLifecycleState.resumed) {
      try {
        await ClassPresenceSnapshotService.instance.onAppResumed();
      } catch (e) {
        debugPrint('⚠️ [MAIN] Erro ao processar snapshots pendentes: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TreinoPro',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.navigatorKey,
      // Força o builder para garantir que as animações funcionem
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Força animações mesmo em dispositivos com animações desabilitadas
            disableAnimations: false,
          ),
          child: child!,
        );
      },
      // Configurações de localização
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Português do Brasil
        Locale('en', 'US'), // Inglês americano
      ],
      locale: const Locale('pt', 'BR'), // Locale padrão
      home: const AppWithGlobalTimer(),
      // Rotas nomeadas usadas pela navegação interna
      routes: {
        '/personal-home': (context) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => di.sl<HomeBloc>()),
            BlocProvider(create: (context) => di.sl<ClassesBloc>()),
            BlocProvider(create: (context) => di.sl<GamificationBloc>()),
            BlocProvider.value(
              value:
                  di.sl<RealtimeDataService>().proposalSearchBloc ??
                  di.sl<ProposalSearchBloc>(),
            ),
            BlocProvider(create: (context) => di.sl<ProposalsBloc>()),
            BlocProvider(create: (context) => di.sl<BalanceBloc>()..add(const LoadBalance())),
          ],
          child: Builder(
            builder: (context) {
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              final initialTab = (args?['initialTabIndex'] as int?) ?? 0;
              return PersonalHomePage(initialTabIndex: initialTab);
            },
          ),
        ),
        '/student-home': (context) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => di.sl<HomeBloc>()),
            BlocProvider(create: (context) => di.sl<ClassesBloc>()),
            BlocProvider(create: (context) => di.sl<GamificationBloc>()),
            BlocProvider.value(
              value:
                  di.sl<RealtimeDataService>().proposalSearchBloc ??
                  di.sl<ProposalSearchBloc>(),
            ),
            BlocProvider(create: (context) => di.sl<ProposalsBloc>()),
          ],
          child: const StudentHomePage(),
        ),
        '/student-profile': (context) => const StudentProfilePage(),
        '/classes': (context) => const ClassesPage(),
        '/profile': (context) => const PersonalProfilePage(),
        '/my-disputes': (context) => BlocProvider(
          create: (context) => di.sl<ClassesBloc>(),
          child: const MyDisputesPage(),
        ),
        '/proposals': (context) => const ProposalsPage(),
        // '/training' não existe ainda; redireciona para home por enquanto
        '/training': (context) => const PersonalHomePage(),
        '/chat': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final classId = (args?['classId'] ?? '').toString();
          final receiverId = (args?['receiverId'] ?? '').toString();
          final receiverName = (args?['receiverName'] ?? 'Contato').toString();
          final location = (args?['location'] ?? 'Local a definir').toString();
          final date = (args?['date'] ?? '').toString();
          final time = (args?['time'] ?? '').toString();
          final duration = (args?['duration'] ?? '').toString();
          final currentUserIsStudent =
              (args?['currentUserIsStudent'] ?? false) == true;
          return ChatPage(
            classId: classId,
            receiverId: receiverId,
            receiverName: receiverName,
            location: location,
            date: date,
            time: time,
            duration: duration,
            currentUserIsStudent: currentUserIsStudent,
          );
        },
      },
    );
  }
}

/// Widget que envolve toda a aplicação com o timer global
class AppWithGlobalTimer extends StatelessWidget {
  const AppWithGlobalTimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Páginas normais
          const SplashPage(),

          // Timer global por cima
          const GlobalTimerWidget(),
        ],
      ),
    );
  }
}
