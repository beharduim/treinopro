import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/forgot_password_request.dart';
import '../models/cref_validation_response.dart';
import '../models/email_verification_response.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/realtime_data_service.dart';
import '../../../../core/services/fcm_token_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../home/data/services/auth_service.dart';

class AuthApiDataSource {
  final ApiService _apiService;

  AuthApiDataSource(this._apiService);

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      // Limpar tokens antigos antes de tentar login
      await _apiService.clearTokens();

      print('🔐 [AUTH_API_DATASOURCE] Iniciando login para: ${request.email}');

      // Quero ver a URL da API.
      print(
        '🔍 [AUTH_API_DATASOURCE] URL da API: ${_apiService.dio.options.baseUrl}/auth/login',
      );

      // ✅ CORREÇÃO: Aumentar timeout especificamente para login
      final response = await _apiService.dio.post(
        '/auth/login',
        data: request.toJson(),
        options: Options(
          receiveTimeout: const Duration(seconds: 90), // 90 segundos para login
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);

        print(
          '🔍 [AUTH_API_DATASOURCE] Login response user: ${authResponse.user.toJson()}',
        );
        print(
          '🔍 [AUTH_API_DATASOURCE] Login response profileImageUrl: ${authResponse.user.profileImageUrl}',
        );

        // Salvar tokens, userId, userType e informações do perfil
        print('💾 [AUTH_API_DATASOURCE] Salvando tokens após login...');
        await _apiService.setTokens(
          authResponse.accessToken,
          authResponse.refreshToken,
          userId: authResponse.user.id,
          userType: authResponse.user.userType,
          firstName: authResponse.user.firstName,
          lastName: authResponse.user.lastName,
          profileImageUrl: authResponse.user.profileImageUrl,
          approvalStatus: authResponse.user.approvalStatus,
        );

        // ✅ CORREÇÃO: Aguardar um pouco para garantir que tokens foram salvos
        // antes de permitir requisições subsequentes
        await Future.delayed(const Duration(milliseconds: 100));

        print('✅ [AUTH_API_DATASOURCE] Tokens salvos e prontos para uso');

        return authResponse;
      } else {
        throw Exception('Falha no login: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // Garantir que tokens sejam limpos em caso de erro
      await _apiService.clearTokens();

      print('❌ [AUTH_API_DATASOURCE] Erro DioException no login: ${e.type}');
      print('❌ [AUTH_API_DATASOURCE] Mensagem: ${e.message}');
      print('❌ [AUTH_API_DATASOURCE] Status: ${e.response?.statusCode}');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'Tempo de conexão esgotado. Verifique sua conexão com a internet e tente novamente.',
        );
      } else if (e.response?.statusCode == 401) {
        throw Exception('Credenciais inválidas');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Dados inválidos');
      } else if (e.response?.statusCode == 504) {
        throw Exception(
          'Servidor demorou muito para responder. Tente novamente em alguns instantes.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          'Erro de conexão. Verifique sua internet e tente novamente.',
        );
      } else {
        throw Exception('Erro de conexão: ${e.message ?? "Erro desconhecido"}');
      }
    } catch (e) {
      // Garantir que tokens sejam limpos em caso de erro
      await _apiService.clearTokens();
      print('❌ [AUTH_API_DATASOURCE] Erro inesperado no login: $e');
      throw Exception('Erro inesperado: $e');
    }
  }

  /// Método de registro seguindo a documentação da API
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      print(
        'AuthApiDataSource: Enviando dados de registro: ${request.toJson()}',
      );

      final response = await _apiService.dio.post(
        '/auth/register',
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        print('AuthApiDataSource: Registro realizado com sucesso');
        final authResponse = AuthResponse.fromJson(response.data);

        // Salvar tokens, userId, userType e informações do perfil
        await _apiService.setTokens(
          authResponse.accessToken,
          authResponse.refreshToken,
          userId: authResponse.user.id,
          userType: authResponse.user.userType,
          firstName: authResponse.user.firstName,
          lastName: authResponse.user.lastName,
          profileImageUrl: authResponse.user.profileImageUrl,
          approvalStatus: authResponse.user.approvalStatus,
        );

        return authResponse;
      } else {
        throw Exception('Erro no registro: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('AuthApiDataSource: Erro DioException no registro: ${e.message}');
      if (e.response?.statusCode == 409) {
        throw Exception('Email já está em uso');
      } else if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] ?? 'Dados inválidos';
        throw Exception(errorMessage);
      } else {
        throw Exception('Erro de conexão: ${e.message}');
      }
    } catch (e) {
      print('AuthApiDataSource: Erro inesperado no registro: $e');
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    try {
      print(
        'AuthApiDataSource: Enviando forgot-password para ${request.email}',
      );
      print('AuthApiDataSource: URL: /auth/forgot-password');
      print('AuthApiDataSource: Data: ${request.toJson()}');

      final response = await _apiService.dio.post(
        '/auth/forgot-password',
        data: request.toJson(),
      );

      print(
        'AuthApiDataSource: Resposta recebida - Status: ${response.statusCode}',
      );
      print('AuthApiDataSource: Resposta data: ${response.data}');

      if (response.statusCode != 200) {
        throw Exception(
          'Falha ao solicitar reset de senha: ${response.statusMessage}',
        );
      }

      print('AuthApiDataSource: Forgot password enviado com sucesso');
    } on DioException catch (e) {
      print('AuthApiDataSource: DioException - ${e.message}');
      print('AuthApiDataSource: Status code: ${e.response?.statusCode}');
      print('AuthApiDataSource: Response data: ${e.response?.data}');
      throw Exception('Erro de conexão: ${e.message}');
    } catch (e) {
      print('AuthApiDataSource: Erro inesperado: $e');
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<void> logout() async {
    print('🚪 [AUTH_DATASOURCE] Iniciando logout...');

    try {
      await NotificationService.setPushNotificationsEnabled(false);
    } catch (e) {
      print(
        '⚠️ [AUTH_DATASOURCE] Erro ao desabilitar push no início do logout: $e',
      );
    }

    // 1. Remover token FCM do backend e limpar localmente
    try {
      final fcmService = FcmTokenService();
      String? userId;
      try {
        final sl = GetIt.instance;
        if (sl.isRegistered<AuthService>()) {
          userId = sl<AuthService>().currentUserId;
        }
      } catch (_) {}
      if (userId == null || userId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('user_id');
      }
      if (userId != null && userId.isNotEmpty) {
        await fcmService.removeTokenFromServer(userId);
        print('✅ [AUTH_DATASOURCE] Token FCM removido do backend');
      } else {
        fcmService.clearToken();
        print('✅ [AUTH_DATASOURCE] Token FCM limpo (sem userId)');
      }
    } catch (e) {
      print('⚠️ [AUTH_DATASOURCE] Erro ao remover token FCM: $e');
    }

    // 2. Limpar tokens e dados do SharedPreferences
    await _apiService.clearTokens();
    print('✅ [AUTH_DATASOURCE] Tokens da API limpos');

    // 3. ⚠️ CRÍTICO: Limpar cache do AuthService
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<AuthService>()) {
        await sl<AuthService>().clearTokens();
        print('✅ [AUTH_DATASOURCE] Cache do AuthService limpo');
      }
    } catch (e) {
      print('⚠️ [AUTH_DATASOURCE] Erro ao limpar AuthService: $e');
    }

    // 4. Resetar services que mantêm cache em memória
    try {
      final sl = GetIt.instance;

      // Resetar services que podem ter cache de dados do usuário
      if (sl.isRegistered<RealtimeDataService>()) {
        sl<RealtimeDataService>().dispose();
      }

      print('✅ [AUTH_DATASOURCE] Services resetados com sucesso');
    } catch (e) {
      print('⚠️ [AUTH_DATASOURCE] Erro ao resetar services: $e');
    }

    print('✅ [AUTH_DATASOURCE] Logout concluído');
  }

  Future<bool> isAuthenticated() async {
    return _apiService.isAuthenticated;
  }

  Future<CrefValidationResponse> validateCref(String cref) async {
    try {
      final response = await _apiService.dio.post(
        '/cref/validate',
        data: {'crefNumber': cref},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return CrefValidationResponse.fromJson(response.data);
      } else {
        throw Exception('Falha na validação CREF: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('CREF não encontrado');
      } else if (e.response?.statusCode == 400) {
        // Extrair mensagem de erro da resposta da API se disponível
        final errorMessage = e.response?.data?['message'];
        if (errorMessage is List && errorMessage.isNotEmpty) {
          throw Exception(errorMessage.first.toString());
        } else if (errorMessage is String) {
          throw Exception(errorMessage);
        }
        throw Exception('Formato de CREF inválido');
      } else if (e.response?.statusCode == 403) {
        throw Exception(
          'Apenas profissionais com bacharelado em Educação Física podem se cadastrar',
        );
      } else {
        throw Exception('Erro de conexão: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<SendVerificationCodeResponse> sendVerificationCode(
    String email,
  ) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/send-verification-code',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        return SendVerificationCodeResponse.fromJson(response.data);
      } else {
        throw Exception('Falha ao enviar código: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorMessage =
            e.response?.data?['message'] ??
            'Email inválido ou usuário não encontrado';
        throw Exception(errorMessage);
      } else {
        throw Exception('Erro de conexão: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<VerifyCodeResponse> verifyCode(String email, String code) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/verify-code',
        data: {'email': email, 'code': code, 'purpose': 'registration'},
      );

      if (response.statusCode == 200) {
        return VerifyCodeResponse.fromJson(response.data);
      } else {
        throw Exception('Falha na verificação: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorMessage =
            e.response?.data?['message'] ?? 'Código inválido ou expirado';
        throw Exception(errorMessage);
      } else {
        throw Exception('Erro de conexão: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }

  Future<bool> checkEmail(String email) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/check-email',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        return response.data['exists'] as bool;
      } else {
        throw Exception('Falha ao verificar email: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print(
        '❌ [AUTH_API_DATASOURCE] Erro DioException ao verificar email: ${e.type}',
      );
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'Tempo de conexão esgotado. Verifique sua conexão com a internet.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Erro de conexão. Verifique sua internet.');
      } else if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data?['message'] ?? 'Email inválido';
        throw Exception(errorMessage);
      } else {
        throw Exception('Erro de conexão: ${e.message}');
      }
    } catch (e) {
      print('❌ [AUTH_API_DATASOURCE] Erro inesperado ao verificar email: $e');
      throw Exception('Erro inesperado ao verificar email: $e');
    }
  }

  Future<bool> checkDocument(String documentType, String documentNumber) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/check-document',
        data: {'documentType': documentType, 'documentNumber': documentNumber},
      );

      if (response.statusCode == 200) {
        return response.data['exists'] as bool;
      } else {
        throw Exception(
          'Falha ao verificar documento: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      print(
        '❌ [AUTH_API_DATASOURCE] Erro DioException ao verificar documento: ${e.type}',
      );
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'Tempo de conexão esgotado. Verifique sua conexão com a internet.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Erro de conexão. Verifique sua internet.');
      } else if (e.response?.statusCode == 400) {
        final errorMessage =
            e.response?.data?['message'] ?? 'Documento inválido';
        throw Exception(errorMessage);
      } else {
        throw Exception('Erro de conexão: ${e.message}');
      }
    } catch (e) {
      print(
        '❌ [AUTH_API_DATASOURCE] Erro inesperado ao verificar documento: $e',
      );
      throw Exception('Erro inesperado ao verificar documento: $e');
    }
  }
}
