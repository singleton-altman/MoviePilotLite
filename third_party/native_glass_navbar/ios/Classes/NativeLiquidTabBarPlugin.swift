import Flutter
import UIKit

public class NativeLiquidTabBarPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "native_liquid_tab_bar", binaryMessenger: registrar.messenger())
    let instance = NativeLiquidTabBarPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    let factory = NativeTabBarFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "NativeTabBar")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "isLiquidGlassSupported" {
      if #available(iOS 26, *) {
        result(true)
      } else {
        result(false)
      }
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
}
