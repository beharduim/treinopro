import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/initialize_app_usecase.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/shader_warmup_service.dart';
import '../../../home/data/services/auth_service.dart';
import 'splash_event.dart';
import 'splash_state.dart';

/// BLoC responsável por gerenciar o estado da splash screen
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final InitializeAppUseCase initializeAppUseCase;

  SplashBloc({
    required this.initializeAppUseCase,
  }) : super(const SplashInitial()) {
    on<InitializeApp>(_onInitializeApp);
    on<AppInitialized>(_onAppInitialized);
  }

  /// Manipula o evento de inicialização da aplicação
  Future<void> _onInitializeApp(
    InitializeApp event,
    Emitter<SplashState> emit,
  ) async {
    try {
      emit(const SplashLoading());
      
      print('ℹ️ [SPLASH] BLoCs são factory - nova instância será criada automaticamente');
      
      // Executar inicializações em paralelo para otimizar o tempo
      final futures = [
        // Pré-aquecer shaders para evitar travamentos nas animações
        ShaderWarmupService().warmUpShaders(),
        // Executa a inicialização da aplicação
        initializeAppUseCase(),
        // Tempo mínimo para garantir que o pré-aquecimento seja efetivo
        Future.delayed(const Duration(milliseconds: 1200)),
      ];
      
      final results = await Future.wait(futures);
      final isAuthenticated = results[1] as bool;
      
      // Obter o tipo de usuário e status de aprovação se autenticado
      String? userType;
      String? approvalStatus;
      String? userCreatedAt;
      if (isAuthenticated) {
        final authService = sl<AuthService>();
        userType = authService.currentUserType;
        approvalStatus = authService.currentApprovalStatus;
        userCreatedAt = authService.currentUserCreatedAt;
        print(
          '✅ [SPLASH] Usuário autenticado - tipo: $userType approvalStatus: $approvalStatus',
        );
      } else {
        print('ℹ️ [SPLASH] Usuário não autenticado');
      }

      add(
        AppInitialized(
          isAuthenticated: isAuthenticated,
          userType: userType,
          approvalStatus: approvalStatus,
          userCreatedAt: userCreatedAt,
        ),
      );
    } catch (e) {
      print('❌ [SPLASH] Erro ao inicializar: $e');
      emit(SplashError(e.toString()));
    }
  }

  /// Manipula o evento de aplicação inicializada
  void _onAppInitialized(
    AppInitialized event,
    Emitter<SplashState> emit,
  ) {
    emit(SplashLoaded(
      isAuthenticated: event.isAuthenticated,
      userType: event.userType,
      approvalStatus: event.approvalStatus,
      userCreatedAt: event.userCreatedAt,
    ));
  }
}
