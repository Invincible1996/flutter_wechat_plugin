import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_wechat_plugin/flutter_wechat_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _wechatStatus = 'Checking...';
  bool _isWechatInstalled = false;
  bool _isRegistered = false;
  final _flutterWechatPlugin = FlutterWechatPlugin();
  final String _appId = ''; // 请替换为您的微信AppID

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initWechat();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _flutterWechatPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> initWechat() async {
    try {
      print('Registering WeChat app with ID: $_appId');
      final registerResult = await _flutterWechatPlugin.registerApp(_appId);
      print('Registration result: $registerResult');

      final isInstalled = await _flutterWechatPlugin.isWechatInstalled();
      print('WeChat installed: $isInstalled');

      setState(() {
        _isRegistered = registerResult;
        _isWechatInstalled = isInstalled;
        if (!isInstalled) {
          _wechatStatus =
              'WeChat is not installed. Please install WeChat first.';
        } else if (!registerResult) {
          _wechatStatus =
              'WeChat registration failed. Please check your App ID.';
        } else {
          _wechatStatus = 'WeChat is ready to use!';
        }
      });
    } catch (e) {
      print('WeChat initialization error: $e');
      setState(() {
        _wechatStatus = 'Failed to initialize WeChat: $e';
      });
    }
  }

  Future<void> _wechatLogin() async {
    if (!_isWechatInstalled) {
      _showDialog('WeChat Not Available', 'Please install WeChat first.');
      return;
    }

    if (!_isRegistered) {
      _showDialog('WeChat Not Registered',
          'WeChat SDK registration failed. Please check your App ID.');
      return;
    }

    try {
      final result = await _flutterWechatPlugin.wechatLogin();
      if (result != null) {
        _showDialog('Login Success', 'Code: ${result['code']}');
      }
    } catch (e) {
      _showDialog('Login Failed', e.toString());
    }
  }

  Future<void> _shareText() async {
    if (!_isWechatInstalled) {
      _showDialog('WeChat Not Available', 'Please install WeChat first.');
      return;
    }

    if (!_isRegistered) {
      _showDialog('WeChat Not Registered',
          'WeChat SDK registration failed. Please check your App ID.');
      return;
    }

    try {
      final success = await _flutterWechatPlugin
          .shareText('Hello from Flutter WeChat Plugin!');
      _showDialog('Share Text', success ? 'Success' : 'Failed');
    } catch (e) {
      _showDialog('Share Text Failed', e.toString());
    }
  }

  Future<void> _shareLink() async {
    if (!_isWechatInstalled) {
      _showDialog('WeChat Not Available', 'Please install WeChat first.');
      return;
    }

    if (!_isRegistered) {
      _showDialog('WeChat Not Registered',
          'WeChat SDK registration failed. Please check your App ID.');
      return;
    }

    try {
      final success = await _flutterWechatPlugin.shareLink(
        url: 'https://flutter.dev',
        title: 'Flutter - Build apps for any screen',
        description: 'Flutter transforms the entire app development process.',
      );
      _showDialog('Share Link', success ? 'Success' : 'Failed');
    } catch (e) {
      _showDialog('Share Link Failed', e.toString());
    }
  }

  Future<void> _shareNetworkImage() async {
    if (!_isWechatInstalled) {
      _showDialog('WeChat Not Available', 'Please install WeChat first.');
      return;
    }

    if (!_isRegistered) {
      _showDialog('WeChat Not Registered',
          'WeChat SDK registration failed. Please check your App ID.');
      return;
    }

    // 保存context的引用
    final currentContext = context;

    // 显示加载对话框
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Downloading image...'),
            ],
          ),
        );
      },
    );

    try {
      const imageUrl = 'https://picsum.photos/400/300'; // 示例图片URL
      final success = await _flutterWechatPlugin.shareNetworkImage(imageUrl);

      // 检查context是否仍然有效
      if (mounted) {
        // 关闭加载对话框
        Navigator.of(currentContext).pop();

        _showDialog('Share Network Image', success ? 'Success' : 'Failed');
      }
    } catch (e) {
      // 检查context是否仍然有效
      if (mounted) {
        // 关闭加载对话框
        Navigator.of(currentContext).pop();
        _showDialog('Share Network Image Failed', e.toString());
      }
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('WeChat Plugin Example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Platform: $_platformVersion'),
                      const SizedBox(height: 8),
                      Text('App ID: $_appId'),
                      const SizedBox(height: 8),
                      Text(
                          'WeChat Installed: ${_isWechatInstalled ? 'Yes' : 'No'}'),
                      const SizedBox(height: 8),
                      Text('SDK Registered: ${_isRegistered ? 'Yes' : 'No'}'),
                      const SizedBox(height: 8),
                      Text('Status: $_wechatStatus'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _wechatStatus = 'Refreshing...';
                  });
                  initWechat();
                },
                child: const Text('Refresh WeChat Status'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed:
                    _isWechatInstalled && _isRegistered ? _wechatLogin : null,
                child: const Text('WeChat Login'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed:
                    _isWechatInstalled && _isRegistered ? _shareText : null,
                child: const Text('Share Text'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed:
                    _isWechatInstalled && _isRegistered ? _shareLink : null,
                child: const Text('Share Link'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isWechatInstalled && _isRegistered
                    ? _shareNetworkImage
                    : null,
                child: const Text('Share Network Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
