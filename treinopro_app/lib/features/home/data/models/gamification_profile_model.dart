import 'package:equatable/equatable.dart';

/// Modelo para o perfil de gamificação do usuário
class GamificationProfileModel extends Equatable {
  final String id;
  final String userId;
  final int level;
  final int totalXP;
  final int currentLevelXP;
  final int nextLevelXP;
  final List<String> badges;
  final List<String> achievements;
  final int rank;

  const GamificationProfileModel({
    required this.id,
    required this.userId,
    required this.level,
    required this.totalXP,
    required this.currentLevelXP,
    required this.nextLevelXP,
    required this.badges,
    required this.achievements,
    required this.rank,
  });

  factory GamificationProfileModel.fromJson(Map<String, dynamic> json) {
    return GamificationProfileModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      level: json['level'] ?? 1,
      totalXP: json['totalXP'] ?? 0,
      currentLevelXP: json['currentLevelXP'] ?? 0,
      nextLevelXP: json['nextLevelXP'] ?? 100,
      badges: List<String>.from(json['badges'] ?? []),
      achievements: List<String>.from(json['achievements'] ?? []),
      rank: json['rank'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'level': level,
      'totalXP': totalXP,
      'currentLevelXP': currentLevelXP,
      'nextLevelXP': nextLevelXP,
      'badges': badges,
      'achievements': achievements,
      'rank': rank,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        level,
        totalXP,
        currentLevelXP,
        nextLevelXP,
        badges,
        achievements,
        rank,
      ];
}
