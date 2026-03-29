import 'package:equatable/equatable.dart';
import '../../data/models/gamification_dto.dart';

// ===== ENTIDADES DE DOMÍNIO =====

/// Perfil de gamificação do usuário
class UserProfile extends Equatable {
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

  const UserProfile({
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

  factory UserProfile.fromDto(UserProfileResponseDto dto) {
    return UserProfile(
      id: dto.id,
      userId: dto.userId,
      level: dto.level,
      totalXP: dto.totalXP,
      currentLevelXP: dto.currentLevelXP,
      xpToNextLevel: dto.xpToNextLevel,
      achievements: dto.achievements,
      missions: dto.missions,
      lastMissionReset: dto.lastMissionReset,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
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

/// Level up do usuário
class LevelUp extends Equatable {
  final String userId;
  final int newLevel;
  final int previousLevel;
  final int xpGained;
  final String message;
  final List<String> unlockedAchievements;

  const LevelUp({
    required this.userId,
    required this.newLevel,
    required this.previousLevel,
    required this.xpGained,
    required this.message,
    required this.unlockedAchievements,
  });

  factory LevelUp.fromDto(LevelUpResponseDto dto) {
    return LevelUp(
      userId: dto.userId,
      newLevel: dto.newLevel,
      previousLevel: dto.previousLevel,
      xpGained: dto.xpGained,
      message: dto.message,
      unlockedAchievements: dto.unlockedAchievements,
    );
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

/// Missão do usuário
class UserMission extends Equatable {
  final String id;
  final String userId;
  final String missionId;
  final MissionStatus status;
  final int progress;
  final int totalRequired;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Mission mission;

  const UserMission({
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

  factory UserMission.fromDto(UserMissionResponseDto dto) {
    return UserMission(
      id: dto.id,
      userId: dto.userId,
      missionId: dto.missionId,
      status: dto.status,
      progress: dto.progress,
      totalRequired: dto.totalRequired,
      completedAt: dto.completedAt,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      mission: Mission.fromDto(dto.mission),
    );
  }

  factory UserMission.fromJson(Map<String, dynamic> json) {
    return UserMission(
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
      mission: Mission.fromJson(json['mission'] as Map<String, dynamic>),
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

  /// Calcula o progresso em porcentagem
  double get progressPercentage {
    if (totalRequired == 0) return 0.0;
    return (progress / totalRequired).clamp(0.0, 1.0);
  }

  /// Verifica se a missão está completa
  bool get isCompleted => status == MissionStatus.completed;

  /// Verifica se a missão está ativa
  bool get isActive => status == MissionStatus.active;

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

/// Missão
class Mission extends Equatable {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final MissionType type;
  final String action;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final MissionRequirementsEntity requirements;
  final int priority;
  final bool autoAssign;
  final List<String> prerequisites;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Mission({
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

  factory Mission.fromDto(MissionResponseDto dto) {
    return Mission(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      xpReward: dto.xpReward,
      type: dto.type,
      action: dto.action,
      isActive: dto.isActive,
      startDate: dto.startDate,
      endDate: dto.endDate,
      requirements: MissionRequirementsEntity.fromDto(dto.requirements),
      priority: dto.priority,
      autoAssign: dto.autoAssign,
      prerequisites: dto.prerequisites,
      createdBy: dto.createdBy,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
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
      requirements: MissionRequirementsEntity.fromJson(json['requirements'] as Map<String, dynamic>),
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

/// Requisitos da missão
class MissionRequirementsEntity extends Equatable {
  final String action;
  final int count;
  final String? timeframe;
  final Map<String, dynamic>? conditions;

  const MissionRequirementsEntity({
    required this.action,
    required this.count,
    this.timeframe,
    this.conditions,
  });

  factory MissionRequirementsEntity.fromDto(MissionRequirements dto) {
    return MissionRequirementsEntity(
      action: dto.action,
      count: dto.count,
      timeframe: dto.timeframe,
      conditions: dto.conditions,
    );
  }

  factory MissionRequirementsEntity.fromJson(Map<String, dynamic> json) {
    return MissionRequirementsEntity(
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

/// Conquista do usuário
class UserAchievement extends Equatable {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime earnedAt;
  final bool isActive;
  final DateTime createdAt;
  final Achievement achievement;

  const UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.earnedAt,
    required this.isActive,
    required this.createdAt,
    required this.achievement,
  });

  factory UserAchievement.fromDto(UserAchievementResponseDto dto) {
    return UserAchievement(
      id: dto.id,
      userId: dto.userId,
      achievementId: dto.achievementId,
      earnedAt: dto.earnedAt,
      isActive: dto.isActive,
      createdAt: dto.createdAt,
      achievement: Achievement.fromDto(dto.achievement),
    );
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

/// Conquista
class Achievement extends Equatable {
  final String id;
  final String name;
  final String description;
  final int xpReward;
  final String? icon;
  final AchievementCategory category;
  final String action;
  final AchievementRequirementsEntity requirements;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Achievement({
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

  factory Achievement.fromDto(AchievementResponseDto dto) {
    return Achievement(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      xpReward: dto.xpReward,
      icon: dto.icon,
      category: dto.category,
      action: dto.action,
      requirements: AchievementRequirementsEntity.fromDto(dto.requirements),
      isActive: dto.isActive,
      createdBy: dto.createdBy,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
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
      requirements: AchievementRequirementsEntity.fromJson(json['requirements'] as Map<String, dynamic>),
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

/// Requisitos da conquista
class AchievementRequirementsEntity extends Equatable {
  final String action;
  final int count;
  final Map<String, dynamic>? conditions;

  const AchievementRequirementsEntity({
    required this.action,
    required this.count,
    this.conditions,
  });

  factory AchievementRequirementsEntity.fromDto(AchievementRequirements dto) {
    return AchievementRequirementsEntity(
      action: dto.action,
      count: dto.count,
      conditions: dto.conditions,
    );
  }

  factory AchievementRequirementsEntity.fromJson(Map<String, dynamic> json) {
    return AchievementRequirementsEntity(
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

/// Histórico de XP
class XPHistory extends Equatable {
  final String id;
  final String userId;
  final int xpAmount;
  final XPSource source;
  final String? sourceId;
  final String? description;
  final DateTime createdAt;

  const XPHistory({
    required this.id,
    required this.userId,
    required this.xpAmount,
    required this.source,
    this.sourceId,
    this.description,
    required this.createdAt,
  });

  factory XPHistory.fromDto(XPHistoryResponseDto dto) {
    return XPHistory(
      id: dto.id,
      userId: dto.userId,
      xpAmount: dto.xpAmount,
      source: dto.source,
      sourceId: dto.sourceId,
      description: dto.description,
      createdAt: dto.createdAt,
    );
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

/// Estatísticas de gamificação
class GamificationStats extends Equatable {
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
  final List<Achievement> recentAchievements;
  final List<UserMission> activeMissionsList;

  const GamificationStats({
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

  factory GamificationStats.fromDto(GamificationStatsResponseDto dto) {
    return GamificationStats(
      userId: dto.userId,
      level: dto.level,
      totalXP: dto.totalXP,
      currentLevelXP: dto.currentLevelXP,
      xpToNextLevel: dto.xpToNextLevel,
      totalAchievements: dto.totalAchievements,
      totalMissions: dto.totalMissions,
      completedMissions: dto.completedMissions,
      activeMissions: dto.activeMissions,
      xpThisWeek: dto.xpThisWeek,
      xpThisMonth: dto.xpThisMonth,
      recentAchievements: dto.recentAchievements.map((a) => Achievement.fromDto(a)).toList(),
      activeMissionsList: dto.activeMissionsList.map((m) => UserMission.fromDto(m)).toList(),
    );
  }

  factory GamificationStats.fromJson(Map<String, dynamic> json) {
    return GamificationStats(
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
          .map((a) => Achievement.fromJson(a as Map<String, dynamic>))
          .toList(),
      activeMissionsList: (json['activeMissionsList'] as List)
          .map((m) => UserMission.fromJson(m as Map<String, dynamic>))
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

/// Progresso de missão
class MissionProgress extends Equatable {
  final String userId;
  final String action;
  final int count;
  final Map<String, dynamic>? metadata;

  const MissionProgress({
    required this.userId,
    required this.action,
    required this.count,
    this.metadata,
  });

  factory MissionProgress.fromDto(MissionProgressDto dto) {
    return MissionProgress(
      userId: dto.userId,
      action: dto.action,
      count: dto.count,
      metadata: dto.metadata,
    );
  }

  @override
  List<Object?> get props => [userId, action, count, metadata];
}

/// Progresso de conquista
class AchievementProgress extends Equatable {
  final String userId;
  final String action;
  final int count;
  final Map<String, dynamic>? metadata;

  const AchievementProgress({
    required this.userId,
    required this.action,
    required this.count,
    this.metadata,
  });

  factory AchievementProgress.fromDto(AchievementProgressDto dto) {
    return AchievementProgress(
      userId: dto.userId,
      action: dto.action,
      count: dto.count,
      metadata: dto.metadata,
    );
  }

  @override
  List<Object?> get props => [userId, action, count, metadata];
}

/// Adicionar XP
class AddXP extends Equatable {
  final int xpAmount;
  final XPSource source;
  final String? sourceId;
  final String? description;

  const AddXP({
    required this.xpAmount,
    required this.source,
    this.sourceId,
    this.description,
  });

  factory AddXP.fromDto(AddXPDto dto) {
    return AddXP(
      xpAmount: dto.xpAmount,
      source: dto.source,
      sourceId: dto.sourceId,
      description: dto.description,
    );
  }

  @override
  List<Object?> get props => [xpAmount, source, sourceId, description];
}
