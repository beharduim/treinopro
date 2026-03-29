import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../constants/app_colors.dart';
import 'notification_foreground_service.dart';
import 'fcm_token_service.dart';

/// Serviço centralizado para gerenciar todas as permissões do app
/// Solicita automaticamente na primeira inicialização:
/// 1. Localização básica
/// 2. Localização em background (com divulgação proeminente)
/// 3. Não otimizar bateria
class AppPermissionsService {
  static const String _keyPermissionsRequested = 'app_permissions_requested';
  
  /// Verifica se as permissões já foram solicitadas anteriormente
  static Future<bool> hasPermissionsBeenRequested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyPermissionsRequested) ?? false;
    } catch (e) {
      print('⚠️ [PERMISSIONS] Erro ao verificar se permissões foram solicitadas: $e');
      return false;
    }
  }
  
  /// Marca as permissões como solicitadas
  static Future<void> markPermissionsAsRequested() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPermissionsRequested, true);
      print('✅ [PERMISSIONS] Permissões marcadas como solicitadas');
    } catch (e) {
      print('⚠️ [PERMISSIONS] Erro ao marcar permissões: $e');
    }
  }
  
  /// Solicita todas as permissões necessárias na primeira vez que o app abre
  /// Conforme exigido pelo Google Play Console (Prominent Disclosure)
  /// [isRequired] - Se true, as permissões são obrigatórias (usuário não pode cancelar)
  static Future<void> requestAllPermissions(BuildContext context, {bool isRequired = false}) async {
    // #region agent log
    try {
      final logData = {
        'sessionId': 'debug-session',
        'runId': 'run1',
        'hypothesisId': 'A',
        'location': 'app_permissions_service.dart:39',
        'message': 'requestAllPermissions called',
        'data': {'platform': Platform.isAndroid ? 'android' : 'ios'},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await File('/Users/marcosinocencio/Works/TreinoPro/.cursor/debug.log')
          .writeAsString('${jsonEncode(logData)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion
    
    // iOS: Tratar permissões específicas
    if (Platform.isIOS) {
      await _requestIOSPermissions(context);
      return;
    }
    
    try {
      // #region agent log
      try {
        final logData = {
          'sessionId': 'debug-session',
          'runId': 'run1',
          'hypothesisId': 'B',
          'location': 'app_permissions_service.dart:47',
          'message': 'Checking if permissions already requested',
          'data': {},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        await File('/Users/marcosinocencio/Works/TreinoPro/.cursor/debug.log')
            .writeAsString('${jsonEncode(logData)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      
      // Verificar se já foi solicitado antes
      final alreadyRequested = await hasPermissionsBeenRequested();
      
      // #region agent log
      try {
        final logData = {
          'sessionId': 'debug-session',
          'runId': 'run1',
          'hypothesisId': 'B',
          'location': 'app_permissions_service.dart:52',
          'message': 'alreadyRequested result',
          'data': {'alreadyRequested': alreadyRequested},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        await File('/Users/marcosinocencio/Works/TreinoPro/.cursor/debug.log')
            .writeAsString('${jsonEncode(logData)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      
      if (alreadyRequested) {
        print('✅ [PERMISSIONS] Permissões já foram solicitadas anteriormente');
        // Ainda assim, verificar e solicitar se necessário (mas sem diálogo)
        await _requestPermissionsSilently();
        return;
      }
      
      // Primeira vez: mostrar divulgação proeminente e solicitar todas as permissões
      print('📱 [PERMISSIONS] Primeira vez - solicitando todas as permissões...');
      
      // #region agent log
      try {
        final logData = {
          'sessionId': 'debug-session',
          'runId': 'run1',
          'hypothesisId': 'C',
          'location': 'app_permissions_service.dart:59',
          'message': 'About to show disclosure dialog',
          'data': {'contextMounted': context.mounted},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        await File('/Users/marcosinocencio/Works/TreinoPro/.cursor/debug.log')
            .writeAsString('${jsonEncode(logData)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      
      // 1. Mostrar divulgação proeminente para localização em background
      final shouldContinue = await _showBackgroundLocationDisclosure(context, isRequired: isRequired);
      
      // #region agent log
      try {
        final logData = {
          'sessionId': 'debug-session',
          'runId': 'run1',
          'hypothesisId': 'C',
          'location': 'app_permissions_service.dart:65',
          'message': 'Disclosure dialog returned',
          'data': {'shouldContinue': shouldContinue, 'isRequired': isRequired},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        await File('/Users/marcosinocencio/Works/TreinoPro/.cursor/debug.log')
            .writeAsString('${jsonEncode(logData)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      
      if (!shouldContinue) {
        if (isRequired) {
          // Se for obrigatório, mostrar novamente até o usuário aceitar
          print('⚠️ [PERMISSIONS] Permissões são obrigatórias - tentando novamente...');
          // Tentar novamente após um delay
          await Future.delayed(const Duration(milliseconds: 500));
          if (context.mounted) {
            return await requestAllPermissions(context, isRequired: isRequired);
          }
        } else {
          print('⚠️ [PERMISSIONS] Usuário cancelou a divulgação');
          return;
        }
      }
      
      // 2. Solicitar permissão de NOTIFICAÇÃO primeiro (depois do modal)
      print('📱 [PERMISSIONS] Solicitando permissão de notificação...');
      final notificationStatus = await Permission.notification.request();
      
      if (!notificationStatus.isGranted) {
        print('⚠️ [PERMISSIONS] Permissão de notificação negada');
        if (isRequired) {
          // Se for obrigatório, tentar novamente
          print('⚠️ [PERMISSIONS] Permissão de notificação é obrigatória - tentando novamente...');
          await Future.delayed(const Duration(milliseconds: 500));
          if (context.mounted) {
            return await requestAllPermissions(context, isRequired: isRequired);
          }
        }
      } else {
        print('✅ [PERMISSIONS] Permissão de notificação concedida');
      }
      
      // 2.1. Solicitar permissão do Firebase Messaging (iOS)
      // No Android, a permissão já foi solicitada acima com Permission.notification
      // No iOS, o Firebase precisa solicitar permissão separadamente
      if (Platform.isIOS) {
        print('📱 [PERMISSIONS] Solicitando permissão do Firebase Messaging (iOS)...');
        try {
          final firebaseMessaging = FirebaseMessaging.instance;
          final permission = await firebaseMessaging.requestPermission();
          print('📱 [PERMISSIONS] Permissão Firebase: ${permission.authorizationStatus}');
        } catch (e) {
          print('⚠️ [PERMISSIONS] Erro ao solicitar permissão Firebase: $e');
        }
      } else {
        // No Android, após conceder Permission.notification, também solicitar do Firebase
        // para garantir que está tudo configurado
        print('📱 [PERMISSIONS] Verificando permissão do Firebase Messaging (Android)...');
        try {
          final firebaseMessaging = FirebaseMessaging.instance;
          // No Android, apenas verificar - a permissão já foi concedida acima
          final settings = await firebaseMessaging.getNotificationSettings();
          print('📱 [PERMISSIONS] Status Firebase: ${settings.authorizationStatus}');
        } catch (e) {
          print('⚠️ [PERMISSIONS] Erro ao verificar permissão Firebase: $e');
        }
      }
      
      // 3. Solicitar permissão de localização básica
      print('📱 [PERMISSIONS] Solicitando permissão de localização básica...');
      final locationStatus = await Permission.location.request();
      
      if (!locationStatus.isGranted) {
        print('⚠️ [PERMISSIONS] Permissão de localização básica negada');
        if (isRequired) {
          // Se for obrigatório, tentar novamente
          print('⚠️ [PERMISSIONS] Permissão de localização é obrigatória - tentando novamente...');
          await Future.delayed(const Duration(milliseconds: 500));
          if (context.mounted) {
            return await requestAllPermissions(context, isRequired: isRequired);
          }
        } else {
          await markPermissionsAsRequested();
          return;
        }
      }
      
      print('✅ [PERMISSIONS] Permissão de localização básica concedida');
      
      // 4. Background location não é solicitada automaticamente
      // O app funciona perfeitamente com apenas "Durante o uso do app"
      // Solicitar background location abriria as configurações automaticamente no Android 11+,
      // o que é confuso para o usuário que já escolheu "Durante o uso do app"
      // Se necessário, o usuário pode habilitar "Permitir sempre" manualmente nas configurações
      print('ℹ️ [PERMISSIONS] Background location não solicitada automaticamente - app funciona com "Durante o uso do app"');
      
      // 4. Solicitar permissão de não otimizar bateria
      print('📱 [PERMISSIONS] Solicitando permissão de não otimizar bateria...');
      final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
      
      if (!batteryStatus.isGranted) {
        print('⚠️ [PERMISSIONS] Permissão de não otimizar bateria negada');
        if (batteryStatus.isPermanentlyDenied) {
          print('⚠️ [PERMISSIONS] Permissão de bateria permanentemente negada - usuário precisa habilitar manualmente');
        }
      } else {
        print('✅ [PERMISSIONS] Permissão de não otimizar bateria concedida');
      }
      
      // Marcar como solicitado
      await markPermissionsAsRequested();
      
      // ✅ CRÍTICO: Inicializar FCM Token Service APÓS permissões serem concedidas
      // O getToken() pode solicitar permissão automaticamente, então só inicializar depois
      try {
        await FcmTokenService().initialize();
        print('✅ [PERMISSIONS] FCM Token Service inicializado após permissões concedidas');
      } catch (e) {
        print('⚠️ [PERMISSIONS] Erro ao inicializar FCM Token Service após permissões: $e');
      }
      
      // ✅ CRÍTICO: Iniciar foreground service APÓS permissões serem concedidas
      // O foreground service precisa de permissões de localização para funcionar
      try {
        await NotificationForegroundService.startService();
        print('✅ [PERMISSIONS] Foreground service iniciado após permissões concedidas');
      } catch (e) {
        print('⚠️ [PERMISSIONS] Erro ao iniciar foreground service após permissões: $e');
      }
      
      // #region agent log
      try {
        final logData = {
          'sessionId': 'debug-session',
          'runId': 'run1',
          'hypothesisId': 'D',
          'location': 'app_permissions_service.dart:104',
          'message': 'All permissions requested successfully',
          'data': {},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        await File('/Users/marcosinocencio/Works/TreinoPro/.cursor/debug.log')
            .writeAsString('${jsonEncode(logData)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      
    } catch (e, stackTrace) {
      // #region agent log
      try {
        final logData = {
          'sessionId': 'debug-session',
          'runId': 'run1',
          'hypothesisId': 'E',
          'location': 'app_permissions_service.dart:115',
          'message': 'Exception in requestAllPermissions',
          'data': {
            'error': e.toString(),
            'stackTrace': stackTrace.toString().substring(0, stackTrace.toString().length > 500 ? 500 : stackTrace.toString().length),
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        await File('/Users/marcosinocencio/Works/TreinoPro/.cursor/debug.log')
            .writeAsString('${jsonEncode(logData)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      
      print('❌ [PERMISSIONS] Erro ao solicitar permissões: $e');
      print('📍 [PERMISSIONS] Stack trace: $stackTrace');
    }
  }
  
  /// Solicita permissões específicas do iOS
  /// No iOS, precisamos solicitar permissão de notificação via FirebaseMessaging
  static Future<void> _requestIOSPermissions(BuildContext context) async {
    try {
      print('📱 [PERMISSIONS] iOS - Iniciando solicitação de permissões...');

      // Verificar se já foi solicitado antes
      final alreadyRequested = await hasPermissionsBeenRequested();

      if (alreadyRequested) {
        print('✅ [PERMISSIONS] iOS - Permissões já foram solicitadas anteriormente');

        // Verificar estado real da permissão de notificação no sistema
        // O usuário pode ter desabilitado nas Configurações após a primeira solicitação
        final firebaseMessaging = FirebaseMessaging.instance;
        final currentSettings = await firebaseMessaging.getNotificationSettings();
        print('📱 [PERMISSIONS] iOS - Estado atual da permissão: ${currentSettings.authorizationStatus}');

        if (currentSettings.authorizationStatus == AuthorizationStatus.denied) {
          print('⚠️ [PERMISSIONS] iOS - Permissão de notificação NEGADA no sistema');
          print('ℹ️ [PERMISSIONS] iOS - Usuário precisa habilitar em Ajustes > Notificações > TreinoPro');
        } else if (currentSettings.authorizationStatus == AuthorizationStatus.notDetermined) {
          // Estado mudou (ex: reinstalação) - solicitar novamente
          print('🔄 [PERMISSIONS] iOS - Permissão não determinada - solicitando novamente...');
          await firebaseMessaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
        }

        // Garantir que o FcmTokenService está inicializado
        await _initializeFcmTokenServiceForIOS();
        return;
      }

      // Primeira vez: mostrar divulgação e solicitar permissões
      print('📱 [PERMISSIONS] iOS - Primeira vez - solicitando permissões...');

      // Mostrar modal explicativo (opcional, mas melhora UX)
      if (context.mounted) {
        final shouldContinue = await _showIOSPermissionsDisclosure(context);
        if (!shouldContinue) {
          print('⚠️ [PERMISSIONS] iOS - Usuário cancelou permissões');
          return;
        }
      }

      // Solicitar permissão de notificação via FirebaseMessaging
      // CRÍTICO: Isso é obrigatório no iOS para receber push notifications
      print('📱 [PERMISSIONS] iOS - Solicitando permissão de notificação...');

      final firebaseMessaging = FirebaseMessaging.instance;
      final settings = await firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('📱 [PERMISSIONS] iOS - Status da permissão: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ [PERMISSIONS] iOS - Permissão de notificação CONCEDIDA');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ [PERMISSIONS] iOS - Permissão de notificação PROVISIONAL');
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('❌ [PERMISSIONS] iOS - Permissão de notificação NEGADA');
        print('ℹ️ [PERMISSIONS] iOS - Usuário precisa habilitar nas Configurações > Notificações');
      } else {
        print('❓ [PERMISSIONS] iOS - Permissão de notificação: ${settings.authorizationStatus}');
      }

      // Solicitar permissão de localização (se necessário)
      print('📱 [PERMISSIONS] iOS - Solicitando permissão de localização...');
      final locationStatus = await Permission.location.request();

      if (locationStatus.isGranted) {
        print('✅ [PERMISSIONS] iOS - Permissão de localização concedida');
      } else {
        print('⚠️ [PERMISSIONS] iOS - Permissão de localização: $locationStatus');
      }

      // Marcar como solicitado
      await markPermissionsAsRequested();

      // CRÍTICO: Inicializar FCM Token Service APÓS permissões serem concedidas
      await _initializeFcmTokenServiceForIOS();

      print('✅ [PERMISSIONS] iOS - Todas as permissões processadas');

    } catch (e, stackTrace) {
      print('❌ [PERMISSIONS] iOS - Erro ao solicitar permissões: $e');
      print('📍 [PERMISSIONS] iOS - Stack trace: $stackTrace');
    }
  }

  /// Inicializa o FcmTokenService para iOS
  static Future<void> _initializeFcmTokenServiceForIOS() async {
    try {
      print('📱 [PERMISSIONS] iOS - Inicializando FcmTokenService...');
      await FcmTokenService().initialize();
      print('✅ [PERMISSIONS] iOS - FcmTokenService inicializado com sucesso');
    } catch (e) {
      print('⚠️ [PERMISSIONS] iOS - Erro ao inicializar FcmTokenService: $e');
    }
  }

  /// Mostra modal explicativo de permissões para iOS
  static Future<bool> _showIOSPermissionsDisclosure(BuildContext context) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      if (!context.mounted) {
        return true; // Se contexto não está montado, continuar sem modal
      }

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: AppColors.primaryOrange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Permissões Necessárias',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'O TreinoPro precisa das seguintes permissões para funcionar corretamente:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                _buildPermissionItem(
                  icon: Icons.notifications_active,
                  title: 'Notificações',
                  description: 'Para receber alertas de propostas, mensagens e atualizações importantes',
                ),
                const SizedBox(height: 16),

                _buildPermissionItem(
                  icon: Icons.location_on,
                  title: 'Localização',
                  description: 'Para encontrar academias e locais de treino próximos a você',
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Suas informações são usadas apenas para melhorar sua experiência no app.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      return result ?? true;
    } catch (e) {
      print('⚠️ [PERMISSIONS] iOS - Erro ao mostrar modal: $e');
      return true; // Em caso de erro, continuar com as permissões
    }
  }

  /// Solicita permissões silenciosamente (sem diálogo) se já foram solicitadas antes
  static Future<void> _requestPermissionsSilently() async {
    try {
      // Verificar e solicitar localização básica se necessário
      final locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted && !locationStatus.isPermanentlyDenied) {
        await Permission.location.request();
      }
      
      // Verificar e solicitar localização em background se necessário
      final backgroundLocationStatus = await Permission.locationAlways.status;
      if (!backgroundLocationStatus.isGranted && !backgroundLocationStatus.isPermanentlyDenied) {
        await Permission.locationAlways.request();
      }
      
      // Verificar e solicitar não otimizar bateria se necessário
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted && !batteryStatus.isPermanentlyDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      print('❌ [PERMISSIONS] Erro ao solicitar permissões silenciosamente: $e');
    }
  }
  
  /// Mostra diálogo de divulgação proeminente para localização em background
  /// Conforme exigido pelo Google Play Console
  /// [isRequired] - Se true, remove o botão cancelar (permissões obrigatórias)
  static Future<bool> _showBackgroundLocationDisclosure(BuildContext context, {bool isRequired = false}) async {
    // #region agent log
    try {
      final logData = {
        'sessionId': 'debug-session',
        'runId': 'run1',
        'hypothesisId': 'C',
        'location': 'app_permissions_service.dart:133',
        'message': 'showDialog called',
        'data': {'contextMounted': context.mounted},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await File('/Users/marcosinocencio/Works/TreinoPro/.cursor/debug.log')
          .writeAsString('${jsonEncode(logData)}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion
    
    try {
      // Aguardar um pouco para garantir que o Navigator está pronto
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Verificar se o contexto ainda está montado antes de mostrar o diálogo
      if (!context.mounted) {
        print('⚠️ [PERMISSIONS] Context não está mais montado, não é possível mostrar diálogo');
        return false;
      }
      
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // Não permite fechar clicando fora
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
          children: [
            Icon(
              Icons.location_on,
              color: AppColors.primaryOrange,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Permissões Necessárias',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          ),
          content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'O TreinoPro precisa das seguintes permissões para funcionar corretamente:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              
              _buildPermissionItem(
                icon: Icons.notifications_active,
                title: 'Notificações',
                description: 'Para receber alertas de propostas, mensagens e atualizações importantes',
              ),
              const SizedBox(height: 16),
              
              _buildPermissionItem(
                icon: Icons.location_on,
                title: 'Localização',
                description: 'Para encontrar academias e locais de treino próximos a você',
              ),
              const SizedBox(height: 16),
              
              _buildPermissionItem(
                icon: Icons.location_searching,
                title: 'Localização em Segundo Plano',
                description: 'Para personal trainers: receber notificações de propostas de treino mesmo com o app fechado',
              ),
              const SizedBox(height: 16),
              
              _buildPermissionItem(
                icon: Icons.battery_charging_full,
                title: 'Não Otimizar Bateria',
                description: 'Para garantir que você receba notificações importantes mesmo em modo de economia de bateria',
              ),
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryOrange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Suas informações de localização são usadas apenas para melhorar sua experiência no app e nunca são compartilhadas com outros usuários.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
          actions: [
          // Só mostrar botão cancelar se as permissões NÃO forem obrigatórias
          if (!isRequired)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(isRequired ? 'Continuar' : 'Permitir'),
          ),
        ],
        ),
      );
      
      // #region agent log
      try {
        final logData = {
          'sessionId': 'debug-session',
          'runId': 'run1',
          'hypothesisId': 'C',
          'location': 'app_permissions_service.dart:256',
          'message': 'showDialog completed',
          'data': {'result': result},
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        await File('/Users/marcosinocencio/Works/TreinoPro/.cursor/debug.log')
            .writeAsString('${jsonEncode(logData)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      
      return result ?? false;
    } catch (e, stackTrace) {
      // #region agent log
      try {
        final logData = {
          'sessionId': 'debug-session',
          'runId': 'run1',
          'hypothesisId': 'C',
          'location': 'app_permissions_service.dart:268',
          'message': 'Exception in showDialog',
          'data': {
            'error': e.toString(),
            'stackTrace': stackTrace.toString().substring(0, stackTrace.toString().length > 500 ? 500 : stackTrace.toString().length),
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        await File('/Users/marcosinocencio/Works/TreinoPro/.cursor/debug.log')
            .writeAsString('${jsonEncode(logData)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      
      print('❌ [PERMISSIONS] Erro ao mostrar diálogo: $e');
      print('📍 [PERMISSIONS] Stack trace: $stackTrace');
      return false;
    }
  }
  
  static Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryOrange,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}



