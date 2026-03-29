import '../../domain/entities/home_state.dart';

/// Modelo de dados da home
class HomeModel extends HomeState {
  const HomeModel({
    required super.userName,
    super.userId,
    required super.userLevel,
    required super.userXp,
    required super.weeklyMissionProgress,
    required super.weeklyMissionTarget,
    required super.weeklyMissionDescription,
    required super.hasHealthQuestionnaire,
    required super.hasWorkouts,
    required super.completedWorkouts,
    required super.achievements,
    super.profileImageUrl,
  });

  /// Cria um modelo a partir de um JSON
  factory HomeModel.fromJson(Map<String, dynamic> json) {
    return HomeModel(
      userName: json['userName'] ?? '',
      userId: json['userId'],
      userLevel: json['userLevel'] ?? '',
      userXp: json['userXp'] ?? 0,
      weeklyMissionProgress: json['weeklyMissionProgress'] ?? 0,
      weeklyMissionTarget: json['weeklyMissionTarget'] ?? 3,
      weeklyMissionDescription: json['weeklyMissionDescription'] ?? '',
      hasHealthQuestionnaire: json['hasHealthQuestionnaire'] ?? true,
      hasWorkouts: json['hasWorkouts'] ?? false,
      completedWorkouts: json['completedWorkouts'] ?? 0,
      achievements: json['achievements'] ?? 0,
      profileImageUrl: json['profileImageUrl'],
    );
  }

  /// Converte o modelo para JSON
  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'userLevel': userLevel,
      'userXp': userXp,
      'weeklyMissionProgress': weeklyMissionProgress,
      'weeklyMissionTarget': weeklyMissionTarget,
      'weeklyMissionDescription': weeklyMissionDescription,
      'hasHealthQuestionnaire': hasHealthQuestionnaire,
      'hasWorkouts': hasWorkouts,
      'completedWorkouts': completedWorkouts,
      'achievements': achievements,
      'profileImageUrl': profileImageUrl,
    };
  }

  /// Converte o modelo para entidade
  HomeState toEntity() {
    return HomeState(
      userName: userName,
      userLevel: userLevel,
      userXp: userXp,
      weeklyMissionProgress: weeklyMissionProgress,
      weeklyMissionTarget: weeklyMissionTarget,
      weeklyMissionDescription: weeklyMissionDescription,
      hasHealthQuestionnaire: hasHealthQuestionnaire,
      hasWorkouts: hasWorkouts,
      completedWorkouts: completedWorkouts,
      achievements: achievements,
      profileImageUrl: profileImageUrl,
    );
  }
}
