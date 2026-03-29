import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecases.dart';
import 'login_event.dart';
import 'login_state.dart';

/// BLoC responsável por gerenciar o estado da tela de login
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUserUseCase loginUserUseCase;
  final LoginWithGoogleUseCase loginWithGoogleUseCase;
  final LoginWithFacebookUseCase loginWithFacebookUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;

  LoginBloc({
    required this.loginUserUseCase,
    required this.loginWithGoogleUseCase,
    required this.loginWithFacebookUseCase,
    required this.forgotPasswordUseCase,
  }) : super(const LoginInitial()) {
    on<LoginWithEmail>(_onLoginWithEmail);
    on<LoginWithGoogle>(_onLoginWithGoogle);
    on<LoginWithFacebook>(_onLoginWithFacebook);
    on<ForgotPassword>(_onForgotPassword);
    on<NavigateToSignUp>(_onNavigateToSignUp);
  }

  /// Manipula o evento de login com email
  Future<void> _onLoginWithEmail(
    LoginWithEmail event,
    Emitter<LoginState> emit,
  ) async {
    try {
      emit(const LoginLoading());

      // Validações básicas
      if (event.email.isEmpty || event.password.isEmpty) {
        emit(const LoginError('Email e senha são obrigatórios'));
        return;
      }

      if (!event.email.contains('@')) {
        emit(const LoginError('Email inválido'));
        return;
      }

      final authResponse = await loginUserUseCase(
        email: event.email,
        password: event.password,
      );

      emit(LoginSuccess(authResponse.user));
    } catch (e) {
      emit(LoginError(e.toString()));
    }
  }

  /// Manipula o evento de login com Google
  Future<void> _onLoginWithGoogle(
    LoginWithGoogle event,
    Emitter<LoginState> emit,
  ) async {
    try {
      emit(const LoginGoogleLoading());

      // TODO: Implementar login real com Google
      // Por enquanto, apenas simula o processo
      await loginWithGoogleUseCase();

      // Em caso de sucesso, o use case deve retornar os dados do usuário
      // ou lançar uma exceção em caso de erro
      emit(const LoginError('Login com Google ainda não implementado'));
    } catch (e) {
      emit(LoginError(e.toString()));
    }
  }

  /// Manipula o evento de login com Facebook
  Future<void> _onLoginWithFacebook(
    LoginWithFacebook event,
    Emitter<LoginState> emit,
  ) async {
    try {
      emit(const LoginFacebookLoading());

      // TODO: Implementar login real com Facebook
      // Por enquanto, apenas simula o processo
      await loginWithFacebookUseCase();

      // Em caso de sucesso, o use case deve retornar os dados do usuário
      // ou lançar uma exceção em caso de erro
      emit(const LoginError('Login com Facebook ainda não implementado'));
    } catch (e) {
      emit(LoginError(e.toString()));
    }
  }

  /// Manipula o evento de esqueci minha senha
  Future<void> _onForgotPassword(
    ForgotPassword event,
    Emitter<LoginState> emit,
  ) async {
    try {
      if (event.email.isEmpty || !event.email.contains('@')) {
        emit(const LoginError('Email inválido'));
        return;
      }

      await forgotPasswordUseCase(email: event.email);
      emit(const ForgotPasswordSent());

      // Volta para o estado inicial após um tempo
      await Future.delayed(const Duration(milliseconds: 100));
      emit(const LoginInitial());
    } catch (e) {
      emit(LoginError(e.toString()));
    }
  }

  /// Manipula o evento de navegação para cadastro
  void _onNavigateToSignUp(NavigateToSignUp event, Emitter<LoginState> emit) {
    emit(const NavigateToSignUpState());
  }
}
