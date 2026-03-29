import 'package:equatable/equatable.dart';

/// Modelo para conquista
class AchievementModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int xpReward;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.unlockedAt,
    required this.xpReward,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt']) 
          : null,
      xpReward: json['xpReward'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'xpReward': xpReward,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        icon,
        isUnlocked,
        unlockedAt,
        xpReward,
      ];
}
