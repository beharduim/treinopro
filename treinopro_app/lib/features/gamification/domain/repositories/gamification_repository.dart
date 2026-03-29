import '../entities/gamification_entity.dart';
import '../../data/models/gamification_dto.dart';

/// Interface abstrata para o repositório de gamificação
abstract class GamificationRepository {
  // ===== PERFIL DE USUÁRIO =====
  
  /// Busca o perfil de gamificação do usuário
  Future<UserProfile> getUserProfile(String userId);
  
  /// Busca estatísticas de gamificação do usuário
  Future<GamificationStats> getGamificationStats(String userId);

  // ===== MISSÕES =====
  
  /// Busca missões do usuário
  Future<List<UserMission>> getUserMissions(String userId, {MissionStatus? status});
  
  /// Atribui próxima missão automaticamente
  Future<UserMission?> autoAssignNextMission(String userId);
  
  /// Atualiza progresso de missão
  Future<List<UserMission>> updateMissionProgress(
    String userId,
    MissionProgress progress,
  );

  // ===== XP =====
  
  /// Adiciona XP ao usuário
  Future<LevelUp?> addXP(String userId, AddXP addXP);
  
  /// Busca histórico de XP
  Future<List<XPHistory>> getXPHistory(
    String userId, {
    XPSource? source,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 10,
  });

  // ===== AÇÕES DE INTEGRAÇÃO =====
  
  /// Processa conclusão de aula para gamificação
  Future<void> processClassCompletion(String userId, String classId);
  
  /// Processa login diário para gamificação
  Future<void> processDailyLogin(String userId);
}
