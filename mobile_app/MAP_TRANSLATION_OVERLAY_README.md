# WanderChina 地图翻译蒙层系统

## 📖 概述

WanderChina地图翻译蒙层系统为外国游客提供实时的中文地图翻译和语音翻译功能，帮助他们在中国旅行时更好地理解地图信息和进行语言交流。

### 核心功能

1. **地图翻译蒙层** - 在高德地图上实时显示POI的英文/法文/西班牙文翻译
2. **语音翻译** - 双向实时语音翻译（外语↔中文）
3. **三级缓存** - 内存 → 数据库 → AI翻译，确保快速响应
4. **多种标签样式** - Badge（徽章）/ Minimal（简约）/ Floating（浮动卡片）
5. **智能优化** - 防抖刷新、去重显示、优先级排序

---

## 🏗️ 架构设计

### 技术栈

| 组件 | 技术 | 说明 |
|------|------|------|
| 地图底图 | 高德地图 (`amap_flutter_map`) | 中国本土POI数据最准确 |
| 数据库 | 腾讯云 PostgreSQL | 存储翻译缓存 |
| AI翻译 | DeepSeek API | 实时翻译未缓存内容 |
| 语音识别 | 百度 ASR | 支持中文、英文、法文、西班牙文 |
| 语音合成 | 百度 TTS | 播放翻译结果 |
| 录音 | `record` 包 | 跨平台录音支持 |
| 音频播放 | `audioplayers` 包 | TTS结果播放 |

### 文件结构

```
lib/
├── models/
│   └── poi_translation.dart              # 数据模型
│
├── services/
│   ├── map/
│   │   └── poi_translation_service.dart  # POI翻译服务
│   └── voice/
│       └── voice_translation_service.dart # 语音翻译服务
│
├── widgets/
│   └── map/
│       ├── translation_overlay_widget.dart # 翻译蒙层组件
│       ├── voice_translation_overlay.dart  # 语音按钮组件
│       └── wander_map.dart                 # 主地图组件
│
└── screens/
    └── map/
        └── map_with_translation_screen.dart # 使用示例
```

---

## 🚀 快速开始

### 1. 安装依赖

依赖包已添加到 `pubspec.yaml`：

```yaml
dependencies:
  # 地图
  amap_flutter_map: ^3.0.0
  amap_flutter_base: ^3.0.0

  # 网络
  http: ^1.1.0

  # 数据库
  postgres: ^3.0.2

  # 语音
  record: ^5.1.2
  audioplayers: ^6.0.0

  # 工具
  path_provider: ^2.1.1
```

运行安装：
```bash
flutter pub get
```

### 2. 配置API密钥

#### 方式1：环境变量（推荐）

```bash
flutter run \
  --dart-define=DEEPSEEK_API_KEY=sk-xxx \
  --dart-define=BAIDU_API_KEY=xxx \
  --dart-define=BAIDU_SECRET_KEY=xxx \
  --dart-define=DB_HOST=your-db-host \
  --dart-define=DB_PASSWORD=your-db-password
```

#### 方式2：修改配置文件

编辑 `lib/core/config/backend_config.dart`，修改默认值：

```dart
static const String deepseekApiKey = String.fromEnvironment(
  'DEEPSEEK_API_KEY',
  defaultValue: 'your-api-key-here',  // ⚠️ 不要提交到Git
);
```

### 3. 配置iOS权限

已在 `ios/Runner/Info.plist` 中添加：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>WanderChina需要麦克风权限用于语音翻译</string>
```

### 4. 初始化数据库

在腾讯云PostgreSQL执行建表SQL（见 `IMPLEMENTATION_SUMMARY.md`），并插入种子数据。

---

## 💻 使用示例

### 基础用法

```dart
import 'package:wanderchina/widgets/map/wander_map.dart';
import 'package:wanderchina/models/poi_translation.dart';

// 最简单的用法
WanderMap(
  initialCenter: LatLng(39.9042, 116.4074), // 天安门
  initialZoom: 15.0,
  language: AppLanguage.english,
)
```

### 完整配置

```dart
WanderMap(
  initialCenter: LatLng(31.2304, 121.4737), // 上海外滩
  initialZoom: 16.0,
  language: AppLanguage.french,
  labelStyle: LabelStyle.floating,
  showTranslationOverlay: true,
  showVoiceButton: true,
  onMapTap: (latLng) {
    print('地图点击: ${latLng.latitude}, ${latLng.longitude}');
  },
)
```

### 编程式控制

```dart
final mapKey = GlobalKey<WanderMapState>();

WanderMap(
  key: mapKey,
  initialCenter: LatLng(39.9042, 116.4074),
  language: AppLanguage.english,
)

// 移动地图
mapKey.currentState?.moveTo(
  LatLng(31.2304, 121.4737),
  zoom: 14.0,
);

// 添加自定义标记
mapKey.currentState?.addSearchMarker(poiTranslation);

// 清除所有标记
mapKey.currentState?.clearSearchMarkers();
```

### 完整页面示例

参见 `lib/screens/map/map_with_translation_screen.dart`，包含：
- 语言切换菜单
- 标签样式切换
- 城市快速切换
- 设置对话框
- 浮动操作按钮

---

## 🎨 UI设计规范

### 翻译标签样式

#### 1. Badge（徽章样式）
- 带圆角矩形背景
- 底部有三角形指示箭头
- 高优先级：橙色背景 `#E6FF6B35`
- 普通：白色背景 `#E6FFFFFF`
- 字体大小：10px

#### 2. Minimal（简约样式）
- 纯文本，无背景
- 白色描边阴影，确保可读性
- 高优先级：橙红色 `#E55A2B`
- 普通：深灰色 `#333333`
- 字体大小：9px

#### 3. Floating（浮动卡片）
- 渐变背景 `#F0FF6B35` → `#F0FF8C42`
- 显示英文名 + 中文名
- 圆角：12px
- 字体大小：11px（英文）/ 8px（中文）

### 语音按钮

- **位置**：右下角，距底部导航栏 90px
- **尺寸**：64×64px 圆形
- **状态颜色**：
  - Idle（待机）：橙色 `#FF6B35`
  - Recording（录音中）：红色 `#F44336` + 脉冲动画
  - Processing（处理中）：橙色 + 加载动画
  - Playing（播放中）：绿色 `#4CAF50`
  - Error（错误）：灰色 → 2秒后自动恢复

### 显示规则

- **最小缩放级别**：zoom ≥ 14.0
- **最大标签数**：12个/屏幕
- **去重距离**：80px
- **防抖延迟**：300ms

---

## 🔧 配置选项

### WanderMap参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `initialCenter` | `LatLng` | **必需** | 地图初始中心点 |
| `initialZoom` | `double` | `15.0` | 初始缩放级别 |
| `language` | `AppLanguage` | `english` | 翻译目标语言 |
| `labelStyle` | `LabelStyle` | `badge` | 标签样式 |
| `showTranslationOverlay` | `bool` | `true` | 是否显示翻译蒙层 |
| `showVoiceButton` | `bool` | `true` | 是否显示语音按钮 |
| `onMapTap` | `Function(LatLng)?` | `null` | 地图点击回调 |
| `onPOITap` | `Function(POITranslation)?` | `null` | POI点击回调 |

### AppLanguage枚举

```dart
enum AppLanguage {
  english,   // 英语
  french,    // 法语
  spanish,   // 西班牙语
}
```

### LabelStyle枚举

```dart
enum LabelStyle {
  badge,     // 徽章样式（带箭头）
  minimal,   // 简约样式（纯文本）
  floating,  // 浮动卡片样式
}
```

---

## 📊 服务说明

### POITranslationService

**功能**：管理POI翻译的三级缓存

```dart
final service = POITranslationService();

// 初始化（已在main.dart中调用）
await service.initialize();

// 获取翻译（批量）
final translations = await service.getTranslations(
  gaodePoiIds: ['id1', 'id2', 'id3'],
  language: AppLanguage.english,
);

// 翻译原始POI数据
final translatedPOIs = await service.translateRawPOIs(
  rawPOIs: [
    {
      'gaode_poi_id': 'xxx',
      'name_zh': '故宫博物院',
      'category_zh': '景点',
      'city': '北京',
      'lat': 39.9163,
      'lng': 116.3972,
    }
  ],
);
```

### VoiceTranslationService

**功能**：双向语音翻译

```dart
final service = VoiceTranslationService();

// 开始录音
await service.startRecording();

// 停止录音并翻译
final result = await service.stopAndTranslate(
  direction: TranslationDirection.foreignToChinese,
  foreignLanguage: AppLanguage.english,
);

// 取消录音
await service.cancelRecording();

// 停止播放
await service.stopPlaying();

// 查看历史记录
final history = service.history;

// 清空历史
service.clearHistory();
```

---

## ⚙️ 性能优化

### 1. 三级缓存策略

```
查询流程：
内存缓存 → 数据库 → DeepSeek API → 保存到数据库 → 更新内存缓存
  ↓         ↓           ↓
 <1ms     ~50ms      ~500ms
```

### 2. 防抖机制

- 地图移动/缩放时不立即更新
- 停止移动300ms后才刷新标签
- 避免频繁的数据库查询和API调用

### 3. 去重算法

- 使用欧氏距离计算标签间距
- 最小距离80px，确保标签不重叠
- 高优先级POI优先显示

### 4. 预加载

- 应用启动时预加载6个城市的核心POI（2000条）
- 后台静默翻译常用POI
- 减少首次显示的延迟

---

## 🐛 常见问题

### Q1: 翻译标签不显示？

**解决方案**：
1. 检查缩放级别是否 ≥ 14.0
2. 确认 `showTranslationOverlay` 为 `true`
3. 查看控制台是否有数据库连接错误

### Q2: 语音翻译无法使用？

**解决方案**：
1. 检查麦克风权限是否授权
2. 确认百度API密钥已配置
3. 查看控制台是否有"Token无效"错误

### Q3: AMap API方法不存在？

**当前已知问题**：
- `convertCoordinate()` - 需替换为实际API
- `getVisibleRegion()` - 需替换为实际API
- POI搜索API - 需集成 `AMapPOISearch`

**解决方案**：查阅 `amap_flutter_map` 官方文档，使用正确的API方法。

### Q4: 翻译质量不佳？

**优化建议**：
1. 手动添加高频POI到数据库（source='manual'）
2. 调整DeepSeek prompt提示词
3. 增加本地词典覆盖率

---

## 📝 开发者备注

### 待办事项

- [ ] 集成高德地图POI搜索API
- [ ] 修复AMap控制器方法调用
- [ ] 添加更多城市的种子数据
- [ ] 实现拼音回退翻译
- [ ] 添加用户反馈翻译功能
- [ ] 支持离线翻译包

### 贡献指南

1. Fork项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

---

## 📄 许可证

Copyright © 2026 WanderChina. All rights reserved.

---

## 🔗 相关文档

- [完整实施规范](docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md)
- [实施指南](TRANSLATION_OVERLAY_IMPLEMENTATION_GUIDE.md)
- [实施总结](IMPLEMENTATION_SUMMARY.md)
- [UI设计规范](docs/design/SCREEN_SPECIFICATIONS_v2.md)

---

**最后更新**: 2026-02-14
**版本**: 1.0.0
**作者**: WanderChina开发团队 + Claude Code
