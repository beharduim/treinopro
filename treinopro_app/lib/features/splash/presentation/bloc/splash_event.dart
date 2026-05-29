import 'package:equatable/equatable.dart';

/// Eventos da splash screen
abstract class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object> get props => [];
}

/// Evento para inicializar a aplicação
class InitializeApp extends SplashEvent {
  const InitializeApp();
}

/// Evento disparado quando a inicialização for concluída
class AppInitialized extends SplashEvent {
  final bool isAuthenticated;
  final String? userType;
  final String? approvalStatus;
  final String? userCreatedAt;

  const AppInitialized({
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
