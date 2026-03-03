# 地图翻译蒙层实施总结

## ✅ 已完成工作（2026-02-14）

### 1. 数据模型
**文件**: `lib/models/poi_translation.dart`
- ✅ POITranslation类（存储POI多语言翻译）
- ✅ TranslationSource枚举（database/deepseek/manual/fallback）
- ✅ AppLanguage枚举（English/French/Spanish）
- ✅ OverlayLabel类（翻译标签的屏幕位置信息）

### 2. 核心服务

#### 2.1 POI翻译服务
**文件**: `lib/services/map/poi_translation_service.dart`
- ✅ 三级缓存机制：内存 → PostgreSQL → DeepSeek API
- ✅ 预加载6个城市的核心POI（景点、博物馆、地铁站等）
- ✅ 批量翻译未缓存的POI
- ✅ 自动保存新翻译到数据库

#### 2.2 语音翻译服务
**文件**: `lib/services/voice/voice_translation_service.dart`
- ✅ 完整语音翻译链路：百度ASR → DeepSeek → 百度TTS
- ✅ 双向翻译支持（外语↔中文）
- ✅ 五种状态管理（idle/recording/processing/playing/error）
- ✅ 自动Token刷新（百度API）
- ✅ 历史记录存储

### 3. UI组件

#### 3.1 翻译蒙层组件
**文件**: `lib/widgets/map/translation_overlay_widget.dart`
- ✅ 三种标签样式：
  - **Badge**: 徽章样式，带指示箭头
  - **Minimal**: 简约文字，白色阴影
  - **Floating**: 浮动卡片，渐变背景
- ✅ 高优先级POI橙色标签（景点、博物馆等）
- ✅ 防抖更新机制（300ms）
- ✅ 去重逻辑（标签间距≥80px）
- ✅ 缩放级别控制（zoom ≥ 14.0才显示）

#### 3.2 语音按钮组件
**文件**: `lib/widgets/map/voice_translation_overlay.dart`
- ✅ 悬浮圆形按钮（64×64px）
- ✅ 五种视觉状态（颜色+图标变化）
- ✅ 录音中脉冲动画
- ✅ 方向切换chip（EN→中 / 中→EN）
- ✅ 翻译结果气泡展示
- ✅ 底部位置自适应（safe area + 90px）

#### 3.3 主地图组件
**文件**: `lib/widgets/map/wander_map.dart`
- ✅ 整合高德地图 + 翻译蒙层 + 语音按钮
- ✅ 自动防抖刷新机制
- ✅ 公开接口：moveTo / addSearchMarker / clearSearchMarkers
- ✅ 配置化设计（语言、样式、开关等）

### 4. 配置更新

#### 4.1 依赖包（pubspec.yaml）
- ✅ 添加 `record: ^5.1.2`（录音）
- ✅ 添加 `audioplayers: ^6.0.0`（音频播放）
- ✅ 添加 `http: ^1.1.0`（网络请求）
- ✅ 运行 `flutter pub get` 成功

#### 4.2 后端配置（lib/core/config/backend_config.dart）
- ✅ 添加 `deepseekApiKey`（翻译）
- ✅ 添加 `baiduApiKey` 和 `baiduSecretKey`（语音）

---

## ⚠️ 待完成工作

### 1. 数据库部署
**优先级：高**

在腾讯云PostgreSQL执行：

```sql
-- 创建表
CREATE TABLE IF NOT EXISTS poi_translations (
  id              SERIAL PRIMARY KEY,
  gaode_poi_id    TEXT NOT NULL UNIQUE,
  name_zh         TEXT NOT NULL,
  name_en         TEXT NOT NULL,
  name_fr         TEXT,
  name_es         TEXT,
  category_en     TEXT,
  city            TEXT NOT NULL,
  lat             DECIMAL(10, 8) NOT NULL,
  lng             DECIMAL(11, 8) NOT NULL,
  source          TEXT DEFAULT 'database',
  priority_score  INT DEFAULT 0,
  cached_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_poi_city ON poi_translations(city);
CREATE INDEX idx_poi_priority ON poi_translations(priority_score DESC);
```

**种子数据**: 参见 `TRANSLATION_OVERLAY_IMPLEMENTATION_GUIDE.md` 或 `docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md` 第6节

### 2. iOS权限配置
**文件**: `ios/Runner/Info.plist`

添加麦克风权限：
```xml
<key>NSMicrophoneUsageDescription</key>
<string>WanderChina需要麦克风权限用于语音翻译</string>
```

### 3. API密钥申请

#### 百度语音API
- 访问：https://ai.baidu.com
- 开通"语音识别"和"语音合成"
- 获取 `API Key` 和 `Secret Key`
- 免费额度：ASR 50万次/天，TTS 100万次/天

#### DeepSeek API
- 访问：https://platform.deepseek.com
- 创建API密钥
- 成本：~0.002元/1000 tokens

### 4. main.dart服务初始化
**文件**: `lib/main.dart`

添加新服务初始化：
```dart
await Future.wait([
  LanguageManager().initialize(),
  AMapService().initialize(),
  POITranslationService().initialize(),      // ✅ 已存在
  MapTranslationService().initialize(),      // ✅ 已存在（路线翻译）
  POITranslationService().initialize(),      // 🆕 新增（POI翻译）
  VoiceTranslationService().initialize(),    // 🆕 新增（语音翻译）
  // ... 其他服务
], eagerError: false);
```

### 5. 高德地图API集成
**优先级：中**

**问题**: `wander_map.dart`中使用的AMap API方法可能不存在：
- `mapController.convertCoordinate()`（translation_overlay_widget.dart:92）
- `mapController.getVisibleRegion()`（wander_map.dart:95）
- `mapController.dispose()`（wander_map.dart:171）

**解决方案**: 需要查阅当前安装的 `amap_flutter_map: ^3.0.0` 的实际API文档，替换为正确方法：
- 屏幕坐标转换方法
- 获取地图可视区域方法
- POI周边搜索API（AMapPOISearch或类似）

### 6. 环境变量配置
**运行时传递API密钥**：

```bash
flutter run --dart-define=DEEPSEEK_API_KEY=sk-xxx \
           --dart-define=BAIDU_API_KEY=xxx \
           --dart-define=BAIDU_SECRET_KEY=xxx \
           --dart-define=DB_HOST=xxx \
           --dart-define=DB_PASSWORD=xxx
```

或创建 `.env` 文件并在构建时加载。

---

## 📋 使用示例

### 基础用法
```dart
import 'package:wanderchina/widgets/map/wander_map.dart';
import 'package:wanderchina/models/poi_translation.dart';

WanderMap(
  initialCenter: LatLng(39.9042, 116.4074), // 天安门
  initialZoom: 15.0,
  language: AppLanguage.english,
  labelStyle: LabelStyle.badge,
  showTranslationOverlay: true,
  showVoiceButton: true,
  onMapTap: (latLng) => print('Tapped: $latLng'),
)
```

### 进阶用法
```dart
final mapKey = GlobalKey<WanderMapState>();

WanderMap(
  key: mapKey,
  initialCenter: LatLng(31.2304, 121.4737), // 上海外滩
  initialZoom: 16.0,
  language: AppLanguage.french,
  labelStyle: LabelStyle.floating,
  showTranslationOverlay: true,
  showVoiceButton: true,
)

// 编程式控制
mapKey.currentState?.moveTo(LatLng(39.9042, 116.4074), zoom: 14.0);
mapKey.currentState?.addSearchMarker(poiTranslation);
mapKey.currentState?.clearSearchMarkers();
```

---

## 🔑 技术要点

### 架构设计
- **分层架构**: Model → Service → Widget
- **依赖注入**: 单例模式（Singleton）
- **状态管理**: ChangeNotifier（语音服务）
- **性能优化**: 三级缓存、防抖、去重

### API集成
- **DeepSeek**: JSON模式输出，temperature=0.1（高确定性）
- **百度ASR**: dev_pid区分语言（1537中文/1737英文/1836法文/1936西班牙文）
- **百度TTS**: 返回200不一定成功，需检查content-type是否为audio/*
- **PostgreSQL**: ON CONFLICT处理幂等性

### UI设计规范
- **颜色**:
  - 主题橙：#FF6B35
  - 高优先级：#E6FF6B35（90%透明度）
  - 普通标签：#E6FFFFFF
- **尺寸**:
  - 语音按钮：64×64px
  - 标签字体：10px（badge）/ 9px（minimal）/ 11px（floating）
  - 最小间距：80px（去重距离）

---

## ⚡ 下一步行动

1. **数据库初始化**（10分钟）
   - 执行建表SQL
   - 插入18条种子数据（6城市核心景点）

2. **申请API密钥**（30分钟）
   - 百度AI开放平台注册
   - DeepSeek平台注册

3. **修复AMap API调用**（1小时）
   - 查阅amap_flutter_map文档
   - 替换不兼容的方法调用
   - 集成POI搜索API

4. **添加服务初始化**（5分钟）
   - 修改main.dart

5. **iOS权限配置**（5分钟）
   - 添加麦克风权限描述

6. **测试运行**（30分钟）
   - 配置环境变量
   - flutter run测试
   - 验证翻译功能
   - 验证语音功能

---

## 📚 参考文档

- **完整规范**: `/docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md`
- **实施指南**: `TRANSLATION_OVERLAY_IMPLEMENTATION_GUIDE.md`
- **UI设计**: `/docs/design/SCREEN_SPECIFICATIONS_v2.md`
- **高德地图文档**: https://lbs.amap.com/api/flutter/summary
- **百度语音文档**: https://ai.baidu.com/ai-doc/SPEECH/overview

---

**创建时间**: 2026-02-14
**状态**: 核心代码已完成 ✅，待集成测试 🔄
