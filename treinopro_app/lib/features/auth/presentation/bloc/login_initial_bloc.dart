import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/auth_navigation_usecases.dart';
import 'login_initial_event.dart';
import 'login_initial_state.dart';

/// BLoC responsável por gerenciar o estado da tela de login inicial
class LoginInitialBloc extends Bloc<LoginInitialEvent, LoginInitialState> {
  final NavigateToSignUpUseCase navigateToSignUpUseCase;
  final NavigateToLoginUseCase navigateToLoginUseCase;

  LoginInitialBloc({
    required this.navigateToSignUpUseCase,
    required this.navigateToLoginUseCase,
  }) : super(const LoginInitialIdle()) {
    on<NavigateToSignUp>(_onNavigateToSignUp);
    on<NavigateToLogin>(_onNavigateToLogin);
    on<OpenTermsOfUse>(_onOpenTermsOfUse);
  }

  /// Manipula o evento de navegação para cadastro
  Future<void> _onNavigateToSignUp(
    NavigateToSignUp event,
    Emitter<LoginInitialState> emit,
  ) async {
    try {
      emit(const LoginInitialLoading());
      await navigateToSignUpUseCase();
      emit(const NavigateToSignUpState());
    } catch (e) {
      emit(LoginInitialError(e.toString()));
    }
  }

  /// Manipula o evento de navegação para login
  Future<void> _onNavigateToLogin(
    NavigateToLogin event,
    Emitter<LoginInitialState> emit,
  ) async {
    try {
      emit(const LoginInitialLoading());
      await navigateToLoginUseCase();
      emit(const NavigateToLoginState());
    } catch (e) {
      emit(LoginInitialError(e.toString()));
    }
  }

  /// Manipula o evento de abertura dos termos de uso
  Future<void> _onOpenTermsOfUse(
    OpenTermsOfUse event,
    Emitter<LoginInitialState> emit,
  ) async {
    try {
      emit(const OpenTermsState());
      // Volta para o estado idle após um tempo
      await Future.delayed(const Duration(milliseconds: 100));
      emit(const LoginInitialIdle());
    } catch (e) {
      emit(LoginInitialError(e.toString()));
    }
  }
}
