import 'package:equatable/equatable.dart';

/// Estados do card dinâmico de treinos
enum WorkoutCardState {
  noWorkout,           // Sem treino
  searchingProfessional, // Buscando profissional (modal ativo)
  pendingProposal,     // Proposta aguardando match
  scheduledClass,      // Aula agendada
}

/// Estado da home do aluno
class HomeState extends Equatable {
  final String userName;
  final String? userId; // UUID do usuário
  final String userLevel;
  final int userXp;
  final int weeklyMissionProgress;
  final int weeklyMissionTarget;
  final String weeklyMissionDescription;
  final bool hasHealthQuestionnaire;
  final bool hasWorkouts;
  final int completedWorkouts;
  final int achievements;
  final String? profileImageUrl;

  // Estados do card dinâmico
  final WorkoutCardState workoutCardState;
  final String? workoutCardLocation;
  final DateTime? workoutCardDate;
  final String? workoutCardTime;
  final Map<String, dynamic>? workoutCardData;
  
  // Lista de todas as propostas/aulas do usuário
  final List<Map<String, dynamic>> scheduledClasses;
  final List<Map<String, dynamic>> pendingProposals;
  final bool isSearchingActive; // Modal de busca ativo

  const HomeState({
    this.userName = '',
    this.userId,
    this.userLevel = '',
    this.userXp = 0,
    this.weeklyMissionProgress = 0,
    this.weeklyMissionTarget = 3,
    this.weeklyMissionDescription = '',
    this.hasHealthQuestionnaire = true,
    this.hasWorkouts = false,
    this.completedWorkouts = 0,
    this.achievements = 0,
    this.profileImageUrl,
    this.workoutCardState = WorkoutCardState.noWorkout,
    this.workoutCardLocation,
    this.workoutCardDate,
    this.workoutCardTime,
    this.workoutCardData,
    this.scheduledClasses = const [],
    this.pendingProposals = const [],
    this.isSearchingActive = false,
  });

  HomeState copyWith({
    String? userName,
    String? userId,
    String? userLevel,
    int? userXp,
    int? weeklyMissionProgress,
    int? weeklyMissionTarget,
    String? weeklyMissionDescription,
    bool? hasHealthQuestionnaire,
    bool? hasWorkouts,
    int? completedWorkouts,
    int? achievements,
    String? profileImageUrl,
    WorkoutCardState? workoutCardState,
    String? workoutCardLocation,
    DateTime? workoutCardDate,
    String? workoutCardTime,
    Map<String, dynamic>? workoutCardData,
    List<Map<String, dynamic>>? scheduledClasses,
    List<Map<String, dynamic>>? pendingProposals,
    bool? isSearchingActive,
  }) {
    return HomeState(
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      userLevel: userLevel ?? this.userLevel,
      userXp: userXp ?? this.userXp,
      weeklyMissionProgress: weeklyMissionProgress ?? this.weeklyMissionProgress,
      weeklyMissionTarget: weeklyMissionTarget ?? this.weeklyMissionTarget,
      weeklyMissionDescription: weeklyMissionDescription ?? this.weeklyMissionDescription,
      hasHealthQuestionnaire: hasHealthQuestionnaire ?? this.hasHealthQuestionnaire,
      hasWorkouts: hasWorkouts ?? this.hasWorkouts,
      completedWorkouts: completedWorkouts ?? this.completedWorkouts,
      achievements: achievements ?? this.achievements,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      workoutCardState: workoutCardState ?? this.workoutCardState,
      workoutCardLocation: workoutCardLocation ?? this.workoutCardLocation,
      workoutCardDate: workoutCardDate ?? this.workoutCardDate,
      workoutCardTime: workoutCardTime ?? this.workoutCardTime,
      workoutCardData: workoutCardData ?? this.workoutCardData,
      scheduledClasses: scheduledClasses ?? this.scheduledClasses,
      pendingProposals: pendingProposals ?? this.pendingProposals,
      isSearchingActive: isSearchingActive ?? this.isSearchingActive,
    );
  }

  @override
  List<Object?> get props => [
        userName,
        userId,
        userLevel,
        userXp,
        weeklyMissionProgress,
        weeklyMissionTarget,
        weeklyMissionDescription,
        hasHealthQuestionnaire,
        hasWorkouts,
        completedWorkouts,
        achievements,
        profileImageUrl,
        workoutCardState,
        workoutCardLocation,
        workoutCardDate,
        workoutCardTime,
        workoutCardData,
        scheduledClasses,
        pendingProposals,
        isSearchingActive,
      ];
}
