import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

/// Serviço de foreground para manter app pronto para receber notificações
/// Similar ao WhatsApp/Uber - previne Doze Mode e garante entrega de notificações
class NotificationForegroundService {
  static bool _isRunning = false;
  static bool _isInitialized = false;

  /// Verifica se o serviço está rodando
  static bool get isRunning => _isRunning;

  /// Inicializa o serviço de foreground
  static Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('🔔 [FG_SERVICE] Já inicializado');
      }
      return;
    }

    // Apenas para Android
    if (!Platform.isAndroid) {
      if (kDebugMode) {
        print(
          'ℹ️ [FG_SERVICE] Foreground service disponível apenas no Android',
        );
      }
      return;
    }

    try {
      // Inicializar plugin
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'notification_listener',
          channelName: 'Listener de Notificações',
          channelDescription:
              'Mantém o app pronto para receber notificações importantes',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          visibility: NotificationVisibility
              .VISIBILITY_SECRET, // Não mostra na lock screen
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false, // iOS não precisa de foreground service
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(60000),
          autoRunOnBoot: true,
          allowWakeLock: true,
          allowWifiLock: false,
        ),
      );

      _isInitialized = true;
      if (kDebugMode) {
        print('✅ [FG_SERVICE] Inicializado com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FG_SERVICE] Erro ao inicializar: $e');
      }
    }
  }

  /// Inicia o serviço de foreground
  /// Retorna true se iniciado com sucesso, false caso contrário
  /// NOTA: Timeout não é crítico - WorkManager fornece camada adicional de proteção
  static Future<bool> startService({int maxRetries = 2}) async {
    // Apenas para Android
    if (!Platform.isAndroid) {
      if (kDebugMode) {
        print('ℹ️ [FG_SERVICE] Serviço disponível apenas no Android');
      }
      return false;
    }

    // ✅ CRÍTICO: Verificar se as permissões de localização estão concedidas
    // O foreground service com tipo location requer permissões de localização
    try {
      final locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted) {
        if (kDebugMode) {
          print('⚠️ [FG_SERVICE] Permissão de localização não concedida - não é possível iniciar serviço com tipo location');
          print('⚠️ [FG_SERVICE] Serviço será iniciado após permissões serem concedidas');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [FG_SERVICE] Erro ao verificar permissão de localização: $e');
      }
      return false;
    }

    // Verificar se já está rodando
    if (_isRunning) {
      if (kDebugMode) {
        print('ℹ️ [FG_SERVICE] Serviço já está rodando');
      }
      return true;
    }

    // Garantir que está inicializado
    if (!_isInitialized) {
      await initialize();
    }

    // Tentar iniciar com retry em caso de timeout
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        // Verificar se já está rodando (double check)
        _isRunning = await FlutterForegroundTask.isRunningService;
        if (_isRunning) {
          if (kDebugMode) {
            print('ℹ️ [FG_SERVICE] Serviço já estava rodando');
          }
          return true;
        }

        // Iniciar serviço
        if (kDebugMode) {
          if (attempt > 0) {
            print('🔄 [FG_SERVICE] Tentativa ${attempt + 1}/${maxRetries + 1} de iniciar serviço...');
          } else {
            print('🔄 [FG_SERVICE] Tentando iniciar serviço...');
          }
        }
        
        // ✅ Aumentar timeout para 20 segundos (alguns dispositivos precisam de mais tempo)
        // O Android pode demorar para iniciar o serviço, especialmente em dispositivos mais antigos
        final ServiceRequestResult result =
            await FlutterForegroundTask.startService(
              notificationTitle: 'TreinoPro',
              notificationText: 'Pronto para receber notificações',
              callback: startCallback,
            ).timeout(
              const Duration(seconds: 20), // ✅ Aumentado de 10s para 20s
              onTimeout: () {
                throw TimeoutException(
                  'Foreground service start timeout após 20 segundos',
                  const Duration(seconds: 20),
                );
              },
            );

        _isRunning = result is ServiceRequestSuccess;

        if (_isRunning) {
          if (kDebugMode) {
            print('✅ [FG_SERVICE] Serviço iniciado com sucesso');
          }
          return true;
        } else {
          if (kDebugMode) {
            print('❌ [FG_SERVICE] Falha ao iniciar serviço');
            if (result is ServiceRequestFailure) {
              print('❌ [FG_SERVICE] Erro: ${result.error}');
              print('❌ [FG_SERVICE] Tipo do erro: ${result.error.runtimeType}');
              // Tentar extrair mensagem se for uma Exception ou String
              if (result.error is Exception) {
                print('❌ [FG_SERVICE] Exception: ${result.error.toString()}');
              } else if (result.error is String) {
                print('❌ [FG_SERVICE] Mensagem de erro: ${result.error}');
              }
              
              // Se for timeout e ainda temos tentativas, aguardar antes de retry
              final errorStr = result.error.toString();
              if (errorStr.contains('timeout') || errorStr.contains('Timeout')) {
                if (attempt < maxRetries) {
                  final delaySeconds = (attempt + 1) * 2; // 2s, 4s, 6s...
                  if (kDebugMode) {
                    print('⏳ [FG_SERVICE] Aguardando ${delaySeconds}s antes de retry...');
                  }
                  await Future.delayed(Duration(seconds: delaySeconds));
                  continue; // Tentar novamente
                }
              }
            } else {
              print('❌ [FG_SERVICE] Tipo de resultado: ${result.runtimeType}');
              print('❌ [FG_SERVICE] Resultado completo: $result');
            }
          }
        }

        // Se chegou aqui e não iniciou, e não é timeout, não tentar novamente
        break;
      } catch (e) {
        if (kDebugMode) {
          print('❌ [FG_SERVICE] Erro ao iniciar serviço (tentativa ${attempt + 1}): $e');
        }
        
        // Se for timeout e ainda temos tentativas, aguardar antes de retry
        if (e is TimeoutException && attempt < maxRetries) {
          final delaySeconds = (attempt + 1) * 2; // 2s, 4s, 6s...
          if (kDebugMode) {
            print('⏳ [FG_SERVICE] Timeout detectado - aguardando ${delaySeconds}s antes de retry...');
          }
          await Future.delayed(Duration(seconds: delaySeconds));
          continue; // Tentar novamente
        }
        
        // Se não for timeout ou não há mais tentativas, retornar false
        if (kDebugMode && attempt == maxRetries) {
          print('⚠️ [FG_SERVICE] Todas as tentativas falharam - WorkManager continuará ativo como fallback');
        }
        return false;
      }
    }

    return _isRunning;
  }

  /// Para o serviço de foreground
  static Future<bool> stopService() async {
    if (!Platform.isAndroid) {
      return false;
    }

    if (!_isRunning) {
      if (kDebugMode) {
        print('ℹ️ [FG_SERVICE] Serviço já está parado');
      }
      return true;
    }

    try {
      final ServiceRequestResult result =
          await FlutterForegroundTask.stopService();
      final success = result is ServiceRequestSuccess;
      _isRunning = !success;

      if (success) {
        if (kDebugMode) {
          print('✅ [FG_SERVICE] Serviço parado com sucesso');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FG_SERVICE] Erro ao parar serviço: $e');
      }
      return false;
    }
  }

  /// Atualiza o texto da notificação de foreground
  static Future<void> updateNotification({String? title, String? text}) async {
    if (!Platform.isAndroid || !_isRunning) {
      return;
    }

    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: title ?? 'TreinoPro',
        notificationText: text ?? 'Pronto para receber notificações',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FG_SERVICE] Erro ao atualizar notificação: $e');
      }
    }
  }

  /// Verifica e inicia serviço se necessário (chamado no boot ou periodicamente)
  static Future<void> ensureServiceRunning() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (!isRunning) {
        if (kDebugMode) {
          print('⚠️ [FG_SERVICE] Serviço não está rodando, reiniciando...');
        }
        await startService();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FG_SERVICE] Erro ao verificar/iniciar serviço: $e');
      }
    }
  }
}

/// Callback executado quando o serviço de foreground é iniciado
/// DEVE ser uma função top-level (não pode ser método de classe)
/// ✅ CRÍTICO: Este callback roda em isolate separado - manter mínimo e rápido
@pragma('vm:entry-point')
void startCallback() {
  // ✅ Configurar task handler de forma síncrona e rápida
  // Não fazer operações pesadas aqui para evitar timeout
  FlutterForegroundTask.setTaskHandler(NotificationTaskHandler());
}

/// Handler para tarefas do foreground service
class NotificationTaskHandler extends TaskHandler {
  // Contador para logging periódico (não logar a cada minuto)
  int _tickCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    if (kDebugMode) {
      print('🚀 [FG_SERVICE] Task handler iniciado em $timestamp');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _tickCount++;

    // Log apenas a cada 15 minutos (15 ticks de 1 minuto)
    if (_tickCount % 15 == 0) {
      if (kDebugMode) {
        print(
          '⏰ [FG_SERVICE] Foreground service ativo - ${_tickCount}min de uptime',
        );
      }
    }

    // Verificar saúde do FCM periodicamente (a cada 30 minutos)
    if (_tickCount % 30 == 0) {
      if (kDebugMode) {
        print('🔍 [FG_SERVICE] Verificando saúde do FCM...');
      }
      // Aqui poderíamos fazer verificações adicionais se necessário
      // Por exemplo: verificar se FirebaseMessaging ainda está ativo
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    if (kDebugMode) {
      print('🛑 [FG_SERVICE] Task handler destruído em $timestamp');
      print('📊 [FG_SERVICE] Uptime total: $_tickCount minutos');
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    // Sem botões configurados, mas método necessário
    if (kDebugMode) {
      print('🔘 [FG_SERVICE] Botão pressionado: $id');
    }
  }

  @override
  void onNotificationPressed() {
    // Quando usuário toca na notificação de foreground
    if (kDebugMode) {
      print('👆 [FG_SERVICE] Notificação de foreground tocada');
    }
    // Trazer app para foreground
    FlutterForegroundTask.launchApp('/');
  }
}
