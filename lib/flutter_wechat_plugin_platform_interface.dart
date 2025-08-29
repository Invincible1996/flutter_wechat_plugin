import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_wechat_plugin_method_channel.dart';

abstract class FlutterWechatPluginPlatform extends PlatformInterface {
  /// Constructs a FlutterWechatPluginPlatform.
  FlutterWechatPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterWechatPluginPlatform _instance =
      MethodChannelFlutterWechatPlugin();

  /// The default instance of [FlutterWechatPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterWechatPlugin].
  static FlutterWechatPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterWechatPluginPlatform] when
  /// they register themselves.
  static set instance(FlutterWechatPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> registerApp(
      {required String appId, required String universalLink}) {
    throw UnimplementedError('registerApp() has not been implemented.');
  }

  Future<bool> isWechatInstalled() {
    throw UnimplementedError('isWechatInstalled() has not been implemented.');
  }

  Future<bool> shareNetworkImage(String imageUrl) {
    throw UnimplementedError('shareNetworkImage() has not been implemented.');
  }

  Future<bool> shareNetworkImageToScene(String imageUrl, int scene) {
    throw UnimplementedError(
        'shareNetworkImageToScene() has not been implemented.');
  }

  Future<bool> shareImage(String imagePath) {
    throw UnimplementedError('shareImage() has not been implemented.');
  }

  Future<Map<String, dynamic>?> wechatLogin() {
    throw UnimplementedError('wechatLogin() has not been implemented.');
  }

  Future<bool> shareText(String text) {
    throw UnimplementedError('shareText() has not been implemented.');
  }

  Future<bool> shareLink(
      {required String url,
      required String title,
      required String description}) {
    throw UnimplementedError('shareLink() has not been implemented.');
  }

  Future<bool> openMiniProgram(
      {required String username,
      required String path,
      int miniProgramType = 0}) {
    throw UnimplementedError('openMiniProgram() has not been implemented.');
  }
}
