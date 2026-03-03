# 高德地图集成指南

本文档详细说明如何在WanderChina Flutter应用中配置和使用高德地图功能。

## 目录
1. [获取高德地图API Key](#1-获取高德地图api-key)
2. [Android配置](#2-android配置)
3. [iOS配置](#3-ios配置)
4. [权限配置](#4-权限配置)
5. [初始化地图服务](#5-初始化地图服务)
6. [常见问题](#6-常见问题)

---

## 1. 获取高德地图API Key

### 步骤 1.1: 注册高德开发者账号

1. 访问 [高德开放平台](https://lbs.amap.com/)
2. 点击右上角"注册"或"登录"
3. 完成账号注册流程

### 步骤 1.2: 创建应用

1. 登录后进入[控制台](https://console.amap.com/)
2. 点击"应用管理" → "我的应用"
3. 点击"创建新应用"
4. 填写应用信息：
   - 应用名称: `WanderChina`
   - 应用类型: 移动应用

### 步骤 1.3: 添加Key

#### Android Key:
1. 在应用下点击"添加Key"
2. 选择平台: `Android平台`
3. 填写以下信息：
   - Key名称: `WanderChina Android`
   - PackageName: `com.wanderchina.mobile_app` (与android/app/build.gradle中的applicationId一致)
   - SHA1安全码: 需要从Android Keystore获取

**获取SHA1安全码:**
```bash
# 调试版SHA1（开发用）
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# 发布版SHA1（正式发布用）
keytool -list -v -keystore /path/to/your/release.keystore -alias your_alias
```

#### iOS Key:
1. 再次点击"添加Key"
2. 选择平台: `iOS平台`
3. 填写以下信息：
   - Key名称: `WanderChina iOS`
   - Bundle ID: `com.wanderchina.mobileApp` (与ios/Runner.xcodeproj中的Bundle Identifier一致)

### 步骤 1.4: 获取并保存Key

创建完成后，你会得到两个API Key，将它们保存到配置文件中。

---

## 2. Android配置

### 步骤 2.1: 更新AndroidManifest.xml

打开 `android/app/src/main/AndroidManifest.xml`，在 `<application>` 标签内添加：

```xml
<application>
    ...

    <!-- 高德地图API Key -->
    <meta-data
        android:name="com.amap.api.v2.apikey"
        android:value="YOUR_ANDROID_API_KEY_HERE"/>

    <!-- 高德地图服务 -->
    <service android:name="com.amap.api.location.APSService"/>

    ...
</application>
```

### 步骤 2.2: 添加权限

在 `<manifest>` 标签内添加以下权限：

```xml
<!-- 定位权限 -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>

<!-- 网络权限 -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>

<!-- 存储权限（离线地图需要） -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

<!-- 其他权限 -->
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE"/>
```

### 步骤 2.3: 更新build.gradle

确保 `android/app/build.gradle` 中的 minSdkVersion >= 21:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
        ...
    }
}
```

---

## 3. iOS配置

### 步骤 3.1: 更新Info.plist

打开 `ios/Runner/Info.plist`，添加以下配置：

```xml
<!-- 高德地图API Key -->
<key>AMapApiKey</key>
<string>YOUR_IOS_API_KEY_HERE</string>

<!-- 定位权限描述 -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>WanderChina需要访问您的位置以提供地图和导航服务</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>WanderChina需要访问您的位置以提供实时定位和安全功能</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>WanderChina需要始终访问您的位置以提供位置共享和安全监控</string>

<!-- 后台定位模式 -->
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

### 步骤 3.2: 更新Podfile

打开 `ios/Podfile`，确保iOS版本 >= 10.0:

```ruby
platform :ios, '10.0'
```

### 步骤 3.3: 安装Pods

```bash
cd ios
pod install
cd ..
```

---

## 4. 权限配置

### 4.1 更新amap_config.dart

打开 `lib/core/config/amap_config.dart`，替换API Key:

```dart
class AMapConfig {
  // Android 平台 API Key
  static const String androidApiKey = 'YOUR_ANDROID_API_KEY_HERE'; // 替换为你的Android Key

  // iOS 平台 API Key
  static const String iosApiKey = 'YOUR_IOS_API_KEY_HERE'; // 替换为你的iOS Key

  ...
}
```

### 4.2 隐私合规

高德地图要求在使用前设置隐私合规信息。已在 `lib/services/amap_service.dart` 中实现：

```dart
// 设置隐私合规
await AMapFlutterLocation.updatePrivacyShow(true, true);
await AMapFlutterLocation.updatePrivacyAgree(true);
```

---

## 5. 初始化地图服务

### 5.1 在main.dart中初始化

在应用启动时初始化地图服务：

```dart
import 'package:flutter/material.dart';
import 'services/amap_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化高德地图服务
  try {
    await AMapService().initialize();
    print('✅ 高德地图初始化成功');
  } catch (e) {
    print('❌ 高德地图初始化失败: $e');
  }

  runApp(MyApp());
}
```

### 5.2 使用地图组件

```dart
import 'package:flutter/material.dart';
import 'screens/map/map_screen_new.dart';

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapScreenNew(), // 使用高德地图屏幕
    );
  }
}
```

---

## 6. 常见问题

### Q1: 地图显示空白

**可能原因:**
1. API Key未正确配置
2. 网络连接问题
3. SHA1安全码不匹配（Android）

**解决方法:**
1. 检查 `amap_config.dart` 中的API Key是否正确
2. 确认SHA1安全码与高德控制台配置一致
3. 查看控制台日志排查错误

### Q2: 定位失败

**可能原因:**
1. 未授予定位权限
2. GPS未开启
3. 网络问题

**解决方法:**
1. 在设置中授予应用定位权限
2. 开启设备GPS
3. 检查网络连接

### Q3: iOS编译失败

**可能原因:**
1. Pod依赖未安装
2. Info.plist配置错误

**解决方法:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

### Q4: Android编译失败

**可能原因:**
1. minSdkVersion过低
2. AndroidManifest.xml配置错误

**解决方法:**
1. 确保 minSdkVersion >= 21
2. 检查AndroidManifest.xml中的配置

### Q5: 离线地图下载失败

**可能原因:**
1. 存储空间不足
2. 网络不稳定
3. 权限未授予

**解决方法:**
1. 清理设备存储空间
2. 使用稳定的WiFi网络
3. 授予存储权限

---

## 7. 功能清单

已实现的功能：

- ✅ 地图显示（标准、卫星、夜间模式）
- ✅ 地图缩放、平移、旋转
- ✅ 当前定位
- ✅ POI标记
- ✅ 交通路况显示
- ✅ 离线地图管理
- ⏳ POI搜索（待对接API）
- ⏳ 路线规划（待实现）
- ⏳ 导航功能（待实现）

---

## 8. 下一步

1. 获取高德地图API Key
2. 按照本指南配置Android和iOS
3. 更新 `amap_config.dart` 中的API Key
4. 运行应用测试地图功能
5. 根据需求集成更多功能（POI搜索、路线规划等）

---

## 9. 参考资料

- [高德地图官方文档](https://lbs.amap.com/api/flutter/summary)
- [高德地图Flutter SDK](https://pub.dev/packages/amap_flutter_map)
- [高德开放平台控制台](https://console.amap.com/)
- [高德地图API使用条款](https://lbs.amap.com/home/terms/)

---

**版本:** 1.0
**最后更新:** 2026-01-15
**维护者:** WanderChina开发团队
