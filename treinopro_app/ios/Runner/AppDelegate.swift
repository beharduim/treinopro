import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import ActivityKit

// Fallback local para o target Runner.
// Em CI, o target/widget ProposalLiveActivity pode não estar presente no Runner.xcodeproj,
// então este tipo garante compilação do AppDelegate.
@available(iOS 16.1, *)
private struct ProposalAttributes: ActivityAttributes {
  let proposalId: String

  struct ContentState: Codable, Hashable {
    let studentName: String
    let location: String
    let modality: String
    let price: String
    let trainingTime: String
    let expiresAt: Date
    let proposalStatus: String
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var liveActivityChannel: FlutterMethodChannel?
  private var deepLinkChannel: FlutterMethodChannel?
  private var pendingDeepLinkUrl: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configurar Firebase ANTES de qualquer outra coisa
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    // Configurar delegate de notificações ANTES de registrar plugins
    // Isso é CRÍTICO para receber notificações no iOS
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // Configurar delegate do Firebase Messaging
    Messaging.messaging().delegate = self

    // Registrar para notificações remotas
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)

    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    cleanupLiveActivitiesIfNeeded()

    // ✅ Configurar Method Channel para Live Activities.
    // Alguns ciclos de inicialização deixam window/rootViewController indisponíveis aqui,
    // então tentamos imediatamente e novamente no próximo runloop.
    setupLiveActivityChannelIfNeeded()
    DispatchQueue.main.async { [weak self] in
      self?.setupLiveActivityChannelIfNeeded()
    }

    return didFinish
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    setupLiveActivityChannelIfNeeded()
    cleanupLiveActivitiesIfNeeded()
  }

  private func setupLiveActivityChannelIfNeeded() {
    if liveActivityChannel != nil {
      return
    }

    guard let controller = window?.rootViewController as? FlutterViewController else {
      print("[LiveActivity] FlutterViewController indisponível; channel ainda não configurado")
      return
    }

    liveActivityChannel = FlutterMethodChannel(
      name: "com.treinopro.oficial/live_activity",
      binaryMessenger: controller.binaryMessenger
    )

    deepLinkChannel = FlutterMethodChannel(
      name: "com.treinopro.oficial/deep_link",
      binaryMessenger: controller.binaryMessenger
    )

    liveActivityChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "startLiveActivity":
        self?.handleStartLiveActivity(call: call, result: result)
      case "updateLiveActivity":
        self?.handleUpdateLiveActivity(call: call, result: result)
      case "endLiveActivity":
        self?.handleEndLiveActivity(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Entregar URL pendente caso o app tenha sido aberto via deep link enquanto terminado
    if let pending = pendingDeepLinkUrl {
      pendingDeepLinkUrl = nil
      print("[DeepLink] Entregando URL pendente ao Flutter: \(pending)")
      DispatchQueue.main.async { [weak self] in
        self?.deepLinkChannel?.invokeMethod("onDeepLink", arguments: pending)
      }
    }

    print("[LiveActivity] Method channel configurado com sucesso")
  }

  // MARK: - Live Activity Handlers

  private func handleStartLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("[LiveActivity] Start ignored because Live Activity is disabled on iOS")
    result(nil)
  }

  private func cleanupLiveActivitiesIfNeeded() {
    guard #available(iOS 16.1, *) else {
      return
    }

    endLiveActivityImpl(proposalId: nil) { _ in }
  }

  @available(iOS 16.1, *)
  private func startLiveActivityImpl(
    proposalId: String,
    studentName: String,
    location: String,
    modality: String,
    price: String,
    trainingTime: String,
    expiresIn: Int,
    result: @escaping FlutterResult
  ) {
    // End any existing activity for this proposal
    for activity in Activity<ProposalAttributes>.activities {
      if activity.attributes.proposalId == proposalId {
        Task {
          if #available(iOS 16.2, *) {
            await activity.end(nil, dismissalPolicy: .immediate)
          } else {
            await activity.end(using: activity.contentState, dismissalPolicy: .immediate)
          }
        }
      }
    }

    let attributes = ProposalAttributes(proposalId: proposalId)
    let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))

    let contentState = ProposalAttributes.ContentState(
      studentName: studentName,
      location: location,
      modality: modality,
      price: price,
      trainingTime: trainingTime,
      expiresAt: expiresAt,
      proposalStatus: "pending"
    )

    do {
      let activity: Activity<ProposalAttributes>
      if #available(iOS 16.2, *) {
        let activityContent = ActivityContent(state: contentState, staleDate: expiresAt)
        activity = try Activity.request(
          attributes: attributes,
          content: activityContent,
          pushType: .token
        )

        // Disparar um alertConfiguration imediatamente após criar a atividade.
        // Sem isso, a Live Activity fica "silenciosa" na lock screen e só aparece
        // depois que o usuário desbloqueia/bloqueia o dispositivo.
        // O alert força o iOS a exibir o banner mesmo com a tela bloqueada.
        let alertConfig = AlertConfiguration(
          title: "Nova proposta de treino!",
          body: "\(studentName) · \(location)",
          sound: .default
        )
        Task {
          await activity.update(
            ActivityContent(state: contentState, staleDate: expiresAt),
            alertConfiguration: alertConfig
          )
        }
      } else {
        activity = try Activity.request(
          attributes: attributes,
          contentState: contentState,
          pushType: .token
        )
      }

      print("[LiveActivity] Started activity: \(activity.id) for proposal: \(proposalId)")

      // Observe push token updates and send back to Flutter
      Task {
        for await tokenData in activity.pushTokenUpdates {
          let tokenString = tokenData.map { String(format: "%02x", $0) }.joined()
          print("[LiveActivity] Push token received: \(tokenString)")

          DispatchQueue.main.async { [weak self] in
            self?.liveActivityChannel?.invokeMethod("onLiveActivityToken", arguments: [
              "proposalId": proposalId,
              "token": tokenString,
            ])
          }
        }
      }

      result(activity.id)
    } catch {
      print("[LiveActivity] Error starting activity: \(error)")
      result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  private func handleUpdateLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      result(nil)
      return
    }

    guard let args = call.arguments as? [String: Any],
          let proposalId = args["proposalId"] as? String,
          let status = args["status"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
      return
    }

    updateLiveActivityImpl(proposalId: proposalId, args: args, status: status, result: result)
  }

  @available(iOS 16.1, *)
  private func updateLiveActivityImpl(proposalId: String, args: [String: Any], status: String, result: @escaping FlutterResult) {
    for activity in Activity<ProposalAttributes>.activities {
      if activity.attributes.proposalId == proposalId {
        let currentState: ProposalAttributes.ContentState
        if #available(iOS 16.2, *) {
          currentState = activity.content.state
        } else {
          currentState = activity.contentState
        }

        let contentState = ProposalAttributes.ContentState(
          studentName: args["studentName"] as? String ?? currentState.studentName,
          location: args["location"] as? String ?? currentState.location,
          modality: args["modality"] as? String ?? currentState.modality,
          price: args["price"] as? String ?? currentState.price,
          trainingTime: args["trainingTime"] as? String ?? currentState.trainingTime,
          expiresAt: currentState.expiresAt,
          proposalStatus: status
        )

        Task {
          if #available(iOS 16.2, *) {
            await activity.update(ActivityContent(state: contentState, staleDate: nil))
          } else {
            await activity.update(using: contentState)
          }
          print("[LiveActivity] Updated activity for proposal: \(proposalId) to status: \(status)")
        }
        result(true)
        return
      }
    }
    result(false)
  }

  private func handleEndLiveActivity(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      result(nil)
      return
    }

    let proposalId = (call.arguments as? [String: Any])?["proposalId"] as? String

    endLiveActivityImpl(proposalId: proposalId, result: result)
  }

  @available(iOS 16.1, *)
  private func endLiveActivityImpl(proposalId: String?, result: @escaping FlutterResult) {
    var ended = false
    for activity in Activity<ProposalAttributes>.activities {
      if proposalId == nil || activity.attributes.proposalId == proposalId {
        Task {
          if #available(iOS 16.2, *) {
            await activity.end(nil, dismissalPolicy: .immediate)
          } else {
            await activity.end(using: activity.contentState, dismissalPolicy: .immediate)
          }
          print("[LiveActivity] Ended activity for proposal: \(activity.attributes.proposalId)")
        }
        ended = true
      }
    }
    result(ended)
  }

  // MARK: - URL Scheme handler (Live Activity deep links)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    let urlString = url.absoluteString
    print("[DeepLink] URL recebida: \(urlString)")
    if deepLinkChannel != nil {
      DispatchQueue.main.async { [weak self] in
        self?.deepLinkChannel?.invokeMethod("onDeepLink", arguments: urlString)
      }
    } else {
      // Canal ainda não está pronto (app terminado) — guardar para entregar depois
      pendingDeepLinkUrl = urlString
      print("[DeepLink] Canal não disponível, URL salva como pendente")
    }
    return true
  }

  // CRITICAL: Receive APNs token and pass to Firebase
  override func application(_ application: UIApplication,
                          didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("[iOS] APNs token received: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")

    // Pass APNs token to Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken

    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(_ application: UIApplication,
                          didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("[iOS] Failed to register for remote notifications: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("[iOS] FCM Token received: \(fcmToken ?? "nil")")

    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}
