import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/check_onboarding_completed_usecase.dart';
import '../../domain/usecases/complete_onboarding_usecase.dart';
import '../../domain/usecases/get_onboarding_state_usecase.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// BLoC para gerenciar o estado de onboarding
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final GetOnboardingStateUseCase getOnboardingStateUseCase;
  final CheckOnboardingCompletedUseCase checkOnboardingCompletedUseCase;
  final CompleteOnboardingUseCase completeOnboardingUseCase;

  static const int _totalPages = 3; // Total de páginas do onboarding
  int _currentPage = 0;

  OnboardingBloc({
    required this.getOnboardingStateUseCase,
    required this.checkOnboardingCompletedUseCase,
    required this.completeOnboardingUseCase,
  }) : super(const OnboardingInitial()) {
    on<InitializeOnboarding>(_onInitializeOnboarding);
    on<NextPage>(_onNextPage);
    on<PreviousPage>(_onPreviousPage);
    on<GoToPage>(_onGoToPage);
    on<CompleteOnboarding>(_onCompleteOnboarding);
  }

  /// Manipula a inicialização do onboarding
  Future<void> _onInitializeOnboarding(
    InitializeOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    print('OnboardingBloc: _onInitializeOnboarding iniciado');

    try {
      print('OnboardingBloc: Emitindo OnboardingLoading');
      emit(const OnboardingLoading());

      // Simula um pequeno delay para inicialização
      await Future.delayed(const Duration(milliseconds: 300));

      _currentPage = 0;
      emit(_buildDisplayState());
    } catch (e) {
      print('OnboardingBloc: Erro na inicialização: $e');
      emit(OnboardingError(e.toString()));
    }
  }

  /// Manipula a navegação para a próxima página
  Future<void> _onNextPage(
    NextPage event,
    Emitter<OnboardingState> emit,
  ) async {
    if (_currentPage < _totalPages - 1) {
      _currentPage++;
      emit(_buildDisplayState());
    } else {
      // Se está na última página, completa o onboarding
      add(const CompleteOnboarding());
    }
  }

  /// Manipula a navegação para a página anterior
  Future<void> _onPreviousPage(
    PreviousPage event,
    Emitter<OnboardingState> emit,
  ) async {
    if (_currentPage > 0) {
      _currentPage--;
      emit(_buildDisplayState());
    }
  }

  /// Manipula a navegação para uma página específica
  Future<void> _onGoToPage(
    GoToPage event,
    Emitter<OnboardingState> emit,
  ) async {
    if (event.pageIndex >= 0 && event.pageIndex < _totalPages) {
      _currentPage = event.pageIndex;
      emit(_buildDisplayState());
    }
  }

  /// Manipula a conclusão do onboarding
  Future<void> _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<OnboardingState> emit,
  ) async {
    try {
      emit(const OnboardingLoading());

      // Aqui você pode adicionar lógica para salvar que o onboarding foi completado
      await Future.delayed(const Duration(milliseconds: 500));

      emit(const OnboardingCompleted());
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }

  /// Constrói o estado de exibição com as informações atuais
  OnboardingDisplay _buildDisplayState() {
    return OnboardingDisplay(
      currentPage: _currentPage,
      totalPages: _totalPages,
      canGoNext: _currentPage < _totalPages - 1,
      canGoPrevious: _currentPage > 0,
    );
  }
}
