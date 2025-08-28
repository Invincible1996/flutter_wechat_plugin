import 'package:flutter/material.dart';
import 'package:flutter_wechat_plugin/flutter_wechat_plugin.dart';

/// Example demonstrating the usage of WechatUtil class
class WechatUtilExample extends StatefulWidget {
  const WechatUtilExample({Key? key}) : super(key: key);

  @override
  State<WechatUtilExample> createState() => _WechatUtilExampleState();
}

class _WechatUtilExampleState extends State<WechatUtilExample> {
  String _status = 'Ready';
  bool _isWechatInstalled = false;

  @override
  void initState() {
    super.initState();
    _checkWechatStatus();
  }

  Future<void> _checkWechatStatus() async {
    try {
      final isInstalled = await WechatUtil.isWechatInstalled();
      setState(() {
        _isWechatInstalled = isInstalled;
        _status = isInstalled ? 'WeChat is installed' : 'WeChat not installed';
      });
    } catch (e) {
      setState(() {
        _status = 'Error checking WeChat status: $e';
      });
    }
  }

  Future<void> _performWechatLogin() async {
    if (!_isWechatInstalled) {
      _showDialog('WeChat Not Available', 'Please install WeChat first.');
      return;
    }

    setState(() {
      _status = 'Logging in...';
    });

    try {
      final result = await WechatUtil.wechatLogin();
      if (result != null) {
        String loginInfo = 'Login Success!\n';
        loginInfo += 'Authorization Code: ${result['code'] ?? 'N/A'}\n';
        loginInfo += 'State: ${result['state'] ?? 'N/A'}\n';
        loginInfo += 'Language: ${result['lang'] ?? 'N/A'}\n';
        loginInfo += 'Country: ${result['country'] ?? 'N/A'}';
        
        setState(() {
          _status = 'Login successful';
        });
        _showDialog('WeChat Login Success', loginInfo);
      } else {
        setState(() {
          _status = 'Login failed - no result';
        });
        _showDialog('Login Failed', 'No result returned from WeChat login.');
      }
    } catch (e) {
      String errorMessage = 'Login failed: ';
      if (e.toString().contains('USER_CANCELLED')) {
        errorMessage += 'User cancelled the login process.';
        setState(() {
          _status = 'Login cancelled by user';
        });
      } else if (e.toString().contains('AUTH_DENIED')) {
        errorMessage += 'User denied authorization.';
        setState(() {
          _status = 'Authorization denied';
        });
      } else if (e.toString().contains('WECHAT_NOT_INSTALLED')) {
        errorMessage += 'WeChat is not installed.';
        setState(() {
          _status = 'WeChat not installed';
        });
      } else {
        errorMessage += e.toString();
        setState(() {
          _status = 'Login error';
        });
      }
      _showDialog('Login Failed', errorMessage);
    }
  }

  Future<void> _shareToSession() async {
    if (!_isWechatInstalled) {
      _showDialog('WeChat Not Available', 'Please install WeChat first.');
      return;
    }

    try {
      final success = await WechatUtil.shareNetworkImage(
          'https://picsum.photos/400/300');
      _showDialog('Share to Session', success ? 'Success' : 'Failed');
    } catch (e) {
      _showDialog('Share Failed', e.toString());
    }
  }

  Future<void> _shareToTimeline() async {
    if (!_isWechatInstalled) {
      _showDialog('WeChat Not Available', 'Please install WeChat first.');
      return;
    }

    try {
      final success = await WechatUtil.shareNetworkImageToTimeline(
          'https://picsum.photos/400/300');
      _showDialog('Share to Timeline', success ? 'Success' : 'Failed');
    } catch (e) {
      _showDialog('Share Failed', e.toString());
    }
  }

  Future<void> _shareText() async {
    if (!_isWechatInstalled) {
      _showDialog('WeChat Not Available', 'Please install WeChat first.');
      return;
    }

    try {
      final success = await WechatUtil.shareText(
          'Hello from WechatUtil! This is a test message.');
      _showDialog('Share Text', success ? 'Success' : 'Failed');
    } catch (e) {
      _showDialog('Share Failed', e.toString());
    }
  }

  Future<void> _shareLink() async {
    if (!_isWechatInstalled) {
      _showDialog('WeChat Not Available', 'Please install WeChat first.');
      return;
    }

    try {
      final success = await WechatUtil.shareLink(
        url: 'https://flutter.dev',
        title: 'Flutter - Build apps for any screen',
        description: 'Flutter transforms the app development process.',
      );
      _showDialog('Share Link', success ? 'Success' : 'Failed');
    } catch (e) {
      _showDialog('Share Failed', e.toString());
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('WechatUtil Example'),
        backgroundColor: Colors.green,
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
                    const Text(
                      'WechatUtil Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('WeChat Installed: ${_isWechatInstalled ? 'Yes' : 'No'}'),
                    const SizedBox(height: 8),
                    Text('Status: $_status'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkWechatStatus,
              child: const Text('Refresh WeChat Status'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isWechatInstalled ? _performWechatLogin : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('WeChat Login (WechatUtil)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isWechatInstalled ? _shareText : null,
              child: const Text('Share Text (WechatUtil)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isWechatInstalled ? _shareLink : null,
              child: const Text('Share Link (WechatUtil)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isWechatInstalled ? _shareToSession : null,
              child: const Text('Share Image to Session (WechatUtil)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isWechatInstalled ? _shareToTimeline : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Share Image to Timeline (WechatUtil)'),
            ),
          ],
        ),
      ),
    );
  }
}