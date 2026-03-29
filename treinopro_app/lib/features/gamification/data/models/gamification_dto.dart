import 'package:equatable/equatable.dart';

// ===== ENUMS =====

enum MissionType {
  daily,
  weekly,
  monthly,
  oneTime,
}

enum MissionStatus {
  active,
  completed,
  expired,
  cancelled,
}

enum AchievementCategory {
  fitness,
  consistency,
  social,
  exploration,
  milestone,
}

enum XPSource {
  classCompletion,
  mission,
  achievement,
  dailyLogin,
  streak,
  bonus,
}

// ===== DTOs DE PERFIL DE USUÁRIO =====

class UserProfileResponseDto extends Equatable {
  final String id;
  final String userId;
  final int level;
  final int totalXP;
  final int currentLevelXP;
  final int xpToNextLevel;
  final List<String> achievements;
  final List<String> missions;
  final DateTime? lastMissionReset;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfileResponseDto({
    required this.id,
    required this.userId,
    required this.level,
    required this.totalXP,
    required this.currentLevelXP,
    required this.xpToNextLevel,
    required this.achievements,
    required this.missions,
    this.lastMissionReset,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfileResponseDto.fromJson(Map<String, dynamic> json) {
    return UserProfileResponseDto(
      id: json['id'] as String,
      userId: json['userId'] as String,
      level: json['level'] as int,
      totalXP: json['totalXP'] as int,
      currentLevelXP: json['currentLevelXP'] as int,
      xpToNextLevel: json['xpToNextLevel'] as int,
      achievements: List<String>.from(json['achievements'] ?? []),
      missions: List<String>.from(json['missions'] ?? []),
      lastMissionReset: json['lastMissionReset'] != null 
          ? DateTime.parse(json['lastMissionReset'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'level': level,
      'totalXP': totalXP,
      'currentLevelXP': currentLevelXP,
      'xpToNextLevel': xpToNextLevel,
      'achievements': achievements,
      'missions': missions,
      'lastMissionReset': lastMissionReset?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        level,
        totalXP,
        currentLevelXP,
        xpToNextLevel,
        achievements,
        missions,
        lastMissionReset,
        createdAt,
        updatedAt,
      ];
}

class LevelUpResponseDto extends Equatable {
  final String userId;
  final int newLevel;
  final int previousLevel;
  final int xpGained;
  final String message;
  final List<String> unlockedAchievements;

  const LevelUpResponseDto({
    required this.userId,
    required this.newLevel,
    required this.previousLevel,
    required this.xpGained,
    required this.message,
    required this.unlockedAchievements,
  });

  factory LevelUpResponseDto.fromJson(Map<String, dynamic> json) {
    return LevelUpResponseDto(
      userId: json['userId'] as String,
      newLevel: json['newLevel'] as int,
      previousLevel: json['previousLevel'] as int,
      xpGained: json['xpGained'] as int,
      message: json['message'] as String,
      unlockedAchievements: List<String>.from(json['unlockedAchievements'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'newLevel': newLevel,
      'previousLevel': previousLevel,
      'xpGained': xpGained,
      'message': message,
      'unlockedAchievements': unlockedAchievements,
    };
  }

  @override
  List<Object?> get props => [
        userId,
        newLevel,
        previousLevel,
        xpGained,
        message,
        unlockedAchievements,
      ];
}

// ===== DTOs DE MISSÕES =====

class MissionResponseDto extends Equatable {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final MissionType type;
  final String action;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final MissionRequirements requirements;
  final int priority;
  final bool autoAssign;
  final List<String> prerequisites;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MissionResponseDto({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.type,
    required this.action,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.requirements,
    required this.priority,
    required this.autoAssign,
    required this.prerequisites,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MissionResponseDto.fromJson(Map<String, dynamic> json) {
    return MissionResponseDto(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      xpReward: json['xpReward'] as int,
      type: MissionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MissionType.oneTime,
      ),
      action: json['action'] as String,
      isActive: json['isActive'] as bool,
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String)
          : null,
      requirements: MissionRequirements.fromJson(json['requirements'] as Map<String, dynamic>),
      priority: json['priority'] as int,
      autoAssign: json['autoAssign'] as bool,
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'xpReward': xpReward,
      'type': type.name,
      'action': action,
      'isActive': isActive,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'requirements': requirements.toJson(),
      'priority': priority,
      'autoAssign': autoAssign,
      'prerequisites': prerequisites,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        xpReward,
        type,
        action,
        isActive,
        startDate,
        endDate,
        requirements,
        priority,
        autoAssign,
        prerequisites,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

class MissionRequirements extends Equatable {
  final String action;
  final int count;
  final String? timeframe;
  final Map<String, dynamic>? conditions;

  const MissionRequirements({
    required this.action,
    required this.count,
    this.timeframe,
    this.conditions,
  });

  factory MissionRequirements.fromJson(Map<String, dynamic> json) {
    return MissionRequirements(
      action: json['action'] as String,
      count: json['count'] as int,
      timeframe: json['timeframe'] as String?,
      conditions: json['conditions'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'count': count,
      'timeframe': timeframe,
      'conditions': conditions,
    };
  }

  @override
  List<Object?> get props => [action, count, timeframe, conditions];
}

class UserMissionResponseDto extends Equatable {
  final String id;
  final String userId;
  final String missionId;
  final MissionStatus status;
  final int progress;
  final int totalRequired;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MissionResponseDto mission;

  const UserMissionResponseDto({
    required this.id,
    required this.userId,
    required this.missionId,
    required this.status,
    required this.progress,
    required this.totalRequired,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.mission,
  });

  factory UserMissionResponseDto.fromJson(Map<String, dynamic> json) {
    return UserMissionResponseDto(
      id: json['id'] as String,
      userId: json['userId'] as String,
      missionId: json['missionId'] as String,
      status: MissionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MissionStatus.active,
      ),
      progress: json['progress'] as int,
      totalRequired: json['totalRequired'] as int,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      mission: MissionResponseDto.fromJson(json['mission'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'missionId': missionId,
      'status': status.name,
      'progress': progress,
      'totalRequired': totalRequired,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'mission': mission.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        missionId,
        status,
        progress,
        totalRequired,
        completedAt,
        createdAt,
        updatedAt,
        mission,
      ];
}

// ===== DTOs DE CONQUISTAS =====

class AchievementResponseDto extends Equatable {
  final String id;
  final String name;
  final String description;
  final int xpReward;
  final String? icon;
  final AchievementCategory category;
  final String action;
  final AchievementRequirements requirements;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AchievementResponseDto({
    required this.id,
    required this.name,
    required this.description,
    required this.xpReward,
    this.icon,
    required this.category,
    required this.action,
    required this.requirements,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AchievementResponseDto.fromJson(Map<String, dynamic> json) {
    return AchievementResponseDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      xpReward: json['xpReward'] as int,
      icon: json['icon'] as String?,
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AchievementCategory.fitness,
      ),
      action: json['action'] as String,
      requirements: AchievementRequirements.fromJson(json['requirements'] as Map<String, dynamic>),
      isActive: json['isActive'] as bool,
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'xpReward': xpReward,
      'icon': icon,
      'category': category.name,
      'action': action,
      'requirements': requirements.toJson(),
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        xpReward,
        icon,
        category,
        action,
        requirements,
        isActive,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

class AchievementRequirements extends Equatable {
  final String action;
  final int count;
  final Map<String, dynamic>? conditions;

  const AchievementRequirements({
    required this.action,
    required this.count,
    this.conditions,
  });

  factory AchievementRequirements.fromJson(Map<String, dynamic> json) {
    return AchievementRequirements(
      action: json['action'] as String,
      count: json['count'] as int,
      conditions: json['conditions'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'count': count,
      'conditions': conditions,
    };
  }

  @override
  List<Object?> get props => [action, count, conditions];
}

class UserAchievementResponseDto extends Equatable {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime earnedAt;
  final bool isActive;
  final DateTime createdAt;
  final AchievementResponseDto achievement;

  const UserAchievementResponseDto({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.earnedAt,
    required this.isActive,
    required this.createdAt,
    required this.achievement,
  });

  factory UserAchievementResponseDto.fromJson(Map<String, dynamic> json) {
    return UserAchievementResponseDto(
      id: json['id'] as String,
      userId: json['userId'] as String,
      achievementId: json['achievementId'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      achievement: AchievementResponseDto.fromJson(json['achievement'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'achievementId': achievementId,
      'earnedAt': earnedAt.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'achievement': achievement.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        achievementId,
        earnedAt,
        isActive,
        createdAt,
        achievement,
      ];
}

// ===== DTOs DE XP =====

class AddXPDto extends Equatable {
  final int xpAmount;
  final XPSource source;
  final String? sourceId;
  final String? description;

  const AddXPDto({
    required this.xpAmount,
    required this.source,
    this.sourceId,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'xpAmount': xpAmount,
      'source': source.name,
      'sourceId': sourceId,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [xpAmount, source, sourceId, description];
}

class XPHistoryResponseDto extends Equatable {
  final String id;
  final String userId;
  final int xpAmount;
  final XPSource source;
  final String? sourceId;
  final String? description;
  final DateTime createdAt;

  const XPHistoryResponseDto({
    required this.id,
    required this.userId,
    required this.xpAmount,
    required this.source,
    this.sourceId,
    this.description,
    required this.createdAt,
  });

  factory XPHistoryResponseDto.fromJson(Map<String, dynamic> json) {
    return XPHistoryResponseDto(
      id: json['id'] as String,
      userId: json['userId'] as String,
      xpAmount: json['xpAmount'] as int,
      source: XPSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => XPSource.bonus,
      ),
      sourceId: json['sourceId'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'xpAmount': xpAmount,
      'source': source.name,
      'sourceId': sourceId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        xpAmount,
        source,
        sourceId,
        description,
        createdAt,
      ];
}

// ===== DTOs DE ESTATÍSTICAS =====

class GamificationStatsResponseDto extends Equatable {
  final String userId;
  final int level;
  final int totalXP;
  final int currentLevelXP;
  final int xpToNextLevel;
  final int totalAchievements;
  final int totalMissions;
  final int completedMissions;
  final int activeMissions;
  final int xpThisWeek;
  final int xpThisMonth;
  final List<AchievementResponseDto> recentAchievements;
  final List<UserMissionResponseDto> activeMissionsList;

  const GamificationStatsResponseDto({
    required this.userId,
    required this.level,
    required this.totalXP,
    required this.currentLevelXP,
    required this.xpToNextLevel,
    required this.totalAchievements,
    required this.totalMissions,
    required this.completedMissions,
    required this.activeMissions,
    required this.xpThisWeek,
    required this.xpThisMonth,
    required this.recentAchievements,
    required this.activeMissionsList,
  });

  factory GamificationStatsResponseDto.fromJson(Map<String, dynamic> json) {
    return GamificationStatsResponseDto(
      userId: json['userId'] as String,
      level: json['level'] as int,
      totalXP: json['totalXP'] as int,
      currentLevelXP: json['currentLevelXP'] as int,
      xpToNextLevel: json['xpToNextLevel'] as int,
      totalAchievements: json['totalAchievements'] as int,
      totalMissions: json['totalMissions'] as int,
      completedMissions: json['completedMissions'] as int,
      activeMissions: json['activeMissions'] as int,
      xpThisWeek: json['xpThisWeek'] as int,
      xpThisMonth: json['xpThisMonth'] as int,
      recentAchievements: (json['recentAchievements'] as List)
          .map((item) => AchievementResponseDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      activeMissionsList: (json['activeMissionsList'] as List)
          .map((item) => UserMissionResponseDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'level': level,
      'totalXP': totalXP,
      'currentLevelXP': currentLevelXP,
      'xpToNextLevel': xpToNextLevel,
      'totalAchievements': totalAchievements,
      'totalMissions': totalMissions,
      'completedMissions': completedMissions,
      'activeMissions': activeMissions,
      'xpThisWeek': xpThisWeek,
      'xpThisMonth': xpThisMonth,
      'recentAchievements': recentAchievements.map((a) => a.toJson()).toList(),
      'activeMissionsList': activeMissionsList.map((m) => m.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        userId,
        level,
        totalXP,
        currentLevelXP,
        xpToNextLevel,
        totalAchievements,
        totalMissions,
        completedMissions,
        activeMissions,
        xpThisWeek,
        xpThisMonth,
        recentAchievements,
        activeMissionsList,
      ];
}

// ===== DTOs DE PROGRESSO =====

class MissionProgressDto extends Equatable {
  final String userId;
  final String action;
  final int count;
  final Map<String, dynamic>? metadata;

  const MissionProgressDto({
    required this.userId,
    required this.action,
    required this.count,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'action': action,
      'count': count,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [userId, action, count, metadata];
}

class AchievementProgressDto extends Equatable {
  final String userId;
  final String action;
  final int count;
  final Map<String, dynamic>? metadata;

  const AchievementProgressDto({
    required this.userId,
    required this.action,
    required this.count,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'action': action,
      'count': count,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [userId, action, count, metadata];
}
