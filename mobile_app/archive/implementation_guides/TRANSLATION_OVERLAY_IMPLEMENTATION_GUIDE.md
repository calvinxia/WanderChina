# 地图翻译蒙层实施指南

## ✅ 已完成工作

### 1. 数据模型（已创建）
- ✅ `/lib/models/poi_translation.dart`
  - POITranslation 类：存储POI翻译数据
  - TranslationSource 枚举：标记翻译来源（database/deepseek/manual/fallback）
  - AppLanguage 枚举：支持的语言（English/French/Spanish）
  - OverlayLabel 类：翻译标签的屏幕位置信息

## 📋 待实施步骤

### 步骤1：添加依赖包
在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  # 录音
  record: ^5.1.2

  # 音频播放（TTS结果）
  audioplayers: ^6.0.0

  # 确认已有以下依赖
  http: ^1.1.0
  postgres: ^2.6.2 # 或当前版本
  path_provider: ^2.1.1
```

### 步骤2：配置权限

**iOS** (`ios/Runner/Info.plist`)：
```xml
<!-- 麦克风权限 -->
<key>NSMicrophoneUsageDescription</key>
<string>WanderChina需要麦克风权限用于语音翻译</string>
```

**Android** (`android/app/src/main/AndroidManifest.xml`)：
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### 步骤3：创建核心服务

#### 3.1 地图翻译服务
创建 `/lib/services/map/map_translation_service.dart`
- 三级缓存：内存 → PostgreSQL → DeepSeek实时翻译
- 预加载核心POI（景点、地铁站、交通枢纽）
- 批量翻译未缓存的POI

**完整代码见：** `/docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md` 第7.2节

#### 3.2 语音翻译服务
创建 `/lib/services/voice/voice_translation_service.dart`
- 百度ASR语音识别
- DeepSeek文本翻译
- 百度TTS语音合成
- 支持双向翻译（外语↔中文）

**完整代码见：** `/docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md` 第7.3节

### 步骤4：创建UI组件

#### 4.1 翻译蒙层组件
创建 `/lib/widgets/map/translation_overlay_widget.dart`
- 三种标签样式：Badge（徽章）/ Minimal（简约）/ Floating（浮动）
- 高优先级POI橙色标签（景点、博物馆、地铁站）
- 防抖更新（地图停止移动300ms后刷新）
- 去重逻辑（标签间距≥80px）

**完整代码见：** `/docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md` 第7.4节

#### 4.2 语音按钮组件
创建 `/lib/widgets/map/voice_translation_overlay.dart`
- 悬浮按钮（位于右下角，导航栏上方90px）
- 五种状态：Idle / Recording / Processing / Playing / Error
- 脉冲动画（录音中）
- 方向切换pill（EN→中 / 中→EN）
- 翻译结果气泡

**完整代码见：** `/docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md` 第7.5节

#### 4.3 主地图组件
创建 `/lib/widgets/map/wander_map.dart`
- 整合高德地图 + 翻译蒙层 + 语音按钮
- 自动获取视窗内POI（使用高德周边搜索）
- 公开接口：moveTo / addSearchMarker / clearSearchMarkers

**完整代码见：** `/docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md` 第7.6节

### 步骤5：数据库初始化

在腾讯云PostgreSQL执行：
```sql
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

-- 索引
CREATE INDEX idx_poi_city ON poi_translations(city);
CREATE INDEX idx_poi_priority ON poi_translations(priority_score DESC);
```

**完整建表SQL和种子数据见：** `/docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md` 第6节

### 步骤6：环境变量配置

在 `lib/core/config/env_config.dart` 添加：
```dart
class EnvConfig {
  // 百度语音API（在 https://ai.baidu.com 申请）
  static const String baiduApiKey = String.fromEnvironment(
    'BAIDU_API_KEY',
    defaultValue: '',
  );
  static const String baiduSecretKey = String.fromEnvironment(
    'BAIDU_SECRET_KEY',
    defaultValue: '',
  );

  // DeepSeek（应已存在）
  static const String deepseekApiKey = String.fromEnvironment(
    'DEEPSEEK_API_KEY',
    defaultValue: '',
  );
}
```

### 步骤7：main.dart初始化

在 `main.dart` 的服务初始化部分添加：
```dart
await Future.wait([
  LanguageManager().initialize(),
  AMapService().initialize(),
  POITranslationService().initialize(),
  MapTranslationService().initialize(),   // 新增
  VoiceTranslationService().initialize(), // 新增
  // ... 其他服务
], eagerError: false);
```

### 步骤8：使用示例

在任意页面中使用：
```dart
import '../widgets/map/wander_map.dart';
import '../models/poi_translation.dart';

// 北京地图（带翻译）
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

## 🔑 关键API密钥申请

### 1. 百度语音（语音翻译必需）
- 访问：https://ai.baidu.com
- 开通"语音技术" → "语音识别"和"语音合成"
- 获取 `API Key` 和 `Secret Key`
- 免费额度：ASR 50万次/天，TTS 100万次/天

### 2. DeepSeek（实时翻译）
- 访问：https://platform.deepseek.com
- 创建API密钥
- 成本：~0.002元/1000 tokens

### 3. 腾讯云PostgreSQL
- 已配置：使用现有数据库连接
- 确认 `lib/core/config/database_config.dart` 配置正确

## 📱 UI设计规范

### 翻译标签样式
- **高优先级**（景点、博物馆、地铁站）：橙色背景（#E6FF6B35），白色文字
- **普通**（餐厅、购物等）：白色背景（#E6FFFFFF），深灰文字
- **最小缩放级别**：14.0（zoom < 14不显示标签）
- **最大标签数**：12个/屏幕
- **去重距离**：80px

### 语音按钮
- **位置**：右下角，距底部导航栏90px + safe area
- **尺寸**：64×64px圆形
- **颜色状态**：
  - Idle: 橙色 #FF6B35
  - Recording: 红色 #F44336 + 脉冲动画
  - Processing: 橙色 + spinner
  - Playing: 绿色 #4CAF50
  - Error: 灰色 → 2s后auto-reset

## ⚠️ 注意事项

1. **高德地图版本**：`amap_flutter_map` API在不同版本可能略有差异，以实际安装版本为准
2. **坐标系统**：高德使用GCJ-02，数据库存储坐标也需使用GCJ-02
3. **百度TTS**：返回200不一定成功，需检查 `content-type` 是否为 `audio/*`
4. **百度ASR语言代码**：
   - 中文：dev_pid = 1537
   - 英文：dev_pid = 1737
   - 法文：dev_pid = 1836
   - 西班牙文：dev_pid = 1936

## 📚 参考文档

- **完整代码实现**：`/docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md`
- **UI设计规范**：`/docs/design/SCREEN_SPECIFICATIONS_v2.md`
- **数据库设计**：`/docs/design/WANDERCHINA_TRANSLATION_DATA_SPEC.md`
- **高德地图文档**：https://lbs.amap.com/api/flutter/summary
- **百度语音文档**：https://ai.baidu.com/ai-doc/SPEECH/overview

## 🚀 下一步行动

1. **安装依赖**：`flutter pub get`
2. **申请API密钥**：百度语音 + DeepSeek
3. **创建服务文件**：按步骤3创建两个服务
4. **创建UI组件**：按步骤4创建三个组件
5. **数据库初始化**：运行建表SQL + 插入种子数据
6. **配置环境变量**：.env 或 flutter run --dart-define
7. **测试运行**：在地图页面集成WanderMap组件

---

**创建时间**：2026-02-14
**基于文档**：WANDERCHINA_MAP_TRANSLATION_SPEC.md
**状态**：数据模型已创建 ✅，剩余步骤待实施
