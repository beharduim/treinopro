import 'package:equatable/equatable.dart';
import '../../data/models/api_user.dart';

/// Estados da tela de login
abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

/// Estado inicial
class LoginInitial extends LoginState {
  const LoginInitial();
}

/// Estado de carregamento
class LoginLoading extends LoginState {
  const LoginLoading();
}

/// Estado de login realizado com sucesso
class LoginSuccess extends LoginState {
  final ApiUser user;

  const LoginSuccess(this.user);

  @override
  List<Object> get props => [user];
}

/// Estado de erro no login
class LoginError extends LoginState {
  final String message;

  const LoginError(this.message);

  @override
  List<Object> get props => [message];
}

/// Estado de carregamento do Google
class LoginGoogleLoading extends LoginState {
  const LoginGoogleLoading();
}

/// Estado de carregamento do Facebook
class LoginFacebookLoading extends LoginState {
  const LoginFacebookLoading();
}

/// Estado de senha enviada com sucesso
class ForgotPasswordSent extends LoginState {
  const ForgotPasswordSent();
}

/// Estado de navegação para cadastro
class NavigateToSignUpState extends LoginState {
  const NavigateToSignUpState();
}
