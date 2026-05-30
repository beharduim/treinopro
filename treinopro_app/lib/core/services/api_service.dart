import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../utils/account_access_error_parser.dart';
import 'account_access_handler.dart';

class ApiService {
  static const String _pushNotificationsEnabledKey =
      'push_notifications_enabled';
  String get baseUrl => AppConfig.apiBaseUrl;
  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  // Controle de renovação de token para evitar race conditions
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // ✅ CORREÇÃO: Aumentar timeouts para evitar erros de timeout
        // Especialmente importante para login que pode demorar mais
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        // Remove o Content-Type padrão para permitir configuração por request
      ),
    );

    _setupInterceptors();
    _loadTokens();
  }

  void _setupInterceptors() {
    // Interceptor para adicionar token de autorização
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          // Adiciona Content-Type padrão apenas se não estiver definido
          if (!options.headers.containsKey('Content-Type') &&
              options.data is! FormData) {
            options.headers['Content-Type'] = 'application/json';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Não tentar renovar token se for uma rota de login ou refresh
          final isLoginRoute = error.requestOptions.path.contains(
            '/auth/login',
          );
          final isRefreshRoute = error.requestOptions.path.contains(
            '/auth/refresh',
          );

          // Não limpar tokens se for erro 401 em rota de login (credenciais inválidas)
          if (error.response?.statusCode == 401) {
            if (isLoginRoute) {
              print(
                '🔐 [API_SERVICE] Erro 401 em rota de login - credenciais inválidas',
              );
              handler.next(error);
              return;
            }

            final accountAccess = parseAccountAccessFromResponse(
              error.response?.data,
            );
            if (accountAccess != null) {
              print(
                '🚫 [API_SERVICE] Conta bloqueada/recusada — encerrando sessão',
              );
              _resetRefreshState();
              await _clearTokens();
              unawaited(AccountAccessHandler.present(accountAccess));
              handler.next(error);
              return;
            }

            // Tentar renovar se tiver refresh token E não for rota de refresh
            if (_refreshToken != null && !isRefreshRoute) {
              // Renovação com lock para evitar concorrência
              try {
                if (_isRefreshing) {
                  print(
                    '⏳ [API_SERVICE] Aguardando renovação de token em andamento...',
                  );
                  await _refreshCompleter?.future;
                } else {
                  _isRefreshing = true;
                  _refreshCompleter = Completer<void>();
                  print('🔄 [API_SERVICE] Iniciando renovação de token...');
                  await _refreshAccessToken();
                  _isRefreshing = false;
                  _refreshCompleter?.complete();
                  print('✅ [API_SERVICE] Renovação de token concluída');
                }

                // Repetir a requisição original com o novo token
                final req = error.requestOptions;
                final updatedHeaders = Map<String, dynamic>.from(req.headers);
                if (_accessToken != null) {
                  updatedHeaders['Authorization'] = 'Bearer $_accessToken';
                  print(
                    '🔄 [API_SERVICE] Repetindo requisição com novo token: ${req.path}',
                  );
                } else {
                  updatedHeaders.remove('Authorization');
                  print('⚠️ [API_SERVICE] Token ainda null após renovação');
                }

                final response = await _dio.request(
                  req.path,
                  data: req.data,
                  queryParameters: req.queryParameters,
                  options: Options(
                    method: req.method,
                    headers: updatedHeaders,
                    responseType: req.responseType,
                    contentType: req.contentType,
                    followRedirects: req.followRedirects,
                    sendTimeout: req.sendTimeout,
                    receiveTimeout: req.receiveTimeout,
                    validateStatus: req.validateStatus,
                  ),
                  cancelToken: req.cancelToken,
                  onReceiveProgress: req.onReceiveProgress,
                  onSendProgress: req.onSendProgress,
                );
                handler.resolve(response);
                return;
              } catch (e) {
                _isRefreshing = false;
                _refreshCompleter?.completeError(e);

                print('❌ [API_SERVICE] Falha ao renovar token: $e');

                final blockedAfterRefresh = parseAccountAccessError(e) ??
                    parseAccountAccessFromResponse(error.response?.data);
                if (blockedAfterRefresh != null) {
                  _resetRefreshState();
                  await _clearTokens();
                  unawaited(AccountAccessHandler.present(blockedAfterRefresh));
                  handler.next(error);
                  return;
                }

                // Só limpar tokens se o refresh endpoint confirmou que o token é inválido (401/403)
                // Erros de rede, timeout ou outros não devem causar logout
                final isAuthError =
                    e is DioException &&
                    (e.response?.statusCode == 401 ||
                        e.response?.statusCode == 403);
                final isExplicitAuthError =
                    e.toString().contains('401') ||
                    e.toString().contains('Unauthorized') ||
                    e.toString().contains('expired');

                if (isAuthError || isExplicitAuthError) {
                  print(
                    '🗑️ [API_SERVICE] Limpando tokens: refresh confirmou sessão inválida',
                  );
                  await _clearTokens();
                } else {
                  print(
                    '⚠️ [API_SERVICE] Erro transitório no refresh - mantendo sessão',
                  );
                }

                handler.next(error);
                return;
              }
            } else {
              // Sem refresh token: NÃO limpar tokens agressivamente.
              // Propagar o erro para a camada de UI decidir o que fazer.
              // Isso evita "deslogar" o aluno por um 401 isolado em chamada de fundo.
              print(
                '⚠️ [API_SERVICE] Erro 401 sem refresh token - propagando erro (sem limpar sessão)',
              );

              // Só limpar se realmente não temos nenhum token (sessão já perdida)
              if (_accessToken == null) {
                print(
                  '🗑️ [API_SERVICE] Sessão já perdida (_accessToken == null)',
                );
                await _clearTokens();
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> _saveTokens(
    String accessToken,
    String refreshToken, {
    String? userId,
    String? userType,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    String? approvalStatus,
    String? userCreatedAt,
  }) async {
    print('💾 [API_SERVICE] Salvando tokens...');
    print('💾 [API_SERVICE] userId: $userId');
    print('💾 [API_SERVICE] userType: $userType');
    print('💾 [API_SERVICE] Token: ${accessToken.substring(0, 20)}...');

    // ⚠️ CRÍTICO: Atualizar variáveis de instância PRIMEIRO
    // Isso garante que requests imediatos usem o token correto
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    print('✅ [API_SERVICE] Variáveis de instância atualizadas');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setBool(_pushNotificationsEnabledKey, true);
    if (userId != null) {
      await prefs.setString('user_id', userId);
    }
    if (userType != null) {
      await prefs.setString('user_type', userType);
    }
    if (firstName != null) {
      await prefs.setString('first_name', firstName);
    }
    if (lastName != null) {
      await prefs.setString('last_name', lastName);
    }
    if (profileImageUrl != null) {
      await prefs.setString('profile_image_url', profileImageUrl);
      print('✅ [API_SERVICE] profileImageUrl salva: "$profileImageUrl"');
    } else {
      print('⚠️ [API_SERVICE] profileImageUrl é null');
    }
    if (approvalStatus != null) {
      await prefs.setString('approval_status', approvalStatus);
    }
    if (userCreatedAt != null) {
      await prefs.setString('user_created_at', userCreatedAt);
    }

    print('✅ [API_SERVICE] Tokens salvos no SharedPreferences');
  }

  void _resetRefreshState() {
    _isRefreshing = false;
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      _refreshCompleter!.complete();
    }
    _refreshCompleter = null;
  }

  Future<void> _clearTokens() async {
    print('🗑️ [API_SERVICE] Limpando TODOS os dados do SharedPreferences...');

    // ⚠️ CRÍTICO: Limpar variáveis de instância PRIMEIRO
    // Isso garante que nenhum request use o token antigo enquanto limpamos o storage
    final oldAccessToken = _accessToken;
    _accessToken = null;
    _refreshToken = null;
    print('🗑️ [API_SERVICE] Variáveis de instância limpas');
    print(
      '🗑️ [API_SERVICE] Token antigo: ${oldAccessToken?.substring(0, 20)}...',
    );

    final prefs = await SharedPreferences.getInstance();

    // Limpar tokens de autenticação
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.setBool(_pushNotificationsEnabledKey, false);
    await prefs.remove('user_id');
    await prefs.remove('user_type');

    // Limpar dados do perfil
    await prefs.remove('first_name');
    await prefs.remove('last_name');
    await prefs.remove('profile_image_url');

    // ⚠️ CORREÇÃO DO BUG: Limpar TODOS os dados em cache
    // Isso garante que quando outro usuário logar, não verá dados do usuário anterior
    final keys = prefs.getKeys();
    for (final key in keys) {
      // Manter apenas configurações do app que não são específicas do usuário
      // Também preservar notificações locais (são específicas do dispositivo, não do usuário)
      if (!key.startsWith('app_') &&
          !key.startsWith('settings_') &&
          key != 'local_notifications' && // Preservar notificações locais
          key != 'onboarding_completed' && // Preservar estado de onboarding
          key != 'onboarding_current_page') {
        await prefs.remove(key);
        print('🗑️ [API_SERVICE] Removido: $key');
      }
    }

    print('✅ [API_SERVICE] Todos os dados limpos com sucesso');
    print('✅ [API_SERVICE] _accessToken agora é: $_accessToken');
    print('✅ [API_SERVICE] _refreshToken agora é: $_refreshToken');
  }

  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) {
      print('❌ [API_SERVICE] Refresh token não disponível');
      throw Exception('Refresh token não disponível');
    }

    print('🔄 [API_SERVICE] Tentando renovar token...');
    try {
      // ✅ CORREÇÃO: Usar dio sem interceptor para evitar loop infinito
      final dioWithoutInterceptor = Dio(_dio.options);

      final response = await dioWithoutInterceptor.post(
        '/auth/refresh',
        data: {'refreshToken': _refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ [API_SERVICE] Token renovado com sucesso');
        final refreshedApprovalStatus =
            data['user']?['approvalStatus'] as String?;
        await _saveTokens(
          data['accessToken'],
          data['refreshToken'],
          userId: data['user']?['id'] as String? ?? data['userId'] as String?,
          approvalStatus: refreshedApprovalStatus,
        );
      } else {
        print(
          '❌ [API_SERVICE] Falha ao renovar token - Status: ${response.statusCode}',
        );
        throw Exception('Falha ao renovar token');
      }
    } on DioException catch (e) {
      print('❌ [API_SERVICE] Erro DioException ao renovar token: ${e.message}');
      print('❌ [API_SERVICE] Status: ${e.response?.statusCode}');
      print('❌ [API_SERVICE] Response: ${e.response?.data}');
      throw Exception('Erro ao renovar token: ${e.message}');
    } catch (e) {
      print('❌ [API_SERVICE] Erro inesperado ao renovar token: $e');
      throw Exception('Erro ao renovar token: $e');
    }
  }

  // Métodos públicos para gerenciar tokens
  Future<void> setTokens(
    String accessToken,
    String refreshToken, {
    String? userId,
    String? userType,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    String? approvalStatus,
    String? userCreatedAt,
  }) async {
    print('🔑 [API_SERVICE] setTokens chamado');
    await _saveTokens(
      accessToken,
      refreshToken,
      userId: userId,
      userType: userType,
      firstName: firstName,
      lastName: lastName,
      profileImageUrl: profileImageUrl,
      approvalStatus: approvalStatus,
      userCreatedAt: userCreatedAt,
    );
    print('🔑 [API_SERVICE] setTokens concluído');
  }

  Future<void> clearTokens() async {
    print('🗑️ [API_SERVICE] clearTokens chamado');
    await _clearTokens();
    print('🗑️ [API_SERVICE] clearTokens concluído');
  }

  bool get isAuthenticated => _accessToken != null;

  // Getter para o access token
  String? getAccessToken() {
    print(
      '🔍 [API_SERVICE] getAccessToken chamado - Token: ${_accessToken?.substring(0, 20)}...',
    );
    return _accessToken;
  }

  // Getter para o user type
  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }

  // Método público para renovar o token manualmente
  Future<bool> refreshToken() async {
    try {
      await _refreshAccessToken();
      print('✅ [API_SERVICE] Token renovado com sucesso');
      return true;
    } catch (e) {
      print('❌ [API_SERVICE] Erro ao renovar token: $e');
      return false;
    }
  }

  // Getter para o Dio instance
  Dio get dio => _dio;
}
