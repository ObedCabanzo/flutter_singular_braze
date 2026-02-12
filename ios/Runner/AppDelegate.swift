import BrazeKit
import BrazeUI
import Flutter
import UIKit
import UserNotifications
import braze_plugin
import singular_flutter_sdk

@main
@objc class AppDelegate: FlutterAppDelegate, BrazeDelegate {
  static var braze: Braze? = nil
  private var permissionChannel: FlutterMethodChannel?
  private var deepLinkChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let singularAppDelegate = SingularAppDelegate.shared() {
      singularAppDelegate.launchOptions = launchOptions
    }
    // Setup Braze
    let configuration = Braze.Configuration(
      apiKey: "3fe9eb2b-0553-41ce-ad92-8db1febe0533",
      endpoint: "sdk.iad-06.braze.com"
    )

    configuration.push.automation = false
    configuration.forwardUniversalLinks = true
    configuration.logger.level = .info

    let braze = BrazePlugin.initBraze(configuration)
    AppDelegate.braze = braze

    braze.delegate = self

    // InAppMessage UI
    let inAppMessageUI = BrazeInAppMessageUI()
    braze.inAppMessagePresenter = inAppMessageUI

    let center = UNUserNotificationCenter.current()
    center.setNotificationCategories(Braze.Notifications.categories)
    center.delegate = self

    let controller = window?.rootViewController as! FlutterViewController
    permissionChannel = FlutterMethodChannel(
      name: "com.example.flutter_singular/notifications",
      binaryMessenger: controller.binaryMessenger
    )

    deepLinkChannel = FlutterMethodChannel(
      name: "com.example.flutter_singular/deeplinks",
      binaryMessenger: controller.binaryMessenger
    )

    permissionChannel?.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "requestNotificationPermission" {
        self?.requestNotificationPermission(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Método para solicitar permisos cuando el usuario presione el botón
  private func requestNotificationPermission(result: @escaping FlutterResult) {
    let center = UNUserNotificationCenter.current()
    let options: UNAuthorizationOptions = [.alert, .sound, .badge]

    center.requestAuthorization(options: options) { [weak self] granted, error in
      DispatchQueue.main.async {
        if let error = error {
          print("Error requesting notification permission: \(error)")
          result(
            FlutterError(
              code: "PERMISSION_ERROR",
              message: error.localizedDescription,
              details: nil
            ))
          return
        }

        print("Notification permission granted: \(granted)")

        if granted {
          // Registrar para notificaciones remotas
          UIApplication.shared.registerForRemoteNotifications()
        }

        result(granted)
      }
    }
  }

  // Step 3.2 - Registrar el device token con Braze
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("Device token registered with APNs")
    AppDelegate.braze?.notifications.register(deviceToken: deviceToken)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Error al registrar
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Failed to register for remote notifications: \(error)")
  }

  // Step 3.3 - Manejo de push en background
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if let braze = AppDelegate.braze,
      braze.notifications.handleBackgroundNotification(
        userInfo: userInfo,
        fetchCompletionHandler: completionHandler
      )
    {
      return
    }
    completionHandler(.noData)
  }

  // Manejo cuando el usuario interactúa con la notificación (tap)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let braze = AppDelegate.braze,
      braze.notifications.handleUserNotification(
        response: response,
        withCompletionHandler: completionHandler
      )
    {
      return
    }
    completionHandler()
  }

  // Manejo de notificaciones en foreground (app abierta)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if let braze = AppDelegate.braze {
      braze.notifications.handleForegroundNotification(notification: notification)
    }

    if #available(iOS 14.0, *) {
      completionHandler([.list, .banner])
    } else {
      completionHandler([.alert])
    }
  }

  override func application(
    _ app: UIApplication,
    open url: URL, 
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    print("App opened with URL: \(url.absoluteString)")
    forwardURLToSingularBridge(url, options: options)
    return true
  }


  // Universal Links

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {

    print("continue userActivity called")
    print("   Activity type: \(userActivity.activityType)")

    // Primero, intentar que Braze maneje el universal link
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
      let url = userActivity.webpageURL
    {

      print("   URL: \(url.absoluteString)")
      if let braze = AppDelegate.braze {
        // Braze procesará el link y disparará su delegate si está configurado
        // Esto permite que el deep link se maneje dentro de la app
      }

      // También forward a Singular para attribution
      forwardURLToSingularBridge(url, options: [:])

      return true
    }

    // Si no es browsing web, delegar a Singular
    if let singularAppDelegate = SingularAppDelegate.shared() {
      singularAppDelegate.continueUserActivity(userActivity, restorationHandler: nil)
    }

    // Llamar al super para mantener compatibilidad con Flutter
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }

  func braze(_ braze: Braze, shouldOpenURL context: Braze.URLContext) -> Bool {
    let url = context.url
    let urlString = url.absoluteString

    print("=> [BrazeDelegate] shouldOpenURL: \(urlString)")

    if urlString.contains("obed.lat") || urlString.contains("minders.sng.link")  {
      forwardURLToSingularBridge(url, options: [:])
      return false
    } 

    return true
  }

  func forwardURLToSingularBridge(_ url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
    if let singularAppDelegate = SingularAppDelegate.shared() {
      print("URL Delegated to Singular: \(url.absoluteString)")
      singularAppDelegate.handleOpen(url, options: options)
    }
    //forwardDeepLinkToFlutter(url)
  }

  private func forwardDeepLinkToFlutter(_ url: URL) {
    guard let deepLinkChannel = deepLinkChannel else {
      print("Deep link channel not initialized")
      return
    }

    let urlString = url.absoluteString
    let scheme = url.scheme ?? ""
    let host = url.host ?? ""
    let path = url.path
    let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

    // Construir diccionario con todos los parámetros
    var queryParams: [String: String] = [:]
    queryItems?.forEach { item in
      queryParams[item.name] = item.value ?? ""
    }

    let deepLinkData: [String: Any] = [
      "url": urlString,
      "scheme": scheme,
      "host": host,
      "path": path,
      "queryParams": queryParams,
    ]

    print("   Sending deep link to Flutter: \(urlString)")
    print("   Parsed data: \(deepLinkData)")

    // Invocar el método en Flutter
    deepLinkChannel.invokeMethod("onDeepLink", arguments: deepLinkData) { result in
      if let error = result as? FlutterError {
        print("Flutter deep link error: \(error.message ?? "unknown")")
      } else if FlutterMethodNotImplemented.isEqual(result) {
        print("Flutter deep link handler not implemented")
      } else {
        print("Flutter handled deep link successfully")
      }
    }
  }
}
