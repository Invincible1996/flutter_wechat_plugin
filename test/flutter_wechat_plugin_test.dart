import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wechat_plugin/flutter_wechat_plugin.dart';
import 'package:flutter_wechat_plugin/flutter_wechat_plugin_platform_interface.dart';
import 'package:flutter_wechat_plugin/flutter_wechat_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterWechatPluginPlatform
    with MockPlatformInterfaceMixin
    implements FlutterWechatPluginPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> isWechatInstalled() {
    // TODO: implement isWechatInstalled
    throw UnimplementedError();
  }

  Future<bool> shareImage(String imagePath) {
    // TODO: implement shareImage
    throw UnimplementedError();
  }

  @override
  Future<bool> shareLink(
      {required String url,
      required String title,
      String? description,
      String? thumbnailPath}) {
    // TODO: implement shareLink
    throw UnimplementedError();
  }

  @override
  Future<bool> shareText(String text) {
    // TODO: implement shareText
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> wechatLogin() {
    // TODO: implement wechatLogin
    throw UnimplementedError();
  }

  @override
  Future<bool> shareNetworkImage(String imageUrl) {
    // TODO: implement shareNetworkImage
    throw UnimplementedError();
  }

  @override
  Future<bool> shareNetworkImageToScene(String imageUrl, int scene) {
    // TODO: implement shareNetworkImageToScene
    throw UnimplementedError();
  }

  @override
  Future<bool> registerApp(
      {required String appId, required String universalLink}) {
    // TODO: implement registerApp
    throw UnimplementedError();
  }

  @override
  Future<bool> openMiniProgram(
      {required String username, String? path, int miniProgramType = 0}) {
    // TODO: implement openMiniProgram
    throw UnimplementedError();
  }
}

void main() {
  final FlutterWechatPluginPlatform initialPlatform =
      FlutterWechatPluginPlatform.instance;

  test('$MethodChannelFlutterWechatPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterWechatPlugin>());
  });

  test('getPlatformVersion', () async {
    FlutterWechatPlugin flutterWechatPlugin = FlutterWechatPlugin();
    MockFlutterWechatPluginPlatform fakePlatform =
        MockFlutterWechatPluginPlatform();
    FlutterWechatPluginPlatform.instance = fakePlatform;

    expect(await flutterWechatPlugin.getPlatformVersion(), '42');
  });
}
