# WanderChina 项目架构文档

**最后更新**: 2026-02-25
**版本**: 2.0
**项目阶段**: MVP开发中 (55%完成)

---

## 📊 项目概览

WanderChina是一款面向在华旅行者的AI驱动移动应用，提供离线地图、实时翻译、AI行程规划和社区功能。

**核心价值**:
- 🗺️ 高德地图集成 + 多语言POI翻译
- 🎤 实时语音翻译 (百度语音 + DeepSeek)
- 🤖 AI行程规划 (DeepSeek驱动)
- 📱 Flutter跨平台开发 (iOS/Android)
- ☁️ 腾讯云PostgreSQL后端

---

## 🏗️ 技术栈

### 前端 (Mobile App)
```
Flutter 3.24+
├── 状态管理: Riverpod
├── 地图: AMap Flutter SDK 3.0.0
├── 网络: Dio + HTTP
├── 数据库: PostgreSQL Client
├── 语音: Record + AudioPlayers
└── UI: Material Design 3 + Custom Theme
```

### 后端 (Backend Services)
```
腾讯云 PostgreSQL 15+
├── 数据库: 30+ 张表
├── 扩展: PostGIS (地理空间)
├── 认证: JWT + 会话管理
└── 存储: Cloudflare R2 (计划中)
```

### AI & 翻译服务
```
第三方API
├── DeepSeek API: 文本翻译 + AI规划
├── 百度ASR: 语音识别
├── 百度TTS: 语音合成
└── 高德地图API: POI搜索 + 导航
```

---

## 📁 项目目录结构

```
WanderChina/
│
├── 📱 mobile_app/                      # Flutter移动应用
│   ├── lib/
│   │   ├── core/                      # 核心功能
│   │   │   ├── config/                # 配置文件
│   │   │   ├── constants/             # 常量定义
│   │   │   ├── services/              # 核心服务
│   │   │   └── theme/                 # 主题配置
│   │   │
│   │   ├── models/                    # 数据模型
│   │   │   ├── poi_translation.dart   # POI翻译模型
│   │   │   ├── translated_poi.dart    # 翻译后的POI
│   │   │   ├── itinerary.dart         # 行程模型
│   │   │   └── ...
│   │   │
│   │   ├── services/                  # 业务服务
│   │   │   ├── map/                   # 地图服务
│   │   │   │   └── poi_translation_service.dart (三级缓存)
│   │   │   ├── voice/                 # 语音服务
│   │   │   │   └── voice_translation_service.dart
│   │   │   ├── backend/               # 后端服务
│   │   │   │   ├── auth_service.dart
│   │   │   │   └── storage_service.dart
│   │   │   ├── amap_service.dart      # 高德地图集成
│   │   │   └── map_translation_service.dart
│   │   │
│   │   ├── screens/                   # 页面
│   │   │   ├── main/                  # 主导航
│   │   │   ├── home/                  # 首页
│   │   │   ├── map/                   # 地图页面
│   │   │   ├── planner/               # AI行程规划
│   │   │   ├── voice/                 # 语音翻译
│   │   │   ├── profile/               # 个人资料
│   │   │   ├── community/             # 社区 (待移除)
│   │   │   └── challenges/            # 挑战 (待移除)
│   │   │
│   │   └── widgets/                   # 通用组件
│   │       ├── common/                # 通用组件
│   │       │   └── app_bottom_navigation.dart
│   │       ├── map/                   # 地图组件
│   │       │   ├── wander_map.dart    # 主地图组件
│   │       │   ├── translation_overlay_widget.dart
│   │       │   └── voice_translation_overlay.dart
│   │       ├── buttons/
│   │       ├── cards/
│   │       └── dialogs/
│   │
│   ├── android/                       # Android原生代码
│   ├── ios/                           # iOS原生代码
│   ├── assets/                        # 资源文件
│   ├── test/                          # 测试文件
│   │
│   ├── pubspec.yaml                   # Flutter依赖配置
│   ├── README.md                      # 移动应用说明
│   ├── MVP_PROGRESS_TRACKER.md        # MVP进度追踪
│   ├── AMAP_FEATURE_SUMMARY.md        # 高德地图功能总结
│   ├── MAP_TRANSLATION_OVERLAY_README.md  # 地图翻译使用文档
│   └── V2_UI_IMPLEMENTATION_SUMMARY.md    # V2 UI实施总结
│
├── 🗄️ tencentcloud/                    # 腾讯云数据库
│   ├── migrations/                    # 数据库迁移脚本
│   │   ├── 000_auth_setup.sql         # 认证系统 (135行)
│   │   ├── 001_initial_schema.sql     # 核心表结构 (845行)
│   │   └── 002_row_level_security.sql # 安全策略 (654行)
│   │
│   ├── tencentcloud_translation/      # 地图翻译数据库
│   │   ├── map_translation_schema.sql # 翻译表结构 (352行)
│   │   ├── initial_translation_data.sql # 种子数据 (281行)
│   │   └── README.md                  # 使用说明
│   │
│   ├── seed.sql                       # 主数据库种子数据 (407行)
│   └── README.md                      # 部署文档
│
├── 📚 docs/                            # 项目文档
│   ├── design/                        # 设计文档
│   │   ├── SCREEN_SPECIFICATIONS_v2.md           # V2屏幕设计规范
│   │   ├── WANDERCHINA_MAP_TRANSLATION_SPEC.md   # 地图翻译技术规范
│   │   ├── WANDERCHINA_TENCENT_CLOUD_CONFIG.md   # 腾讯云配置
│   │   ├── WANDERCHINA_BAIDU_SPEECH_CONFIG.md    # 百度语音配置
│   │   ├── WANDERCHINA_TRANSLATION_DATA_SPEC.md  # 翻译数据规范
│   │   ├── DEEPSEEK_API_配置指南.md              # DeepSeek配置
│   │   └── 拆分云函数架构快速参考.md              # 云函数架构
│   │
│   ├── architecture/                  # 架构文档
│   │   ├── TECHNICAL_ARCHITECTURE.md  # 技术架构
│   │   └── DATABASE_ERD.md            # 数据库ER图
│   │
│   ├── features/                      # 功能规范
│   │   └── MVP_FEATURES.md            # MVP功能详情
│   │
│   ├── roadmap/                       # 路线图
│   │   ├── DEVELOPMENT_ROADMAP.md     # 开发路线图
│   │   └── ROADMAP_OVERVIEW.md        # 路线图概览
│   │
│   └── api/                           # API文档
│       └── API_DOCUMENTATION.md       # API说明
│
├── 📦 archive/                         # 归档文件
│   ├── docs_v1_planning/              # 早期规划文档
│   │   ├── BUSINESS_VALUE_ASSESSMENT.md
│   │   ├── DOCUMENTATION_INDEX.md
│   │   ├── FLUTTER_APP_IMPLEMENTATION.md
│   │   ├── PROJECT_SUMMARY.md
│   │   ├── SUPABASE_DATABASE_COMPLETE.md
│   │   ├── SUPABASE_QUICKSTART.md
│   │   └── README.md
│   │
│   ├── supabase/                      # 已弃用的Supabase方案
│   │   ├── migrations/
│   │   └── README.md
│   │
│   └── docs/                          # 旧架构文档
│       └── database_schema.sql
│
├── 💼 Business Doc/                    # 商业文档 (非技术)
├── 🎨 assets/                          # 项目资源 (设计素材等)
├── 🔧 config/                          # 全局配置
├── 📝 scripts/                         # 脚本工具
├── 🧪 tests/                           # 测试文件
│
├── README.md                          # 项目简介
├── MIGRATION_SUMMARY.md               # 迁移总结
├── TENCENTCLOUD_MIGRATION_GUIDE.md    # 腾讯云迁移指南
├── .gitignore                         # Git忽略配置
└── PROJECT_ARCHITECTURE.md            # 本文档
```

---

## 🔧 核心功能模块

### 1. 地图翻译系统 (Map Translation)

**架构**: 三级缓存机制

```
用户请求 POI翻译
    ↓
┌─────────────────────────┐
│ Level 1: 内存缓存         │  <1ms
│ Map<String, POITranslation>│
└─────────────────────────┘
    ↓ (未命中)
┌─────────────────────────┐
│ Level 2: PostgreSQL数据库│  ~50ms
│ tencentcloud_translation/│
└─────────────────────────┘
    ↓ (未命中)
┌─────────────────────────┐
│ Level 3: DeepSeek API    │  ~500ms
│ 实时翻译 + 保存到数据库   │
└─────────────────────────┘
```

**关键文件**:
- `lib/services/map/poi_translation_service.dart` - 翻译服务
- `lib/widgets/map/translation_overlay_widget.dart` - 翻译蒙层UI
- `tencentcloud/tencentcloud_translation/` - 数据库schema

**覆盖城市**: 北京、上海、广州、深圳、成都、西安

---

### 2. 语音翻译系统 (Voice Translation)

**工作流程**:

```
用户按住麦克风按钮
    ↓
录音 (Record package)
    ↓
百度ASR API → 识别文本
    ↓
DeepSeek API → 翻译
    ↓
百度TTS API → 语音合成
    ↓
播放音频 (AudioPlayers)
```

**支持语言**: 中文 ⇄ 英文/法文/西班牙文

**关键文件**:
- `lib/services/voice/voice_translation_service.dart`
- `lib/screens/voice/voice_translation_screen.dart`
- `lib/widgets/map/voice_translation_overlay.dart`

---

### 3. AI行程规划 (AI Trip Planner)

**驱动**: DeepSeek API

**输入参数**:
- 城市选择 (6个主要城市)
- 行程天数 (1-5天)
- 兴趣标签 (文化/美食/自然/购物/夜生活/历史)
- 自由文本描述 (可选)

**输出**:
- 结构化JSON行程
- 按天分组的活动
- 预算建议

**关键文件**:
- `lib/screens/planner/planner_home_screen.dart` - AI规划入口
- 服务层实现: 待完成 (任务7)

---

### 4. 高德地图集成 (AMap Integration)

**功能**:
- ✅ 地图显示
- ✅ 定位服务
- ✅ Marker标记
- 🟡 POI搜索 (待完善)
- 🟡 路线规划 (待实现)

**关键文件**:
- `lib/services/amap_service.dart`
- `lib/widgets/map/wander_map.dart`
- `lib/core/config/amap_config.dart`

**API配置**:
- Android Key: 需在 `android/app/src/main/AndroidManifest.xml`
- iOS Key: 需在 `ios/Runner/Info.plist`

---

## 🗃️ 数据库架构

### 主数据库 (PostgreSQL)

**表数量**: 30+ 张表

**核心表**:

| 表名 | 用途 | 记录数估算 |
|------|------|-----------|
| `users` | 用户账户 | ~100K |
| `trips` | 行程 | ~200K |
| `places` | 景点/POI | ~50K |
| `posts` | 社区帖子 | ~500K |
| `challenges` | 挑战任务 | ~200 |
| `achievements` | 成就徽章 | ~50 |
| `expenses` | 费用记录 | ~1M |
| `notifications` | 通知 | ~5M |

**PostGIS扩展**: 用于地理空间查询

---

### 翻译数据库 (tencentcloud_translation)

**表数量**: 6张表

| 表名 | 用途 | 当前记录数 |
|------|------|-----------|
| `road_translations` | 道路名翻译 | 80 |
| `transit_station_translations` | 地铁站翻译 | 45 |
| `route_instruction_translations` | 路线指令翻译 | 30 |
| `area_translations` | 区域翻译 | 30 |
| `translation_cache` | 翻译缓存 | 动态 |
| `translation_feedback` | 用户反馈 | 0 |

**总计**: 185条预存翻译数据

---

## 🎨 UI/UX设计

### V2.0 设计系统

**颜色方案**:
- **主色 (Jade)**: `#10B981` - 激活状态、按钮
- **橙色 (Orange)**: `#FF6B35` - 语音按钮、高优先级
- **灰色系**:

文本和背景

**字体**:
- 标题: 16px, FontWeight.w600
- 正文: 14px, FontWeight.normal
- 副标题: 12px

**导航栏** (底部5个Tab):
```
[Home] [Map] [Planner] [Voice] [Me]
```

**参考文档**: `docs/design/SCREEN_SPECIFICATIONS_v2.md`

---

## 📡 API集成清单

| 服务 | 用途 | 状态 | API密钥配置 |
|------|------|------|------------|
| **DeepSeek** | AI翻译 + 行程规划 | ⏳ 待配置 | `DEEPSEEK_API_KEY` |
| **百度ASR** | 语音识别 | ⏳ 待配置 | `BAIDU_API_KEY` + `BAIDU_SECRET_KEY` |
| **百度TTS** | 语音合成 | ⏳ 待配置 | 同上 |
| **高德地图** | 地图+POI | ✅ 已配置 | `AMAP_KEY_IOS` + `AMAP_KEY_ANDROID` |
| **腾讯云PostgreSQL** | 数据库 | ⏳ 待部署 | `DB_HOST` + `DB_PASSWORD` |

**配置方式**:
1. 创建 `mobile_app/.env` 文件
2. 或使用 `--dart-define` 在运行时传递

---

## 🚀 MVP开发进度

根据 `mobile_app/MVP_PROGRESS_TRACKER.md`:

| 类别 | 完成度 | 状态 |
|------|--------|------|
| 设计阶段 | 95% | ✅ 完成 |
| 代码实现 | 40% | 🟡 进行中 |
| MVP范围调整 | 30% | 🟡 进行中 |
| **总体进度** | **55%** | 🟡 进行中 |

### 关键里程碑

- [x] 技术架构设计完成
- [x] UI/UX规范v2.0完成
- [x] 语音翻译服务实现
- [x] 地图翻译UI组件实现
- [ ] **数据库配置与数据导入** ← 当前重点
- [ ] 地图翻译服务完整实现
- [ ] AI行程规划服务实现
- [ ] MVP范围调整完成
- [ ] 内测版本发布

### 优先级任务 (P0 - 本周)

1. **配置腾讯云PostgreSQL** (2-3小时)
2. **执行数据库初始化** (30分钟)
3. **实现MapTranslationService** (4-6小时)
4. **完善高德POI搜索** (2-3小时)
5. **配置百度语音API** (1-2小时)
6. **配置DeepSeek API** (30分钟)

---

## 📋 待办事项清单

### 高优先级

- [ ] 部署腾讯云PostgreSQL数据库
- [ ] 配置所有API密钥
- [ ] 完成MapTranslationService实现
- [ ] 集成高德POI搜索API
- [ ] 实现AI行程规划服务
- [ ] 移除社区和挑战功能代码

### 中优先级

- [ ] 生成并导入6城市POI数据 (~2900条)
- [ ] 实现道路名翻译规则引擎
- [ ] 添加单元测试
- [ ] 优化性能和缓存策略
- [ ] 完善错误处理

### 低优先级

- [ ] 实现离线翻译包
- [ ] 添加用户反馈功能
- [ ] 国际化(i18n)支持
- [ ] 深色模式
- [ ] 无障碍功能

---

## 🔐 安全与隐私

### 已实施

- ✅ `.gitignore` 配置 (排除敏感文件)
- ✅ 环境变量管理 (`.env` 不提交)
- ✅ PostgreSQL行级安全策略 (RLS)
- ✅ JWT会话管理

### 待实施

- [ ] API密钥加密存储
- [ ] HTTPS强制连接
- [ ] 用户数据加密
- [ ] 隐私政策和用户协议
- [ ] 数据备份策略

---

## 🧪 测试策略

### 当前状态

- **单元测试**: 1个测试文件 (基本未实施)
- **集成测试**: 未实施
- **UI测试**: 未实施
- **E2E测试**: 未实施

### 计划

- [ ] 为核心服务添加单元测试 (覆盖率目标: 70%)
- [ ] 为UI组件添加Widget测试
- [ ] 集成测试 (API调用、数据库操作)
- [ ] E2E测试 (关键用户流程)

---

## 📦 部署流程

### 数据库部署

```bash
cd tencentcloud

# 1. 连接腾讯云PostgreSQL
psql -h your-host.com -U postgres -d wanderchina

# 2. 执行迁移脚本
\i migrations/000_auth_setup.sql
\i migrations/001_initial_schema.sql
\i migrations/002_row_level_security.sql
\i seed.sql

# 3. 执行翻译数据库脚本
\i tencentcloud_translation/map_translation_schema.sql
\i tencentcloud_translation/initial_translation_data.sql
```

### 移动应用构建

```bash
cd mobile_app

# 1. 安装依赖
flutter pub get

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env 填入API密钥

# 3. 构建iOS (需要Mac + Xcode)
flutter build ios --release

# 4. 构建Android
flutter build apk --release
# 或
flutter build appbundle --release
```

---

## 📚 文档维护

### 活跃文档 (需持续更新)

- `mobile_app/MVP_PROGRESS_TRACKER.md` - MVP进度
- `mobile_app/README.md` - 移动应用说明
- `tencentcloud/README.md` - 数据库部署
- `PROJECT_ARCHITECTURE.md` - 本文档

### 参考文档 (相对稳定)

- `docs/design/*.md` - 设计规范
- `docs/architecture/*.md` - 架构文档
- `docs/features/MVP_FEATURES.md` - 功能规范

### 归档文档 (已过时)

- `archive/docs_v1_planning/` - 早期规划文档
- `archive/supabase/` - 旧的Supabase方案
- `mobile_app/archive/implementation_guides/` - 实施指南

---

## 🔗 相关链接

### 外部文档

- [Flutter官方文档](https://flutter.dev/docs)
- [高德地图Flutter插件](https://lbs.amap.com/api/flutter/summary/)
- [DeepSeek API文档](https://platform.deepseek.com/api-docs)
- [百度语音API文档](https://ai.baidu.com/ai-doc/SPEECH/Vk38lxily)
- [腾讯云PostgreSQL文档](https://cloud.tencent.com/document/product/409)

### 内部资源

- [Figma设计稿](https://figma.com/...) - 待添加链接
- [项目看板](https://...) - 待添加链接
- [技术讨论群](https://...) - 待添加链接

---

## 👥 团队角色

### 当前阶段 (MVP)

- **全栈开发** - 负责移动应用和后端开发
- **UI/UX设计** - 参考 `docs/design/` 中的规范
- **AI/Claude Code** - 辅助开发和文档编写

### 未来扩展

- 前端工程师 (Flutter)
- 后端工程师 (PostgreSQL/云函数)
- DevOps工程师
- QA测试工程师
- 产品经理
- 设计师

---

## 📝 变更日志

### 2026-02-25
- ✅ 创建完整项目架构文档
- ✅ 整理并归档早期文档
- ✅ 初始化Git仓库
- ✅ 创建 `.gitignore` 配置

### 2026-02-24
- ✅ 清理SQL文件结构
- ✅ 创建 `tencentcloud_translation/` 文件夹
- ✅ 归档Supabase方案

### 2026-02-23
- ✅ 更新MVP进度跟踪器
- ✅ 完成地图翻译UI组件

### 2026-02-14
- ✅ 实现地图翻译蒙层系统
- ✅ 实现V2.0底部导航栏
- ✅ 创建AI行程规划入口页面

---

## 🆘 常见问题

### Q: 如何配置API密钥？
A: 创建 `mobile_app/.env` 文件，参考 `.env.example`

### Q: 数据库连接失败怎么办？
A: 检查腾讯云PostgreSQL是否已创建实例，确认VPC配置正确

### Q: Flutter构建失败？
A: 运行 `flutter clean && flutter pub get`，检查Flutter版本是否 >=3.24

### Q: 高德地图无法显示？
A: 确认API Key已配置在 `AndroidManifest.xml` 和 `Info.plist`

### Q: DeepSeek API调用超时？
A: 检查网络连接，确认API密钥有效，增加超时时间

---

## 📧 联系方式

- **项目仓库**: (待添加)
- **问题反馈**: (待添加)
- **技术支持**: (待添加)

---

**文档维护**: Development Team
**最后审阅**: 2026-02-25
**下次更新**: MVP完成后或重大变更时
