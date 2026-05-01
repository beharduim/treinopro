import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import ActivityKit
import StripeConnect
import StripePayments

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
  private var stripeConnectChannel: FlutterMethodChannel?
  private var pendingDeepLinkUrl: String?
  private var stripeEmbeddedComponentManager: EmbeddedComponentManager?
  private var stripeOnboardingResult: FlutterResult?
  private var stripeConnectConfig: StripeConnectConfiguration?

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

    stripeConnectChannel = FlutterMethodChannel(
      name: "com.treinopro.oficial/stripe_connect",
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

    stripeConnectChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "presentEmbeddedOnboarding":
        self?.handlePresentStripeOnboarding(call: call, result: result)
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

  private func handlePresentStripeOnboarding(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard stripeOnboardingResult == nil else {
      result(
        FlutterError(
          code: "stripe_onboarding_in_progress",
          message: "Já existe um onboarding de recebimento em andamento.",
          details: nil
        )
      )
      return
    }

    guard
      let args = call.arguments as? [String: Any],
      let publishableKey = args["publishableKey"] as? String,
      let baseUrl = args["baseUrl"] as? String,
      let accessToken = args["accessToken"] as? String,
      !publishableKey.isEmpty,
      !baseUrl.isEmpty,
      !accessToken.isEmpty
    else {
      result(
        FlutterError(
          code: "stripe_onboarding_invalid_arguments",
          message: "Parâmetros inválidos para iniciar o onboarding do Stripe.",
          details: nil
        )
      )
      return
    }

    let newConfig = StripeConnectConfiguration(
      publishableKey: publishableKey,
      baseUrl: baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/")),
      accessToken: accessToken
    )

    if stripeEmbeddedComponentManager == nil || stripeConnectConfig != newConfig {
      stripeConnectConfig = newConfig
      STPAPIClient.shared.publishableKey = publishableKey
      stripeEmbeddedComponentManager = EmbeddedComponentManager(
        fetchClientSecret: { [weak self] in
          guard let self else { return nil }
          return await self.fetchStripeClientSecret(
            baseUrl: newConfig.baseUrl,
            accessToken: newConfig.accessToken
          )
        }
      )
    }

    guard let presenter = topViewController() else {
      result(
        FlutterError(
          code: "stripe_onboarding_presenter_unavailable",
          message: "Não foi possível localizar uma tela para apresentar o onboarding.",
          details: nil
        )
      )
      return
    }

    guard let onboardingController = stripeEmbeddedComponentManager?.createAccountOnboardingController() else {
      result(
        FlutterError(
          code: "stripe_onboarding_unavailable",
          message: "Não foi possível criar o controller de onboarding do Stripe.",
          details: nil
        )
      )
      return
    }

    stripeOnboardingResult = result
    onboardingController.delegate = self
    onboardingController.title = "Configurar recebimento"
    onboardingController.present(from: presenter)
  }

  private func topViewController(
    from controller: UIViewController? = nil
  ) -> UIViewController? {
    let rootController = controller ?? window?.rootViewController

    if let navigationController = rootController as? UINavigationController {
      return topViewController(from: navigationController.visibleViewController)
    }

    if let tabBarController = rootController as? UITabBarController {
      return topViewController(from: tabBarController.selectedViewController)
    }

    if let presentedController = rootController?.presentedViewController {
      return topViewController(from: presentedController)
    }

    return rootController
  }

  private func fetchStripeClientSecret(
    baseUrl: String,
    accessToken: String
  ) async -> String? {
    guard let url = URL(string: "\(baseUrl)/payments/profile/financial/stripe/account-session") else {
      return nil
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = Data()

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard
        let httpResponse = response as? HTTPURLResponse,
        (200...299).contains(httpResponse.statusCode),
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let payload = json["data"] as? [String: Any],
        let clientSecret = payload["clientSecret"] as? String,
        !clientSecret.isEmpty
      else {
        return nil
      }

      return clientSecret
    } catch {
      return nil
    }
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

extension AppDelegate: AccountOnboardingControllerDelegate {
  func accountOnboardingDidExit(_ accountOnboarding: AccountOnboardingController) {
    stripeOnboardingResult?(nil)
    stripeOnboardingResult = nil
  }
}

private struct StripeConnectConfiguration: Equatable {
  let publishableKey: String
  let baseUrl: String
  let accessToken: String
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
