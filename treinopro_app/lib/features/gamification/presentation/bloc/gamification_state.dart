import 'package:equatable/equatable.dart';
import '../../domain/entities/gamification_entity.dart';

/// Estados do GamificationBloc
abstract class GamificationState extends Equatable {
  const GamificationState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class GamificationInitial extends GamificationState {
  const GamificationInitial();
}

/// Estado de carregamento
class GamificationLoading extends GamificationState {
  const GamificationLoading();
}

/// Estado carregado com dados completos
class GamificationLoaded extends GamificationState {
  final UserProfile userProfile;
  final GamificationStats stats;
  final List<UserMission> userMissions;
  final List<XPHistory> xpHistory;
  final bool isLoadingMore;

  const GamificationLoaded({
    required this.userProfile,
    required this.stats,
    required this.userMissions,
    required this.xpHistory,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [
        userProfile,
        stats,
        userMissions,
        xpHistory,
        isLoadingMore,
      ];

  GamificationLoaded copyWith({
    UserProfile? userProfile,
    GamificationStats? stats,
    List<UserMission>? userMissions,
    List<XPHistory>? xpHistory,
    bool? isLoadingMore,
  }) {
    return GamificationLoaded(
      userProfile: userProfile ?? this.userProfile,
      stats: stats ?? this.stats,
      userMissions: userMissions ?? this.userMissions,
      xpHistory: xpHistory ?? this.xpHistory,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Estado de erro
class GamificationError extends GamificationState {
  final String message;
  final String? errorCode;

  const GamificationError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

/// Estado de level up
class GamificationLevelUp extends GamificationState {
  final LevelUp levelUp;
  final UserProfile updatedProfile;
  final GamificationStats updatedStats;

  const GamificationLevelUp({
    required this.levelUp,
    required this.updatedProfile,
    required this.updatedStats,
  });

  @override
  List<Object?> get props => [levelUp, updatedProfile, updatedStats];
}

/// Estado de missão completada
class GamificationMissionCompleted extends GamificationState {
  final UserMission completedMission;
  final List<UserMission> updatedMissions;
  final UserProfile updatedProfile;

  const GamificationMissionCompleted({
    required this.completedMission,
    required this.updatedMissions,
    required this.updatedProfile,
  });

  @override
  List<Object?> get props => [completedMission, updatedMissions, updatedProfile];
}

/// Estado de nova missão atribuída
class GamificationNewMissionAssigned extends GamificationState {
  final UserMission newMission;
  final List<UserMission> updatedMissions;

  const GamificationNewMissionAssigned({
    required this.newMission,
    required this.updatedMissions,
  });

  @override
  List<Object?> get props => [newMission, updatedMissions];
}
