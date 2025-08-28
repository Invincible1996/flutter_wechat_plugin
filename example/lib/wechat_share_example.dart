import 'package:flutter/material.dart';
import 'package:flutter_wechat_plugin/flutter_wechat_plugin.dart';

class WechatShareExample extends StatelessWidget {
  final FlutterWechatPlugin _wechatPlugin = FlutterWechatPlugin();
  final String _imageUrl = 'https://picsum.photos/400/300';

  WechatShareExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('微信分享示例'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              _imageUrl,
              height: 200,
              width: 300,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _shareToSession(),
              child: const Text('分享到微信会话'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _shareToTimeline(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('分享到朋友圈'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _shareToFavorite(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('分享到微信收藏'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareToSession() async {
    try {
      bool result = await _wechatPlugin.shareNetworkImageToScene(_imageUrl, WechatScene.session);
      print('分享到微信会话: $result');
    } catch (e) {
      print('分享失败: $e');
    }
  }

  Future<void> _shareToTimeline() async {
    try {
      bool result = await _wechatPlugin.shareNetworkImageToScene(_imageUrl, WechatScene.timeline);
      print('分享到朋友圈: $result');
    } catch (e) {
      print('分享失败: $e');
    }
  }

  Future<void> _shareToFavorite() async {
    try {
      bool result = await _wechatPlugin.shareNetworkImageToScene(_imageUrl, WechatScene.favorite);
      print('分享到微信收藏: $result');
    } catch (e) {
      print('分享失败: $e');
    }
  }
}