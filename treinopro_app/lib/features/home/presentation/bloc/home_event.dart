import 'package:equatable/equatable.dart';

/// Eventos do BLoC da home
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para inicializar a home
class InitializeHome extends HomeEvent {
  const InitializeHome();
}

/// Evento para atualizar o progresso da missão semanal
class UpdateWeeklyMissionProgress extends HomeEvent {
  final int progress;

  const UpdateWeeklyMissionProgress(this.progress);

  @override
  List<Object?> get props => [progress];
}

/// Evento para completar o questionário de saúde
class CompleteHealthQuestionnaire extends HomeEvent {
  const CompleteHealthQuestionnaire();
}

/// Evento para navegar para o questionário de saúde
class NavigateToHealthQuestionnaire extends HomeEvent {
  const NavigateToHealthQuestionnaire();
}

/// Evento para navegar para o perfil do usuário
class NavigateToUserProfile extends HomeEvent {
  const NavigateToUserProfile();
}

/// Evento para navegar para os treinos
class NavigateToWorkouts extends HomeEvent {
  const NavigateToWorkouts();
}

/// Evento para navegar para as conquistas
class NavigateToAchievements extends HomeEvent {
  const NavigateToAchievements();
}

// ===== EVENTOS DO CARD DINÂMICO =====

/// Evento para iniciar busca de profissional (modal ativo)
class StartProposalSearch extends HomeEvent {
  final String location;
  final DateTime trainingDate;
  final String trainingTime;
  final String? proposalId;

  const StartProposalSearch({
    required this.location,
    required this.trainingDate,
    required this.trainingTime,
    this.proposalId,
  });

  @override
  List<Object?> get props => [location, trainingDate, trainingTime, proposalId];
}

/// Evento para parar busca de profissional
class StopProposalSearch extends HomeEvent {
  const StopProposalSearch();
}

/// Evento quando busca expira (3 minutos)
class ProposalSearchExpired extends HomeEvent {
  const ProposalSearchExpired();
}

/// Evento quando proposta é aceita por profissional
class ProposalMatched extends HomeEvent {
  final Map<String, dynamic> matchData;

  const ProposalMatched(this.matchData);

  @override
  List<Object?> get props => [matchData];
}

/// Evento para cancelar proposta
class ProposalCancelled extends HomeEvent {
  final String? proposalId;

  const ProposalCancelled({this.proposalId});

  @override
  List<Object?> get props => [proposalId];
}

/// Evento para agendar aula
class ClassScheduled extends HomeEvent {
  final Map<String, dynamic> classData;

  const ClassScheduled(this.classData);

  @override
  List<Object?> get props => [classData];
}

/// Evento para cancelar aula
class ClassCancelled extends HomeEvent {
  final String classId;

  const ClassCancelled(this.classId);

  @override
  List<Object?> get props => [classId];
}

/// Evento para recalcular qual card mostrar
class UpdateWorkoutCard extends HomeEvent {
  const UpdateWorkoutCard();
}

/// Evento para carregar dados do card (aulas e propostas)
class LoadWorkoutCardData extends HomeEvent {
  const LoadWorkoutCardData();
}

/// Evento para resetar o estado do HomeBloc (usado no logout)
class ResetHome extends HomeEvent {
  const ResetHome();
}
