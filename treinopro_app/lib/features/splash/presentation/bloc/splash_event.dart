import 'package:equatable/equatable.dart';
import '../../../../core/errors/account_access_denied_exception.dart';

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
  final AccountAccessDeniedException? pendingAccountAccess;

  const AppInitialized({
    this.isAuthenticated = false,
    this.userType,
    this.approvalStatus,
    this.userCreatedAt,
    this.pendingAccountAccess,
  });

  @override
  List<Object> get props => [
    isAuthenticated,
    userType ?? '',
    approvalStatus ?? '',
    userCreatedAt ?? '',
    pendingAccountAccess?.message ?? '',
  ];
}
