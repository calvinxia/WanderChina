# WanderChina v2.0 UI实施总结

**更新日期**: 2026-02-14
**版本**: v2.0
**状态**: ✅ 核心UI组件已完成

---

## 📋 概述

本文档总结了WanderChina v2.0 UI界面的实施工作，包括：
- 新版底部导航栏（5标签）
- 语音翻译全屏模态框
- AI行程规划入口页面
- 主导航结构整合

所有工作基于 `SCREEN_SPECIFICATIONS_v2.md` 设计规范。

---

## ✅ 已完成组件

### 1. AppBottomNavigation（底部导航栏）

**文件**: `lib/widgets/common/app_bottom_navigation.dart`

**功能**:
- 5个标签: Home · Map · Planner · Voice · Me
- 激活状态: Jade 500 (#10B981)
- 未激活状态: Gray 400
- 高度: 56px + safe area
- 白色背景 + 1px顶部边框

**标签详情**:
```dart
0. Home    - Icons.home_outlined / Icons.home
1. Map     - Icons.map_outlined / Icons.map
2. Planner - Icons.calendar_today_outlined / Icons.calendar_today
3. Voice   - Icons.mic_none / Icons.mic + 🎙️ emoji
4. Me      - Icons.person_outline / Icons.person
```

**规范来源**: SCREEN_SPECIFICATIONS_v2.md - Global Components

---

### 2. VoiceTranslationScreen（语音翻译页面）

**文件**: `lib/screens/voice/voice_translation_screen.dart`

**功能**:
- 全屏模态框（`fullscreenDialog: true`）
- 双向翻译切换: EN → 中 ⇄ 中 → EN
- 语言选择器: English / Français / Español
- 对话历史记录（聊天气泡样式）
- 快捷短语（水平滚动）
- 80×80px 麦克风按钮

**核心特性**:
- **方向切换**: 两个140×40px圆角胶囊按钮 + 居中交换图标
- **录音按钮**:
  - Idle（待机）: 橙色→绿色渐变
  - Recording（录音中）: 红色 + 脉冲动画
  - Processing（处理中）: 橙色 + 加载动画
  - Playing（播放中）: 绿色 + 音量图标
  - Error（错误）: 灰色 → 2秒自动恢复

**快捷短语**:
- English: "How much?", "Where is...?", "Help!", "Thank you", "No, thanks"
- Français: "Combien?", "Où est...?", "Au secours!", "Merci", "Non merci"
- Español: "¿Cuánto cuesta?", "¿Dónde está...?", "¡Ayuda!", "Gracias", "No, gracias"

**交互流程**:
1. 按住麦克风按钮 → 开始录音
2. 释放按钮 → 停止录音并翻译
3. AI翻译显示在绿色气泡中
4. 点击"Tap to replay"播放TTS

**规范来源**: SCREEN_SPECIFICATIONS_v2.md - Screen 11

---

### 3. PlannerHomeScreen（AI行程规划页面）

**文件**: `lib/screens/planner/planner_home_screen.dart`

**功能**:
- 城市选择网格（6城市 × 3列）
- 行程天数选择（1-5天圆形按钮）
- 兴趣标签多选（6个标签）
- 自由文本输入（200字符）
- AI生成按钮（DeepSeek驱动）

**城市列表**:
```dart
北京 (BJ) | 上海 (SH) | 广州 (GZ)
深圳 (SZ) | 成都 (CD) | 西安 (XA)
```

**兴趣标签**:
- Culture（文化）
- Food（美食）
- Nature（自然）
- Shopping（购物）
- Nightlife（夜生活）
- History（历史）

**生成按钮**:
- ✨ 图标 + "Generate Plan"
- 绿色背景 (#10B981)
- 全宽 × 48px高
- 只有选择了城市且（选择了兴趣或输入了文本）才启用

**AI生成流程**:
1. 点击"Generate Plan" → 显示加载对话框
2. 调用DeepSeek API生成行程（模拟2秒延迟）
3. 导航到生成的行程页面（待实现）

**已保存行程**:
- 显示"My Saved Trips (2)"
- 卡片格式: 城市 · 天数 · 兴趣 + 创建日期
- "View All"按钮（待实现）

**规范来源**: SCREEN_SPECIFICATIONS_v2.md - Screen 9

---

### 4. MainScreen（主导航结构）

**文件**: `lib/screens/main/main_screen.dart`（已更新）

**功能**:
- 使用`IndexedStack`保持页面状态
- 集成新版`AppBottomNavigation`
- Voice标签特殊处理（打开模态框）

**页面映射**:
```dart
Tab 0: HomeScreen           - 首页仪表盘
Tab 1: MapWithTranslationScreen - 地图翻译页面
Tab 2: PlannerHomeScreen    - AI行程规划
Tab 3: VoiceTranslationScreen   - 语音翻译（模态框）
Tab 4: ProfileScreen        - 个人资料
```

**Voice按钮特殊逻辑**:
```dart
void _onTabTapped(int index) {
  if (index == 3) {
    // Voice标签打开全屏模态框
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VoiceTranslationScreen(),
        fullscreenDialog: true,
      ),
    );
    return;
  }
  setState(() => _currentIndex = index);
}
```

**旧版vs新版对比**:
| 旧版 | 新版 |
|------|------|
| Home | Home |
| Discover | Map |
| Map | Planner |
| Community | Voice（模态框）|
| Profile | Me |

---

## 🎨 设计规范遵循

### 颜色系统
- **Jade 500**: `#10B981` - 主色调（激活状态、按钮）
- **Jade 100**: `#D1FAE5` - 浅色背景（翻译气泡）
- **Jade 700**: `#059669` - 深色文本（翻译标签）
- **Orange**: `#FF6B35` - 语音按钮、高优先级
- **Gray 400**: `#9CA3AF` - 未激活图标
- **Gray 200**: `#E5E7EB` - 边框分隔线

### 字体规范
- **标题**: 16px, FontWeight.w600, Gray 900
- **正文**: 14px, FontWeight.normal, Gray 700
- **副标题**: 12px, Gray 500
- **按钮文字**: 16px, FontWeight.w600

### 间距规范
- **卡片内边距**: 16px（中等）/ 24px（大）
- **组件间距**: 8px（小）/ 12px（中）/ 24px（大）/ 32px（超大）
- **底部导航高度**: 56px + safe area

### 圆角规范
- **按钮圆角**: 12px（矩形）/ 20-22px（胶囊）
- **卡片圆角**: 12px
- **网格项圆角**: 12px

---

## 🔌 服务集成

### VoiceTranslationService
**文件**: `lib/services/voice/voice_translation_service.dart`

**状态机**:
```
idle → recording → processing → playing → idle
  ↓                                ↑
  └─────────── error ──────────────┘
```

**API集成**:
1. **百度ASR（语音识别）**: `_baiduASR()`
   - 支持中文、英文、法文、西班牙文
   - 返回识别文本

2. **DeepSeek（翻译）**: `_deepSeekTranslate()`
   - 双向翻译
   - 保留上下文

3. **百度TTS（语音合成）**: `_baiduTTS()`
   - 播放翻译结果
   - 缓存音频文件

**历史记录**:
- 对话气泡格式
- 显示原文、译文、处理时间
- "Tap to replay"重播功能

### POITranslationService
**文件**: `lib/services/map/poi_translation_service.dart`

**三级缓存**:
```
内存缓存 → 数据库 → DeepSeek API
 <1ms     ~50ms      ~500ms
```

**地图集成**:
- MapWithTranslationScreen使用WanderMap组件
- 翻译蒙层实时显示POI译文
- 支持3种标签样式（Badge / Minimal / Floating）

---

## 📂 文件结构

```
lib/
├── screens/
│   ├── main/
│   │   └── main_screen.dart          ✅ 已更新（v2导航）
│   ├── home/
│   │   └── home_screen.dart          ✅ 已存在（无需改动）
│   ├── map/
│   │   └── map_with_translation_screen.dart  ✅ 已存在
│   ├── planner/
│   │   └── planner_home_screen.dart  ✅ 新增（v2 AI规划）
│   ├── voice/
│   │   └── voice_translation_screen.dart    ✅ 新增（v2全屏模态）
│   └── profile/
│       └── profile_screen.dart       ✅ 已存在（无需改动）
│
├── widgets/
│   ├── common/
│   │   └── app_bottom_navigation.dart  ✅ 新增（v2底部导航）
│   └── map/
│       ├── translation_overlay_widget.dart  ✅ 已存在
│       ├── voice_translation_overlay.dart   ✅ 已存在
│       └── wander_map.dart              ✅ 已存在
│
├── services/
│   ├── voice/
│   │   └── voice_translation_service.dart  ✅ 已存在
│   └── map/
│       └── poi_translation_service.dart    ✅ 已存在
│
└── models/
    └── poi_translation.dart           ✅ 已存在
```

---

## ⚠️ 待完成事项

### 1. API密钥配置（高优先级）

**需要获取**:
- DeepSeek API Key
- 百度API Key
- 百度Secret Key

**配置方式**:
```bash
flutter run \
  --dart-define=DEEPSEEK_API_KEY=sk-xxx \
  --dart-define=BAIDU_API_KEY=xxx \
  --dart-define=BAIDU_SECRET_KEY=xxx
```

或修改 `lib/core/config/backend_config.dart` 默认值。

---

### 2. 数据库部署（高优先级）

**执行建表SQL**:
```sql
CREATE TABLE poi_translations (
  id SERIAL PRIMARY KEY,
  gaode_poi_id VARCHAR(100) UNIQUE NOT NULL,
  name_zh VARCHAR(200) NOT NULL,
  name_en VARCHAR(200) NOT NULL,
  name_fr VARCHAR(200),
  name_es VARCHAR(200),
  category_zh VARCHAR(50),
  category_en VARCHAR(50),
  city VARCHAR(50) NOT NULL,
  lat DECIMAL(10, 7) NOT NULL,
  lng DECIMAL(10, 7) NOT NULL,
  source VARCHAR(20) DEFAULT 'deepseek',
  cached_at TIMESTAMP DEFAULT NOW()
);
```

**插入种子数据**:
- 6个城市核心POI（每城市~300个）
- 北京: 故宫、天安门、颐和园、长城...
- 上海: 外滩、东方明珠、南京路...
- 等等

---

### 3. AMap API修复（中优先级）

**已知问题**:
- `mapController.convertCoordinate()` - 方法可能不存在
- `mapController.getVisibleRegion()` - 方法可能不存在
- POI搜索API需集成

**解决方案**:
查阅 `amap_flutter_map` v3.0.0 官方文档，替换为实际可用方法。

---

### 4. 功能待实现

**PlannerHomeScreen**:
- [ ] DeepSeek API调用（生成行程）
- [ ] 导航到生成行程详情页
- [ ] "View All"查看所有保存的行程
- [ ] 实际保存行程到数据库

**VoiceTranslationScreen**:
- [ ] TTS播放功能（"Tap to replay"）
- [ ] 快捷短语翻译和播放
- [ ] 历史记录持久化

**MapWithTranslationScreen**:
- [ ] POI点击事件详情页
- [ ] 搜索功能集成
- [ ] 路线规划

---

### 5. 测试（中优先级）

- [ ] 端到端测试（iOS模拟器 + 真机）
- [ ] 语音录音权限测试
- [ ] 网络请求错误处理
- [ ] 离线模式测试
- [ ] 多语言切换测试

---

## 📊 实施统计

| 类别 | 完成 | 待办 | 总计 |
|------|------|------|------|
| **UI组件** | 4 | 0 | 4 |
| **页面** | 3 | 3 | 6 |
| **服务** | 2 | 0 | 2 |
| **API集成** | 0 | 3 | 3 |
| **数据库** | 0 | 1 | 1 |

**整体进度**: 🟩🟩🟩🟩🟩🟩⬜⬜⬜⬜ **60%**

---

## 🚀 快速开始

### 运行应用

```bash
cd /Users/calvinxia/Desktop/China\ Travel/WanderChina/mobile_app
flutter pub get
flutter run
```

### 导航到各页面

**方式1 - 底部导航栏**:
1. 启动应用 → 自动进入MainScreen
2. 点击底部标签切换页面
3. 点击Voice标签 → 打开全屏语音翻译

**方式2 - 直接导航**:
```dart
// 语音翻译
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const VoiceTranslationScreen(),
    fullscreenDialog: true,
  ),
);

// AI行程规划
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PlannerHomeScreen(),
  ),
);
```

---

## 🔗 相关文档

- [v2.0设计规范](docs/design/SCREEN_SPECIFICATIONS_v2.md)
- [地图翻译蒙层README](MAP_TRANSLATION_OVERLAY_README.md)
- [实施指南](TRANSLATION_OVERLAY_IMPLEMENTATION_GUIDE.md)
- [完成报告](COMPLETION_REPORT.md)

---

## 👥 贡献者

- **设计**: WanderChina设计团队
- **开发**: WanderChina开发团队 + Claude Code
- **AI支持**: DeepSeek API, 百度语音API

---

**最后更新**: 2026-02-14
**下一步**: 配置API密钥 → 部署数据库 → 集成DeepSeek生成行程

🎉 **v2.0 UI核心组件已完成！**
