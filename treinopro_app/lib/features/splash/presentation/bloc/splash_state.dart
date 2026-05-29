import 'package:equatable/equatable.dart';

/// Estados da splash screen
abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object> get props => [];
}

/// Estado inicial da splash screen
class SplashInitial extends SplashState {
  const SplashInitial();
}

/// Estado quando a aplicação está sendo inicializada
class SplashLoading extends SplashState {
  const SplashLoading();
}

/// Estado quando a inicialização foi concluída com sucesso
class SplashLoaded extends SplashState {
  final bool isAuthenticated;
  final String? userType;
  final String? approvalStatus;
  final String? userCreatedAt;

  const SplashLoaded({
    this.isAuthenticated = false,
    this.userType,
    this.approvalStatus,
    this.userCreatedAt,
  });

  @override
  List<Object> get props => [
    isAuthenticated,
    userType ?? '',
    approvalStatus ?? '',
    userCreatedAt ?? '',
  ];
}

/// Estado de erro durante a inicialização
class SplashError extends SplashState {
  final String message;

  const SplashError(this.message);

  @override
  List<Object> get props => [message];
}
