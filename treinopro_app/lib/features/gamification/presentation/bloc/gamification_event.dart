import 'package:equatable/equatable.dart';
import '../../domain/entities/gamification_entity.dart';
import '../../data/models/gamification_dto.dart';

/// Eventos do GamificationBloc
abstract class GamificationEvent extends Equatable {
  const GamificationEvent();

  @override
  List<Object?> get props => [];
}

/// Inicializar gamificação
class InitializeGamification extends GamificationEvent {
  final String userId;

  const InitializeGamification({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Carregar perfil de gamificação
class LoadUserProfile extends GamificationEvent {
  final String userId;

  const LoadUserProfile({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Carregar estatísticas de gamificação
class LoadGamificationStats extends GamificationEvent {
  final String userId;

  const LoadGamificationStats({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Carregar missões do usuário
class LoadUserMissions extends GamificationEvent {
  final String userId;
  final MissionStatus? status;

  const LoadUserMissions({required this.userId, this.status});

  @override
  List<Object?> get props => [userId, status];
}

/// Atribuir próxima missão automaticamente
class AutoAssignNextMission extends GamificationEvent {
  final String userId;

  const AutoAssignNextMission({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Atualizar progresso de missão
class UpdateMissionProgress extends GamificationEvent {
  final String userId;
  final MissionProgress progress;

  const UpdateMissionProgress({required this.userId, required this.progress});

  @override
  List<Object?> get props => [userId, progress];
}

/// Adicionar XP ao usuário
class AddXPEvent extends GamificationEvent {
  final String userId;
  final AddXP addXP;

  const AddXPEvent({required this.userId, required this.addXP});

  @override
  List<Object?> get props => [userId, addXP];
}

/// Carregar histórico de XP
class LoadXPHistory extends GamificationEvent {
  final String userId;
  final XPSource? source;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int limit;

  const LoadXPHistory({
    required this.userId,
    this.source,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [userId, source, startDate, endDate, page, limit];
}

/// Processar conclusão de aula
class ProcessClassCompletion extends GamificationEvent {
  final String userId;
  final String classId;

  const ProcessClassCompletion({required this.userId, required this.classId});

  @override
  List<Object?> get props => [userId, classId];
}

/// Processar login diário
class ProcessDailyLogin extends GamificationEvent {
  final String userId;

  const ProcessDailyLogin({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Refresh automático de dados
class RefreshGamificationData extends GamificationEvent {
  final String userId;

  const RefreshGamificationData({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Reset do estado
class ResetGamificationState extends GamificationEvent {
  const ResetGamificationState();
}

/// Resetar completamente o GamificationBloc (usado no logout)
class ResetGamification extends GamificationEvent {
  const ResetGamification();
}
