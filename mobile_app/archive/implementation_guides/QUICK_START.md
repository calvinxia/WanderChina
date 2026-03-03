# 🚀 WanderChina 高德地图 - 快速启动指南

## ✅ 配置状态

**配置完成时间:** 2026-01-15
**状态:** 已完成并可运行

---

## 📋 已完成的配置

### ✅ API密钥配置
- **Android Key:** `fa66ce758292ed0b754f373f0ecb370f`
- **iOS Key:** `e6524a7df464c06bb9a399942a9abd0e`

### ✅ 平台配置
- Android: AndroidManifest.xml ✅
- iOS: Info.plist ✅
- Dart: amap_config.dart ✅

### ✅ 依赖安装
- Flutter依赖包: ✅ 已安装
  - amap_flutter_base 3.0.0
  - amap_flutter_location 3.0.0
  - amap_flutter_map 3.0.0

---

## 🎯 立即运行

### 方法1: Android设备/模拟器

```bash
cd "/Users/calvinxia/Desktop/China Travel/WanderChina/mobile_app"

# 查看可用设备
~/flutter/bin/flutter devices

# 运行应用
~/flutter/bin/flutter run
```

### 方法2: iOS设备/模拟器（需要先安装Pod）

```bash
cd "/Users/calvinxia/Desktop/China Travel/WanderChina/mobile_app"

# 安装iOS依赖
cd ios
pod install
cd ..

# 运行应用
~/flutter/bin/flutter run -d ios
```

### 方法3: 使用Android Studio / VS Code

1. 打开项目文件夹: `/Users/calvinxia/Desktop/China Travel/WanderChina/mobile_app`
2. 选择设备/模拟器
3. 点击运行按钮 ▶️

---

## 🔍 验证配置

运行应用后，检查控制台输出：

### 成功的标志 ✅

```
✅ 高德地图SDK初始化成功
📍 Android Key: fa66ce758...
📍 iOS Key: e6524a7df...
✅ 地图服务初始化成功
✅ 地图创建成功
```

### 如果看到错误 ❌

```
❌ 高德地图SDK初始化失败
```

**解决方法:**
1. 确认网络连接正常
2. 检查API Key是否正确
3. 查看详细错误日志
4. 参考 `CONFIGURATION_COMPLETE.md` 进行故障排除

---

## 📱 测试功能

### 1. 打开地图屏幕
- 从主屏幕导航到地图功能
- 应该能看到地图正常加载

### 2. 测试定位
- 点击右上角的定位按钮（蓝色）
- 应该看到定位动画
- 地图会移动到当前位置
- 显示蓝色定位标记

### 3. 测试地图交互
- 双指缩放地图 ✅
- 单指平移地图 ✅
- 双指旋转地图 ✅

### 4. 切换地图类型
- 点击"图层"按钮
- 地图应该在标准/卫星/夜间模式间切换

### 5. 显示交通
- 点击"交通"按钮
- 地图应该显示实时路况

---

## 🔧 常用命令

### 清理并重新构建

```bash
cd "/Users/calvinxia/Desktop/China Travel/WanderChina/mobile_app"

# 清理缓存
~/flutter/bin/flutter clean

# 重新获取依赖
~/flutter/bin/flutter pub get

# iOS需要重新安装Pod
cd ios && pod install && cd ..

# 运行
~/flutter/bin/flutter run
```

### 查看设备列表

```bash
~/flutter/bin/flutter devices
```

### 运行在特定设备

```bash
~/flutter/bin/flutter run -d <device-id>
```

### 查看日志

```bash
~/flutter/bin/flutter logs
```

### 构建APK（Android）

```bash
~/flutter/bin/flutter build apk --release
```

### 构建IPA（iOS）

```bash
~/flutter/bin/flutter build ios --release
```

---

## 📂 项目结构

```
mobile_app/
├── lib/
│   ├── core/
│   │   └── config/
│   │       └── amap_config.dart          ✅ API配置
│   ├── models/
│   │   └── poi.dart                       ✅ POI模型
│   ├── services/
│   │   ├── amap_service.dart             ✅ 地图服务
│   │   ├── poi_service.dart              ✅ POI服务
│   │   ├── offline_map_service.dart      ✅ 离线地图
│   │   └── route_planning_service.dart   ✅ 路线规划
│   ├── widgets/
│   │   └── map/
│   │       └── amap_widget.dart          ✅ 地图组件
│   ├── screens/
│   │   └── map/
│   │       └── map_screen_new.dart       ✅ 地图屏幕
│   └── main.dart                          ✅ 入口文件
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml            ✅ Android配置
├── ios/
│   └── Runner/
│       └── Info.plist                     ✅ iOS配置
└── pubspec.yaml                           ✅ 依赖配置
```

---

## 🎨 可用功能

### 已实现 ✅
- [x] 地图显示（标准/卫星/夜间）
- [x] 地图交互（缩放/平移/旋转）
- [x] 当前定位
- [x] POI标记
- [x] 交通路况
- [x] 离线地图管理（框架）
- [x] POI搜索（框架）
- [x] 路线规划（框架）

### 需要API对接 ⚠️
- [ ] 真实POI搜索数据
- [ ] 离线地图下载
- [ ] 实时路线规划
- [ ] 导航功能

---

## 💡 提示

### 权限授予
首次运行时，务必授予以下权限：
- ✅ 位置权限（允许始终访问或使用时访问）
- ✅ 存储权限（用于离线地图）

### 最佳测试环境
- 使用真实设备（定位更准确）
- 在室外空旷环境（GPS信号好）
- 连接WiFi或移动网络（在线功能需要）

### 性能优化
- 地图首次加载可能需要几秒
- 定位首次获取可能需要10-30秒
- 使用WiFi下载离线地图更快

---

## 📚 相关文档

- **配置详情:** `CONFIGURATION_COMPLETE.md`
- **功能总结:** `AMAP_FEATURE_SUMMARY.md`
- **配置指南:** `AMAP_SETUP_GUIDE.md`

---

## 🆘 需要帮助？

### 常见问题
1. **地图不显示** → 检查网络和API Key
2. **定位失败** → 检查权限和GPS
3. **编译错误** → 运行 `flutter clean`

### 技术支持
- 高德开放平台: https://lbs.amap.com/
- Flutter文档: https://flutter.dev/
- 项目Issue: 查看项目文档

---

**准备好了吗？现在就运行应用吧！** 🚀

```bash
~/flutter/bin/flutter run
```
