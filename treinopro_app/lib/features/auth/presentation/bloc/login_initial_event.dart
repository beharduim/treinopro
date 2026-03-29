import 'package:equatable/equatable.dart';

/// Eventos da tela de login inicial
abstract class LoginInitialEvent extends Equatable {
  const LoginInitialEvent();

  @override
  List<Object> get props => [];
}

/// Evento para navegar para tela de cadastro
class NavigateToSignUp extends LoginInitialEvent {
  const NavigateToSignUp();
}

/// Evento para navegar para tela de login
class NavigateToLogin extends LoginInitialEvent {
  const NavigateToLogin();
}

/// Evento para abrir termos de uso
class OpenTermsOfUse extends LoginInitialEvent {
  const OpenTermsOfUse();
}
