import 'package:flutter_wechat_plugin/flutter_wechat_plugin.dart';
import 'dart:async';

/// WeChat utility class providing convenient methods for WeChat operations
class WechatUtil {
  static final FlutterWechatPlugin _flutterWechatPlugin = FlutterWechatPlugin();
  
  /// Stream for WeChat response events
  static Stream<Map<String, dynamic>> get responseEventHandler => FlutterWechatPlugin.responseEventHandler;

  /// Check if WeChat is installed
  static Future<bool> isWechatInstalled() async {
    return await _flutterWechatPlugin.isWechatInstalled();
  }

  /// Share network image to WeChat session
  static Future<bool> shareNetworkImage(String imageUrl) async {
    return await _flutterWechatPlugin.shareNetworkImage(imageUrl);
  }

  /// Share network image to WeChat Moments (Timeline)
  static Future<bool> shareNetworkImageToTimeline(String imageUrl) async {
    return await _flutterWechatPlugin.shareNetworkImageToScene(imageUrl, WechatScene.timeline);
  }

  /// Share network image to specific WeChat scene
  static Future<bool> shareNetworkImageToScene(String imageUrl, int scene) async {
    return await _flutterWechatPlugin.shareNetworkImageToScene(imageUrl, scene);
  }

  /// WeChat login
  /// Returns a map containing login result:
  /// - code: Authorization code
  /// - state: State parameter
  /// - lang: Language
  /// - country: Country
  static Future<Map<String, dynamic>?> wechatLogin() async {
    return await _flutterWechatPlugin.wechatLogin();
  }

  /// Share text to WeChat
  static Future<bool> shareText(String text) async {
    return await _flutterWechatPlugin.shareText(text);
  }

  /// Share link to WeChat
  static Future<bool> shareLink({
    required String url,
    required String title,
    required String description,
  }) async {
    return await _flutterWechatPlugin.shareLink(
      url: url,
      title: title,
      description: description,
    );
  }

  /// 打开微信小程序
  static Future<bool> openMiniProgram({
    required String username,
    required String path,
    WXMiniProgramType miniProgramType = WXMiniProgramType.release,
  }) async {
    return await _flutterWechatPlugin.openMiniProgram(
      username: username,
      path: path,
      miniProgramType: miniProgramType,
    );
  }
}