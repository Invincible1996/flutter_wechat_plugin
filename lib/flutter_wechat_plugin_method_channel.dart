import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_wechat_plugin_platform_interface.dart';

/// An implementation of [FlutterWechatPluginPlatform] that uses method channels.
class MethodChannelFlutterWechatPlugin extends FlutterWechatPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_wechat_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> registerApp(String appId) async {
    final result = await methodChannel.invokeMethod<bool>('registerApp', {'appId': appId});
    return result ?? false;
  }

  @override
  Future<bool> isWechatInstalled() async {
    final result = await methodChannel.invokeMethod<bool>('isWechatInstalled');
    return result ?? false;
  }

  @override
  Future<Map<String, dynamic>?> wechatLogin() async {
    final result = await methodChannel.invokeMethod<Map<String, dynamic>?>('wechatLogin');
    return result;
  }

  @override
  Future<bool> shareText(String text) async {
    final result = await methodChannel.invokeMethod<bool>('shareText', {'text': text});
    return result ?? false;
  }

  @override
  Future<bool> shareImage(String imagePath) async {
    final result = await methodChannel.invokeMethod<bool>('shareImage', {'imagePath': imagePath});
    return result ?? false;
  }

  @override
  Future<bool> shareLink({
    required String url,
    required String title,
    String? description,
    String? thumbnailPath,
  }) async {
    final result = await methodChannel.invokeMethod<bool>('shareLink', {
      'url': url,
      'title': title,
      'description': description,
      'thumbnailPath': thumbnailPath,
    });
    return result ?? false;
  }

  @override
  Future<bool> shareNetworkImage(String imageUrl) async {
    final result = await methodChannel.invokeMethod<bool>('shareNetworkImage', {'imageUrl': imageUrl});
    return result ?? false;
  }
}
