import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/helpers/status_bar_helper.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../core/widgets/custom_top_bar.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/data_refresh_service.dart';
import '../../../../core/services/realtime_data_service.dart';
import '../../../gamification/data/services/mission_completion_service.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_event.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import '../../../classes/presentation/bloc/classes_event.dart';
import '../../../classes/presentation/bloc/classes_state.dart';
import '../../../proposals/presentation/bloc/proposals_bloc.dart';
import '../../../proposals/presentation/bloc/proposal_search_bloc.dart';
import '../../../gamification/presentation/widgets/gamification_animations.dart';
import '../../../gamification/presentation/services/gamification_dev_notice_coordinator.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../../domain/entities/home_state.dart';
import '../widgets/user_greeting_card.dart';
import '../widgets/weekly_mission_card.dart';
import '../widgets/health_questionnaire_button.dart';
import '../widgets/dynamic_workout_card.dart';
import '../widgets/achievements_workouts_cards.dart';
import '../../widgets/student_bottom_navigation.dart';
import '../../../notifications/notifications.dart';
import '../../../classes/presentation/pages/student_classes_page.dart';
import '../../../profile/presentation/pages/student_profile_page.dart';

/// Página principal da home do aluno
class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage>
    with WidgetsBindingObserver, NotificationsMixin {
  int _currentBottomNavIndex = 0;
  late DataRefreshService _dataRefreshService; // Mantido para compatibilidade
  late RealtimeDataService
  _realtimeDataService; // Serviço centralizado em tempo real
  late MissionCompletionService _missionCompletionService;

  @override
  void initState() {
    super.initState();

    // Registrar observer para detectar mudanças de lifecycle
    WidgetsBinding.instance.addObserver(this);

    // Define ícones pretos para páginas claras
    StatusBarHelper.setDarkStatusBar();

    // Inicializar serviços
    _dataRefreshService =
        sl<DataRefreshService>(); // Mantido para compatibilidade
    _realtimeDataService =
        sl<RealtimeDataService>(); // Serviço centralizado em tempo real
    _missionCompletionService = sl<MissionCompletionService>();

    // Inicializa a home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🏠 [STUDENT_HOME] addPostFrameCallback executado');

      try {
        // ✅ CORREÇÃO: Inicializar apenas se ainda não foi inicializado
        final homeBloc = context.read<HomeBloc>();

        print('🏠 [STUDENT_HOME] HomeBloc obtido do contexto');
        print(
          '🏠 [STUDENT_HOME] Estado atual do HomeBloc: ${homeBloc.state.runtimeType}',
        );
        print('🏠 [STUDENT_HOME] HomeBloc isClosed: ${homeBloc.isClosed}');

        if (!homeBloc.isClosed && homeBloc.state is HomeInitial) {
          print('🏠 [STUDENT_HOME] Inicializando HomeBloc pela primeira vez');
          homeBloc.add(const InitializeHome());
          print('🏠 [STUDENT_HOME] Evento InitializeHome adicionado');
        } else {
          print(
            '⚠️ [STUDENT_HOME] HomeBloc já foi inicializado, estado atual: ${homeBloc.state.runtimeType}',
          );
        }

        // Conectar WebSocket agora que o usuário está autenticado
        final classesBloc = context.read<ClassesBloc>();
        if (!classesBloc.isClosed) {
          classesBloc.add(const ClassesConnectWebSocket());
        }

        // Inicializar serviço em tempo real IMEDIATAMENTE (sem delay)
        _realtimeDataService.initialize(
          homeBloc: homeBloc,
          classesBloc: classesBloc,
          proposalsBloc: context.read<ProposalsBloc>(),
          gamificationBloc: context.read<GamificationBloc>(),
          proposalSearchBloc: context.read<ProposalSearchBloc>(),
        );

        // Exibe aviso de gamificação em desenvolvimento (1x por sessão)
        sl<GamificationDevNoticeCoordinator>().maybeShow(context);
      } catch (e) {
        print('❌ [STUDENT_HOME] Erro ao inicializar: $e');
        print('❌ [STUDENT_HOME] Stack trace: ${StackTrace.current}');
      }
    });
  }

  @override
  void dispose() {
    // Remover observer
    WidgetsBinding.instance.removeObserver(this);

    // Parar serviços
    _realtimeDataService.dispose(); // Serviço centralizado em tempo real
    _missionCompletionService.stopMonitoring();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Notificar o mixin de notificações sobre mudança de lifecycle
    onAppLifecycleStateChanged(state);

    // Quando o app volta para o foreground, forçar refresh e sincronizar aulas ativas
    if (state == AppLifecycleState.resumed) {
      _dataRefreshService.forceRefresh();

      // ✅ CORREÇÃO CRÍTICA: Reinicializar HomeBloc se estiver em HomeInitial
      // Quando o app volta do background, o HomeBloc pode estar em HomeInitial
      // e eventos de propostas são ignorados. Precisamos garantir que ele esteja em HomeLoaded
      final homeBloc = context.read<HomeBloc>();
      if (!homeBloc.isClosed) {
        if (homeBloc.state is HomeInitial) {
          print(
            '🔄 [STUDENT_HOME] HomeBloc está em HomeInitial - reinicializando...',
          );
          homeBloc.add(const InitializeHome());
        } else {
          homeBloc.add(const LoadWorkoutCardData());
        }
      }

      // ✅ CORREÇÃO: Sincronizar aulas ativas quando app volta ao foreground
      // Isso garante que eventos perdidos durante sleep sejam recuperados
      final classesBloc = context.read<ClassesBloc>();
      if (!classesBloc.isClosed) {
        // Se WebSocket não está conectado, tentar reconectar
        if (classesBloc.state is ClassesLoaded) {
          final loadedState = classesBloc.state as ClassesLoaded;
          if (!loadedState.isWebSocketConnected) {
            print('🔄 [STUDENT_HOME] WebSocket desconectado - reconectando...');
            classesBloc.add(const ClassesConnectWebSocket());
          } else {
            // WebSocket está conectado, mas pode ter perdido eventos durante sleep
            // Fazer refresh para sincronizar
            print(
              '🔄 [STUDENT_HOME] App voltou ao foreground - sincronizando aulas ativas...',
            );
            classesBloc.add(const ClassesRefresh());
          }
        }
      }
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });

    // Ao retornar para Home, sincronizar imediatamente o card dinâmico.
    if (index == 0) {
      final homeBloc = context.read<HomeBloc>();
      if (!homeBloc.isClosed) {
        homeBloc.add(const LoadWorkoutCardData());
      }
    }
    // Removido pushNamed para perfil
  }

  void _showComingSoonSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFF6A00), // laranja principal
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      isDarkBackground: false, // Páginas normais têm fundo claro
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF), // #FFFFFF
        appBar: _currentBottomNavIndex == 0
            ? CustomTopBar(
                unreadNotificationsCount: unreadCount,
                onNotificationTap: showNotificationsModal,
              )
            : null,
        body: SafeArea(
          top: _currentBottomNavIndex == 0
              ? false
              : true, // AppBar já cuida do top padding quando mostrado
          bottom: true,
          child: BlocListener<HomeBloc, HomeBlocState>(
            listener: (context, state) {
              if (state is HomeError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }

              // Inicializar dados de gamificação quando a home estiver carregada
              if (state is HomeLoaded) {
                // RealtimeDataService já foi inicializado em initState

                // Inicializar dados de gamificação (perfil, stats, missões)
                context.read<GamificationBloc>().add(
                  InitializeGamification(userId: state.homeState.userId ?? ''),
                );
              }
            },
            child: BlocBuilder<HomeBloc, HomeBlocState>(
              builder: (context, state) {
                print(
                  '🎨 [BLOC_BUILDER] Estado recebido: ${state.runtimeType}',
                );

                if (state is HomeLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF6A00), // Laranja principal
                      ),
                    ),
                  );
                }

                if (state is HomeLoaded) {
                  return GamificationAnimations(
                    child: IndexedStack(
                      index: _currentBottomNavIndex,
                      children: [
                        _buildHomeContent(state.homeState),
                        const StudentClassesPage(),
                        const StudentProfilePage(), // Perfil agora é índice 2
                      ],
                    ),
                  );
                }

                // Estado inicial ou erro
                if (state is HomeInitial) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6A00),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text('Inicializando...'),
                      ],
                    ),
                  );
                }

                if (state is HomeError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Erro: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<HomeBloc>().add(
                              const InitializeHome(),
                            );
                          },
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }

                return const Center(child: Text('Estado desconhecido'));
              },
            ),
          ),
        ),
        bottomNavigationBar: StudentBottomNavigation(
          currentIndex: _currentBottomNavIndex,
          onTap: _onBottomNavTap,
        ),
      ),
    );
  }

  Widget _buildHomeContent(HomeState state) {
    return RefreshIndicator(
      color: const Color(0xFFFF6A00),
      onRefresh: () async {
        // Forçar recarregamento de dados da home e gamificação
        final homeBloc = context.read<HomeBloc>();
        if (!homeBloc.isClosed) homeBloc.add(const LoadWorkoutCardData());
        sl<GamificationBloc>().add(
          RefreshGamificationData(userId: state.userId ?? ''),
        );
        // pequena espera para UX
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: 24,
        ),
        child: Column(
          children: [
            if (latestUnreadCancellationNotification != null) ...[
              PersistentNoticeCard(
                title: latestUnreadCancellationNotification!.title,
                message: latestUnreadCancellationNotification!.message,
                onTap: () async {
                  await markAsRead(latestUnreadCancellationNotification!.id);
                  if (!mounted) return;
                  _onBottomNavTap(1);
                },
                onDismiss: () {
                  markAsRead(latestUnreadCancellationNotification!.id);
                },
              ),
              const SizedBox(height: 12),
            ],
            // Header (avatar + saudação + nível/xp)
            UserGreetingCard(
              homeState: state,
              onAvatarTap: () {
                _onBottomNavTap(2);
              },
              onLevelTap: () {
                _showComingSoonSnackBar(
                  context,
                  'Em breve ver nível estará disponível',
                );
              },
            ),
            // Espaçamento entre blocos
            // Card da missão semanal
            WeeklyMissionCard(homeState: state),

            const SizedBox(height: 12), // Espaçamento entre blocos
            // Botão do questionário de saúde ou criar proposta
            HealthQuestionnaireButton(),
            const SizedBox(height: 12), // Espaçamento entre blocos
            // Card dinâmico de treinos
            Builder(
              builder: (context) {
                print('🎯 [STUDENT_HOME] Renderizando DynamicWorkoutCard');
                return const DynamicWorkoutCard();
              },
            ),

            const SizedBox(height: 12), // Espaçamento entre blocos
            // Cards de conquistas e treinos realizados
            AchievementsWorkoutsCards(
              homeState: state,
              onAchievementsTap: () {
                _showComingSoonSnackBar(
                  context,
                  'Em breve suas conquistas estarão aqui',
                );
              },
            ),

            const SizedBox(height: 12), // Espaçamento final
          ],
        ),
      ),
    );
  }
}
