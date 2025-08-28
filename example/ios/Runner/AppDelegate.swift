import Flutter
import UIKit
import WechatOpenSDK

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, WXApiDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    return WXApi.handleOpenUniversalLink(userActivity, delegate: self)
  }

  // MARK: - WXApiDelegate
  func onReq(_ req: BaseReq) {
    // Handle incoming requests from WeChat
  }

  func onResp(_ resp: BaseResp) {
    // Handle responses from WeChat
  }
}
