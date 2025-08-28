import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_wechat_plugin_platform_interface.dart';
import 'flutter_wechat_plugin.dart';

/// An implementation of [FlutterWechatPluginPlatform] that uses method channels.
class MethodChannelFlutterWechatPlugin extends FlutterWechatPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_wechat_plugin');
  
  /// The event channel used to listen for WeChat response events.
  @visibleForTesting
  final eventChannel = const EventChannel('flutter_wechat_plugin/response_event');
  
  MethodChannelFlutterWechatPlugin() {
    methodChannel.setMethodCallHandler(_handleMethodCall);
    _initEventChannel();
  }
  
  void _initEventChannel() {
    eventChannel.receiveBroadcastStream().listen((dynamic event) {
      if (event is Map) {
        final Map<String, dynamic> eventMap = Map<String, dynamic>.from(event);
        FlutterWechatPlugin.handleResponseEvent(eventMap);
      }
    });
  }
  
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onWeChatResponse':
        final Map<String, dynamic> event = Map<String, dynamic>.from(call.arguments);
        FlutterWechatPlugin.handleResponseEvent(event);
        break;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'Method ${call.method} is not implemented',
        );
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> registerApp({required String appId, required String universalLink}) async {
    final result = await methodChannel.invokeMethod<bool>('registerApp', {'appId': appId, 'universalLink': universalLink});
    return result ?? false;
  }

  @override
  Future<bool> isWechatInstalled() async {
    final result = await methodChannel.invokeMethod<bool>('isWechatInstalled');
    return result ?? false;
  }


  @override
  Future<bool> shareNetworkImage(String imageUrl) async {
    final result = await methodChannel.invokeMethod<bool>('shareNetworkImage', {'imageUrl': imageUrl});
    return result ?? false;
  }

  @override
  Future<bool> shareNetworkImageToScene(String imageUrl, int scene) async {
    final result = await methodChannel.invokeMethod<bool>('shareNetworkImageToScene', {'imageUrl': imageUrl, 'scene': scene});
    return result ?? false;
  }

  @override
  Future<Map<String, dynamic>?> wechatLogin() async {
    // Receive as a generic Map first, then perform a safe cast.
    final result = await methodChannel.invokeMethod<Map>('wechatLogin');
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<bool> shareText(String text) async {
    final result = await methodChannel.invokeMethod<bool>('shareText', {'text': text});
    return result ?? false;
  }

  @override
  Future<bool> shareLink({required String url, required String title, required String description}) async {
    final result = await methodChannel.invokeMethod<bool>('shareLink', {
      'url': url,
      'title': title,
      'description': description,
    });
    return result ?? false;
  }

  @override
  Future<bool> openMiniProgram({required String username, required String path, int miniProgramType = 0}) async {
    final result = await methodChannel.invokeMethod<bool>('openMiniProgram', {
      'username': username,
      'path': path,
      'miniProgramType': miniProgramType,
    });
    return result ?? false;
  }
}
