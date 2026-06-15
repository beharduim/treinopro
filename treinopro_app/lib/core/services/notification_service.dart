import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationVisibility;
import 'package:permission_handler/permission_handler.dart';
import 'package:treinopro_app/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fcm_token_service.dart';
import 'deep_link_service.dart';
import '../../features/notifications/data/models/notification_model.dart';
import '../../features/notifications/data/services/local_notifications_storage.dart';
import '../navigation/app_navigator.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/classes/presentation/pages/classes_page.dart';
import '../../features/balance/presentation/pages/personal_balance_page.dart';

// Função top-level para background handler (necessário para Firebase)
// ✅ CRÍTICO: Esta função DEVE ser top-level e ter @pragma('vm:entry-point')
// ✅ Este handler é chamado quando app está em BACKGROUND ou TERMINADO
// ✅ Backend envia apenas data, Flutter SEMPRE cria notificação local
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  print('📱 [BACKGROUND] ==========================================');
  print('📱 [BACKGROUND] Handler executado - app em BACKGROUND ou TERMINADO');
  print('📱 [BACKGROUND] Data recebida: ${message.data}');
  print(
    '📱 [BACKGROUND] Notification: ${message.notification?.title} - ${message.notification?.body}',
  );
  print('📱 [BACKGROUND] Message ID: ${message.messageId}');
  print('📱 [BACKGROUND] Sent Time: ${message.sentTime}');

  // ✅ Log específico para tipo de notificação
  final notificationType = message.data['type'] as String?;
  print('🔍 [BACKGROUND] Tipo de notificação: $notificationType');
  if (notificationType == 'new_message') {
    print('💬 [BACKGROUND] ===== NOTIFICAÇÃO DE MENSAGEM DETECTADA =====');
    print('💬 [BACKGROUND] classId: ${message.data['classId']}');
    print('💬 [BACKGROUND] senderId: ${message.data['senderId']}');
    print('💬 [BACKGROUND] senderName: ${message.data['senderName']}');
    print('💬 [BACKGROUND] messagePreview: ${message.data['messagePreview']}');
  }

  try {
    final pushEnabled = await NotificationService.arePushNotificationsEnabled();
    if (!pushEnabled) {
      print(
        '🚫 [BACKGROUND] Push ignorado porque o dispositivo está deslogado/com notificações desabilitadas',
      );
      return;
    }

    if (await NotificationService.shouldIgnoreIncomingMessageNotification(
      message.data,
    )) {
      return;
    }

    // ✅ CRÍTICO: Firebase DEVE ser inicializado no background isolate
    print('🔄 [BACKGROUND] Inicializando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ [BACKGROUND] Firebase inicializado');

    // ✅ CRÍTICO: Verificar permissão de notificação antes de criar canal
    if (Platform.isAndroid) {
      print('🔍 [BACKGROUND] Verificando permissão de notificação...');
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        print(
          '⚠️ [BACKGROUND] Permissão de notificação NÃO concedida - notificação pode não aparecer',
        );
        print('⚠️ [BACKGROUND] Status: $status');
      } else {
        print('✅ [BACKGROUND] Permissão de notificação concedida');
      }
    }

    // ✅ Inicializar notificações locais (cria canal se necessário)
    print('🔄 [BACKGROUND] Inicializando notificações locais...');
    await NotificationService.initializeLocalNotifications();
    print('✅ [BACKGROUND] Notificações locais inicializadas');

    // Converter push notification em notificação in-app e salvar localmente
    print('🔄 [BACKGROUND] Convertendo e salvando notificação in-app...');
    await NotificationService.convertAndSaveInAppNotification(message);
    print('✅ [BACKGROUND] Notificação in-app salva');

    // ✅ CRÍTICO: Para PROPOSTAS, abrir o app automaticamente (mesmo com tela desligada)
    // Isso garante que o personal veja a proposta imediatamente
    if (notificationType == 'new_proposal' && message.data.isNotEmpty) {
      final proposalId = message.data['proposalId']?.toString();

      print('🚀 [BACKGROUND] ===== PROPOSTA DETECTADA - ABRINDO APP =====');
      print('🚀 [BACKGROUND] proposalId: $proposalId');

      // ✅ CRÍTICO: Salvar proposalId via SharedPreferences (persiste entre isolates)
      // O DeepLinkService.setPendingProposalId NÃO funciona aqui pois estamos em
      // background isolate separado — variáveis estáticas não são compartilhadas
      if (proposalId != null && proposalId.isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_proposal_id', proposalId);
          await prefs.setInt(
            'pending_proposal_timestamp',
            DateTime.now().millisecondsSinceEpoch,
          );
          print(
            '💾 [BACKGROUND] proposalId salvo em SharedPreferences para processamento',
          );
        } catch (e) {
          print('⚠️ [BACKGROUND] Erro ao salvar proposalId: $e');
        }
      }

      if (Platform.isIOS) {
        // iOS: APNs já exibiu a notificação do sistema com som customizado.
        // Criar uma segunda notificação local causaria duplicata e inconsistência.
        print(
          '🍎 [BACKGROUND] iOS: notificação já exibida pelo APNs, pulando local notification',
        );
      } else {
        // Android: criar notificação fullscreen para acordar o dispositivo
        await NotificationService.showCustomProposalNotification(message.data);
        print('✅ [BACKGROUND] Notificação fullscreen criada');

        // ✅ CRÍTICO: Abrir o app automaticamente usando FlutterForegroundTask
        try {
          print('🚀 [BACKGROUND] Tentando abrir app automaticamente...');
          FlutterForegroundTask.launchApp('/');
          print('✅ [BACKGROUND] App lançado com sucesso!');
        } catch (e) {
          print('⚠️ [BACKGROUND] Erro ao lançar app: $e');
        }
      }

      print('🚀 [BACKGROUND] ===== FIM DO PROCESSAMENTO DE PROPOSTA =====');
      return; // Proposta já processada, sair do handler
    }

    if (notificationType == 'proposal_payment_confirmed' &&
        message.data.isNotEmpty) {
      print('💳 [BACKGROUND] Pagamento confirmado — persistindo para processamento');
      await NotificationService.persistPendingPaymentConfirmed(message.data);
      if (message.notification == null) {
        await NotificationService.showFlutterNotification(message);
      }
      return;
    }

    // ✅ Para outras notificações (não propostas)
    if (message.notification == null) {
      // Backend enviou apenas data - verificar se há dados válidos antes de criar notificação
      if (message.data.isEmpty) {
        print(
          '⚠️ [BACKGROUND] Notificação sem dados e sem notification field - ignorando',
        );
        print('⚠️ [BACKGROUND] Message ID: ${message.messageId}');
        return; // Não criar notificação vazia
      }

      // Verificar se há título ou body nos dados
      final hasTitle =
          message.data['title'] != null &&
          message.data['title'].toString().isNotEmpty;
      final hasBody =
          message.data['body'] != null &&
          message.data['body'].toString().isNotEmpty;

      if (!hasTitle && !hasBody) {
        print(
          '⚠️ [BACKGROUND] Notificação sem título e body válidos - ignorando',
        );
        print('⚠️ [BACKGROUND] Data: ${message.data}');
        return; // Não criar notificação vazia
      }

      // Backend enviou apenas data - criar notificação local customizada
      print(
        '🔄 [BACKGROUND] Backend enviou apenas data - criando notificação local...',
      );
      await NotificationService.showFlutterNotification(message);
      print('✅ [BACKGROUND] Notificação visual criada');
    } else {
      // Backend enviou notification + data - Android já mostrou automaticamente
      print(
        '📱 [BACKGROUND] Backend enviou notification payload - Android já exibiu automaticamente',
      );
      print('📱 [BACKGROUND] Título: ${message.notification?.title}');
      print('📱 [BACKGROUND] Body: ${message.notification?.body}');
    }

    print('✅ [BACKGROUND] Notificação local criada com sucesso');
    if (notificationType == 'new_message') {
      print(
        '💬 [BACKGROUND] ===== NOTIFICAÇÃO DE MENSAGEM PROCESSADA COM SUCESSO =====',
      );
    }
  } catch (e, stackTrace) {
    print('❌ [BACKGROUND] Erro ao processar notificação: $e');
    print('❌ [BACKGROUND] StackTrace: $stackTrace');
    if (notificationType == 'new_message') {
      print(
        '💬 [BACKGROUND] ===== ERRO AO PROCESSAR NOTIFICAÇÃO DE MENSAGEM =====',
      );
    }
  }
  print('📱 [BACKGROUND] ==========================================');
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const String _proposalChannelId = 'proposal_channel_v3';
  static const String _pushNotificationsEnabledKey =
      'push_notifications_enabled';
  static const List<String> _legacyProposalChannelIds = <String>[
    'proposal_channel',
    'proposal_channel_v1',
    'proposal_channel_v2',
  ];

  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  // Guard contra inicialização múltipla
  static bool _isNotificationInitialized = false;
  // Guard contra registro duplicado de listeners (separado da inicialização geral)
  static bool _listenersRegistered = false;
  static const String _pendingLiveActivitiesKey =
      'pending_live_activity_payloads_v1';
  static const String _pendingPaymentConfirmedKey =
      'pending_payment_confirmed_v1';
  static const String _pendingPaymentConfirmedTsKey =
      'pending_payment_confirmed_ts_v1';

  /// Callback registrado pelo RealtimeDataService após inicialização do aluno.
  static void Function(Map<String, dynamic> data)? paymentConfirmedHandler;

  // ✅ Flag para rastrear se app está em foreground
  static bool _isInForeground = true; // Assume foreground por padrão

  // ✅ StreamController para notificar quando uma notificação é adicionada
  static final StreamController<void> _notificationAddedController =
      StreamController<void>.broadcast();

  /// Stream que emite quando uma nova notificação é adicionada
  static Stream<void> get notificationAddedStream =>
      _notificationAddedController.stream;

  static Future<bool> arePushNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final pushEnabled = prefs.getBool(_pushNotificationsEnabledKey) ?? true;
    final accessToken = prefs.getString('access_token');

    return pushEnabled && accessToken != null && accessToken.isNotEmpty;
  }

  /// Evita tocar notificação de chat no aparelho de quem enviou a mensagem.
  static Future<bool> shouldIgnoreIncomingMessageNotification(
    Map<String, dynamic> data,
  ) async {
    if (data['type'] != 'new_message') return false;

    final senderId = data['senderId']?.toString();
    if (senderId == null || senderId.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('user_id');
    if (currentUserId == null || currentUserId.isEmpty) return false;

    if (senderId == currentUserId) {
      print(
        '🚫 [NOTIF] Ignorando push de mensagem enviada pelo próprio usuário ($currentUserId)',
      );
      return true;
    }

    return false;
  }

  static Future<bool> _shouldIgnoreIncomingMessageNotification(
    Map<String, dynamic> data,
  ) {
    return shouldIgnoreIncomingMessageNotification(data);
  }

  /// Cancela a notificação local de uma proposta específica.
  static Future<void> cancelProposalNotification(String proposalId) async {
    if (proposalId.isEmpty) return;

    try {
      await flutterLocalNotificationsPlugin.cancel(proposalId.hashCode);
      print('🔕 [NOTIF] Notificação de proposta cancelada: $proposalId');
    } catch (e) {
      print('⚠️ [NOTIF] Erro ao cancelar notificação de proposta: $e');
    }
  }

  static Future<void> setPushNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushNotificationsEnabledKey, enabled);

    if (!enabled) {
      await flutterLocalNotificationsPlugin.cancelAll();
      await LocalNotificationsStorage.clearAll();
      print(
        '🚫 [NOTIF] Push/local notifications desabilitados para este dispositivo',
      );
    } else {
      print('✅ [NOTIF] Push notifications reabilitados para este dispositivo');
    }
  }

  /// Atualiza o estado do app (foreground/background)
  static void updateAppLifecycleState(AppLifecycleState state) {
    _isInForeground = state == AppLifecycleState.resumed;
    print(
      '📱 [NOTIF] App lifecycle atualizado: ${_isInForeground ? "FOREGROUND" : "BACKGROUND"}',
    );
    if (Platform.isIOS && _isInForeground) {
      unawaited(processPendingLiveActivities());
    }
  }

  /// Atualiza o badge do ícone do app (iOS) conforme notificações não lidas.
  static Future<void> updateAppBadgeCount(int count) async {
    if (!Platform.isIOS) return;

    try {
      const badgeNotificationId = 999998;

      await flutterLocalNotificationsPlugin.show(
        badgeNotificationId,
        null,
        null,
        NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: false,
            presentSound: false,
            presentBadge: true,
            badgeNumber: count,
          ),
        ),
      );
      await flutterLocalNotificationsPlugin.cancel(badgeNotificationId);
    } catch (e) {
      print('⚠️ [NOTIF] Falha ao atualizar badge do app: $e');
    }
  }

  /// Configura listener para renovação de token FCM
  static Future<void> setupTokenRefreshListener() async {
    try {
      print('🔄 [NOTIF] Configurando listener de token refresh...');

      // O listener já é configurado no FcmTokenService.initialize()
      // Este método é apenas para garantir que está ativo
      await FcmTokenService().initialize();

      print('✅ [NOTIF] Token refresh listener configurado');
    } catch (e) {
      print('❌ [NOTIF] Erro ao configurar token refresh listener: $e');
    }
  }

  /// Verifica se app está em foreground
  static bool get isInForeground => _isInForeground;

  /// Processa tentativas pendentes de start de Live Activity salvas em background isolate.
  static Future<void> processPendingLiveActivities() async {
    if (!Platform.isIOS) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingLiveActivitiesKey);

      if (raw == null || raw.isEmpty) {
        print('ℹ️ [NOTIF] Sem Live Activities pendentes para processar');
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded.isEmpty) {
        await prefs.remove(_pendingLiveActivitiesKey);
        print('⚠️ [NOTIF] Fila de Live Activities inválida; limpando storage');
        return;
      }

      final pending = Map<String, dynamic>.from(decoded);
      print(
        '🔄 [NOTIF] Processando ${pending.length} Live Activities pendentes no startup',
      );

      for (final entry in pending.entries.toList()) {
        if (entry.value is! Map) {
          pending.remove(entry.key);
          continue;
        }

        final payload = Map<String, dynamic>.from(entry.value as Map);
        final savedAt = (payload['_savedAt'] as num?)?.toInt();
        final expiresIn =
            int.tryParse(payload['expiresIn']?.toString() ?? '120') ?? 120;

        if (savedAt != null) {
          final ageSeconds =
              (DateTime.now().millisecondsSinceEpoch - savedAt) ~/ 1000;
          if (ageSeconds > expiresIn + 120) {
            print(
              'ℹ️ [NOTIF] Live Activity pendente expirada, removendo: ${entry.key}',
            );
            pending.remove(entry.key);
            continue;
          }
        }

        final started = await _startLiveActivityForProposalData(
          payload,
          source: 'startup_pending_queue',
          persistOnFailure: true,
        );

        if (started) {
          pending.remove(entry.key);
        }
      }

      if (pending.isEmpty) {
        await prefs.remove(_pendingLiveActivitiesKey);
      } else {
        await prefs.setString(_pendingLiveActivitiesKey, jsonEncode(pending));
      }
    } catch (e) {
      print('⚠️ [NOTIF] Erro ao processar Live Activities pendentes: $e');
    }
  }

  /// Initialize Firebase Messaging and Local Notifications.
  static Future<void> initializeNotification() async {
    if (_isNotificationInitialized) {
      print('ℹ️ [NOTIF] Notificações já inicializadas, pulando...');
      return;
    }
    print('🔄 [NOTIF] ===== INICIALIZANDO NOTIFICAÇÕES =====');

    // ✅ CRÍTICO iOS: Configurar apresentação de notificação em foreground
    // Sem isso, iOS NÃO mostra banners/alertas quando app está em foreground
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    print(
      '✅ [NOTIF] iOS foreground notification presentation options configuradas',
    );

    // ✅ REMOVIDO: Todas as solicitações de permissão agora são feitas pelo AppPermissionsService
    // após o modal explicativo, na ordem correta: Modal → Notificação → Localização → Background Location → Bateria
    // Não fazer NENHUMA verificação ou solicitação aqui para evitar que apareça antes do modal
    print(
      'ℹ️ [NOTIF] Todas as permissões serão solicitadas após modal explicativo no AppPermissionsService',
    );

    // ✅ ADIADO: Inicialização do FCM Token Service agora é feita pelo AppPermissionsService
    // após as permissões serem concedidas. Isso evita que getToken() solicite permissão automaticamente.
    // O FcmTokenService será inicializado após o modal de permissões.
    print(
      'ℹ️ [NOTIF] FCM Token Service será inicializado após permissões serem concedidas',
    );

    //Called when message is received while app is in foreground.
    // ✅ Quando app está em foreground, mostrar notificação visual usando flutter_local_notifications
    // E também converter em notificação in-app e salvar localmente
    // Guard: registrar listeners apenas uma vez, mesmo que initializeNotification seja chamado novamente após falha
    if (_listenersRegistered) {
      print('ℹ️ [NOTIF] Listeners já registrados, pulando registro...');
    } else {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final pushEnabled = await arePushNotificationsEnabled();
        if (!pushEnabled) {
          print('⚠️ [NOTIF] Push desabilitado - ignorando onMessage');
          return;
        }

        if (await shouldIgnoreIncomingMessageNotification(message.data)) {
          return;
        }

        print('📱 [NOTIF] Mensagem recebida (onMessage): ${message.data}');
        print('📱 [NOTIF] App em foreground: $_isInForeground');
        print(
          '📱 [NOTIF] Notification field: ${message.notification?.title} - ${message.notification?.body}',
        );

        final data = message.data;

        // Se for notificação de proposta, WebSocket já vai abrir o modal
        if (data.isNotEmpty && data['type'] == 'new_proposal') {
          print(
            '📱 [NOTIF] Notificação de proposta - WebSocket vai abrir modal',
          );
          await _startLiveActivityForProposalData(
            data,
            source: 'onMessage_foreground',
          );
          return;
        }

        if (data.isNotEmpty && data['type'] == 'proposal_payment_confirmed') {
          print('💳 [NOTIF] Pagamento confirmado via FCM (foreground)');
          await _dispatchPaymentConfirmed(data);
          await convertAndSaveInAppNotification(message);
          if (Platform.isIOS && message.notification != null) {
            return;
          }
          if (message.notification == null) {
            await showFlutterNotification(message);
          }
          return;
        }

        // Converter push notification em notificação in-app e salvar localmente
        await convertAndSaveInAppNotification(message);
        print('📱 [NOTIF] Notificação in-app salva localmente');

        // ✅ CRÍTICO: Verificar se backend enviou notification field
        // Se sim, Android já mostrou a notificação automaticamente (mesmo em foreground)
        // Só criar notificação local se backend enviou APENAS data (sem notification)
        if (Platform.isIOS && message.notification != null) {
          print(
            '🍎 [NOTIF] iOS foreground: APNs já apresentou a notificação, pulando local notification',
          );
        } else if (message.notification == null) {
          // Backend enviou apenas data - criar notificação local customizada
          print(
            '📱 [NOTIF] Backend enviou apenas data - criando notificação local...',
          );
          await showFlutterNotification(message);
          print('📱 [NOTIF] Notificação visual exibida');
        } else {
          // Backend enviou notification + data - Android já mostrou automaticamente
          // Mas em foreground, ainda queremos mostrar notificação local para melhor UX
          print(
            '📱 [NOTIF] Backend enviou notification payload - criando versão customizada...',
          );
          await showFlutterNotification(message);
          print('📱 [NOTIF] Notificação visual customizada exibida');
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((
        RemoteMessage message,
      ) async {
        final pushEnabled = await arePushNotificationsEnabled();
        if (!pushEnabled) {
          print('⚠️ [NOTIF] Push desabilitado - ignorando onMessageOpenedApp');
          return;
        }

        print('📱 [NOTIF] App aberto via notificação');
        print('📱 [NOTIF] Data completa: ${message.data}');
        print(
          '📱 [NOTIF] Notification: ${message.notification?.title} - ${message.notification?.body}',
        );

        // Processar deep link se for notificação de proposta
        final data = message.data;
        print('📱 [NOTIF] Verificando tipo de notificação: ${data['type']}');

        if (data.isNotEmpty && data['type'] == 'new_proposal') {
          final proposalId = data['proposalId'];
          print('📱 [NOTIF] proposalId encontrado: $proposalId');

          if (proposalId != null && proposalId.toString().isNotEmpty) {
            await _startLiveActivityForProposalData(
              data,
              source: 'onMessageOpenedApp',
            );

            print(
              '🔗 [NOTIF] Processando deep link para proposta: $proposalId',
            );

            // Aguardar um pouco para garantir que app está pronto
            await Future.delayed(const Duration(milliseconds: 1000));

            final deepLinkService = DeepLinkService();
            await deepLinkService.handleDeepLink(proposalId.toString());
            return;
          } else {
            print('⚠️ [NOTIF] proposalId vazio ou inválido');
          }
        } else {
          // ✅ Para outras notificações, processar navegação
          final notificationType = data['type'] as String?;
          if (notificationType != null) {
            await Future.delayed(const Duration(milliseconds: 500));
            await _handleNotificationNavigation(notificationType, data);
          }
        }

        // Converter push notification em notificação in-app e salvar localmente
        await convertAndSaveInAppNotification(message);
      });
      // Marcar apenas após ambos os listeners terem sido registrados com sucesso
      _listenersRegistered = true;
    } // fim do guard _listenersRegistered

    //Get and print FCM token (for sending target messages).
    await _getFcmToken();

    //Initialize local notifications plugin.
    await initializeLocalNotifications();

    // Check if app was launched by a local notification/full-screen intent.
    await _getInitialLocalNotificationLaunch();

    //Check if app was launched by a tapping on a notification.
    await _getInitialNotification();

    // Marcar como inicializado somente após todas as etapas completarem
    _isNotificationInitialized = true;
    print('✅ [NOTIF] ===== NOTIFICAÇÕES INICIALIZADAS COM SUCESSO =====');
  }

  static Future<void> _getInitialLocalNotificationLaunch() async {
    try {
      final launchDetails = await flutterLocalNotificationsPlugin
          .getNotificationAppLaunchDetails();

      if (launchDetails == null || !launchDetails.didNotificationLaunchApp) {
        print(
          'ℹ️ [NOTIF] App não foi lançado via notificação local/full-screen',
        );
        return;
      }

      final payload = launchDetails.notificationResponse?.payload;
      print(
        '📱 [NOTIF] App lançado via notificação local/full-screen. Payload: $payload',
      );

      if (payload == null || payload.isEmpty) {
        print('⚠️ [NOTIF] Notificação local abriu o app sem payload');
        return;
      }

      await _handleLocalNotificationPayload(
        payload,
        deferProposalNavigation: true,
      );
    } catch (e, stackTrace) {
      print('❌ [NOTIF] Erro ao obter launch details da notificação local: $e');
      print('❌ [NOTIF] StackTrace: $stackTrace');
    }
  }

  static Future<void> _handleLocalNotificationPayload(
    String payload, {
    required bool deferProposalNavigation,
  }) async {
    if (payload.isEmpty) {
      print('⚠️ [NOTIF] Payload local vazio, ignorando...');
      return;
    }

    if (payload.startsWith('proposal:')) {
      final proposalId = payload.replaceFirst('proposal:', '');
      if (proposalId.isEmpty) {
        print('⚠️ [NOTIF] Payload de proposta sem proposalId');
        return;
      }

      if (deferProposalNavigation) {
        print(
          '💾 [NOTIF] Salvando proposta pendente via payload local: $proposalId',
        );
        DeepLinkService.setPendingProposalId(proposalId);
      } else {
        print(
          '🔗 [NOTIF] Processando deep link de notificação local: $proposalId',
        );
        await DeepLinkService().handleDeepLink(proposalId);
      }
      return;
    }

    try {
      final payloadData = jsonDecode(payload) as Map<String, dynamic>;
      final notificationType = payloadData['type'] as String?;
      print('📱 [NOTIF] Payload local JSON recebido: $payloadData');

      if ((notificationType == 'proposal' ||
              notificationType == 'new_proposal') &&
          payloadData['proposalId'] != null) {
        final proposalId = payloadData['proposalId'].toString();
        if (proposalId.isEmpty) {
          print('⚠️ [NOTIF] Payload local de proposta sem proposalId válido');
          return;
        }

        if (deferProposalNavigation) {
          print(
            '💾 [NOTIF] Salvando proposta pendente via payload local JSON: $proposalId',
          );
          DeepLinkService.setPendingProposalId(proposalId);
        } else {
          await DeepLinkService().handleDeepLink(proposalId);
        }
        return;
      }

      if (deferProposalNavigation) {
        print(
          'ℹ️ [NOTIF] Payload local de tipo $notificationType será tratado após bootstrap normal',
        );
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));
      await _handleNotificationNavigation(notificationType, payloadData);
    } catch (e) {
      print('❌ [NOTIF] Erro ao processar payload local: $e');
      print('📱 [NOTIF] Payload recebido: $payload');
    }
  }

  /// Fetches and prints FCM token (optional).
  static Future<void> _getFcmToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null && token.isNotEmpty) {
        print('✅ [NOTIF] FCM Token obtido: ${token.substring(0, 20)}...');
        print('✅ [NOTIF] Token completo: $token');
      } else {
        print('⚠️ [NOTIF] FCM Token não disponível');
      }
    } catch (e) {
      print('❌ [NOTIF] Erro ao obter FCM Token: $e');
    }
  }

  //Show a local notification when a message is received
  // ✅ ESTRATÉGIA HÍBRIDA: Backend envia notification + data
  // - notification: Android mostra imediatamente (fallback se handler falhar)
  // - data: Flutter processa e customiza quando handler executar
  // - Para propostas: sempre usar versão customizada quando possível
  static Future<void> showFlutterNotification(RemoteMessage message) async {
    final data = message.data;
    final notificationType = data['type'] as String?;

    if (await _shouldIgnoreIncomingMessageNotification(data)) {
      return;
    }

    print('📱 [NOTIF] ===== CRIANDO NOTIFICAÇÃO LOCAL =====');
    print('📱 [NOTIF] Tipo: $notificationType');
    print('📱 [NOTIF] Data completa: $data');
    print(
      '📱 [NOTIF] Notification field: ${message.notification?.title} - ${message.notification?.body}',
    );

    // ✅ Log específico para mensagens
    if (notificationType == 'new_message') {
      print('💬 [NOTIF] ===== PROCESSANDO NOTIFICAÇÃO DE MENSAGEM =====');
      print('💬 [NOTIF] classId: ${data['classId']}');
      print('💬 [NOTIF] senderId: ${data['senderId']}');
      print('💬 [NOTIF] senderName: ${data['senderName']}');
      print('💬 [NOTIF] messagePreview: ${data['messagePreview']}');
    }

    // ✅ Se for notificação de proposta, SEMPRE usar estilo customizado
    // Isso substitui a notificação padrão do Android com versão customizada
    if (data.isNotEmpty && data['type'] == 'new_proposal') {
      print('📱 [NOTIF] É notificação de proposta - usando estilo customizado');
      await showCustomProposalNotification(data);
      return;
    }

    // Para outras notificações, usar formato padrão
    // ✅ Priorizar dados do 'data' sobre 'notification' (mais confiável para customização)
    // Mas usar 'notification' como fallback se 'data' não tiver título/body
    String title = data['title'] ?? message.notification?.title ?? '';
    String body = data['body'] ?? message.notification?.body ?? '';

    // ✅ CRÍTICO: Ignorar notificações sem título ou body válidos
    // Evita criar notificações vazias ("No Title", "No Body")
    if (title.isEmpty && body.isEmpty) {
      print('⚠️ [NOTIF] Notificação sem título e body - ignorando');
      print('⚠️ [NOTIF] Data: $data');
      print(
        '⚠️ [NOTIF] Notification field: ${message.notification?.title} - ${message.notification?.body}',
      );
      return; // Não criar notificação vazia
    }

    // Se tiver apenas um dos campos, usar valores padrão mínimos
    if (title.isEmpty) {
      title = 'Notificação';
      print('⚠️ [NOTIF] Título vazio, usando padrão: $title');
    }
    if (body.isEmpty) {
      body = 'Nova notificação';
      print('⚠️ [NOTIF] Body vazio, usando padrão: $body');
    }

    print('📱 [NOTIF] Título extraído: $title');
    print('📱 [NOTIF] Body extraído: $body');

    if (notificationType == 'new_message') {
      print('💬 [NOTIF] Título final: $title');
      print('💬 [NOTIF] Body final: $body');
    }

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      priority: Priority.high,
      importance: Importance.high,
      icon: '@mipmap/launcher_icon',
    );

    // Determinar threadIdentifier para agrupamento iOS
    String? threadId;
    if (notificationType == 'new_message' && data['classId'] != null) {
      threadId = 'chat_${data['classId']}';
    } else if (data['proposalId'] != null) {
      threadId = 'proposta_${data['proposalId']}';
    } else if (data['classId'] != null) {
      threadId = 'aula_${data['classId']}';
    } else if (notificationType != null) {
      threadId = 'type_$notificationType';
    }

    DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: notificationType == 'new_message' ? 'alert_proposal.caf' : null,
      threadIdentifier: threadId,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // ✅ Usar ID único baseado em dados para evitar duplicação
    final notificationId =
        data['proposalId']?.hashCode ??
        data['notificationId']?.hashCode ??
        DateTime.now().millisecondsSinceEpoch % 2147483647;

    // ✅ Criar payload JSON com tipo e dados para navegação
    String? payload;

    if (notificationType != null) {
      // Criar payload JSON com tipo e dados necessários para navegação
      final payloadData = <String, dynamic>{'type': notificationType};

      // Adicionar dados específicos baseado no tipo
      switch (notificationType) {
        case 'new_message':
          if (data['classId'] != null) payloadData['classId'] = data['classId'];
          if (data['senderId'] != null)
            payloadData['senderId'] = data['senderId'];
          if (data['senderName'] != null)
            payloadData['senderName'] = data['senderName'];
          if (data['location'] != null)
            payloadData['location'] = data['location'];
          if (data['date'] != null) payloadData['date'] = data['date'];
          if (data['time'] != null) payloadData['time'] = data['time'];
          if (data['duration'] != null)
            payloadData['duration'] = data['duration'];
          break;
        case 'class_reminder':
          if (data['classId'] != null) payloadData['classId'] = data['classId'];
          break;
        case 'class_cancelled':
          if (data['classId'] != null) payloadData['classId'] = data['classId'];
          if (data['actorName'] != null)
            payloadData['actorName'] = data['actorName'];
          break;
        case 'payment_received':
          if (data['classId'] != null) payloadData['classId'] = data['classId'];
          break;
        case 'proposal_payment_confirmed':
          if (data['proposalId'] != null) {
            payloadData['proposalId'] = data['proposalId'];
          }
          if (data['locationName'] != null) {
            payloadData['locationName'] = data['locationName'];
          }
          if (data['trainingDate'] != null) {
            payloadData['trainingDate'] = data['trainingDate'];
          }
          if (data['trainingTime'] != null) {
            payloadData['trainingTime'] = data['trainingTime'];
          }
          break;
        case 'proposal':
        case 'new_proposal':
          if (data['proposalId'] != null) {
            payloadData['proposalId'] = data['proposalId'];
          }
          break;
      }

      // Converter para JSON string
      try {
        payload = jsonEncode(payloadData);
        print('📱 [NOTIF] Payload criado: $payload');
      } catch (e) {
        print('❌ [NOTIF] Erro ao criar payload JSON: $e');
      }
    } else if (data['proposalId'] != null) {
      // Fallback para propostas antigas
      payload = 'proposal:${data['proposalId']}';
    }

    // ✅ Verificar se permissão está concedida antes de mostrar notificação
    if (Platform.isAndroid) {
      print('🔍 [NOTIF] Verificando permissão de notificação...');
      final permissionStatus = await Permission.notification.status;
      if (!permissionStatus.isGranted) {
        print(
          '❌ [NOTIF] Permissão de notificação NÃO concedida - notificação não será exibida',
        );
        print('❌ [NOTIF] Status da permissão: $permissionStatus');
        if (notificationType == 'new_message') {
          print(
            '💬 [NOTIF] ===== NOTIFICAÇÃO DE MENSAGEM BLOQUEADA POR PERMISSÃO =====',
          );
        }
        return; // Não tentar mostrar se não tiver permissão
      } else {
        print('✅ [NOTIF] Permissão de notificação concedida');
      }
    }

    // ✅ O canal já deve ter sido criado em initializeLocalNotifications
    // Se estivermos no background handler, o canal foi criado lá
    print('✅ [NOTIF] Usando canal: high_importance_channel');

    print('🔄 [NOTIF] Chamando flutterLocalNotificationsPlugin.show...');
    print('🔄 [NOTIF] ID: $notificationId');
    print('🔄 [NOTIF] Título: $title');
    print('🔄 [NOTIF] Body: $body');
    print('🔄 [NOTIF] Payload: $payload');

    try {
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      print('✅ [NOTIF] Notificação local criada (ID: $notificationId)');
      print('✅ [NOTIF] Título: $title');
      print('✅ [NOTIF] Body: $body');
      print('✅ [NOTIF] Canal: high_importance_channel');
      if (notificationType == 'new_message') {
        print(
          '💬 [NOTIF] ===== NOTIFICAÇÃO DE MENSAGEM EXIBIDA COM SUCESSO =====',
        );
      }
    } catch (e, stackTrace) {
      print('❌ [NOTIF] Erro ao exibir notificação: $e');
      print('❌ [NOTIF] StackTrace: $stackTrace');
      if (notificationType == 'new_message') {
        print('💬 [NOTIF] ===== ERRO AO EXIBIR NOTIFICAÇÃO DE MENSAGEM =====');
      }
    }
    print('📱 [NOTIF] ===== FIM DA CRIAÇÃO DE NOTIFICAÇÃO =====');
  }

  /// Mostra notificação customizada e estilizada para propostas
  /// Método público para permitir chamada do background handler
  static Future<void> showCustomProposalNotification(
    Map<String, dynamic> data,
  ) async {
    final proposalId = data['proposalId']?.toString() ?? '';
    final studentName =
        data['studentName']?.toString() ?? 'Aluno não informado';
    final location = data['location']?.toString() ?? 'Local não informado';
    final time = data['time']?.toString() ?? 'Horário não informado';
    final price = data['price']?.toString() ?? '0.00';
    final expiresIn =
        int.tryParse(data['expiresIn']?.toString() ?? '120') ?? 120;

    // Formatar preço
    final priceFormatted = double.tryParse(price) ?? 0.0;
    final priceString =
        'R\$ ${priceFormatted.toStringAsFixed(2).replaceAll('.', ',')}';

    // Calcular tempo restante
    final expiresInMinutes = expiresIn ~/ 60;
    final expiresInSeconds = expiresIn % 60;
    final expiresText = expiresInMinutes > 0
        ? '${expiresInMinutes}min'
        : '${expiresInSeconds}s';

    // Título e body formatados com layout visual melhorado
    const title = '🎯 Nova Proposta de Treino!';

    // ✅ Body formatado com quebras de linha e emojis para melhor visualização
    final bodyFormatted =
        '''
👤 $studentName
📍 $location
🕐 $time
💰 $priceString
⏰ Expira em $expiresText''';

    // Body compacto para preview (primeira linha)
    final bodyPreview = '👤 $studentName • 📍 $location • 💰 $priceString';

    // ✅ Android: Notificação estilizada com BigTextStyle e ações
    final androidDetails = AndroidNotificationDetails(
      _proposalChannelId, // Canal específico para propostas
      'Propostas de Treino',
      channelDescription:
          'Notificações de novas propostas de treino disponíveis',
      importance: Importance
          .max, // ✅ CRÍTICO: Prioridade máxima para garantir entrega imediata
      priority: Priority.max, // ✅ CRÍTICO: Prioridade máxima
      icon: '@mipmap/launcher_icon',
      color: const Color(0xFFFF6A00), // Laranja do TreinoPro
      enableVibration: true,
      vibrationPattern: Int64List.fromList([
        0,
        250,
        250,
        250,
      ]), // Padrão de vibração
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(
        'alert_proposal',
      ), // Som personalizado
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      styleInformation: BigTextStyleInformation(
        bodyFormatted, // ✅ Body completo com quebras de linha
        contentTitle: title,
        summaryText: 'Toque para ver detalhes',
        htmlFormatBigText:
            false, // ✅ Usar false para quebras de linha simples funcionarem melhor
      ),
      fullScreenIntent:
          true, // ✅ Full-screen intent para aparecer mesmo com tela bloqueada
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      ongoing: false, // Não é notificação contínua
      autoCancel: true, // Pode ser cancelada pelo usuário
    );

    // ✅ iOS: Som customizado em .caf (único formato suportado para notificações iOS).
    // O arquivo alert_proposal.caf deve estar na raiz do bundle (ios/Runner/).
    // iOS ignora silenciosamente qualquer formato diferente e usa 'default'.
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alert_proposal.caf',
      interruptionLevel: InterruptionLevel.timeSensitive,
      threadIdentifier: proposalId.isNotEmpty
          ? 'proposta_$proposalId'
          : 'propostas',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // ✅ Criar canal Android específico para propostas (se não existir)
    // ✅ CRÍTICO: Canal DEVE ter som configurado e prioridade máxima para funcionar
    const proposalChannel = AndroidNotificationChannel(
      _proposalChannelId,
      'Propostas de Treino',
      description: 'Notificações de novas propostas de treino disponíveis',
      importance: Importance
          .max, // ✅ CRÍTICO: Prioridade máxima para garantir entrega imediata
      enableVibration: true,
      playSound: true, // ✅ Habilitar som no canal
      sound: const RawResourceAndroidNotificationSound(
        'alert_proposal',
      ), // ✅ Som personalizado
      showBadge: true,
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
    );

    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(proposalChannel);
      print(
        '✅ [NOTIF] Canal de propostas criado: proposal_channel_v3 (prioridade máxima + som customizado)',
      );
    } else {
      print('⚠️ [NOTIF] AndroidFlutterLocalNotificationsPlugin não disponível');
    }

    // Mostrar notificação com ID único baseado no proposalId
    final notificationId = proposalId.hashCode;
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      bodyPreview, // ✅ Usar preview compacto (expandido mostra bodyFormatted completo)
      notificationDetails,
      payload: 'proposal:$proposalId', // Payload para identificar quando tocar
    );

    print('✅ [NOTIF] Notificação customizada de proposta exibida: $proposalId');
    print('📱 [NOTIF] Body formatado: $bodyFormatted');

    // ✅ iOS: Iniciar Live Activity se disponível
    if (Platform.isIOS) {
      await _startLiveActivityForProposalData(
        data,
        source: 'showCustomProposalNotification',
      );
    }
  }

  static Future<bool> _startLiveActivityForProposalData(
    Map<String, dynamic> data, {
    required String source,
    bool persistOnFailure = true,
  }) async {
    if (!Platform.isIOS) return false;

    final proposalId = data['proposalId']?.toString() ?? '';
    print(
      'ℹ️ [NOTIF] Live Activity desativada no iOS; ignorando ($source): $proposalId | persistOnFailure=$persistOnFailure',
    );
    return false;
  }

  static Map<String, dynamic> _normalizeLiveActivityPayload(
    Map<String, dynamic> data,
  ) {
    final proposalId = data['proposalId']?.toString() ?? '';
    final studentName =
        data['studentName']?.toString() ?? 'Aluno não informado';
    final location = data['location']?.toString() ?? 'Local não informado';
    final modality = data['modality']?.toString() ?? '';
    final trainingTime =
        data['trainingTime']?.toString() ??
        data['time']?.toString() ??
        'Horário não informado';

    final rawPrice = data['price']?.toString() ?? '0.00';
    final numericPrice = rawPrice
        .replaceAll(RegExp(r'[^0-9,.-]'), '')
        .replaceAll(',', '.');
    final parsedPrice = double.tryParse(numericPrice) ?? 0.0;
    final formattedPrice =
        'R\$ ${parsedPrice.toStringAsFixed(2).replaceAll('.', ',')}';

    final expiresIn =
        int.tryParse(data['expiresIn']?.toString() ?? '120') ?? 120;

    return <String, dynamic>{
      'proposalId': proposalId,
      'studentName': studentName,
      'location': location,
      'modality': modality,
      'trainingTime': trainingTime,
      'price': formattedPrice,
      'expiresIn': expiresIn,
      '_savedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Future<void> _persistPendingLiveActivityPayload(
    Map<String, dynamic> normalizedPayload,
  ) async {
    try {
      final proposalId = normalizedPayload['proposalId'] as String? ?? '';
      if (proposalId.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingLiveActivitiesKey);
      final pending = raw == null || raw.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);

      pending[proposalId] = normalizedPayload;
      await prefs.setString(_pendingLiveActivitiesKey, jsonEncode(pending));
      print('💾 [NOTIF] Live Activity pendente salva: $proposalId');
    } catch (e) {
      print('⚠️ [NOTIF] Falha ao salvar Live Activity pendente: $e');
    }
  }

  static Future<void> _removePendingLiveActivityPayload(
    String proposalId,
  ) async {
    if (proposalId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingLiveActivitiesKey);
      if (raw == null || raw.isEmpty) return;

      final pending = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (!pending.containsKey(proposalId)) return;

      pending.remove(proposalId);
      if (pending.isEmpty) {
        await prefs.remove(_pendingLiveActivitiesKey);
      } else {
        await prefs.setString(_pendingLiveActivitiesKey, jsonEncode(pending));
      }
    } catch (e) {
      print('⚠️ [NOTIF] Falha ao remover Live Activity pendente: $e');
    }
  }

  //Inititialize the local notifications system for both Android and iOS.
  static Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    // ✅ CRÍTICO: Criar canal de notificação para Android antes de inicializar
    // O canal DEVE ser criado com todas as configurações necessárias
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'This channel is used for important notifications.',
      importance: Importance
          .high, // ✅ CRÍTICO: Alta importância para aparecer em background
      playSound: true, // ✅ Habilitar som
      enableVibration: true, // ✅ Habilitar vibração
      showBadge: true, // ✅ Mostrar badge
    );

    // ✅ Criar os canais no Android (garantir que sejam criados)
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      for (final legacyChannelId in _legacyProposalChannelIds) {
        try {
          await androidImplementation.deleteNotificationChannel(
            legacyChannelId,
          );
          print(
            '🧹 [NOTIF] Canal legado removido para recriar som corretamente: $legacyChannelId',
          );
        } catch (e) {
          print(
            'ℹ️ [NOTIF] Canal legado não pôde ser removido (seguindo normalmente): $legacyChannelId - $e',
          );
        }
      }

      // Canal padrão de alta importância
      await androidImplementation.createNotificationChannel(channel);
      print('✅ [NOTIF] Canal de notificação criado: high_importance_channel');

      // ✅ CRÍTICO: Criar canal de propostas na inicialização
      // Isso garante que o canal exista antes de qualquer notificação chegar
      const proposalChannel = AndroidNotificationChannel(
        _proposalChannelId,
        'Propostas de Treino',
        description: 'Notificações de novas propostas de treino disponíveis',
        importance:
            Importance.max, // Prioridade máxima para garantir entrega imediata
        enableVibration: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alert_proposal'),
        showBadge: true,
        audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      );
      await androidImplementation.createNotificationChannel(proposalChannel);
      print(
        '✅ [NOTIF] Canal de propostas criado: proposal_channel_v3 (prioridade máxima + som customizado)',
      );
    } else {
      print('⚠️ [NOTIF] AndroidFlutterLocalNotificationsPlugin não disponível');
    }

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('📱 [NOTIF] Notificação local tocada: ${response.payload}');

        if (response.payload == null || response.payload!.isEmpty) {
          print('⚠️ [NOTIF] Payload vazio, ignorando...');
          return;
        }

        await _handleLocalNotificationPayload(
          response.payload!,
          deferProposalNavigation: false,
        );
      },
    );
  }

  /// Converte uma push notification em notificação in-app e salva localmente
  static Future<void> convertAndSaveInAppNotification(
    RemoteMessage message,
  ) async {
    try {
      final pushEnabled = await arePushNotificationsEnabled();
      if (!pushEnabled) {
        print(
          '🚫 [CONVERT] Ignorando notificação porque o dispositivo está deslogado/com push desabilitado',
        );
        return;
      }

      final data = message.data;
      final notification = message.notification;
      final type = data['type'] as String?;

      print('🔄 [CONVERT] ===== CONVERTENDO NOTIFICAÇÃO IN-APP =====');
      print('🔄 [CONVERT] Tipo: $type');
      print('🔄 [CONVERT] Data: $data');

      // ✅ Log específico para mensagens
      if (type == 'new_message') {
        print('💬 [CONVERT] ===== CONVERTENDO NOTIFICAÇÃO DE MENSAGEM =====');
        print('💬 [CONVERT] classId: ${data['classId']}');
        print('💬 [CONVERT] senderId: ${data['senderId']}');
        print('💬 [CONVERT] senderName: ${data['senderName']}');
        print('💬 [CONVERT] messagePreview: ${data['messagePreview']}');
      }

      // Ignorar notificações de proposta (já são tratadas pelo WebSocket)
      if (data['type'] == 'new_proposal') {
        print(
          '⚠️ [CONVERT] Ignorando notificação de proposta (tratada pelo WebSocket)',
        );
        return;
      }

      // Extrair informações da notificação
      final notificationType = type ?? 'info';
      final title =
          notification?.title ?? data['title'] as String? ?? 'Notificação';
      final body = notification?.body ?? data['body'] as String? ?? '';

      print('🔄 [CONVERT] Título: $title');
      print('🔄 [CONVERT] Body: $body');

      // Determinar tipo de notificação baseado no type
      String inAppNotificationType = 'info';

      switch (notificationType) {
        case 'new_message':
          inAppNotificationType = 'info';
          print('💬 [CONVERT] Tipo de notificação in-app: info');
          break;
        case 'class_reminder':
          inAppNotificationType = 'info';
          break;
        case 'class_cancelled':
          inAppNotificationType = 'warning';
          break;
        case 'payment_received':
          inAppNotificationType = 'success';
          break;
        case 'proposal_payment_confirmed':
          inAppNotificationType = 'success';
          break;
        case 'dispute_created':
        case 'dispute_update':
          inAppNotificationType = 'warning';
          break;
        case 'withdrawal_failed':
          inAppNotificationType = 'warning';
          break;
        case 'mission_completed':
          inAppNotificationType = 'success';
          break;
        default:
          inAppNotificationType = 'info';
      }

      // Criar NotificationModel
      print('🔄 [CONVERT] Criando NotificationModel...');
      final notificationModel = NotificationModel(
        id:
            data['notificationId']?.toString() ??
            message.messageId ??
            'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: body,
        type: inAppNotificationType,
        isRead: false,
        createdAt: message.sentTime ?? DateTime.now(),
        data: data,
      );

      print('🔄 [CONVERT] NotificationModel criado:');
      print('🔄 [CONVERT] - ID: ${notificationModel.id}');
      print('🔄 [CONVERT] - Título: ${notificationModel.title}');
      print('🔄 [CONVERT] - Mensagem: ${notificationModel.message}');
      print('🔄 [CONVERT] - Tipo: ${notificationModel.type}');

      // Salvar no armazenamento local
      print('🔄 [CONVERT] Salvando no armazenamento local...');
      await LocalNotificationsStorage.addNotification(notificationModel);
      print('✅ [NOTIF] Notificação in-app salva localmente: $title');

      if (type == 'new_message') {
        print(
          '💬 [CONVERT] ===== NOTIFICAÇÃO DE MENSAGEM SALVA COM SUCESSO =====',
        );
      }

      // ✅ Notificar que uma nova notificação foi adicionada (para atualizar contador)
      _notificationAddedController.add(null);
      print('📢 [NOTIF] Evento de notificação adicionada emitido');

      print('✅ [CONVERT] ===== CONVERSÃO CONCLUÍDA =====');
    } catch (e, stackTrace) {
      print('❌ [NOTIF] Erro ao converter e salvar notificação in-app: $e');
      print('❌ [NOTIF] StackTrace: $stackTrace');
      if (message.data['type'] == 'new_message') {
        print(
          '💬 [CONVERT] ===== ERRO AO CONVERTER NOTIFICAÇÃO DE MENSAGEM =====',
        );
      }
    }
  }

  static Future<void> saveInAppNotificationFromData({
    required String id,
    required String title,
    required String message,
    String type = 'info',
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) async {
    try {
      final pushEnabled = await arePushNotificationsEnabled();
      if (!pushEnabled) {
        print(
          '🚫 [NOTIF] Ignorando salvamento local porque o dispositivo está deslogado/com push desabilitado',
        );
        return;
      }

      final notificationModel = NotificationModel(
        id: id,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: createdAt ?? DateTime.now(),
        data: data,
      );

      await LocalNotificationsStorage.addNotification(notificationModel);
      _notificationAddedController.add(null);
      print('✅ [NOTIF] Informe salvo localmente: $title | $message');
    } catch (e, stackTrace) {
      print('❌ [NOTIF] Erro ao salvar informe local: $e');
      print('❌ [NOTIF] StackTrace: $stackTrace');
    }
  }

  /// Dispose do StreamController (chamar quando app for encerrado)
  static void dispose() {
    _notificationAddedController.close();
  }

  //Handle notification tap when app is terminated
  // ✅ CRÍTICO: Este método é chamado quando o app é lançado de estado TERMINADO
  // ao tocar em uma notificação FCM
  static Future<void> _getInitialNotification() async {
    try {
      final pushEnabled = await arePushNotificationsEnabled();
      if (!pushEnabled) {
        print('🚫 [NOTIF] Push desabilitado - ignorando initial notification');
        return;
      }

      print('🔄 [NOTIF] Verificando se app foi lançado via notificação...');

      RemoteMessage? message = await FirebaseMessaging.instance
          .getInitialMessage();

      if (message == null) {
        print('ℹ️ [NOTIF] App não foi lançado via notificação');
        // ✅ Fallback crítico: cold start pode vir do background handler (launchApp)
        // sem getInitialMessage, então restauramos o pending salvo em SharedPreferences.
        await DeepLinkService.hydratePendingDeepLinkFromStorage();
        if (DeepLinkService.hasPendingDeepLink) {
          print(
            '✅ [NOTIF] Deep link pendente restaurado do SharedPreferences: ${DeepLinkService.pendingProposalId}',
          );
        }
        return;
      }

      print('📱 [NOTIF] ==========================================');
      print('📱 [NOTIF] App lançado de estado TERMINADO via notificação!');
      print('📱 [NOTIF] Data: ${message.data}');
      print(
        '📱 [NOTIF] Notification: ${message.notification?.title} - ${message.notification?.body}',
      );
      print('📱 [NOTIF] Message ID: ${message.messageId}');
      print('📱 [NOTIF] ==========================================');

      // Processar deep link se for notificação de proposta
      final data = message.data;
      final notificationType = data['type'] as String?;

      print('🔍 [NOTIF] Tipo de notificação: $notificationType');

      if (data.isNotEmpty && notificationType == 'new_proposal') {
        final proposalId = data['proposalId']?.toString();
        if (proposalId != null && proposalId.isNotEmpty) {
          await _startLiveActivityForProposalData(
            data,
            source: 'getInitialMessage',
          );

          print('🔗 [NOTIF] ===== PROPOSTA DETECTADA =====');
          print(
            '🔗 [NOTIF] Salvando deep link pendente para proposta: $proposalId',
          );
          // ✅ Salvar para processar depois que app inicializar e PersonalHomePage estiver pronta
          DeepLinkService.setPendingProposalId(proposalId);
          print('✅ [NOTIF] proposalId salvo para processamento posterior');

          // ✅ Também converter em notificação in-app
          await convertAndSaveInAppNotification(message);
          return;
        } else {
          print('⚠️ [NOTIF] proposalId vazio ou inválido');
        }
      }

      // ✅ Para outras notificações (não proposta), processar navegação
      if (notificationType != null && notificationType.isNotEmpty) {
        print('🔗 [NOTIF] Processando navegação para tipo: $notificationType');
        // Aguardar app estar completamente pronto
        await Future.delayed(const Duration(milliseconds: 2000));
        await _handleNotificationNavigation(notificationType, data);
      }

      // Converter push notification em notificação in-app e salvar localmente
      await convertAndSaveInAppNotification(message);
    } catch (e, stackTrace) {
      print('❌ [NOTIF] Erro em _getInitialNotification: $e');
      print('❌ [NOTIF] StackTrace: $stackTrace');
    }
  }

  static Future<void> persistPendingPaymentConfirmed(
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingPaymentConfirmedKey, jsonEncode(data));
      await prefs.setInt(
        _pendingPaymentConfirmedTsKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('⚠️ [NOTIF] Erro ao persistir confirmação de pagamento: $e');
    }
  }

  static Future<void> _dispatchPaymentConfirmed(
    Map<String, dynamic> data,
  ) async {
    if (paymentConfirmedHandler != null) {
      paymentConfirmedHandler!(data);
      return;
    }

    print(
      '💾 [NOTIF] RealtimeDataService indisponível — persistindo confirmação de pagamento',
    );
    await persistPendingPaymentConfirmed(data);
  }

  /// Processa navegação baseada no tipo de notificação
  static Future<void> _handleNotificationNavigation(
    String? notificationType,
    Map<String, dynamic> payloadData,
  ) async {
    final context = AppNavigator.navigatorKey.currentContext;
    if (context == null) {
      print('⚠️ [NOTIF] Contexto não disponível, aguardando...');
      // Aguardar até contexto estar disponível
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        final ctx = AppNavigator.navigatorKey.currentContext;
        if (ctx != null) {
          print('✅ [NOTIF] Contexto disponível após ${i * 100}ms');
          await _navigateFromNotification(notificationType, payloadData, ctx);
          return;
        }
      }
      print('❌ [NOTIF] Timeout aguardando contexto');
      return;
    }

    await _navigateFromNotification(notificationType, payloadData, context);
  }

  /// Navega para a tela apropriada baseado no tipo de notificação
  static Future<void> _navigateFromNotification(
    String? notificationType,
    Map<String, dynamic> payloadData,
    BuildContext context,
  ) async {
    switch (notificationType) {
      case 'new_message':
        await _navigateToChat(payloadData, context);
        break;

      case 'class_reminder':
      case 'class_cancelled':
        await _navigateToClasses(payloadData, context);
        break;

      case 'payment_received':
        // Apenas marcar como lida (sem navegação específica)
        print('💰 [NOTIF] Notificação de pagamento recebido');
        break;

      case 'proposal_payment_confirmed':
        await _dispatchPaymentConfirmed(payloadData);
        break;

      case 'proposal':
      case 'new_proposal':
        final proposalId = payloadData['proposalId'] as String?;
        if (proposalId != null && proposalId.isNotEmpty) {
          print('🔗 [NOTIF] Processando deep link para proposta: $proposalId');
          final deepLinkService = DeepLinkService();
          await deepLinkService.handleDeepLink(proposalId);
        }
        break;

      case 'withdrawal_failed':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PersonalBalancePage(),
          ),
        );
        break;

      default:
        print(
          'ℹ️ [NOTIF] Tipo de notificação não reconhecido: $notificationType',
        );
    }
  }

  /// Navega para a página de chat
  static Future<void> _navigateToChat(
    Map<String, dynamic> payloadData,
    BuildContext context,
  ) async {
    final classId = payloadData['classId'] as String?;
    final senderId = payloadData['senderId'] as String?;
    final senderName = payloadData['senderName'] as String? ?? 'Contato';
    final location = payloadData['location'] as String? ?? 'Local a definir';
    final date = payloadData['date'] as String? ?? '';
    final time = payloadData['time'] as String? ?? '';
    final duration = payloadData['duration'] as String? ?? '60min';

    if (classId == null || senderId == null) {
      print('❌ [NOTIF] Dados insuficientes para navegar para chat');
      print('📱 [NOTIF] classId: $classId, senderId: $senderId');
      return;
    }

    // Detectar se o usuário atual é aluno ou personal
    bool currentUserIsStudent = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('user_type');
      currentUserIsStudent = userType == 'student';
    } catch (e) {
      print('⚠️ [NOTIF] Erro ao detectar tipo de usuário: $e');
    }

    print(
      '💬 [NOTIF] Navegando para ChatPage (isStudent: $currentUserIsStudent)...',
    );

    // Usar navigatorKey para evitar uso de BuildContext stale após awaits
    final navigator = AppNavigator.navigatorKey.currentState;
    if (navigator == null) {
      print('❌ [NOTIF] Navigator não disponível para navegação ao chat');
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          classId: classId,
          receiverId: senderId,
          receiverName: senderName,
          location: location,
          date: date,
          time: time,
          duration: duration,
          currentUserIsStudent: currentUserIsStudent,
        ),
      ),
    );
  }

  /// Navega para a página de aulas
  static Future<void> _navigateToClasses(
    Map<String, dynamic> payloadData,
    BuildContext context,
  ) async {
    print('📚 [NOTIF] Navegando para ClassesPage...');

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ClassesPage()));
  }
}
