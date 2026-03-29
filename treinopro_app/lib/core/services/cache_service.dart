import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/gamification/domain/entities/gamification_entity.dart';

/// Serviço para cache local de dados
class CacheService {
  final SharedPreferences _prefs;
  
  // Chaves do cache
  static const String _scheduledClassesKey = 'cached_scheduled_classes';
  static const String _pendingProposalsKey = 'cached_pending_proposals';
  static const String _lastRefreshKey = 'last_data_refresh';
  static const String _userDataKey = 'cached_user_data';
  
  // Chaves do cache de gamificação
  static const String _userProfileKey = 'cached_user_profile';
  static const String _gamificationStatsKey = 'cached_gamification_stats';
  static const String _userMissionsKey = 'cached_user_missions';
  
  // Configurações de cache
  static const Duration _cacheExpiration = Duration(minutes: 5); // Cache expira em 5 minutos
  
  CacheService({required SharedPreferences prefs}) : _prefs = prefs;

  // Normaliza objetos para JSON (converte DateTime em ISO8601)
  dynamic _normalize(dynamic value) {
    if (value is DateTime) return value.toIso8601String();
    if (value is List) return value.map(_normalize).toList();
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((k, v) { out[k.toString()] = _normalize(v); });
      return out;
    }
    return value;
  }

  /// Salva dados de aulas agendadas no cache
  Future<void> cacheScheduledClasses(List<Map<String, dynamic>> classes) async {
    try {
      final jsonString = json.encode(_normalize(classes));
      await _prefs.setString(_scheduledClassesKey, jsonString);
      await _prefs.setString(_lastRefreshKey, DateTime.now().toIso8601String());
      
    } catch (e) {
      print('❌ DEBUG: Erro ao salvar cache de aulas: $e');
    }
  }

  /// Recupera dados de aulas agendadas do cache
  List<Map<String, dynamic>> getCachedScheduledClasses() {
    try {
      final jsonString = _prefs.getString(_scheduledClassesKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('❌ DEBUG: Erro ao recuperar cache de aulas: $e');
    }
    return [];
  }

  /// Salva dados de propostas pendentes no cache
  Future<void> cachePendingProposals(List<Map<String, dynamic>> proposals) async {
    try {
      final jsonString = json.encode(_normalize(proposals));
      await _prefs.setString(_pendingProposalsKey, jsonString);
      
      print('💾 DEBUG: Propostas pendentes salvas no cache');
    } catch (e) {
      print('❌ DEBUG: Erro ao salvar cache de propostas: $e');
    }
  }

  /// Recupera dados de propostas pendentes do cache
  List<Map<String, dynamic>> getCachedPendingProposals() {
    try {
      final jsonString = _prefs.getString(_pendingProposalsKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('❌ DEBUG: Erro ao recuperar cache de propostas: $e');
    }
    return [];
  }

  /// Salva dados do usuário no cache
  Future<void> cacheUserData(Map<String, dynamic> userData) async {
    try {
      final jsonString = json.encode(userData);
      await _prefs.setString(_userDataKey, jsonString);
      
      print('💾 DEBUG: Dados do usuário salvos no cache');
    } catch (e) {
      print('❌ DEBUG: Erro ao salvar cache do usuário: $e');
    }
  }

  /// Recupera dados do usuário do cache
  Map<String, dynamic>? getCachedUserData() {
    try {
      final jsonString = _prefs.getString(_userDataKey);
      if (jsonString != null) {
        return json.decode(jsonString);
      }
    } catch (e) {
      print('❌ DEBUG: Erro ao recuperar cache do usuário: $e');
    }
    return null;
  }

  /// Verifica se o cache ainda é válido
  bool isCacheValid() {
    try {
      final lastRefreshString = _prefs.getString(_lastRefreshKey);
      if (lastRefreshString != null) {
        final lastRefresh = DateTime.parse(lastRefreshString);
        final now = DateTime.now();
        return now.difference(lastRefresh) < _cacheExpiration;
      }
    } catch (e) {
      print('❌ DEBUG: Erro ao verificar validade do cache: $e');
    }
    return false;
  }

  /// Invalida o cache forçando próxima atualização
  Future<void> invalidateCache() async {
    try {
      await _prefs.remove(_lastRefreshKey);
      print('🔄 DEBUG: Cache invalidado - próxima consulta será da API');
    } catch (e) {
      print('❌ DEBUG: Erro ao invalidar cache: $e');
    }
  }

  /// Limpa todo o cache
  Future<void> clearCache() async {
    try {
      print('🗑️🗑️🗑️ [CACHE_SERVICE] ===== INICIANDO LIMPEZA COMPLETA DO CACHE =====');
      
      // Limpar chaves específicas de cache
      await _prefs.remove(_scheduledClassesKey);
      await _prefs.remove(_pendingProposalsKey);
      await _prefs.remove(_lastRefreshKey);
      await _prefs.remove(_userDataKey);
      
      // Limpar cache de gamificação
      await _prefs.remove(_userProfileKey);
      await _prefs.remove(_gamificationStatsKey);
      await _prefs.remove(_userMissionsKey);
      
      // CRÍTICO: Limpar TODAS as chaves que podem conter dados do usuário
      // Isso garante que nenhum dado do usuário anterior seja mantido
      final allKeys = _prefs.getKeys();
      print('🗑️ DEBUG: Limpando ${allKeys.length} chaves do SharedPreferences');
      
      for (final key in allKeys) {
        // Manter apenas chaves de configuração do app (se houver)
        // Por exemplo: theme, language, etc.
        if (!key.startsWith('app_config_')) {
          await _prefs.remove(key);
          print('🗑️ DEBUG: Removida chave: $key');
        }
      }
      
      print('✅✅✅ [CACHE_SERVICE] Cache limpo completamente (incluindo gamificação e todos os dados do usuário)');
    } catch (e) {
      print('❌ DEBUG: Erro ao limpar cache: $e');
    }
  }

  /// Limpa cache específico
  Future<void> clearSpecificCache(String type) async {
    try {
      switch (type) {
        case 'classes':
          await _prefs.remove(_scheduledClassesKey);
          break;
        case 'proposals':
          await _prefs.remove(_pendingProposalsKey);
          break;
        case 'user':
          await _prefs.remove(_userDataKey);
          break;
        default:
          print('⚠️ DEBUG: Tipo de cache inválido: $type');
      }
      
      print('🗑️ DEBUG: Cache $type limpo');
    } catch (e) {
      print('❌ DEBUG: Erro ao limpar cache $type: $e');
    }
  }

  /// Obtém dados combinados do cache
  Map<String, dynamic> getCachedWorkoutCardData() {
    return {
      'scheduledClasses': getCachedScheduledClasses(),
      'pendingProposals': getCachedPendingProposals(),
      'cachedAt': _prefs.getString(_lastRefreshKey),
      'isValid': isCacheValid(),
    };
  }

  // ===== MÉTODOS DE CACHE DE GAMIFICAÇÃO =====

  /// Salva perfil de usuário no cache
  Future<void> cacheUserProfile(UserProfile profile) async {
    try {
      final cacheKey = '${_userProfileKey}_${profile.userId}';
      final jsonString = json.encode(_normalize(profile.toJson()));
      await _prefs.setString(cacheKey, jsonString);
      
      print('💾 DEBUG: Perfil de gamificação salvo no cache');
      print('🔑 DEBUG: Cache key: $cacheKey');
      print('📊 DEBUG: Level: ${profile.level}, XP: ${profile.totalXP}');
    } catch (e) {
      print('❌ DEBUG: Erro ao salvar cache do perfil: $e');
    }
  }

  /// Recupera perfil de usuário do cache
  UserProfile? getCachedUserProfile(String userId) {
    try {
      final jsonString = _prefs.getString('${_userProfileKey}_$userId');
      if (jsonString != null) {
        final data = json.decode(jsonString);
        return UserProfile.fromJson(data);
      }
    } catch (e) {
      print('❌ DEBUG: Erro ao recuperar cache do perfil: $e');
    }
    return null;
  }

  /// Salva estatísticas de gamificação no cache
  Future<void> cacheGamificationStats(GamificationStats stats) async {
    try {
      final cacheKey = '${_gamificationStatsKey}_${stats.userId}';
      final jsonString = json.encode(_normalize(stats.toJson()));
      await _prefs.setString(cacheKey, jsonString);
      
      print('💾 DEBUG: Estatísticas de gamificação salvas no cache');
      print('🔑 DEBUG: Cache key: $cacheKey');
    } catch (e) {
      print('❌ DEBUG: Erro ao salvar cache das estatísticas: $e');
    }
  }

  /// Recupera estatísticas de gamificação do cache
  GamificationStats? getCachedGamificationStats(String userId) {
    try {
      final jsonString = _prefs.getString('${_gamificationStatsKey}_$userId');
      if (jsonString != null) {
        final data = json.decode(jsonString);
        return GamificationStats.fromJson(data);
      }
    } catch (e) {
      print('❌ DEBUG: Erro ao recuperar cache das estatísticas: $e');
    }
    return null;
  }

  /// Salva missões do usuário no cache
  Future<void> cacheUserMissions(String userId, List<UserMission> missions) async {
    try {
      final cacheKey = '${_userMissionsKey}_$userId';
      final missionsJson = missions.map((m) => _normalize(m.toJson())).toList();
      final jsonString = json.encode(missionsJson);
      await _prefs.setString(cacheKey, jsonString);
      
      print('💾 DEBUG: Missões do usuário salvas no cache');
      print('🔑 DEBUG: Cache key: $cacheKey');
      print('📊 DEBUG: ${missions.length} missões salvas');
    } catch (e) {
      print('❌ DEBUG: Erro ao salvar cache das missões: $e');
    }
  }

  /// Recupera missões do usuário do cache
  List<UserMission>? getCachedUserMissions(String userId) {
    try {
      final jsonString = _prefs.getString('${_userMissionsKey}_$userId');
      if (jsonString != null) {
        final List<dynamic> missionsJson = json.decode(jsonString);
        return missionsJson.map((m) => UserMission.fromJson(m)).toList();
      }
    } catch (e) {
      print('❌ DEBUG: Erro ao recuperar cache das missões: $e');
    }
    return null;
  }

  /// Invalida cache do perfil de usuário
  Future<void> invalidateUserProfileCache(String userId) async {
    try {
      await _prefs.remove('${_userProfileKey}_$userId');
      print('🔄 DEBUG: Cache do perfil invalidado');
    } catch (e) {
      print('❌ DEBUG: Erro ao invalidar cache do perfil: $e');
    }
  }

  /// Invalida cache das estatísticas de gamificação
  Future<void> invalidateGamificationStatsCache(String userId) async {
    try {
      await _prefs.remove('${_gamificationStatsKey}_$userId');
      print('🔄 DEBUG: Cache das estatísticas invalidado');
    } catch (e) {
      print('❌ DEBUG: Erro ao invalidar cache das estatísticas: $e');
    }
  }

  /// Invalida cache das missões do usuário
  Future<void> invalidateUserMissionsCache(String userId) async {
    try {
      await _prefs.remove('${_userMissionsKey}_$userId');
      print('🔄 DEBUG: Cache das missões invalidado');
    } catch (e) {
      print('❌ DEBUG: Erro ao invalidar cache das missões: $e');
    }
  }

}
