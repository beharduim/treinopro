import 'package:equatable/equatable.dart';

/// Eventos da tela de login
abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

/// Evento para realizar login com email e senha
class LoginWithEmail extends LoginEvent {
  final String email;
  final String password;

  const LoginWithEmail({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

/// Evento para login com Google
class LoginWithGoogle extends LoginEvent {
  const LoginWithGoogle();
}

/// Evento para login com Facebook
class LoginWithFacebook extends LoginEvent {
  const LoginWithFacebook();
}

/// Evento para esqueci minha senha
class ForgotPassword extends LoginEvent {
  final String email;

  const ForgotPassword({required this.email});

  @override
  List<Object> get props => [email];
}

/// Evento para navegar para cadastro
class NavigateToSignUp extends LoginEvent {
  const NavigateToSignUp();
}
