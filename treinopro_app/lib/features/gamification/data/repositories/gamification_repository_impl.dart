import '../../../home/data/services/auth_service.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/gamification_entity.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../services/gamification_service.dart';
import '../models/gamification_dto.dart';

/// Implementação do repositório de gamificação
class GamificationRepositoryImpl implements GamificationRepository {
  final GamificationService _gamificationService;
  final AuthService _authService;
  final CacheService _cacheService;

  GamificationRepositoryImpl({
    required GamificationService gamificationService,
    required AuthService authService,
    required CacheService cacheService,
  }) : _gamificationService = gamificationService,
       _authService = authService,
       _cacheService = cacheService;

  // ===== PERFIL DE USUÁRIO =====

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final authToken = await _authService.getValidToken();
      if (authToken == null) {
        throw UnauthorizedException('Token de autenticação não encontrado');
      }

      print('🎮 DEBUG: Buscando perfil de gamificação para userId: $userId');
      print('🔍 DEBUG: AuthService.currentUserId: ${_authService.currentUserId}');
      
      final profileDto = await _gamificationService.getUserProfile(userId, authToken);
      final profile = UserProfile.fromDto(profileDto);
      
      print('🔍 DEBUG: Profile.userId retornado da API: ${profile.userId}');
      print('🔍 DEBUG: Salvando no cache com userId: ${profile.userId}');
      
      // Salvar no cache
      await _cacheService.cacheUserProfile(profile);
      
      print('✅ DEBUG: Perfil de gamificação carregado - Level: ${profile.level}, XP: ${profile.totalXP}');
      
      return profile;
    } catch (e) {
      print('❌ DEBUG: Erro ao buscar perfil de gamificação: $e');
      
      // Se o perfil não existe, tentar criar um novo
      if (e.toString().contains('404') || e.toString().contains('não encontrado')) {
        print('🆕 DEBUG: Perfil não encontrado, tentando criar perfil inicial...');
        try {
          // Chamar endpoint de auto-assign que deve criar o perfil
          await _gamificationService.autoAssignNextMission(userId, await _authService.getValidToken() ?? '');
          // Tentar buscar novamente
          final profileDto = await _gamificationService.getUserProfile(userId, await _authService.getValidToken() ?? '');
          final profile = UserProfile.fromDto(profileDto);
          await _cacheService.cacheUserProfile(profile);
          print('✅ DEBUG: Perfil criado automaticamente - Level: ${profile.level}, XP: ${profile.totalXP}');
          return profile;
        } catch (createError) {
          print('❌ DEBUG: Erro ao criar perfil automaticamente: $createError');
        }
      }
      
      // Tentar buscar do cache em caso de erro
      try {
        final cachedProfile = await _cacheService.getCachedUserProfile(userId);
        if (cachedProfile != null) {
          print('📱 DEBUG: Usando perfil em cache');
          return cachedProfile;
        }
      } catch (cacheError) {
        print('⚠️ DEBUG: Erro ao buscar cache: $cacheError');
      }
      
      rethrow;
    }
  }

  @override
  Future<GamificationStats> getGamificationStats(String userId) async {
    try {
      final authToken = await _authService.getValidToken();
      if (authToken == null) {
        throw UnauthorizedException('Token de autenticação não encontrado');
      }

      print('📊 DEBUG: Buscando estatísticas de gamificação para userId: $userId');
      print('🔍 DEBUG: AuthService.currentUserId: ${_authService.currentUserId}');
      
      final statsDto = await _gamificationService.getGamificationStats(userId, authToken);
      final stats = GamificationStats.fromDto(statsDto);
      
      print('🔍 DEBUG: Stats.userId retornado da API: ${stats.userId}');
      print('🔍 DEBUG: Salvando no cache com userId: ${stats.userId}');
      
      // Salvar no cache
      await _cacheService.cacheGamificationStats(stats);
      
      print('✅ DEBUG: Estatísticas carregadas - Missões ativas: ${stats.activeMissions}, XP esta semana: ${stats.xpThisWeek}');
      
      return stats;
    } catch (e) {
      print('❌ DEBUG: Erro ao buscar estatísticas: $e');
      
      // Tentar buscar do cache em caso de erro
      try {
        final cachedStats = await _cacheService.getCachedGamificationStats(userId);
        if (cachedStats != null) {
          print('📱 DEBUG: Usando estatísticas em cache');
          return cachedStats;
        }
      } catch (cacheError) {
        print('⚠️ DEBUG: Erro ao buscar cache: $cacheError');
      }
      
      rethrow;
    }
  }

  // ===== MISSÕES =====

  @override
  Future<List<UserMission>> getUserMissions(String userId, {MissionStatus? status}) async {
    try {
      final authToken = await _authService.getValidToken();
      if (authToken == null) {
        throw UnauthorizedException('Token de autenticação não encontrado');
      }

      print('🎯 DEBUG: Buscando missões do usuário - Status: ${status?.name ?? 'todos'}');
      print('🔍 DEBUG: userId passado: $userId');
      print('🔍 DEBUG: AuthService.currentUserId: ${_authService.currentUserId}');
      
      final missionsDto = await _gamificationService.getUserMissions(userId, authToken, status: status?.name);
      final missions = missionsDto.map((dto) => UserMission.fromDto(dto)).toList();
      
      print('🔍 DEBUG: Salvando ${missions.length} missões no cache com userId: $userId');
      
      // Salvar no cache
      await _cacheService.cacheUserMissions(userId, missions);
      
      print('✅ DEBUG: ${missions.length} missões carregadas');
      
      return missions;
    } catch (e) {
      print('❌ DEBUG: Erro ao buscar missões: $e');
      
      // Tentar buscar do cache em caso de erro
      try {
        final cachedMissions = await _cacheService.getCachedUserMissions(userId);
        if (cachedMissions != null) {
          print('📱 DEBUG: Usando missões em cache');
          return cachedMissions;
        }
      } catch (cacheError) {
        print('⚠️ DEBUG: Erro ao buscar cache: $cacheError');
      }
      
      rethrow;
    }
  }

  @override
  Future<UserMission?> autoAssignNextMission(String userId) async {
    try {
      final authToken = await _authService.getValidToken();
      if (authToken == null) {
        throw UnauthorizedException('Token de autenticação não encontrado');
      }

      print('🎯 DEBUG: Atribuindo próxima missão automaticamente');
      
      final missionDto = await _gamificationService.autoAssignNextMission(userId, authToken);
      
      if (missionDto != null) {
        final mission = UserMission.fromDto(missionDto);
        
        // Invalidar cache de missões para forçar refresh
        await _cacheService.invalidateUserMissionsCache(userId);
        
        print('✅ DEBUG: Nova missão atribuída: ${mission.mission.title}');
        
        return mission;
      } else {
        print('ℹ️ DEBUG: Nenhuma missão disponível para atribuição');
        return null;
      }
    } catch (e) {
      print('❌ DEBUG: Erro ao atribuir missão: $e');
      rethrow;
    }
  }

  @override
  Future<List<UserMission>> updateMissionProgress(
    String userId,
    MissionProgress progress,
  ) async {
    try {
      final authToken = await _authService.getValidToken();
      if (authToken == null) {
        throw UnauthorizedException('Token de autenticação não encontrado');
      }

      print('📈 DEBUG: Atualizando progresso de missão - Ação: ${progress.action}, Count: ${progress.count}');
      
      final progressDto = MissionProgressDto(
        userId: progress.userId,
        action: progress.action,
        count: progress.count,
        metadata: progress.metadata,
      );
      
      final missionsDto = await _gamificationService.updateMissionProgress(userId, authToken, progressDto);
      final missions = missionsDto.map((dto) => UserMission.fromDto(dto)).toList();
      
      // Invalidar cache de missões para forçar refresh
      await _cacheService.invalidateUserMissionsCache(userId);
      
      print('✅ DEBUG: Progresso atualizado para ${missions.length} missões');
      
      return missions;
    } catch (e) {
      print('❌ DEBUG: Erro ao atualizar progresso: $e');
      rethrow;
    }
  }

  // ===== XP =====

  @override
  Future<LevelUp?> addXP(String userId, AddXP addXP) async {
    try {
      final authToken = await _authService.getValidToken();
      if (authToken == null) {
        throw UnauthorizedException('Token de autenticação não encontrado');
      }

      print('💫 DEBUG: Adicionando XP - Quantidade: ${addXP.xpAmount}, Fonte: ${addXP.source.name}');
      
      final addXPDto = AddXPDto(
        xpAmount: addXP.xpAmount,
        source: addXP.source,
        sourceId: addXP.sourceId,
        description: addXP.description,
      );
      
      final levelUpDto = await _gamificationService.addXP(userId, authToken, addXPDto);
      
      if (levelUpDto != null) {
        final levelUp = LevelUp.fromDto(levelUpDto);
        
        // Invalidar cache de perfil para forçar refresh
        await _cacheService.invalidateUserProfileCache(userId);
        
        print('🎉 DEBUG: Level up! Novo nível: ${levelUp.newLevel}');
        
        return levelUp;
      } else {
        print('✅ DEBUG: XP adicionado sem level up');
        return null;
      }
    } catch (e) {
      print('❌ DEBUG: Erro ao adicionar XP: $e');
      rethrow;
    }
  }

  @override
  Future<List<XPHistory>> getXPHistory(
    String userId, {
    XPSource? source,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final authToken = await _authService.getValidToken();
      if (authToken == null) {
        throw UnauthorizedException('Token de autenticação não encontrado');
      }

      print('📜 DEBUG: Buscando histórico de XP - Página: $page, Limite: $limit');
      
      final historyDto = await _gamificationService.getXPHistory(
        userId,
        authToken,
        source: source,
        startDate: startDate,
        endDate: endDate,
        page: page,
        limit: limit,
      );
      
      final history = historyDto.map((dto) => XPHistory.fromDto(dto)).toList();
      
      print('✅ DEBUG: ${history.length} entradas de histórico carregadas');
      
      return history;
    } catch (e) {
      print('❌ DEBUG: Erro ao buscar histórico: $e');
      rethrow;
    }
  }

  // ===== AÇÕES DE INTEGRAÇÃO =====

  @override
  Future<void> processClassCompletion(String userId, String classId) async {
    try {
      print('🏋️ [REPOSITORY] ===== INICIANDO PROCESSAMENTO DE CONCLUSÃO =====');
      print('🏋️ [REPOSITORY] UserId: $userId');
      print('🏋️ [REPOSITORY] ClassId: $classId');
      
      final authToken = await _authService.getValidToken();
      if (authToken == null) {
        print('❌ [REPOSITORY] Token de autenticação não encontrado');
        throw UnauthorizedException('Token de autenticação não encontrado');
      }
      print('🏋️ [REPOSITORY] Token obtido com sucesso');

      print('🏋️ [REPOSITORY] Chamando _gamificationService.processClassCompletion...');
      await _gamificationService.processClassCompletion(userId, authToken, classId);
      print('🏋️ [REPOSITORY] processClassCompletion concluído com sucesso');
      
      print('🏋️ [REPOSITORY] Invalidando caches relacionados...');
      // Invalidar caches relacionados
      await _cacheService.invalidateUserProfileCache(userId);
      await _cacheService.invalidateUserMissionsCache(userId);
      await _cacheService.invalidateGamificationStatsCache(userId);
      print('🏋️ [REPOSITORY] Caches invalidados com sucesso');
      
      print('✅ [REPOSITORY] ===== PROCESSAMENTO DE CONCLUSÃO FINALIZADO =====');
    } catch (e) {
      print('❌ [REPOSITORY] Erro ao processar conclusão: $e');
      print('❌ [REPOSITORY] Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  @override
  Future<void> processDailyLogin(String userId) async {
    try {
      final authToken = await _authService.getValidToken();
      if (authToken == null) {
        throw UnauthorizedException('Token de autenticação não encontrado');
      }

      print('🌅 DEBUG: Processando login diário');
      
      await _gamificationService.processDailyLogin(userId, authToken);
      
      // Invalidar caches relacionados
      await _cacheService.invalidateUserProfileCache(userId);
      await _cacheService.invalidateUserMissionsCache(userId);
      await _cacheService.invalidateGamificationStatsCache(userId);
      
      print('✅ DEBUG: Login diário processado com sucesso');
    } catch (e) {
      print('❌ DEBUG: Erro ao processar login diário: $e');
      rethrow;
    }
  }
}
