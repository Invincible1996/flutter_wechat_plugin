import Flutter
import UIKit
import WechatOpenSDK

public class FlutterWechatPlugin: NSObject, FlutterPlugin, WXApiDelegate {
  private var pendingResult: FlutterResult?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_wechat_plugin", binaryMessenger: registrar.messenger())
    let instance = FlutterWechatPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "registerApp":
      if let args = call.arguments as? [String: Any],
         let appId = args["appId"] as? String {
        registerApp(appId: appId, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "App ID is required", details: nil))
      }
    case "isWechatInstalled":
      let isInstalled = WXApi.isWXAppInstalled()
      print("FlutterWechatPlugin: WeChat installed check: \(isInstalled)")
      result(isInstalled)
    case "wechatLogin":
      wechatLogin(result: result)
    case "shareText":
      if let args = call.arguments as? [String: Any],
         let text = args["text"] as? String {
        shareText(text: text, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Text is required", details: nil))
      }
    case "shareImage":
      if let args = call.arguments as? [String: Any],
         let imagePath = args["imagePath"] as? String {
        shareImage(imagePath: imagePath, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Image path is required", details: nil))
      }
    case "shareLink":
      if let args = call.arguments as? [String: Any],
         let url = args["url"] as? String,
         let title = args["title"] as? String {
        let description = args["description"] as? String
        let thumbnailPath = args["thumbnailPath"] as? String
        shareLink(url: url, title: title, description: description, thumbnailPath: thumbnailPath, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "URL and title are required", details: nil))
      }
    case "shareNetworkImage":
      if let args = call.arguments as? [String: Any],
         let imageUrl = args["imageUrl"] as? String {
        shareNetworkImage(imageUrl: imageUrl, result: result)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Image URL is required", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func registerApp(appId: String, result: @escaping FlutterResult) {
    print("FlutterWechatPlugin: Registering WeChat app with ID: \(appId)")
    let success = WXApi.registerApp(appId, universalLink: "")
    print("FlutterWechatPlugin: WeChat registration result: \(success)")
    result(success)
  }
  
  private func wechatLogin(result: @escaping FlutterResult) {
    if !WXApi.isWXAppInstalled() {
      result(FlutterError(code: "WECHAT_NOT_INSTALLED", message: "WeChat is not installed", details: nil))
      return
    }
    
    pendingResult = result
    
    let req = SendAuthReq()
    req.scope = "snsapi_userinfo"
    req.state = "wechat_sdk_demo_test"
    
    WXApi.send(req) { success in
      if !success {
        self.pendingResult?(FlutterError(code: "LOGIN_FAILED", message: "Failed to send login request", details: nil))
        self.pendingResult = nil
      }
    }
  }
  
  private func shareText(text: String, result: @escaping FlutterResult) {
    if !WXApi.isWXAppInstalled() {
      result(FlutterError(code: "WECHAT_NOT_INSTALLED", message: "WeChat is not installed", details: nil))
      return
    }
    
    let message = WXMediaMessage()
    message.title = text
    message.description = text
    message.mediaObject = WXTextObject()
    (message.mediaObject as! WXTextObject).contentText = text
    
    let req = SendMessageToWXReq()
    req.bText = false
    req.message = message
    req.scene = Int32(WXSceneSession.rawValue)
    
    WXApi.send(req) { success in
      result(success)
    }
  }
  
  private func shareImage(imagePath: String, result: @escaping FlutterResult) {
    if !WXApi.isWXAppInstalled() {
      result(FlutterError(code: "WECHAT_NOT_INSTALLED", message: "WeChat is not installed", details: nil))
      return
    }
    
    guard let image = UIImage(contentsOfFile: imagePath) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Invalid image file", details: nil))
      return
    }
    
    let message = WXMediaMessage()
    message.title = "Image"
    message.description = "Shared from Flutter"
    message.mediaObject = WXImageObject()
    (message.mediaObject as! WXImageObject).imageData = image.jpegData(compressionQuality: 0.8)
    
    // Set thumbnail
    let thumbImage = image.resized(to: CGSize(width: 150, height: 150))
    message.thumbData = thumbImage?.jpegData(compressionQuality: 0.8)
    
    let req = SendMessageToWXReq()
    req.bText = false
    req.message = message
    req.scene = Int32(WXSceneSession.rawValue)
    
    WXApi.send(req) { success in
      result(success)
    }
  }
  
  private func shareLink(url: String, title: String, description: String?, thumbnailPath: String?, result: @escaping FlutterResult) {
    if !WXApi.isWXAppInstalled() {
      result(FlutterError(code: "WECHAT_NOT_INSTALLED", message: "WeChat is not installed", details: nil))
      return
    }
    
    let webpageObject = WXWebpageObject()
    webpageObject.webpageUrl = url
    
    let message = WXMediaMessage()
    message.title = title
    message.description = description ?? ""
    message.mediaObject = webpageObject
    
    // Set thumbnail if provided
    if let thumbnailPath = thumbnailPath,
       let thumbImage = UIImage(contentsOfFile: thumbnailPath) {
      let resizedThumb = thumbImage.resized(to: CGSize(width: 150, height: 150))
      message.thumbData = resizedThumb?.jpegData(compressionQuality: 0.8)
    }
    
    let req = SendMessageToWXReq()
    req.bText = false
    req.message = message
    req.scene = Int32(WXSceneSession.rawValue)
    
    WXApi.send(req) { success in
      result(success)
    }
  }
  
  // MARK: - WXApiDelegate
  public func onReq(_ req: BaseReq) {
    // Handle incoming requests from WeChat
  }
  
  public func onResp(_ resp: BaseResp) {
    if let authResp = resp as? SendAuthResp {
      handleAuthResponse(authResp)
    }
  }
  
  private func shareNetworkImage(imageUrl: String, result: @escaping FlutterResult) {
    if !WXApi.isWXAppInstalled() {
      result(FlutterError(code: "WECHAT_NOT_INSTALLED", message: "WeChat is not installed", details: nil))
      return
    }
    
    // 异步下载图片
    downloadImage(from: imageUrl) { [weak self] image in
      DispatchQueue.main.async {
        if let image = image {
          self?.shareDownloadedImage(image: image, result: result)
        } else {
          result(FlutterError(code: "DOWNLOAD_FAILED", message: "Failed to download image", details: nil))
        }
      }
    }
  }
  
  private func downloadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
    guard let url = URL(string: urlString) else {
      completion(nil)
      return
    }
    
    URLSession.shared.dataTask(with: url) { data, response, error in
      if let error = error {
        print("FlutterWechatPlugin: Error downloading image: \(error.localizedDescription)")
        completion(nil)
        return
      }
      
      guard let data = data, let image = UIImage(data: data) else {
        completion(nil)
        return
      }
      
      completion(image)
    }.resume()
  }
  
  private func shareDownloadedImage(image: UIImage, result: @escaping FlutterResult) {
    let message = WXMediaMessage()
    message.title = "Network Image"
    message.description = "Shared from Flutter"
    message.mediaObject = WXImageObject()
    (message.mediaObject as! WXImageObject).imageData = image.jpegData(compressionQuality: 0.8)
    
    // Set thumbnail
    let thumbImage = image.resized(to: CGSize(width: 150, height: 150))
    message.thumbData = thumbImage?.jpegData(compressionQuality: 0.8)
    
    let req = SendMessageToWXReq()
    req.bText = false
    req.message = message
    req.scene = Int32(WXSceneSession.rawValue)
    
    WXApi.send(req) { success in
      result(success)
    }
  }
  
  private func handleAuthResponse(_ resp: SendAuthResp) {
    guard let result = pendingResult else { return }
    pendingResult = nil
    
    if resp.errCode == WXSuccess.rawValue {
      let authData: [String: Any] = [
        "code": resp.code ?? "",
        "state": resp.state ?? "",
        "lang": resp.lang ?? "",
        "country": resp.country ?? ""
      ]
      result(authData)
    } else {
      let errorMessage = resp.errStr ?? "Login failed"
      result(FlutterError(code: "LOGIN_FAILED", message: errorMessage, details: nil))
    }
  }
}

// MARK: - UIImage Extension
extension UIImage {
  func resized(to size: CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    defer { UIGraphicsEndImageContext() }
    draw(in: CGRect(origin: .zero, size: size))
    return UIGraphicsGetImageFromCurrentImageContext()
  }
}
