import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/account_access_denied_exception.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/account_access_error_parser.dart';
import '../../../auth/data/services/upload_service.dart';

class ProfileApiService {
  final http.Client _httpClient;
  final ApiService _apiService;
  final UploadService _uploadService;
  final String _baseUrl;

  ProfileApiService({
    required http.Client client,
    required ApiService apiService,
    required UploadService uploadService,
    String? baseUrl,
  }) : _httpClient = client,
       _apiService = apiService,
       _uploadService = uploadService,
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Map<String, String> get _headers {
    final token = _apiService.getAccessToken();
    if (token == null) {
      return {
        'Content-Type': 'application/json',
      };
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Busca dados do perfil do usuário logado
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      print('🔍 [PROFILE API] Buscando perfil do usuário...');
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/users/profile/me'),
        headers: _headers,
      );

      print('🔍 [PROFILE API] Status da resposta: ${response.statusCode}');
      print('🔍 [PROFILE API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 [PROFILE API] Dados decodificados: $data');
        return data;
      }

      if (response.statusCode == 401) {
        final accountAccess = parseAccountAccessFromResponse(response.body);
        if (accountAccess != null) throw accountAccess;
        throw Exception('Sessão expirada. Faça login novamente.');
      }

      throw Exception('Não foi possível carregar seu perfil. Tente novamente.');
    } on AccountAccessDeniedException {
      rethrow;
    } catch (e) {
      print('❌ [PROFILE API] Erro ao buscar perfil: $e');
      final accountAccess = parseAccountAccessError(e);
      if (accountAccess != null) throw accountAccess;
      throw Exception('Não foi possível carregar seu perfil. Tente novamente.');
    }
  }

  /// Atualiza dados do perfil do usuário
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      print('🔍 [PROFILE_API] Iniciando updateUserProfile...');
      print('🔍 [PROFILE_API] Dados enviados: $profileData');
      print('🔍 [PROFILE_API] URL: $_baseUrl/users/profile/me');
      print('🔍 [PROFILE_API] Headers: $_headers');
      
      final response = await _httpClient.put(
        Uri.parse('$_baseUrl/users/profile/me'),
        headers: _headers,
        body: json.encode(profileData),
      );

      print('🔍 [PROFILE_API] Status da resposta: ${response.statusCode}');
      print('🔍 [PROFILE_API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ [PROFILE_API] Perfil atualizado com sucesso: $result');
        return result;
      } else {
        print('❌ [PROFILE_API] Erro na resposta: ${response.statusCode} - ${response.body}');
        throw Exception('Erro ao atualizar perfil: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [PROFILE_API] Erro na chamada: $e');
      throw Exception('Falha ao conectar com a API de perfil: $e');
    }
  }

  /// Extrai a mensagem de erro do backend (campo `message`/`error`).
  String _extractApiMessage(String body, String fallback) {
    try {
      final data = json.decode(body);
      if (data is Map<String, dynamic>) {
        final msg = data['message'] ?? data['error'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
        if (msg is List && msg.isNotEmpty) return msg.first.toString();
      }
    } catch (_) {}
    return fallback;
  }

  /// Envia um código de verificação para o NOVO e-mail (troca de e-mail).
  /// O backend rejeita caso o e-mail já esteja em uso.
  Future<void> sendEmailChangeCode(String newEmail) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/auth/send-verification-code'),
      headers: _headers,
      body: json.encode({'email': newEmail}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) return;
    throw Exception(
      _extractApiMessage(response.body, 'Não foi possível enviar o código.'),
    );
  }

  /// Confirma o código recebido no novo e-mail (marca como verificado).
  Future<void> verifyEmailChangeCode(String newEmail, String code) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/auth/verify-code'),
      headers: _headers,
      body: json.encode({
        'email': newEmail,
        'code': code,
        'purpose': 'registration',
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) return;
    throw Exception(
      _extractApiMessage(response.body, 'Código inválido ou expirado.'),
    );
  }

  /// Efetiva a troca de e-mail após o código ter sido verificado.
  Future<Map<String, dynamic>> changeEmail(
    String newEmail,
    String code,
  ) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/users/profile/me/change-email'),
      headers: _headers,
      body: json.encode({'newEmail': newEmail, 'code': code}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception(
      _extractApiMessage(response.body, 'Não foi possível alterar o e-mail.'),
    );
  }

  /// Atualiza localização de atendimento do personal trainer
  Future<Map<String, dynamic>> updateServiceLocation({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    try {
      print('📍 [PROFILE_API] Atualizando localização de atendimento...');
      print('📍 [PROFILE_API] Dados: lat=$lat, lng=$lng, radius=$radiusKm');
      
      final response = await _httpClient.patch(
        Uri.parse('$_baseUrl/users/profile/me/service-location'),
        headers: _headers,
        body: json.encode({
          'serviceLocationLat': lat,
          'serviceLocationLng': lng,
          'serviceRadiusKm': radiusKm,
        }),
      );

      print('📍 [PROFILE_API] Status da resposta: ${response.statusCode}');
      print('📍 [PROFILE_API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ [PROFILE_API] Localização de atendimento atualizada com sucesso');
        return result;
      } else {
        print('❌ [PROFILE_API] Erro na resposta: ${response.statusCode} - ${response.body}');
        throw Exception('Erro ao atualizar localização: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [PROFILE_API] Erro na chamada: $e');
      throw Exception('Falha ao atualizar localização de atendimento: $e');
    }
  }

  /// Upload de imagem de perfil
  Future<Map<String, dynamic>> uploadProfileImage(String imagePath) async {
    try {
      print('🔍 [PROFILE_API] Iniciando upload de imagem: $imagePath');
      
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Arquivo de imagem não encontrado');
      }

      // Usar o UploadService para fazer o upload real
      final uploadResult = await _uploadService.uploadProfileImage(
        file: file,
        description: 'Foto de perfil do usuário',
      );

      print('✅ [PROFILE_API] Upload concluído: ${uploadResult.url}');

      // Atualizar o perfil do usuário com o novo ID da imagem
      await updateUserProfile({
        'profileImageId': uploadResult.id,
      });

      return {
        'success': true,
        'imageUrl': uploadResult.url,
        'message': 'Imagem de perfil atualizada com sucesso!',
      };
    } catch (e) {
      print('❌ [PROFILE_API] Erro no upload: $e');
      throw Exception('Falha ao fazer upload da imagem: $e');
    }
  }

  /// Altera senha do usuário
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/auth/change-password'),
        headers: _headers,
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      // Tentar extrair mensagem do backend
      try {
        final data = json.decode(response.body);
        final message = data is Map<String, dynamic> ? (data['message'] ?? data['error'] ?? '') : '';
        throw Exception('Erro ao alterar senha: ${response.statusCode}${message.isNotEmpty ? ' - ' + message : ''}');
      } catch (_) {
        throw Exception('Erro ao alterar senha: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Falha ao conectar com a API: $e');
    }
  }

  /// Busca estatísticas do usuário (gamificação)
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      print('🔍 [PROFILE API] Buscando estatísticas do usuário...');
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/gamification/profile'),
        headers: _headers,
      );

      print('🔍 [PROFILE API] Status da resposta (stats): ${response.statusCode}');
      print('🔍 [PROFILE API] Corpo da resposta (stats): ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 [PROFILE API] Dados de estatísticas decodificados: $data');
        return data;
      } else {
        throw Exception('Erro ao buscar estatísticas: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [PROFILE API] Erro ao buscar estatísticas: $e');
      throw Exception('Falha ao conectar com a API de gamificação: $e');
    }
  }

  /// Exclui a conta do usuário
  Future<void> deleteAccount() async {
    try {
      print('🗑️ [PROFILE API] Excluindo conta do usuário...');
      
      // Pegar o ID do usuário do SharedPreferences (já salvo no login)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) {
        throw Exception('ID do usuário não encontrado. Faça login novamente.');
      }
      
      print('🗑️ [PROFILE API] ID do usuário: $userId');
      
      // Usar o endpoint correto: DELETE /users/account/me
      final response = await _httpClient.delete(
        Uri.parse('$_baseUrl/users/account/me'),
        headers: _headers,
      );

      print('🗑️ [PROFILE API] Status da resposta: ${response.statusCode}');
      print('🗑️ [PROFILE API] Corpo da resposta: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ [PROFILE API] Conta excluída com sucesso');
        return;
      } else if (response.statusCode == 400) {
        // Erro de validação (ex: aulas agendadas)
        final responseData = json.decode(response.body);
        final message = responseData['message'] ?? 'Não é possível excluir a conta';
        // Lançar apenas a mensagem limpa, sem "Exception:"
        throw message;
      } else {
        final responseData = json.decode(response.body);
        final message = responseData['message'] ?? 'Erro desconhecido';
        throw 'Erro ao excluir conta: $message';
      }
    } catch (e) {
      print('❌ [PROFILE API] Erro ao excluir conta: $e');
      // Se já é uma string (nossa mensagem), relançar como está
      if (e is String) {
        rethrow;
      }
      // Se é outro tipo de erro, mostrar mensagem genérica
      throw 'Não foi possível conectar com o servidor. Tente novamente.';
    }
  }
}
