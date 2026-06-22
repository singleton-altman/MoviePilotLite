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
@objc class AppDelegate: FlutterAppDelegate {
  private let widgetRouteChannelName = "org.moviepilot/widget_navigation"
  private var pendingWidgetRoute: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let url = launchOptions?[.url] as? URL {
      pendingWidgetRoute = widgetRoute(from: url)
    }
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "org.moviepilot/ios_shared_session",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "saveSharedSession":
          guard
            let arguments = call.arguments as? [String: Any],
            let server = arguments["server"] as? String,
            let accessToken = arguments["accessToken"] as? String
          else {
            result(FlutterError(code: "bad_args", message: "Missing session arguments", details: nil))
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
            result(FlutterError(code: "bad_args", message: "Missing site widget payload", details: nil))
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
        binaryMessenger: controller.binaryMessenger
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
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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

  private func handleWidgetRoute(_ url: URL) {
    appWidgetLog.info("received widget url=\(url.absoluteString, privacy: .public)")
    guard let route = widgetRoute(from: url) else { return }
    appWidgetLog.info("resolved widget route=\(route, privacy: .public)")
    pendingWidgetRoute = route
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let channel = FlutterMethodChannel(
      name: widgetRouteChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    channel.invokeMethod("openWidgetRoute", arguments: route)
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
