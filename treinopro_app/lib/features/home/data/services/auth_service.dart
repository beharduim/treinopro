import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';

/// Serviço para gerenciar autenticação local
class AuthService {
  static const String _pushNotificationsEnabledKey =
      'push_notifications_enabled';
  final SharedPreferences _prefs;

  // Cache para token válido
  String? _cachedValidToken;
  DateTime? _tokenCacheTime;
  static const Duration _tokenCacheTTL = Duration(minutes: 5);

  AuthService({required SharedPreferences prefs}) : _prefs = prefs;

  /// Obtém o token de acesso atual
  String? get accessToken => _prefs.getString('access_token');

  /// Obtém o token de refresh atual
  String? get refreshToken => _prefs.getString('refresh_token');

  /// Verifica se o usuário está autenticado
  bool get isAuthenticated => accessToken != null;

  /// Obtém o ID do usuário atual
  String? get currentUserId => _prefs.getString('user_id');

  /// Obtém o tipo de usuário atual
  String? get currentUserType => _prefs.getString('user_type');

  /// Obtém o status de aprovação profissional do personal trainer atual
  String? get currentApprovalStatus => _prefs.getString('approval_status');

  /// Data de cadastro do usuário (ISO 8601) — usada no prazo de graça de 3 dias.
  String? get currentUserCreatedAt => _prefs.getString('user_created_at');

  /// Salva tokens de autenticação
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    String? userType,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
  }) async {
    await _prefs.setString('access_token', accessToken);
    await _prefs.setString('refresh_token', refreshToken);
    await _prefs.setBool(_pushNotificationsEnabledKey, true);
    await _prefs.setString('user_id', userId);
    if (userType != null) {
      await _prefs.setString('user_type', userType);
    }
    if (firstName != null) {
      await _prefs.setString('first_name', firstName);
    }
    if (lastName != null) {
      await _prefs.setString('last_name', lastName);
    }
    if (profileImageUrl != null) {
      await _prefs.setString('profile_image_url', profileImageUrl);
    }
  }

  /// Limpa tokens de autenticação (logout)
  Future<void> clearTokens() async {
    print('🗑️ [AUTH_SERVICE] Limpando tokens...');
    print('🗑️ [AUTH_SERVICE] Cache de token antes: $_cachedValidToken');

    // ⚠️ CRÍTICO: Limpar cache de token em memória PRIMEIRO!
    _cachedValidToken = null;
    _tokenCacheTime = null;
    print('✅ [AUTH_SERVICE] Cache de token limpo');

    await _prefs.remove('access_token');
    await _prefs.remove('refresh_token');
    await _prefs.setBool(_pushNotificationsEnabledKey, false);
    await _prefs.remove('user_id');
    await _prefs.remove('user_type');
    await _prefs.remove('first_name');
    await _prefs.remove('last_name');
    await _prefs.remove('profile_image_url');
    await _prefs.remove('approval_status');
    await _prefs.remove('user_created_at');

    print('✅ [AUTH_SERVICE] Todos os tokens limpos');
  }

  /// Atualiza token de acesso
  Future<void> updateAccessToken(String newAccessToken) async {
    await _prefs.setString('access_token', newAccessToken);
  }

  /// Verifica se um token JWT está expirado
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Decodificar payload
      final payload = parts[1];
      // Adicionar padding se necessário
      String normalized = payload;
      switch (payload.length % 4) {
        case 1:
          normalized += '===';
          break;
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> tokenData = json.decode(decoded);

      // Verificar expiração
      final exp = tokenData['exp'] as int?;
      if (exp == null) return true;

      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();

      // ✅ Considerar expirado se faltar menos de 1 minuto (margem de segurança)
      final isExpired = now.isAfter(
        expirationDate.subtract(const Duration(minutes: 1)),
      );

      if (isExpired) {
        print(
          '⏰ [AUTH_SERVICE] Token expirado. Exp: $expirationDate, Now: $now',
        );
      }

      return isExpired;
    } catch (e) {
      print('⚠️ [AUTH_SERVICE] Erro ao verificar expiração do token: $e');
      // Em caso de erro, considerar expirado por segurança
      return true;
    }
  }

  /// Obtém token válido (verifica expiração)
  /// ✅ CORREÇÃO: Se token estiver expirado, retorna null para forçar renovação via ApiService
  Future<String?> getValidToken() async {
    if (!isAuthenticated) {
      return null;
    }

    final token = accessToken;
    if (token == null) {
      return null;
    }

    // ✅ NOVO: Verificar se token está expirado
    if (_isTokenExpired(token)) {
      print('⏰ [AUTH_SERVICE] Token expirado detectado');
      print(
        '⏰ [AUTH_SERVICE] Retornando null - ApiService deve renovar via interceptor',
      );

      // Verificar se refresh token também está expirado
      final refresh = refreshToken;
      if (refresh != null && _isTokenExpired(refresh)) {
        print(
          '❌ [AUTH_SERVICE] Refresh token também está expirado - limpando tokens',
        );
        await clearTokens();
        return null;
      }

      // Retornar null para que ApiService tente renovar via interceptor
      // O interceptor vai usar o refresh token para renovar
      return null;
    }

    // Verificar cache primeiro
    if (_cachedValidToken != null &&
        _tokenCacheTime != null &&
        DateTime.now().difference(_tokenCacheTime!) < _tokenCacheTTL) {
      return _cachedValidToken;
    }

    // Token válido - atualizar cache
    _cachedValidToken = token;
    _tokenCacheTime = DateTime.now();
    return token;
  }

  /// Obtém informações do usuário autenticado (apenas dados locais)
  Future<Map<String, dynamic>> getMe(String? token) async {
    final validToken = token ?? await getValidToken();
    if (validToken == null) {
      throw UnauthorizedException('Usuário não autenticado');
    }

    final profileImageUrl = _prefs.getString('profile_image_url');
    print(
      '🔍 [AUTH_SERVICE] Recuperando profileImageUrl do SharedPreferences: "$profileImageUrl"',
    );

    // Debug: verificar todas as chaves salvas
    final allKeys = _prefs.getKeys();
    print('🔍 [AUTH_SERVICE] Todas as chaves no SharedPreferences: $allKeys');
    for (final key in allKeys) {
      if (key.contains('profile') || key.contains('image')) {
        print('🔍 [AUTH_SERVICE] $key: ${_prefs.getString(key)}');
      }
    }

    // Retornar dados locais incluindo informações do perfil
    return {
      'id': currentUserId,
      'userType': currentUserType,
      'accessToken': validToken,
      'firstName': _prefs.getString('first_name') ?? '',
      'lastName': _prefs.getString('last_name') ?? '',
      'profileImageUrl': profileImageUrl,
    };
  }

  /// Limpa o cache de token (útil quando token é atualizado)
  void clearTokenCache() {
    _cachedValidToken = null;
    _tokenCacheTime = null;
  }
}
