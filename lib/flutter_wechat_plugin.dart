import 'flutter_wechat_plugin_platform_interface.dart';
import 'dart:async';

export 'wechat_scene.dart';
export 'wechat_util.dart';

enum WeChatScene {
  session,
  timeline,
}

enum WXMiniProgramType {
  release(0), // 正式版
  test(1), // 开发版
  preview(2); // 体验版

  const WXMiniProgramType(this.value);
  final int value;
}

class FlutterWechatPlugin {
  static final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream for WeChat response events
  static Stream<Map<String, dynamic>> get responseEventHandler =>
      _eventController.stream;

  /// Internal method to handle response events
  static void handleResponseEvent(Map<String, dynamic> event) {
    _eventController.add(event);
  }

  Future<String?> getPlatformVersion() {
    return FlutterWechatPluginPlatform.instance.getPlatformVersion();
  }

  Future<bool> registerApp(
      {required String appId, required String universalLink}) {
    return FlutterWechatPluginPlatform.instance
        .registerApp(appId: appId, universalLink: universalLink);
  }

  Future<bool> isWechatInstalled() {
    return FlutterWechatPluginPlatform.instance.isWechatInstalled();
  }

  Future<bool> shareNetworkImage(String imageUrl) {
    return FlutterWechatPluginPlatform.instance.shareNetworkImage(imageUrl);
  }

  Future<bool> shareNetworkImageToScene(String imageUrl, int scene) {
    return FlutterWechatPluginPlatform.instance
        .shareNetworkImageToScene(imageUrl, scene);
  }

  Future<bool> shareImage(String imagePath) {
    return FlutterWechatPluginPlatform.instance.shareImage(imagePath);
  }

  Future<Map<String, dynamic>?> wechatLogin() {
    return FlutterWechatPluginPlatform.instance.wechatLogin();
  }

  Future<bool> shareText(String text) {
    return FlutterWechatPluginPlatform.instance.shareText(text);
  }

  Future<bool> shareLink(
      {required String url,
      required String title,
      required String description}) {
    return FlutterWechatPluginPlatform.instance
        .shareLink(url: url, title: title, description: description);
  }

  Future<bool> openMiniProgram(
      {required String username,
      required String path,
      WXMiniProgramType miniProgramType = WXMiniProgramType.release}) {
    return FlutterWechatPluginPlatform.instance.openMiniProgram(
        username: username, path: path, miniProgramType: miniProgramType.value);
  }
}
