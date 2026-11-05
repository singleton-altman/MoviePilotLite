import Flutter
import UIKit

class NativeTabBarFactory: NSObject, FlutterPlatformViewFactory {
	private var messenger: FlutterBinaryMessenger

	init(messenger: FlutterBinaryMessenger) {
		self.messenger = messenger
		super.init()
	}

	func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?)
		-> FlutterPlatformView
	{
		return NativeTabBarPlatformView(
			frame: frame,
			viewId: viewId,
			args: args,
			messenger: messenger
		)
	}

	func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
		return FlutterStandardMessageCodec.sharedInstance()
	}
}

class NativeTabBarPlatformView: NSObject, FlutterPlatformView {
	private let controller: LiquidGlassTabBarController

	init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
		self.controller = LiquidGlassTabBarController(
			viewId: viewId,
			messenger: messenger,
			args: args
		)
		super.init()
	}

	func view() -> UIView {
		return controller.view
	}
}

struct TabBarConfig: Equatable {
	var labels: [String] = []
	var symbols: [String] = []
	var actionButtonSymbol: String = ""  // Default to empty
	var tintColor: UIColor = .systemBlue
	var selectedIndex: Int = 0
	var isDark: Bool = false

	init(from dict: [String: Any]?) {
		guard let dict = dict else { return }
		if let l = dict["labels"] as? [String] { self.labels = l }
		if let s = dict["symbols"] as? [String] { self.symbols = s }

		if let action = dict["actionButtonSymbol"] as? String {
			self.actionButtonSymbol = action
		}

		if let colorInt = dict["tintColor"] as? NSNumber {
			self.tintColor = TabBarConfig.uiColorFromARGB(colorInt.intValue)
		}
		if let idx = dict["selectedIndex"] as? Int {
			self.selectedIndex = idx
		}
		if let isDark = dict["isDark"] as? Bool {
			self.isDark = isDark
		}
	}

	func structuralChange(from other: TabBarConfig) -> Bool {
		return labels.count != other.labels.count || symbols.count != other.symbols.count
			|| (actionButtonSymbol.isEmpty != other.actionButtonSymbol.isEmpty)
	}

	private static func uiColorFromARGB(_ argb: Int) -> UIColor {
		let a = CGFloat((argb >> 24) & 0xFF) / 255.0
		let r = CGFloat((argb >> 16) & 0xFF) / 255.0
		let g = CGFloat((argb >> 8) & 0xFF) / 255.0
		let b = CGFloat(argb & 0xFF) / 255.0
		return UIColor(red: r, green: g, blue: b, alpha: a)
	}
}

class LiquidGlassTabBarController: UITabBarController, UITabBarControllerDelegate {
	private let channel: FlutterMethodChannel
	private var config: TabBarConfig
	private var currentAppearanceIsDark: Bool

	init(viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
		self.channel = FlutterMethodChannel(
			name: "NativeTabBar_\(viewId)",
			binaryMessenger: messenger
		)
		self.config = TabBarConfig(from: args as? [String: Any])
		self.currentAppearanceIsDark = config.isDark
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.backgroundColor = .clear
		self.view.isOpaque = false
		self.delegate = self
		overrideUserInterfaceStyle = config.isDark ? .dark : .light

		configureAppearance()
		performFullRebuild()

		channel.setMethodCallHandler { [weak self] call, result in
			self?.handle(call, result: result)
		}
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		self.view.backgroundColor = .clear
	}

	private func configureAppearance() {
		if #available(iOS 26.0, *) {
			tabBar.isTranslucent = true
			tabBar.backgroundColor = .clear
			tabBar.barTintColor = nil
			tabBar.tintColor = config.tintColor
			tabBar.unselectedItemTintColor = .secondaryLabel
			return
		}

		let appearance = UITabBarAppearance()
		appearance.configureWithDefaultBackground()
		appearance.backgroundColor = .clear
		appearance.shadowColor = .clear
		appearance.backgroundEffect = UIBlurEffect(style: config.isDark ? .dark : .light)

		let itemAppearance = UITabBarItemAppearance()
		itemAppearance.normal.iconColor = .systemGray
		itemAppearance.selected.iconColor = config.tintColor

		appearance.stackedLayoutAppearance = itemAppearance
		appearance.inlineLayoutAppearance = itemAppearance
		appearance.compactInlineLayoutAppearance = itemAppearance

		tabBar.standardAppearance = appearance
		if #available(iOS 15.0, *) {
			tabBar.scrollEdgeAppearance = appearance
		}

		tabBar.isTranslucent = true
		tabBar.tintColor = config.tintColor
	}

	private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
		if call.method == "update", let dict = call.arguments as? [String: Any] {
			let newConfig = TabBarConfig(from: dict)
			let oldConfig = self.config

			if newConfig.structuralChange(from: oldConfig) {
				self.config = newConfig
				performFullRebuild()  // Destructive
			} else {
				// 2. Light Updates (In-Place)
				self.config = newConfig

				// A. Update Colors
				updateSelectionAndColors()

				// B. Update Symbol In-Place (Fixes Jank)
				if oldConfig.actionButtonSymbol != newConfig.actionButtonSymbol {
					updateActionSymbolInPlace()
				}
			}

			result(nil)
		} else {
			result(FlutterMethodNotImplemented)
		}
	}

	// Updates the icon without destroying the TabBarItem
	private func updateActionSymbolInPlace() {
		guard let vcs = self.viewControllers else { return }

		// Find the action button (Tag 99)
		if let actionVC = vcs.first(where: { $0.tabBarItem.tag == 99 }) {
			actionVC.tabBarItem.image = resolveSymbol(config.actionButtonSymbol)
		}
	}

	private func performFullRebuild() {
		var controllers: [UIViewController] = []
		let count = max(config.labels.count, config.symbols.count)

		// Standard Tabs
		for i in 0..<count {
			let dummyVC = UIViewController()
			dummyVC.view.backgroundColor = .clear

			let symbolName = i < config.symbols.count ? config.symbols[i] : "questionmark"
			let label = i < config.labels.count ? config.labels[i] : ""

			dummyVC.tabBarItem = UITabBarItem(
				title: label,
				image: resolveSymbol(symbolName),
				tag: i
			)
			controllers.append(dummyVC)
		}

		// Action Button
		if !config.actionButtonSymbol.isEmpty {
			let actionVC = UIViewController()
			actionVC.view.backgroundColor = .clear

			let item = UITabBarItem(tabBarSystemItem: .search, tag: 99)
			item.image = resolveSymbol(config.actionButtonSymbol)

			actionVC.tabBarItem = item
			controllers.append(actionVC)
		}

		self.setViewControllers(controllers, animated: false)
		updateSelectionAndColors()
	}

	private func updateSelectionAndColors() {
		let needsAppearanceUpdate =
			tabBar.tintColor != config.tintColor
			|| currentAppearanceIsDark != config.isDark

		if needsAppearanceUpdate {
			tabBar.tintColor = config.tintColor
			currentAppearanceIsDark = config.isDark
			overrideUserInterfaceStyle = config.isDark ? .dark : .light
			configureAppearance()
		}

		if self.selectedIndex != config.selectedIndex {
			if let vcs = self.viewControllers,
				config.selectedIndex < vcs.count,
				vcs[config.selectedIndex].tabBarItem.tag != 99
			{
				self.selectedIndex = config.selectedIndex
			}
		}
	}
    
    private func resolveSymbol(_ name: String) -> UIImage? {
        return UIImage(systemName: name) ?? UIImage(named: name)
    }

	// MARK: - Delegate
	func tabBarController(
		_ tabBarController: UITabBarController,
		shouldSelect viewController: UIViewController
	) -> Bool {
		if viewController.tabBarItem.tag == 99 {
			channel.invokeMethod("actionButtonPressed", arguments: nil)
			return false
		}
		return true
	}

	func tabBarController(
		_ tabBarController: UITabBarController,
		didSelect viewController: UIViewController
	) {
		let tag = viewController.tabBarItem.tag
		if tag != 99 {
			config.selectedIndex = tag
			channel.invokeMethod("valueChanged", arguments: ["index": tag])
		}
	}
}
