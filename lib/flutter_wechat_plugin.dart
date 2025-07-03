
import 'flutter_wechat_plugin_platform_interface.dart';

class FlutterWechatPlugin {
  Future<String?> getPlatformVersion() {
    return FlutterWechatPluginPlatform.instance.getPlatformVersion();
  }

  Future<bool> registerApp(String appId) {
    return FlutterWechatPluginPlatform.instance.registerApp(appId);
  }

  Future<bool> isWechatInstalled() {
    return FlutterWechatPluginPlatform.instance.isWechatInstalled();
  }

  Future<Map<String, dynamic>?> wechatLogin() {
    return FlutterWechatPluginPlatform.instance.wechatLogin();
  }

  Future<bool> shareText(String text) {
    return FlutterWechatPluginPlatform.instance.shareText(text);
  }

  Future<bool> shareImage(String imagePath) {
    return FlutterWechatPluginPlatform.instance.shareImage(imagePath);
  }

  Future<bool> shareLink({
    required String url,
    required String title,
    String? description,
    String? thumbnailPath,
  }) {
    return FlutterWechatPluginPlatform.instance.shareLink(
      url: url,
      title: title,
      description: description,
      thumbnailPath: thumbnailPath,
    );
  }

  Future<bool> shareNetworkImage(String imageUrl) {
    return FlutterWechatPluginPlatform.instance.shareNetworkImage(imageUrl);
  }
}
