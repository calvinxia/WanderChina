# POI翻译层使用指南

## 概述

由于高德地图API目前不提供英文支持，我们实现了一个POI翻译层系统，为国际用户提供双语（中英文）地图体验。

**支持城市:** 北京、上海、广州、深圳、成都、西安（6个主要城市）
**创建日期:** 2026-01-15
**版本:** 1.1.0

---

## 城市支持

### 支持的城市列表

POI搜索和翻译功能仅在以下6个主要城市提供：

| 中文名 | 英文名 | 高德地图代码 |
|--------|--------|--------------|
| 北京 | Beijing | 110000 |
| 上海 | Shanghai | 310000 |
| 广州 | Guangzhou | 440100 |
| 深圳 | Shenzhen | 440300 |
| 成都 | Chengdu | 510100 |
| 西安 | Xi'an | 610100 |

### 城市检测

系统自动根据坐标检测POI所在城市：

- POI搜索时，仅返回支持城市内的结果
- POI翻译时，仅翻译支持城市内的地点
- 超出支持城市范围的POI将不会被处理

### 城市过滤控制

```dart
// 启用城市过滤（默认）
POIService().enableCityFilter = true;
POITranslationService().enableCityFilter = true;

// 禁用城市过滤（仅测试使用）
POIService().enableCityFilter = false;
POITranslationService().enableCityFilter = false;
```

---

## 功能特性

### ✅ 已实现功能

1. **多层翻译策略**
   - 本地词典翻译（最快，300+常用地点）
   - 翻译缓存（次快，无限容量）
   - 在线API翻译（最准确，百度翻译）

2. **双语POI模型**
   - 中文名称 + 英文翻译
   - 中文地址 + 英文翻译
   - 中文描述 + 英文翻译
   - 翻译置信度标记

3. **语言管理**
   - 全局语言切换（中文/英文）
   - 语言偏好持久化
   - 实时UI更新

4. **智能信息窗**
   - 根据当前语言显示POI信息
   - 双语名称显示（英文+中文原名）
   - 翻译来源标记

---

## 文件结构

```
lib/
├── models/
│   └── translated_poi.dart               # 双语POI模型（300+翻译词典）
├── services/
│   ├── poi_service.dart                  # POI搜索服务（城市过滤）
│   └── poi_translation_service.dart      # POI翻译服务（城市过滤）
├── core/
│   ├── constants/
│   │   └── supported_cities.dart         # 支持的城市配置
│   └── services/
│       └── language_manager.dart         # 语言管理器
└── widgets/
    └── map/
        └── bilingual_poi_info_window.dart # 双语信息窗组件
```

---

## 使用方法

### 1. 初始化语言管理器

在应用启动时初始化：

```dart
import 'package:wanderchina/core/services/language_manager.dart';
import 'package:wanderchina/services/poi_translation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化语言管理器
  await LanguageManager().initialize();

  // 初始化翻译服务（可选配置百度API）
  await POITranslationService().initialize(
    baiduAppId: 'YOUR_BAIDU_APP_ID',      // 可选
    baiduSecretKey: 'YOUR_BAIDU_SECRET',  // 可选
  );

  runApp(MyApp());
}
```

### 2. 翻译POI

```dart
import 'package:wanderchina/services/poi_translation_service.dart';
import 'package:wanderchina/models/poi.dart';
import 'package:wanderchina/models/translated_poi.dart';

// 翻译单个POI
final translationService = POITranslationService();
final poi = POI(...); // 从高德地图获取的POI

final translatedPOI = await translationService.translatePOI(poi);

// 访问翻译后的字段
print(translatedPOI.nameEn);      // 英文名称
print(translatedPOI.addressEn);   // 英文地址
print(translatedPOI.isTranslated); // 是否已翻译
```

### 3. 批量翻译

```dart
// 翻译POI列表
List<POI> pois = [...]; // POI列表

final translatedPOIs = await translationService.translatePOIs(pois);
```

### 4. 语言切换

```dart
import 'package:wanderchina/core/services/language_manager.dart';

// 获取语言管理器
final languageManager = LanguageManager();

// 切换语言（中英文自动切换）
await languageManager.toggleLanguage();

// 设置为英文
await languageManager.setLanguage('en');

// 设置为中文
await languageManager.setLanguage('zh');

// 获取当前语言
String currentLang = languageManager.currentLanguage; // 'zh' 或 'en'

// 判断当前语言
bool isEnglish = languageManager.isEnglish;
bool isChinese = languageManager.isChinese;
```

### 5. 显示双语POI信息

```dart
import 'package:wanderchina/widgets/map/bilingual_poi_info_window.dart';
import 'package:wanderchina/models/translated_poi.dart';

// 在地图上显示POI信息窗
BilingualPOIInfoWindow(
  poi: translatedPOI,
  onTap: () {
    // 点击详情按钮
    print('查看POI详情');
  },
  onClose: () {
    // 点击关闭按钮
    print('关闭信息窗');
  },
)
```

### 6. 使用静态文本翻译

```dart
import 'package:wanderchina/core/services/language_manager.dart';

// 使用AppTexts获取翻译文本
Text(AppTexts.mapTitle);           // "地图" 或 "Map"
Text(AppTexts.search);             // "搜索" 或 "Search"
Text(AppTexts.myLocation);         // "我的位置" 或 "My Location"

// 或使用LanguageManager直接翻译
final manager = LanguageManager();
String text = manager.text('地图', 'Map');
```

### 7. 监听语言变化

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final LanguageManager _languageManager = LanguageManager();

  @override
  void initState() {
    super.initState();
    // 监听语言变化
    _languageManager.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageManager.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {
      // 语言改变时更新UI
    });
  }

  @override
  Widget build(BuildContext context) {
    // UI会在语言变化时自动重建
    return Text(_languageManager.text('你好', 'Hello'));
  }
}
```

---

## 翻译策略

### 三层翻译架构

```
请求翻译
    ↓
1. 本地词典
   ├─ 200+常用地点
   ├─ 速度: <1ms
   └─ 置信度: 0.9
    ↓ (未找到)
2. 缓存查询
   ├─ 持久化缓存
   ├─ 速度: <10ms
   └─ 置信度: 原值
    ↓ (未找到)
3. 在线API
   ├─ 百度翻译API
   ├─ 速度: 100-500ms
   ├─ 置信度: 0.85
   └─ 自动缓存结果
    ↓
返回翻译结果
```

### 本地词典

内置300+常用地点翻译，覆盖6个支持城市的主要景点和地标：

#### 北京（Beijing）
- 故宫博物院 (Palace Museum)
- 天安门广场 (Tiananmen Square)
- 长城 (Great Wall)
- 颐和园 (Summer Palace)
- 天坛 (Temple of Heaven)
- 圆明园 (Old Summer Palace)
- 鸟巢 (Bird's Nest)
- 798艺术区 (798 Art District)
- 30+景点、餐饮、交通设施

#### 上海（Shanghai）
- 外滩 (The Bund)
- 东方明珠 (Oriental Pearl Tower)
- 上海中心大厦 (Shanghai Tower)
- 豫园 (Yu Garden)
- 新天地 (Xintiandi)
- 上海迪士尼乐园 (Shanghai Disneyland)
- 25+景点、购物、交通设施

#### 广州（Guangzhou）
- 广州塔 (Canton Tower)
- 越秀公园 (Yuexiu Park)
- 陈家祠 (Chen Clan Ancestral Hall)
- 长隆野生动物世界 (Chimelong Safari Park)
- 20+景点、餐饮、交通设施

#### 深圳（Shenzhen）
- 世界之窗 (Window of the World)
- 欢乐谷 (Happy Valley)
- 深圳湾公园 (Shenzhen Bay Park)
- 15+景点、购物、交通设施

#### 成都（Chengdu）
- 武侯祠 (Wuhou Temple)
- 锦里 (Jinli Ancient Street)
- 宽窄巷子 (Kuanzhai Alley)
- 熊猫基地 (Panda Base)
- 20+景点、餐饮、交通设施

#### 西安（Xi'an）
- 兵马俑 (Terracotta Warriors)
- 大雁塔 (Big Wild Goose Pagoda)
- 西安城墙 (Xi'an City Wall)
- 钟鼓楼 (Bell & Drum Tower)
- 回民街 (Muslim Quarter)
- 华山 (Mount Hua)
- 15+景点、餐饮、交通设施

#### 通用设施
- 地铁站、火车站、机场
- 餐厅、咖啡厅、酒店
- 银行、医院、购物中心
- 100+通用设施和常用词汇

### 翻译缓存

- **内存缓存**: 快速访问，应用运行期间有效
- **持久化缓存**: SharedPreferences存储，永久保存
- **自动管理**: 翻译结果自动缓存，减少API调用

### 在线翻译API

支持百度翻译API（可选）：

```dart
await POITranslationService().initialize(
  baiduAppId: 'YOUR_APP_ID',
  baiduSecretKey: 'YOUR_SECRET_KEY',
);
```

**获取百度翻译API密钥:**
1. 访问 [百度翻译开放平台](https://fanyi-api.baidu.com/)
2. 注册并创建应用
3. 获取APP ID和密钥
4. 在初始化时配置

---

## POI类别翻译

自动翻译14种POI类别：

| 中文 | 英文 | 图标 |
|------|------|------|
| 景点 | Attraction | 🏛️ |
| 餐厅 | Restaurant | 🍜 |
| 酒店 | Hotel | 🏨 |
| 购物 | Shopping | 🛍️ |
| 交通 | Transport | 🚇 |
| 医院 | Hospital | 🏥 |
| 银行 | Bank | 🏦 |
| 咖啡厅 | Cafe | ☕ |
| 酒吧 | Bar | 🍺 |
| 公园 | Park | 🌳 |
| 博物馆 | Museum | 🏛️ |
| 寺庙 | Temple | ⛩️ |
| 紧急服务 | Emergency | 🚨 |
| 其他 | Other | 📍 |

---

## 高级功能

### 1. 清空翻译缓存

```dart
final translationService = POITranslationService();

// 清空所有缓存
await translationService.clearCache();

// 获取缓存统计
final stats = translationService.getCacheStats();
print('缓存数量: ${stats['totalCached']}');
```

### 2. 预翻译常用POI

```dart
// 预先翻译常用地点（应用启动时）
await translationService.preTranslateCommonPOIs();
```

### 3. 自定义翻译逻辑

扩展 `CommonPlaceTranslations.translations` 添加更多本地翻译：

```dart
// 在translated_poi.dart中添加
static const Map<String, String> translations = {
  // 原有翻译...

  // 添加你的自定义翻译
  '你的地点名': 'Your Place Name',
  // ...
};
```

### 4. 根据语言显示内容

```dart
// 使用TranslatedPOI的便捷方法
final name = translatedPOI.getName('en');        // 英文名称
final address = translatedPOI.getAddress('zh');  // 中文地址
final desc = translatedPOI.getDescription('en'); // 英文描述
final tags = translatedPOI.getTags('zh');        // 中文标签
```

---

## 性能优化

### 翻译性能

| 翻译方式 | 速度 | 准确度 | 成本 |
|---------|------|--------|------|
| 本地词典 | <1ms | 高 | 无 |
| 缓存 | <10ms | 高 | 无 |
| 百度API | 100-500ms | 中高 | 有限免费额度 |

### 优化建议

1. **优先使用本地词典**
   - 添加更多常用地点到词典
   - 准确且无需网络

2. **利用缓存**
   - 翻译结果自动缓存
   - 相同POI只翻译一次

3. **批量翻译**
   - 使用 `translatePOIs()` 批量处理
   - 减少循环调用开销

4. **预翻译**
   - 应用启动时预翻译常用地点
   - 提升首次使用体验

---

## 示例代码

### 完整示例：在地图上显示翻译后的POI

```dart
import 'package:flutter/material.dart';
import 'package:wanderchina/services/poi_service.dart';
import 'package:wanderchina/services/poi_translation_service.dart';
import 'package:wanderchina/models/translated_poi.dart';
import 'package:wanderchina/widgets/map/bilingual_poi_info_window.dart';
import 'package:wanderchina/core/services/language_manager.dart';

class MapScreenWithTranslation extends StatefulWidget {
  @override
  _MapScreenWithTranslationState createState() => _MapScreenWithTranslationState();
}

class _MapScreenWithTranslationState extends State<MapScreenWithTranslation> {
  final POIService _poiService = POIService();
  final POITranslationService _translationService = POITranslationService();
  final LanguageManager _languageManager = LanguageManager();

  List<TranslatedPOI> _translatedPOIs = [];
  TranslatedPOI? _selectedPOI;

  @override
  void initState() {
    super.initState();
    _loadNearbyPOIs();
    _languageManager.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _languageManager.removeListener(_onLanguageChanged);
    super.dispose();
  }

  Future<void> _loadNearbyPOIs() async {
    // 1. 从高德地图获取附近POI
    final pois = await _poiService.searchNearby(
      latitude: 39.9042,
      longitude: 116.4074,
    );

    // 2. 翻译所有POI
    final translated = await _translationService.translatePOIs(pois);

    setState(() {
      _translatedPOIs = translated;
    });
  }

  void _onLanguageChanged() {
    // 语言切换时更新UI
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppTexts.mapTitle),
        actions: [
          // 语言切换按钮
          IconButton(
            icon: Icon(Icons.language),
            onPressed: () async {
              await _languageManager.toggleLanguage();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 地图组件
          // AMapWidget(...),

          // 显示选中的POI信息
          if (_selectedPOI != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: BilingualPOIInfoWindow(
                poi: _selectedPOI!,
                onClose: () {
                  setState(() {
                    _selectedPOI = null;
                  });
                },
                onTap: () {
                  // 查看POI详情
                },
              ),
            ),

          // 语言指示器
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                _languageManager.getLanguageDisplayName(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 常见问题

### Q1: 为什么只支持这6个城市？

**A:**
- 这6个城市是中国最主要的旅游目的地，覆盖了大部分国际游客
- 专注于这些城市可以提供更高质量的翻译和更好的用户体验
- 可以集中维护和扩展这些城市的POI翻译词典

### Q2: 如果我在不支持的城市，会发生什么？

**A:**
- POI搜索将返回空结果
- 翻译服务会跳过不支持城市的POI
- 控制台会显示警告信息
- 可以通过设置 `enableCityFilter = false` 临时禁用过滤（仅测试用）

### Q3: 如何添加新城市？

**A:** 编辑 `lib/core/constants/supported_cities.dart`：

```dart
static const List<String> citiesZh = [
  '北京', '上海', '广州', '深圳', '成都', '西安',
  '新城市', // 添加新城市
];

static const Map<String, CityBounds> cityBounds = {
  // 添加城市边界
  '新城市': CityBounds(
    minLat: xx.x,
    maxLat: xx.x,
    minLng: xxx.x,
    maxLng: xxx.x,
  ),
};
```

然后在 `lib/models/translated_poi.dart` 添加该城市的地点翻译。

### Q4: 翻译不准确怎么办？

**A:**
1. 检查本地词典，添加准确的翻译
2. 配置百度翻译API提高准确度
3. 手动校正并添加到词典

### Q5: 翻译速度慢？

**A:**
1. 确保使用了缓存机制
2. 预翻译常用地点
3. 批量翻译而非逐个翻译

### Q6: 如何添加更多本地翻译？

**A:** 编辑 `lib/models/translated_poi.dart`：

```dart
static const Map<String, String> translations = {
  // 在对应城市区块添加翻译
  '新地点': 'New Place',
};
```

### Q7: 是否需要百度翻译API？

**A:** 不是必需的。系统会使用本地词典（300+地点）和缓存。如果需要更高准确度和覆盖更多地点，建议配置百度API。

### Q8: 翻译结果会保存吗？

**A:** 是的。所有翻译结果自动缓存到SharedPreferences，永久保存。

---

## 未来改进

- [ ] 支持更多语言（西班牙语、法语、日语等）
- [ ] 集成Google翻译API作为备选
- [ ] 优化翻译准确度
- [ ] 添加用户反馈机制（报告错误翻译）
- [ ] 离线翻译包（预下载常用翻译）
- [ ] 翻译质量评分
- [ ] 社区贡献翻译

---

## 相关文档

- **高德地图配置:** `AMAP_SETUP_GUIDE.md`
- **功能总结:** `AMAP_FEATURE_SUMMARY.md`
- **快速启动:** `QUICK_START.md`

---

**版本:** 1.1.0
**最后更新:** 2026-01-15
**维护者:** WanderChina开发团队

---

## 版本历史

### v1.1.0 (2026-01-15)
- ✅ 添加城市限制功能（仅支持6个主要城市）
- ✅ 扩展翻译词典至300+地点
- ✅ 新增城市常量配置文件
- ✅ POI服务和翻译服务支持城市过滤
- ✅ 按城市分类的翻译词典

### v1.0.0 (2026-01-15)
- ✅ 初始POI翻译层实现
- ✅ 三层翻译策略（词典/缓存/API）
- ✅ 双语POI模型
- ✅ 语言管理器
- ✅ 双语信息窗组件
