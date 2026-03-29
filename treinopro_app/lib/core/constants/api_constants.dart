import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Constantes da API
class ApiConstants {
  // Usar configuração centralizada do AppConfig
  static String get baseUrl => AppConfig.apiBaseUrl;
  
  // TODO: Implementar token real de autenticação
  static const String authToken = 'temp_token_placeholder';
  
  // Endpoints de autenticação
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';
  
  // Endpoints de usuários
  static const String userProfile = '/users/profile/me';
  
  // Endpoints de gamificação
  static const String gamificationProfile = '/gamification/profile';
  static const String gamificationStats = '/gamification/stats';
  static const String gamificationMissions = '/gamification/missions/user/my-missions';
  static const String gamificationAchievements = '/gamification/achievements/user/my-achievements';
  
  // Endpoints de classes
  static const String classes = '/classes';
  static const String classesStats = '/classes/stats';
  
  // Endpoints de propostas
  static const String proposals = '/proposals';
  static const String myProposals = '/proposals/my';
  static const String proposalsStats = '/proposals/stats';
  
  // Endpoints de locais
  static const String locationsSearch = '/locations/search';
  static const String locationsFavorites = '/locations/favorites';
  
  // Endpoints de upload
  static const String uploadProfile = '/upload/profile-image';
  static const String uploadDocument = '/upload/document';
  static const String uploadTemp = '/upload/temp';
  
  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };
  
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
