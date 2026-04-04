import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:treinopro_app/firebase_options.dart';
import 'package:treinopro_app/core/config/app_config.dart';

/// Serviço WorkManager para garantir reliability do FCM mesmo em Doze Mode
/// Executa verificações periódicas (a cada 15 minutos) para garantir que o FCM está funcionando
class FcmWorkManagerService {
  // Nome único da task
  static const String _taskName = 'fcmHealthCheck';
  static const String _uniqueName = 'fcmHealthCheckUnique';

  /// Inicializa o WorkManager e registra a task periódica
  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('🔧 [WORKMANAGER] Inicializando...');
      }

      // Inicializar Workmanager
      await Workmanager().initialize(
        callbackDispatcher,
        // Mantém sem notificação de debug do plugin (ex.: "Result: Success / dartTask")
        isInDebugMode: false,
      );

      // Registrar task periódica
      await registerPeriodicTask();

      if (kDebugMode) {
        print('✅ [WORKMANAGER] Inicializado com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [WORKMANAGER] Erro ao inicializar: $e');
      }
    }
  }

  /// Registra task periódica para verificação de saúde do FCM
  static Future<void> registerPeriodicTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        _uniqueName,
        _taskName,
        frequency: const Duration(minutes: 15), // Mínimo permitido
        constraints: Constraints(
          networkType: NetworkType.connected, // Requer conexão com internet
          requiresBatteryNotLow: false, // Executa mesmo com bateria baixa
          requiresCharging: false, // Executa mesmo sem estar carregando
          requiresDeviceIdle:
              false, // Executa mesmo que dispositivo esteja em uso
          requiresStorageNotLow: false, // Executa mesmo com storage baixo
        ),
        existingWorkPolicy: ExistingWorkPolicy.keep, // Manter work existente
        initialDelay: const Duration(
          minutes: 15,
        ), // Primeira execução após 15min
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 1),
      );

      if (kDebugMode) {
        print('✅ [WORKMANAGER] Task periódica registrada (15min)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [WORKMANAGER] Erro ao registrar task: $e');
      }
    }
  }

  /// Cancela todas as tasks do WorkManager
  static Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelAll();
      if (kDebugMode) {
        print('🗑️ [WORKMANAGER] Todas as tasks canceladas');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [WORKMANAGER] Erro ao cancelar tasks: $e');
      }
    }
  }

  /// Cancela task específica
  static Future<void> cancelTask() async {
    try {
      await Workmanager().cancelByUniqueName(_uniqueName);
      if (kDebugMode) {
        print('🗑️ [WORKMANAGER] Task FCM health check cancelada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [WORKMANAGER] Erro ao cancelar task: $e');
      }
    }
  }
}

/// Callback dispatcher para WorkManager
/// DEVE ser top-level function com @pragma
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (kDebugMode) {
        print('⏰ [WORKMANAGER] Task executando: $task');
        print('📊 [WORKMANAGER] InputData: $inputData');
      }

      switch (task) {
        case 'fcmHealthCheck':
          await _performFcmHealthCheck();
          break;

        default:
          if (kDebugMode) {
            print('⚠️ [WORKMANAGER] Task desconhecida: $task');
          }
      }

      // Retornar sucesso
      return Future.value(true);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [WORKMANAGER] Erro ao executar task: $e');
      }
      // Retornar falha para trigger retry com backoff
      return Future.value(false);
    }
  });
}

/// Realiza verificação de saúde do FCM
Future<void> _performFcmHealthCheck() async {
  try {
    if (kDebugMode) {
      print('🔍 [FCM_HEALTH] Iniciando health check...');
    }

    // ✅ WorkManager roda em isolate separado - garantir que Firebase esteja inicializado
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) {
        print('🔄 [FCM_HEALTH] Firebase não inicializado - inicializando...');
      }
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) {
        print('✅ [FCM_HEALTH] Firebase inicializado no WorkManager isolate');
      }
    }

    // 1. Verificar se FCM token existe
    final messaging = FirebaseMessaging.instance;
    final token = await messaging.getToken();

    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        print('⚠️ [FCM_HEALTH] Token FCM não disponível!');
      }

      // Tentar obter novo token
      await messaging.deleteToken();
      final newToken = await messaging.getToken();

      if (newToken != null) {
        if (kDebugMode) {
          print(
            '✅ [FCM_HEALTH] Novo token obtido: ${newToken.substring(0, 20)}...',
          );
        }
      } else {
        if (kDebugMode) {
          print('❌ [FCM_HEALTH] Falha ao obter novo token');
        }
      }
    } else {
      if (kDebugMode) {
        print('✅ [FCM_HEALTH] Token FCM válido: ${token.substring(0, 20)}...');
      }
    }

    // 2. Verificar permissões de notificação
    final settings = await messaging.getNotificationSettings();
    if (kDebugMode) {
      print(
        '📋 [FCM_HEALTH] Status de permissão: ${settings.authorizationStatus}',
      );
    }

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('⚠️ [FCM_HEALTH] Permissão de notificação não concedida');
        print('⚠️ [FCM_HEALTH] Notificações podem não funcionar corretamente');
      }
    } else {
      if (kDebugMode) {
        print('✅ [FCM_HEALTH] Permissão de notificação concedida');
      }
    }

    // 3. Verificar configurações de notificação (iOS)
    if (kDebugMode) {
      print('📋 [FCM_HEALTH] Alert: ${settings.alert}');
      print('📋 [FCM_HEALTH] Badge: ${settings.badge}');
      print('📋 [FCM_HEALTH] Sound: ${settings.sound}');
      print('📋 [FCM_HEALTH] Announcement: ${settings.announcement}');
      print('📋 [FCM_HEALTH] Car Play: ${settings.carPlay}');
      print('📋 [FCM_HEALTH] Critical Alert: ${settings.criticalAlert}');
    }

    // 4. Ping ao servidor para confirmar conectividade e saúde do backend
    await _pingServer();

    // 4. Log de sucesso
    if (kDebugMode) {
      print('✅ [FCM_HEALTH] Health check concluído com sucesso');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ [FCM_HEALTH] Erro no health check: $e');
    }
    // Não rethrow - health check não deve quebrar o WorkManager
    // Apenas loga o erro para monitoramento
  }
}

/// Ping ao servidor para verificar conectividade e saúde do backend
/// ✅ CRÍTICO: Verifica se backend está acessível e funcionando
Future<void> _pingServer() async {
  try {
    if (kDebugMode) {
      print('🏓 [FCM_HEALTH] Ping ao servidor...');
    }

    // Obter URL base do servidor
    // WorkManager roda em isolate separado, não pode acessar GetIt ou AppConfig
    String baseUrl;
    try {
      if (dotenv.env.isEmpty) {
        baseUrl = AppConfig.apiBaseUrl;
        if (kDebugMode) {
          print(
            '⚠️ [FCM_HEALTH] .env não carregado, usando baseUrl resolvida: $baseUrl',
          );
        }
      } else {
        baseUrl = AppConfig.apiBaseUrl;
      }
    } catch (e) {
      baseUrl = AppConfig.defaultApiBaseUrl;
      if (kDebugMode) {
        print(
          '⚠️ [FCM_HEALTH] Erro ao resolver baseUrl, usando fallback: $baseUrl',
        );
      }
    }

    // Construir URL do health check
    final healthUrl = Uri.parse('$baseUrl/health');

    // Fazer requisição HTTP simples (sem autenticação - endpoint público)
    final response = await http
        .get(healthUrl)
        .timeout(
          const Duration(seconds: 10), // Timeout de 10 segundos
          onTimeout: () {
            throw TimeoutException('Timeout ao pingar servidor');
          },
        );

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print(
          '✅ [FCM_HEALTH] Servidor respondendo corretamente (${response.statusCode})',
        );
        try {
          final body = response.body;
          if (body.isNotEmpty) {
            print(
              '📋 [FCM_HEALTH] Resposta: ${body.substring(0, body.length > 100 ? 100 : body.length)}...',
            );
          }
        } catch (e) {
          // Ignorar erro ao parsear resposta
        }
      }
    } else {
      if (kDebugMode) {
        print(
          '⚠️ [FCM_HEALTH] Servidor respondeu com status: ${response.statusCode}',
        );
      }
    }
  } on SocketException catch (e) {
    // Erro de conexão (sem internet, servidor offline, etc)
    if (kDebugMode) {
      print('⚠️ [FCM_HEALTH] Erro de conexão ao pingar servidor: ${e.message}');
      print(
        '⚠️ [FCM_HEALTH] Possíveis causas: sem internet, servidor offline, ou URL incorreta',
      );
    }
  } on TimeoutException catch (e) {
    // Timeout na requisição
    if (kDebugMode) {
      print('⚠️ [FCM_HEALTH] Timeout ao pingar servidor: ${e.message}');
      print('⚠️ [FCM_HEALTH] Servidor pode estar lento ou inacessível');
    }
  } on HttpException catch (e) {
    // Erro HTTP
    if (kDebugMode) {
      print('⚠️ [FCM_HEALTH] Erro HTTP ao pingar servidor: ${e.message}');
    }
  } catch (e) {
    // Outros erros
    if (kDebugMode) {
      print('⚠️ [FCM_HEALTH] Erro inesperado ao pingar servidor: $e');
    }
  }
}
