import 'package:equatable/equatable.dart';

/// Estados da tela de login inicial
abstract class LoginInitialState extends Equatable {
  const LoginInitialState();

  @override
  List<Object> get props => [];
}

/// Estado inicial
class LoginInitialIdle extends LoginInitialState {
  const LoginInitialIdle();
}

/// Estado de carregamento
class LoginInitialLoading extends LoginInitialState {
  const LoginInitialLoading();
}

/// Estado de navegação para cadastro
class NavigateToSignUpState extends LoginInitialState {
  const NavigateToSignUpState();
}

/// Estado de navegação para login
class NavigateToLoginState extends LoginInitialState {
  const NavigateToLoginState();
}

/// Estado de abertura dos termos de uso
class OpenTermsState extends LoginInitialState {
  const OpenTermsState();
}

/// Estado de erro
class LoginInitialError extends LoginInitialState {
  final String message;

  const LoginInitialError(this.message);

  @override
  List<Object> get props => [message];
}
