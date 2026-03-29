import 'package:equatable/equatable.dart';

/// Modelo para missão semanal
class WeeklyMissionModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String type;
  final bool isActive;
  final int progress;
  final int target;
  final int xpReward;
  final String status;

  const WeeklyMissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.isActive,
    required this.progress,
    required this.target,
    required this.xpReward,
    required this.status,
  });

  factory WeeklyMissionModel.fromJson(Map<String, dynamic> json) {
    // Mapear dados da API de missões do usuário
    final mission = json['mission'] as Map<String, dynamic>? ?? json;
    final requirements = mission['requirements'] as Map<String, dynamic>? ?? {};
    
    return WeeklyMissionModel(
      id: mission['id'] ?? json['id'] ?? '',
      title: mission['title'] ?? json['title'] ?? '',
      description: mission['description'] ?? json['description'] ?? '',
      type: mission['type'] ?? json['type'] ?? 'weekly',
      isActive: mission['isActive'] ?? json['isActive'] ?? false,
      progress: json['progress'] ?? 0, // Progress vem do userMissions
      target: requirements['count'] ?? json['target'] ?? 0, // Target vem de requirements.count
      xpReward: mission['xpReward'] ?? json['xpReward'] ?? 0,
      status: json['status'] ?? 'inactive',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'isActive': isActive,
      'progress': progress,
      'target': target,
      'xpReward': xpReward,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        isActive,
        progress,
        target,
        xpReward,
        status,
      ];
}
