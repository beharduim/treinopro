import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Serviço para gerenciar envio de token FCM ao backend
class FcmTokenService {
  static final FcmTokenService _instance = FcmTokenService._internal();
  factory FcmTokenService() => _instance;
  FcmTokenService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static const String _persistedTokenKey = 'last_fcm_token';
  String? _currentToken;
  String? _lastSentUserId;
  bool _isInitialized = false;
  bool _listenerRegistered = false;

  String _detectarPlataforma() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    }

    return 'unknown';
  }

  Future<void> _persistToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_persistedTokenKey);
      return;
    }
    await prefs.setString(_persistedTokenKey, token);
  }

  Future<String?> _loadPersistedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_persistedTokenKey);
  }

  /// Inicializar serviço e configurar listeners
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('🔥 [FCM_TOKEN] Serviço já inicializado');
      }
      return;
    }

    try {
      // iOS: garantir que APNs token está disponível antes de obter FCM token
      if (Platform.isIOS) {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (kDebugMode) {
          print(
            '🍎 [FCM_TOKEN] APNs token: ${apnsToken != null ? "obtido" : "indisponível"}',
          );
        }
        if (apnsToken == null) {
          // Aguardar um pouco e tentar novamente — APNs pode demorar
          await Future.delayed(const Duration(seconds: 2));
          final retryToken = await _firebaseMessaging.getAPNSToken();
          if (kDebugMode) {
            print(
              '🍎 [FCM_TOKEN] APNs token (retry): ${retryToken != null ? "obtido" : "ainda indisponível"}',
            );
          }
        }
      }

      // Obter token FCM
      _currentToken = await _firebaseMessaging.getToken();
      await _persistToken(_currentToken);
      if (kDebugMode) {
        print(
          '🔥 [FCM_TOKEN] Token inicial obtido: ${_currentToken?.substring(0, 20)}...',
        );
      }

      // Listener para quando token mudar — registrado apenas uma vez durante o ciclo de vida do app.
      // _lastSentUserId controla se o token deve ser enviado ao backend.
      if (!_listenerRegistered) {
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          if (kDebugMode) {
            print(
              '🔥 [FCM_TOKEN] Token atualizado: ${newToken.substring(0, 20)}...',
            );
          }
          _currentToken = newToken;
          await _persistToken(newToken);

          // Só envia se usuário estiver logado
          if (_lastSentUserId != null) {
            if (kDebugMode) {
              print(
                '🔄 [FCM_TOKEN] Enviando token atualizado para usuário: $_lastSentUserId',
              );
            }
            final success = await sendTokenToServer(_lastSentUserId!);
            if (kDebugMode) {
              print(
                success
                    ? '✅ [FCM_TOKEN] Token atualizado enviado com sucesso'
                    : '⚠️ [FCM_TOKEN] Falha ao enviar token atualizado',
              );
            }
          } else {
            if (kDebugMode) {
              print(
                'ℹ️ [FCM_TOKEN] Token atualizado mas nenhum usuário logado — ignorando',
              );
            }
          }
        });
        _listenerRegistered = true;
      }

      _isInitialized = true;
      if (kDebugMode) {
        print('✅ [FCM_TOKEN] Serviço inicializado com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FCM_TOKEN] Erro ao inicializar: $e');
      }
    }
  }

  /// Obter token atual
  String? get currentToken => _currentToken;

  /// Verificar se usuário já enviou token
  bool hasSentTokenForUser(String userId) {
    return _lastSentUserId == userId && _currentToken != null;
  }

  /// Enviar token para o backend
  Future<bool> sendTokenToServer(String userId) async {
    try {
      // Registrar usuário alvo imediatamente para permitir envio automático
      // quando o token chegar via onTokenRefresh (caso ainda não exista agora).
      _lastSentUserId = userId;

      // Garantir que serviço está inicializado
      if (!_isInitialized) {
        await initialize();
      }

      // Tentar obter token se ainda não tiver
      if (_currentToken == null || _currentToken!.isEmpty) {
        if (kDebugMode) {
          print('🔄 [FCM_TOKEN] Token não disponível, obtendo novo token...');
        }
        try {
          // iOS pode demorar para disponibilizar APNs/FCM token após login.
          // Fazemos algumas tentativas antes de desistir.
          if (Platform.isIOS) {
            const maxAttempts = 8;
            for (var attempt = 1; attempt <= maxAttempts; attempt++) {
              await _firebaseMessaging.getAPNSToken();
              _currentToken = await _firebaseMessaging.getToken();
              if (_currentToken != null && _currentToken!.isNotEmpty) {
                await _persistToken(_currentToken);
                break;
              }
              if (kDebugMode) {
                print(
                  '🍎 [FCM_TOKEN] Tentativa $attempt/$maxAttempts sem token, aguardando...',
                );
              }
              await Future.delayed(const Duration(seconds: 1));
            }
          } else {
            _currentToken = await _firebaseMessaging.getToken();
            await _persistToken(_currentToken);
          }

          if (kDebugMode) {
            if (_currentToken != null && _currentToken!.isNotEmpty) {
              print(
                '✅ [FCM_TOKEN] Novo token obtido: ${_currentToken!.substring(0, 20)}...',
              );
            } else {
              print('⚠️ [FCM_TOKEN] Falha ao obter token FCM');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ [FCM_TOKEN] Erro ao obter token FCM: $e');
          }
        }
      }

      if (_currentToken == null || _currentToken!.isEmpty) {
        if (kDebugMode) {
          print('❌ [FCM_TOKEN] Token não disponível para usuário: $userId');
          print(
            '❌ [FCM_TOKEN] Isso pode impedir o recebimento de notificações quando app está TERMINATED',
          );
          print(
            'ℹ️ [FCM_TOKEN] O userId foi mantido em memória e será usado no próximo onTokenRefresh',
          );
        }
        return false;
      }

      // Obter ApiService
      final apiService = GetIt.instance<ApiService>();
      final token = apiService.getAccessToken();

      if (token == null) {
        if (kDebugMode) {
          print(
            '⚠️ [FCM_TOKEN] Token de autenticação não disponível para usuário: $userId',
          );
        }
        return false;
      }

      // Verificar se já enviou o mesmo token para o mesmo usuário
      if (_lastSentUserId == userId && _currentToken != null) {
        // Pode ser que o token não tenha mudado, mas vamos enviar mesmo assim
        // para garantir sincronização com o backend
        if (kDebugMode) {
          print('🔄 [FCM_TOKEN] Reenviando token para sincronização: $userId');
        }
      }

      if (kDebugMode) {
        print('🔥 [FCM_TOKEN] Enviando token FCM para usuário: $userId');
        print('🔥 [FCM_TOKEN] Token: ${_currentToken!.substring(0, 20)}...');
      }

      final response = await apiService.dio.post(
        '/users/$userId/fcm-token',
        data: {'token': _currentToken, 'platform': _detectarPlataforma()},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print(
            '✅ [FCM_TOKEN] Token enviado com sucesso para usuário: $userId',
          );
          print('✅ [FCM_TOKEN] Resposta do servidor: ${response.data}');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ [FCM_TOKEN] Erro ao enviar token: ${response.statusCode}');
          print('❌ [FCM_TOKEN] Resposta: ${response.data}');
        }
        return false;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [FCM_TOKEN] Erro ao enviar token: $e');
        print('❌ [FCM_TOKEN] StackTrace: $stackTrace');
      }
      return false;
    }
  }

  /// Remove o token FCM do backend, invalida o token no Firebase e limpa todo o estado local (logout).
  /// Após isso, a próxima chamada a sendTokenToServer gerará um token completamente novo.
  Future<void> removeTokenFromServer(String userId) async {
    // Tentar obter token fresh do Firebase antes de deletar.
    String? token = _currentToken;
    if (token == null || token.isEmpty) {
      token = await _loadPersistedToken();
    }
    if (token == null || token.isEmpty) {
      try {
        if (Platform.isIOS) {
          await _firebaseMessaging.getAPNSToken();
        }
        token = await _firebaseMessaging.getToken();
        await _persistToken(token);
        if (kDebugMode) {
          print(
            '🔄 [FCM_TOKEN] Token obtido fresh para logout: ${token?.substring(0, 20)}...',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '⚠️ [FCM_TOKEN] Não foi possível obter token fresh no logout: $e',
          );
        }
      }
    }

    // Limpar estado local imediatamente — independente do resultado das chamadas abaixo
    _lastSentUserId = null;
    _currentToken = null;
    _isInitialized = false;
    await _persistToken(null);

    // 1. Remover token do backend
    if (token != null && token.isNotEmpty) {
      try {
        final apiService = GetIt.instance<ApiService>();
        final authToken = apiService.getAccessToken();
        if (authToken != null) {
          await apiService.dio.delete(
            '/users/$userId/fcm-token',
            queryParameters: {'token': token},
          );
          if (kDebugMode) {
            print('✅ [FCM_TOKEN] Token removido do backend no logout');
          }
        } else {
          if (kDebugMode) {
            print(
              '⚠️ [FCM_TOKEN] Auth token inválido — não foi possível remover token do backend',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            '⚠️ [FCM_TOKEN] Erro ao remover token do backend no logout: $e',
          );
        }
      }
    } else {
      if (kDebugMode) {
        print('ℹ️ [FCM_TOKEN] Sem token para remover do backend no logout');
      }
    }

    // 2. Invalidar o token no Firebase — garante que nenhuma notificação será entregue
    // ao dispositivo com o token antigo. O próximo login gerará um token novo.
    try {
      await _firebaseMessaging.deleteToken();
      if (kDebugMode) {
        print('✅ [FCM_TOKEN] Token FCM invalidado no Firebase (logout)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [FCM_TOKEN] Erro ao invalidar token no Firebase: $e');
      }
    }
  }

  /// Limpar token quando usuário fizer logout (apenas local, sem chamar backend)
  void clearToken() {
    _lastSentUserId = null;
    _currentToken = null;
    _isInitialized = false;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.remove(_persistedTokenKey),
    );
    if (kDebugMode) {
      print('🔥 [FCM_TOKEN] Token limpo (logout)');
    }
  }

  /// Atualizar token FCM (chamado quando token é renovado)
  Future<bool> updateToken(String newToken) async {
    if (kDebugMode) {
      print(
        '🔄 [FCM_TOKEN] Atualizando token: ${newToken.substring(0, 20)}...',
      );
    }

    _currentToken = newToken;
    await _persistToken(newToken);

    // Enviar novo token se usuário estiver logado
    if (_lastSentUserId != null) {
      if (kDebugMode) {
        print(
          '📤 [FCM_TOKEN] Enviando token atualizado para usuário: $_lastSentUserId',
        );
      }
      return await sendTokenToServer(_lastSentUserId!);
    } else {
      if (kDebugMode) {
        print('ℹ️ [FCM_TOKEN] Token atualizado mas nenhum usuário logado');
      }
      return true; // Não é erro, apenas não tem usuário logado
    }
  }

  /// Forçar atualização do token (útil para retry)
  Future<void> refreshToken() async {
    try {
      if (Platform.isIOS) {
        await _firebaseMessaging.getAPNSToken();
      }
      _currentToken = await _firebaseMessaging.getToken();
      await _persistToken(_currentToken);
      if (kDebugMode) {
        print('🔥 [FCM_TOKEN] Token atualizado manualmente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FCM_TOKEN] Erro ao atualizar token: $e');
      }
    }
  }
}
