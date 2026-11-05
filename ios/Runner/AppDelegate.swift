import Flutter
import UIKit
import UserNotifications
import WidgetKit
import os

private enum SharedSessionConfig {
  static let appGroup = "group.com.altman.moviepilot.shared"
  static let serverKey = "shared_server_url"
  static let tokenKey = "shared_access_token"
  static let siteWidgetPayloadKey = "shared_site_widget_payload"
}

private let appWidgetLog = Logger(subsystem: "com.altman.moviepilot", category: "app_widget_route")

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let widgetRouteChannelName = "org.moviepilot/widget_navigation"
  private var pendingWidgetRoute: String?
  private var widgetRouteChannel: FlutterMethodChannel?
  private let sceneLifecycle = MoviePilotSceneLifecycle()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let url = launchOptions?[.url] as? URL {
      pendingWidgetRoute = widgetRoute(from: url)
    }
    if pendingWidgetRoute == nil,
      let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any]
    {
      pendingWidgetRoute = appRoute(fromNotificationUserInfo: userInfo)
    }
    self.registrar(forPlugin: "MoviePilotSceneLifecycle")?.addSceneDelegate(sceneLifecycle)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()

    let appIconChannel = FlutterMethodChannel(
      name: "org.moviepilot/app_icon",
      binaryMessenger: messenger
    )
    appIconChannel.setMethodCallHandler { call, result in
      guard call.method == "setAppIcon",
        let arguments = call.arguments as? [String: Any],
        let iconId = arguments["iconId"] as? String
      else {
        result(false)
        return
      }
      self.setAlternateAppIcon(iconId: iconId, result: result)
    }

    let channel = FlutterMethodChannel(
      name: "org.moviepilot/ios_shared_session",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "saveSharedSession":
        guard
          let arguments = call.arguments as? [String: Any],
          let server = arguments["server"] as? String,
          let accessToken = arguments["accessToken"] as? String
        else {
          result(
            FlutterError(code: "bad_args", message: "Missing session arguments", details: nil))
          return
        }
        self.saveSharedSession(server: server, accessToken: accessToken)
        result(nil)
      case "clearSharedSession":
        self.clearSharedSession()
        result(nil)
      case "saveSiteWidgetPayload":
        guard
          let arguments = call.arguments as? [String: Any],
          let payload = arguments["payload"] as? String
        else {
          result(
            FlutterError(code: "bad_args", message: "Missing site widget payload", details: nil))
          return
        }
        self.saveSiteWidgetPayload(payload)
        result(nil)
      case "reloadWidgets":
        WidgetCenter.shared.reloadAllTimelines()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let widgetRouteChannel = FlutterMethodChannel(
      name: widgetRouteChannelName,
      binaryMessenger: messenger
    )
    widgetRouteChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "getPendingWidgetRoute":
        result(self.pendingWidgetRoute)
        self.pendingWidgetRoute = nil
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.widgetRouteChannel = widgetRouteChannel
  }

  private func setAlternateAppIcon(iconId: String, result: @escaping FlutterResult) {
    guard UIApplication.shared.supportsAlternateIcons else {
      result(false)
      return
    }
    let iconName: String?
    switch iconId {
    case "default": iconName = nil
    case "midnight": iconName = "IconMidnight"
    case "sunset": iconName = "IconSunset"
    case "mint": iconName = "IconMint"
    case "neon": iconName = "IconNeon"
    case "aurora": iconName = "IconAurora"
    case "sunset_pop": iconName = "IconSunsetPop"
    case "mono": iconName = "IconMono"
    default:
      result(false)
      return
    }
    UIApplication.shared.setAlternateIconName(iconName) { error in
      result(error == nil)
    }
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    handleWidgetRoute(url)
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    MPJPushRegisterDeviceToken(deviceToken)
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("didFailToRegisterForRemoteNotificationsWithError: \(error)")
    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    MPJPushHandleRemoteNotification(userInfo)
    completionHandler(.newData)
  }

  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    MPJPushHandleRemoteNotification(notification.request.content.userInfo)
    completionHandler([.alert, .badge, .sound])
  }

  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    handleNotificationRoute(response.notification.request.content.userInfo)
    MPJPushHandleRemoteNotification(response.notification.request.content.userInfo)
    completionHandler()
  }

  private func saveSharedSession(server: String, accessToken: String) {
    guard let defaults = UserDefaults(suiteName: SharedSessionConfig.appGroup) else { return }
    defaults.set(server, forKey: SharedSessionConfig.serverKey)
    defaults.set(accessToken, forKey: SharedSessionConfig.tokenKey)
    WidgetCenter.shared.reloadAllTimelines()
  }

  private func clearSharedSession() {
    guard let defaults = UserDefaults(suiteName: SharedSessionConfig.appGroup) else { return }
    defaults.removeObject(forKey: SharedSessionConfig.serverKey)
    defaults.removeObject(forKey: SharedSessionConfig.tokenKey)
    defaults.removeObject(forKey: SharedSessionConfig.siteWidgetPayloadKey)
    WidgetCenter.shared.reloadAllTimelines()
  }

  private func saveSiteWidgetPayload(_ payload: String) {
    guard let defaults = UserDefaults(suiteName: SharedSessionConfig.appGroup) else { return }
    defaults.set(payload, forKey: SharedSessionConfig.siteWidgetPayloadKey)
    WidgetCenter.shared.reloadAllTimelines()
  }

  fileprivate func handleWidgetRoute(_ url: URL) {
    appWidgetLog.info("received widget url=\(url.absoluteString, privacy: .public)")
    guard let route = widgetRoute(from: url) else { return }
    openAppRoute(route)
  }

  private func handleNotificationRoute(_ userInfo: [AnyHashable: Any]) {
    guard let route = appRoute(fromNotificationUserInfo: userInfo) else { return }
    appWidgetLog.info("resolved notification route=\(route, privacy: .public)")
    openAppRoute(route)
  }

  private func openAppRoute(_ route: String) {
    appWidgetLog.info("resolved app route=\(route, privacy: .public)")
    pendingWidgetRoute = route
    widgetRouteChannel?.invokeMethod("openWidgetRoute", arguments: route)
  }

  private func appRoute(fromNotificationUserInfo userInfo: [AnyHashable: Any]) -> String? {
    if let route = firstMoviePilotRoute(in: userInfo) {
      return route
    }
    if hasSystemMessageHint(in: userInfo) {
      return "moviepilot://system-message"
    }
    return nil
  }

  private func firstMoviePilotRoute(in value: Any) -> String? {
    if let string = value as? String {
      let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.lowercased().hasPrefix("moviepilot://"),
        let url = URL(string: trimmed)
      {
        return widgetRoute(from: url)
      }
      if let data = trimmed.data(using: .utf8),
        let json = try? JSONSerialization.jsonObject(with: data)
      {
        return firstMoviePilotRoute(in: json)
      }
      return nil
    }
    if let map = value as? [AnyHashable: Any] {
      for nested in map.values {
        if let route = firstMoviePilotRoute(in: nested) {
          return route
        }
      }
      return nil
    }
    if let map = value as? [String: Any] {
      for nested in map.values {
        if let route = firstMoviePilotRoute(in: nested) {
          return route
        }
      }
      return nil
    }
    if let list = value as? [Any] {
      for nested in list {
        if let route = firstMoviePilotRoute(in: nested) {
          return route
        }
      }
    }
    return nil
  }

  private func hasSystemMessageHint(in value: Any) -> Bool {
    let keys: Set<String> = ["page", "open_page", "target_page", "type", "route"]
    let values: Set<String> = [
      "system_message", "system-message", "systemmessage", "/system-message",
    ]

    if let string = value as? String {
      let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
      if let data = trimmed.data(using: .utf8),
        let json = try? JSONSerialization.jsonObject(with: data)
      {
        return hasSystemMessageHint(in: json)
      }
      return values.contains(trimmed.lowercased())
    }
    if let map = value as? [AnyHashable: Any] {
      for (rawKey, nested) in map {
        let key = String(describing: rawKey).lowercased()
        if keys.contains(key), let string = nested as? String {
          let value = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
          if values.contains(value) {
            return true
          }
        }
        if hasSystemMessageHint(in: nested) {
          return true
        }
      }
      return false
    }
    if let map = value as? [String: Any] {
      for (key, nested) in map {
        if keys.contains(key.lowercased()), let string = nested as? String {
          let value = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
          if values.contains(value) {
            return true
          }
        }
        if hasSystemMessageHint(in: nested) {
          return true
        }
      }
      return false
    }
    if let list = value as? [Any] {
      return list.contains { hasSystemMessageHint(in: $0) }
    }
    return false
  }

  private func widgetRoute(from url: URL) -> String? {
    guard let scheme = url.scheme?.lowercased(), scheme == "moviepilot" else {
      return nil
    }
    if url.host?.lowercased() == "media-detail" || url.path.lowercased() == "/media-detail" {
      return url.absoluteString
    }
    if url.host?.lowercased() == "subscribe-calendar" {
      return "moviepilot://subscribe-calendar"
    }
    if url.path.lowercased() == "/subscribe-calendar" {
      return "moviepilot://subscribe-calendar"
    }
    if url.host?.lowercased() == "site-overview" {
      return "moviepilot://site-overview"
    }
    if url.path.lowercased() == "/site-overview" {
      return "moviepilot://site-overview"
    }
    if url.host?.lowercased() == "system-message" {
      return "moviepilot://system-message"
    }
    if url.path.lowercased() == "/system-message" {
      return "moviepilot://system-message"
    }
    return nil
  }
}

private class MoviePilotSceneLifecycle: NSObject, FlutterSceneLifeCycleDelegate {
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
    connectionOptions?.urlContexts.forEach { appDelegate.handleWidgetRoute($0.url) }
    return false
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false }
    URLContexts.forEach { appDelegate.handleWidgetRoute($0.url) }
    return false
  }
}
