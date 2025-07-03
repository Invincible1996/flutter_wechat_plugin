# Flutter WeChat Plugin

一个功能完整的Flutter微信SDK插件，支持微信登录和多种分享功能。

## 功能特性

- ✅ 微信登录
- ✅ 分享文本到微信
- ✅ 分享本地图片到微信
- ✅ 分享网络图片到微信
- ✅ 分享链接到微信
- ✅ 检测微信是否安装
- ✅ 支持Android和iOS平台

## 安装

在 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  flutter_wechat_plugin:
    path: ../  # 或者发布到pub.dev后使用版本号
```

然后运行：

```bash
flutter pub get
```

## 配置

### 1. 获取微信AppID

首先需要在[微信开放平台](https://open.weixin.qq.com/)注册应用并获取AppID。

### 2. Android配置

#### 添加权限
在 `android/app/src/main/AndroidManifest.xml` 中添加必要权限：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- Android 11+ package visibility -->
<queries>
  <package android:name="com.tencent.mm" />
</queries>
```

#### 配置应用签名
在微信开放平台配置你的应用包名和签名。

### 3. iOS配置

#### 配置URL Scheme
在 `ios/Runner/Info.plist` 中添加URL Scheme：

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>weixin</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>your_wechat_app_id</string>
    </array>
  </dict>
</array>
```

#### 配置LSApplicationQueriesSchemes
在 `ios/Runner/Info.plist` 中添加：

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>weixin</string>
  <string>weixinULAPI</string>
</array>
```

## 使用方法

### 初始化

```dart
import 'package:flutter_wechat_plugin/flutter_wechat_plugin.dart';

final _flutterWechatPlugin = FlutterWechatPlugin();
final String _appId = 'your_wechat_app_id';

// 注册微信应用
await _flutterWechatPlugin.registerApp(_appId);

// 检查微信是否安装
final isInstalled = await _flutterWechatPlugin.isWechatInstalled();
```

### 微信登录

```dart
try {
  final result = await _flutterWechatPlugin.wechatLogin();
  if (result != null) {
    String code = result['code'];
    String state = result['state'];
    // 使用code到你的服务器换取access_token
    print('Login success, code: $code');
  }
} catch (e) {
  print('Login failed: $e');
}
```

### 分享文本

```dart
try {
  final success = await _flutterWechatPlugin.shareText('Hello from Flutter!');
  print('Share text: ${success ? 'Success' : 'Failed'}');
} catch (e) {
  print('Share text failed: $e');
}
```

### 分享本地图片

```dart
try {
  final success = await _flutterWechatPlugin.shareImage('/path/to/image.jpg');
  print('Share image: ${success ? 'Success' : 'Failed'}');
} catch (e) {
  print('Share image failed: $e');
}
```

### 分享网络图片

```dart
try {
  final success = await _flutterWechatPlugin.shareNetworkImage('https://example.com/image.jpg');
  print('Share network image: ${success ? 'Success' : 'Failed'}');
} catch (e) {
  print('Share network image failed: $e');
}
```

### 分享链接

```dart
try {
  final success = await _flutterWechatPlugin.shareLink(
    url: 'https://flutter.dev',
    title: 'Flutter - Build apps for any screen',
    description: 'Flutter transforms the entire app development process.',
    thumbnailPath: '/path/to/thumbnail.jpg', // 可选
  );
  print('Share link: ${success ? 'Success' : 'Failed'}');
} catch (e) {
  print('Share link failed: $e');
}
```

## API参考

### 方法

| 方法 | 描述 | 参数 | 返回值 |
|------|------|------|--------|
| `registerApp(String appId)` | 注册微信应用 | appId: 微信AppID | `Future<bool>` |
| `isWechatInstalled()` | 检查微信是否安装 | 无 | `Future<bool>` |
| `wechatLogin()` | 微信登录 | 无 | `Future<Map<String, dynamic>?>` |
| `shareText(String text)` | 分享文本 | text: 要分享的文本 | `Future<bool>` |
| `shareImage(String imagePath)` | 分享本地图片 | imagePath: 本地图片路径 | `Future<bool>` |
| `shareNetworkImage(String imageUrl)` | 分享网络图片 | imageUrl: 网络图片URL | `Future<bool>` |
| `shareLink({...})` | 分享链接 | url, title, description?, thumbnailPath? | `Future<bool>` |

### 登录返回数据

```dart
{
  'code': String,     // 授权码，用于换取access_token
  'state': String,    // 自定义状态值
  'lang': String,     // 语言
  'country': String   // 国家
}
```

## 注意事项

1. **网络权限**: 确保应用有网络访问权限，网络图片分享需要下载图片。

2. **图片格式**: 支持常见的图片格式（JPEG、PNG等）。

3. **图片大小**: 微信对分享的图片大小有限制，过大的图片可能分享失败。

4. **缩略图**: 分享链接时建议提供缩略图以获得更好的显示效果。

5. **错误处理**: 建议使用try-catch包装API调用以处理可能的异常。

6. **平台差异**: Android和iOS在某些细节上可能有不同的行为。

## 示例应用

查看 `example/` 目录下的完整示例应用，演示了所有功能的使用方法。

运行示例：

```bash
cd example
flutter run
```

## 常见问题

### Q: 提示"WeChat is not installed"
A: 
1. 确保设备上已安装微信应用
2. 检查Android的package visibility权限配置
3. 查看控制台日志获取更多调试信息

### Q: 登录或分享失败
A:
1. 确认AppID配置正确
2. 检查应用签名是否与微信开放平台配置一致
3. 确保网络连接正常

### Q: iOS分享失败
A:
1. 检查URL Scheme配置
2. 确认Info.plist中的配置正确
3. 检查Universal Link配置（如果使用）

## 开发者

如需贡献代码或报告问题，请访问项目仓库。

## 许可证

本项目采用 MIT 许可证。