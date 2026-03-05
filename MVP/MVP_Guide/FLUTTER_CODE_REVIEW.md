# WanderChina Flutter 代码审查报告

**审查范围：** `mobile_app/lib/` 全部 64 个 Dart 文件（18,621 行）
**对照标准：** WANDERCHINA_TENCENT_CLOUD_CONFIG_v2.md + 3 份 API 配置文档 v2
**审查日期：** 2026-03-04

---

## 审查结论

代码库处于 **Supabase → 腾讯云迁移的半完成状态**。UI 层（screens/widgets）完成度约 60%，基本可用；但 **服务层（services）几乎全部需要重写**，因为当前架构直接从 Flutter 连接 PostgreSQL 和调用第三方 API，严重违反 v2.0 的云函数中间层设计。

发现 **7 个必须修复项 + 5 个建议优化项**。

---

## 🔴 必须修复（开发前处理）

### F1. Flutter 直连 PostgreSQL — 必须彻底移除

**位置：**
- `lib/services/map/poi_translation_service.dart:3` — `import 'package:postgres/postgres.dart'`
- `lib/services/map/poi_translation_service.dart:26-30` — 直接用 `BackendConfig.databaseHost` 连接 PG
- `lib/services/backend/auth_service.dart` — 整个文件通过 `DatabaseService` 直接操作 users 表
- `lib/services/map_translation_service.dart:5` — 通过 `DatabaseService` 查翻译表

**问题：** Flutter 是客户端应用，APK/IPA 可被反编译。`BackendConfig` 里的 DB_HOST、DB_PASSWORD 一旦发布就等于向全世界公开数据库密码。v2.0 架构明确规定：Flutter 只调云函数 URL，永不接触数据库凭证。

**修复：** 删除所有直连代码。所有数据操作改为 HTTP 调用对应的云函数 URL：
- 翻译查询 → `get_nearby_pois` + `translate_db_write(batch_get)`
- 用户认证 → `user_auth`
- 行程操作 → `create_trip`

`pubspec.yaml` 中移除 `postgres: ^3.0.2`。

---

### F2. Flutter 直调百度语音 API — 必须改走云函数

**位置：** `lib/services/voice/voice_translation_service.dart:41-43`
```dart
static const String _baiduASRUrl   = 'https://vop.baidu.com/server_api';
static const String _baiduTTSUrl   = 'https://tsn.baidu.com/text2audio';
static const String _baiduTokenUrl = 'https://aip.baidubce.com/oauth/2.0/token';
```
**第 71-72 行：** `BackendConfig.baiduApiKey` 和 `BackendConfig.baiduSecretKey` 直接用于获取 Token。

**问题：** 这正是我们在 BAIDU_SPEECH_CONFIG 审查中标记的 C1 级安全漏洞。百度 API Key 暴露在客户端，反编译即可提取。

**修复：** 三个百度 URL 全部替换为两个云函数 URL：
- `_baiduASRUrl` → `ASR_URL`（baidu_voice_asr 云函数）
- `_baiduTTSUrl` → `TTS_URL`（baidu_voice_tts 云函数）
- 删除 `_baiduTokenUrl` 和 Token 管理代码（Token 在云函数服务端管理）

---

### F3. Flutter 直调 DeepSeek API — 必须改走云函数

**位置：**
- `lib/services/voice/voice_translation_service.dart:274-276` — `api.deepseek.com` + `BackendConfig.deepseekApiKey`
- `lib/services/map/poi_translation_service.dart:164` — 同上

**修复：** 替换为 `TRANSLATE_URL`（deepseek_translate 云函数）。`pubspec.yaml` 中移除 `crypto: ^3.0.3`（密码哈希应在服务端）。

---

### F4. Cloudflare R2 存储代码 — 必须替换为 COS

**位置：**
- `lib/core/config/backend_config.dart:46-75` — R2 配置（r2AccountId, r2AccessKeyId, r2SecretAccessKey）
- `lib/services/backend/storage_service.dart` — 整个文件基于 Minio SDK 连接 R2
- `pubspec.yaml` 注释行 — `# minio: ^5.0.0`

**问题：** v2.0 已决定用腾讯云 COS 替代 R2。存储服务完全需要重写。

**修复：** `StorageService` 重写为两步：
1. 调 `get_cos_token` 云函数获取 STS 临时凭证
2. 用临时凭证直传 COS（或用腾讯 COS SDK for Flutter）

从 `BackendConfig` 中删除所有 R2 配置，替换为：
```dart
static const String cosStaticUrl = String.fromEnvironment('COS_STATIC_URL');
static const String cosUserBucket = String.fromEnvironment('COS_USER_BUCKET');
static const String cosRegion = String.fromEnvironment('COS_REGION');
```

---

### F5. backend_config.dart 重写 — 移除所有后端凭证

**位置：** `lib/core/config/backend_config.dart`（整个文件）

**当前状态：** 包含 DB_HOST、DB_PASSWORD、R2_ACCESS_KEY、JWT_SECRET、DEEPSEEK_API_KEY、BAIDU_API_KEY、BAIDU_SECRET_KEY。

**v2.0 要求：** Flutter .env 只存函数 URL + 高德 Key + COS 公开信息。

**修复：** 重写为：

```dart
class BackendConfig {
  // ===== 云函数 URL（唯一的后端入口）=====
  static const String translateUrl = String.fromEnvironment('TRANSLATE_URL');
  static const String dbWriteUrl = String.fromEnvironment('DB_WRITE_URL');
  static const String nearbyUrl = String.fromEnvironment('NEARBY_URL');
  static const String authUrl = String.fromEnvironment('AUTH_URL');
  static const String tripUrl = String.fromEnvironment('TRIP_URL');
  static const String cosTokenUrl = String.fromEnvironment('COS_TOKEN_URL');
  static const String asrUrl = String.fromEnvironment('ASR_URL');
  static const String ttsUrl = String.fromEnvironment('TTS_URL');

  // ===== COS 公开信息 =====
  static const String cosStaticUrl = String.fromEnvironment('COS_STATIC_URL');
  static const String cosUserBucket = String.fromEnvironment('COS_USER_BUCKET');
  static const String cosRegion = String.fromEnvironment('COS_REGION');

  // ===== 高德地图 =====
  static const String amapKeyAndroid = String.fromEnvironment('AMAP_KEY_ANDROID');
  static const String amapKeyIos = String.fromEnvironment('AMAP_KEY_IOS');

  static bool get isConfigured => translateUrl.isNotEmpty && authUrl.isNotEmpty;
}
```

`.env.example` 同步更新。

---

### F6. 旧数据库 Schema（40 张表）需要清理

**位置：** `tencentcloud/migrations/001_initial_schema.sql` — 40 张表

**问题：** v2.0 MVP 只有 4 张表（poi_translations, users, user_sessions, trips + trip_days）。旧 schema 包含社区帖子（posts/comments/likes）、挑战系统（challenges/achievements）、旅行伴侣（companion_profiles）、本地向导（local_guides/guide_bookings）、预订（bookings/subscriptions/payments）等。这些全是 v1.0 的全功能设计，不属于 MVP。

**修复：** 用任务书 Phase 2 的 SQL 替代。旧 migrations 移入 `archive/migrations_v1/`。

---

### F7. pubspec.yaml 依赖清理

**需移除（不应在客户端）：**
```yaml
postgres: ^3.0.2          # 直连数据库，安全风险
# minio: ^5.0.0           # R2 已弃用
dart_jsonwebtoken: ^2.13.0 # JWT 验证应在服务端
crypto: ^3.0.3             # 密码哈希应在服务端
google_maps_flutter: ^2.5.0 # 不用 Google Maps，用高德
```

**需添加：**
```yaml
flutter_dotenv: ^5.1.0     # .env 文件读取（当前用 String.fromEnvironment，两种方案选一）
```

**注意：** 当前用 `String.fromEnvironment` + `--dart-define-from-file=.env`，这是编译时注入，比 flutter_dotenv 的运行时读取更安全（值编译进二进制而非明文 .env 文件随包）。如果坚持用这种方式，不需要加 flutter_dotenv，但每次改 .env 需要重新编译。两种方案各有利弊，建议保持当前 `String.fromEnvironment` 方式。

---

## 🟡 建议优化

### O1. 语言管理器只支持 zh/en — 应扩展为 en/fr/es

**位置：** `lib/core/services/language_manager.dart`

**当前：** `_currentLanguage` 只接受 `'zh'` 和 `'en'`。`toggleLanguage()` 在中英文之间切换。`AppTexts` 所有文本只有中英两个版本。

**v2.0：** 目标用户是外国游客，MVP 支持 3 种语言（en/fr/es），App UI 语言应默认英文，中文是开发调试用。

**修复：**
- `_currentLanguage` 改为 enum：`{ en, fr, es }`（移除 zh，App 面向外国用户）
- `AppTexts` 扩展为三语 fallback：`text(english, french, spanish)`
- 如果用户语言是法语但该文本没有法语翻译，fallback 到英语

---

### O2. 重复/冗余文件清理

**问题：** 同名或相似功能的文件散落在不同目录：

| 文件 | 目录 | 功能 | 建议 |
|------|------|------|------|
| `poi_translation_service.dart` | `lib/services/` | POI 翻译（本地词典+百度翻译） | 合并 |
| `poi_translation_service.dart` | `lib/services/map/` | POI 翻译（直连 PG+DeepSeek） | 合并 |
| `map_screen.dart` | `lib/screens/map/` | 基础地图 | 保留一个 |
| `map_screen_new.dart` | `lib/screens/map/` | 新版地图 | 移除 |
| `map_screen_with_translation.dart` | `lib/screens/map/` | 带翻译的地图 | 移除 |
| `map_with_translation_screen.dart` | `lib/screens/map/` | 同上（名字略不同）| 保留这个 |
| `main.dart` | `lib/` | 当前入口 | 合并 |
| `main_backend.dart` | `lib/` | 后端集成示例入口 | 移除 |

**修复：** 合并为单一服务、单一地图页面。多余文件移入 `archive/`。

---

### O3. 社区/挑战代码仍存在 — 按进度表任务 11-12 移除

**位置：**
- `lib/screens/community/community_screen.dart`
- `lib/screens/challenges/challenges_screen.dart`
- `lib/screens/challenges/challenge_detail_screen.dart`
- `lib/models/challenge.dart`
- `lib/models/achievement.dart`
- `lib/screens/budget/budget_screen.dart`（Budget 不在 MVP 范围）
- `lib/screens/discover/discover_screen.dart`（已被 Map tab 替代）

**修复：** 移入 `archive/screens_v1/`。MainScreen 的 5 个 tab 已正确实现（Home·Map·Planner·Voice·Me），移除后不影响导航。

---

### O4. main.dart 初始化过多服务

**位置：** `lib/main.dart` — 6 个服务逐个初始化

**问题：** 当前初始化 LanguageManager、AMapService、POITranslationService、MapTranslationService、overlay.POITranslationService、VoiceTranslationService。重写后大部分服务会变成简单的 HTTP 客户端，不需要复杂初始化。且两个 POITranslationService（不同 import 别名）说明服务重复。

**修复：** 合并为 `main_backend.dart` 风格的单一 `BackendManager.initialize()`，只做：
1. 初始化高德 SDK
2. 验证云函数 URL 已配置
3. 尝试匿名认证或恢复 session

---

### O5. .env.example 需要更新

**位置：** `mobile_app/.env.example`

**当前：** 包含 DB_HOST、DB_PASSWORD、R2_ACCOUNT_ID、R2_ACCESS_KEY 等后端凭证。

**修复：** 替换为 v2.0 版本（只有函数 URL + 高德 Key + COS 公开信息），与 F5 的 BackendConfig 重写对齐。

---

## ✅ 无需修改（已对齐 v2.0）

| 模块 | 状态 | 说明 |
|------|------|------|
| MainScreen 导航 | ✅ | 5 个 tab (Home·Map·Planner·Voice·Me) 已正确实现 |
| Voice tab 模态框 | ✅ | index==3 打开 fullscreenDialog，符合 v2.0 |
| 高德地图 SDK | ✅ | amap_flutter_map/base/location 3.0.0 |
| AMapConfig | ✅ | String.fromEnvironment 读取，有 isApiKeyConfigured 校验 |
| 状态管理 | ✅ | flutter_riverpod 2.4.0 |
| 主题系统 | ✅ | AppTheme.lightTheme/darkTheme 已实现 |
| Splash/Onboarding | ✅ | 完整实现 |
| Voice UI 组件 | ✅ | VoiceTranslationScreen + overlay 已实现 |
| 地图 UI 组件 | ✅ | WanderMap、TranslationOverlay、BilingualPOIInfoWindow 已实现 |
| IndexedStack 页面保活 | ✅ | MainScreen 正确使用 IndexedStack |
| SCREEN_SPECIFICATIONS_v2.md | ✅ | 1121 行，完整可用 |

---

## 📊 代码库结构图（当前 vs 目标）

```
当前代码库 (64 files, 18621 lines)          目标状态
─────────────────────────────────       ─────────────────────
lib/
├── core/
│   ├── config/
│   │   ├── amap_config.dart     ✅     保留
│   │   └── backend_config.dart  🔴F5   重写（移除所有凭证）
│   ├── constants/               ✅     保留
│   ├── services/
│   │   ├── backend_manager.dart 🔴     重写（HTTP 客户端）
│   │   └── language_manager.dart🟡O1   扩展 en/fr/es
│   └── theme/                   ✅     保留
├── models/
│   ├── poi.dart                 ✅     保留
│   ├── poi_translation.dart     ✅     保留
│   ├── translated_poi.dart      ✅     保留
│   ├── translated_route.dart    ✅     保留
│   ├── itinerary.dart           ✅     保留
│   ├── expense.dart             🟡     MVP 不用，archive
│   ├── achievement.dart         🟡O3   archive
│   └── challenge.dart           🟡O3   archive
├── screens/
│   ├── main/main_screen.dart    ✅     保留
│   ├── home/home_screen.dart    ✅     保留
│   ├── map/
│   │   ├── map_with_trans...    ✅     保留（主地图页）
│   │   ├── map_screen.dart      🟡O2   archive
│   │   ├── map_screen_new.dart  🟡O2   archive
│   │   └── map_screen_with...   🟡O2   archive
│   ├── planner/                 ✅     保留（4 个文件）
│   ├── voice/                   ✅     保留
│   ├── onboarding/              ✅     保留
│   ├── profile/                 ✅     保留
│   ├── budget/                  🟡O3   archive
│   ├── challenges/              🟡O3   archive
│   ├── community/               🟡O3   archive
│   └── discover/                🟡O3   archive
├── services/
│   ├── backend/
│   │   ├── auth_service.dart    🔴F1   重写（调 user_auth URL）
│   │   ├── storage_service.dart 🔴F4   重写（调 get_cos_token）
│   │   └── database_service.dart🔴F1   删除（不再直连 DB）
│   ├── map/
│   │   └── poi_trans...dart     🔴F1   重写（调 get_nearby_pois）
│   ├── voice/
│   │   └── voice_trans...dart   🔴F2,F3 重写（调 ASR/TTS/translate URL）
│   ├── amap_service.dart        ✅     保留
│   ├── map_translation...dart   🔴F1   重写（调云函数）
│   ├── poi_service.dart         ✅     保留
│   ├── poi_translation...dart   🟡O2   合并到 map/ 版本
│   ├── route_planning...dart    ✅     保留
│   ├── currency_service.dart    ✅     保留
│   └── offline_map_service.dart ✅     保留
├── widgets/                     ✅     全部保留
├── main.dart                    🟡O4   简化初始化
└── main_backend.dart            🟡O2   删除

tencentcloud/
├── migrations/
│   ├── 001_initial_schema.sql   🔴F6   移入 archive（40表→4表）
│   └── ...
└── seed.sql                     🟡     用任务书 Phase 6 脚本替代
```

---

## 🎯 建议执行顺序

Claude Code 开始 Flutter 端开发前，按以下顺序清理：

**Step 1（30 分钟）— 安全清理：**
- 重写 `backend_config.dart`（F5）
- 更新 `.env.example`（O5）
- 清理 `pubspec.yaml`（F7）

**Step 2（1 小时）— 服务层重写：**
- 新建 `lib/services/api_client.dart`（统一 HTTP 客户端，封装 8 个云函数调用）
- 重写 `auth_service.dart`（F1）→ 调 `authUrl`
- 重写 `voice_translation_service.dart`（F2, F3）→ 调 `asrUrl` / `ttsUrl` / `translateUrl`
- 重写 `poi_translation_service.dart`（F1）→ 调 `nearbyUrl` / `dbWriteUrl`
- 重写 `storage_service.dart`（F4）→ 调 `cosTokenUrl`
- 删除 `database_service.dart`

**Step 3（30 分钟）— 代码清理：**
- 移除冗余文件（O2）
- 移除社区/挑战/预算代码（O3）
- 简化 main.dart（O4）
- 旧 migrations 移入 archive（F6）

**Step 4（可选）— 语言扩展：**
- 扩展 LanguageManager 支持 en/fr/es（O1）

清理后代码库预计从 64 文件 → ~45 文件，18621 行 → ~13000 行，且零安全漏洞。

---

## 交给 Claude Code 的指令摘要

```
你拿到的 Flutter 代码库有以下已知问题需要先修复：

1. 当前代码直接从 Flutter 连 PostgreSQL 数据库和调用百度/DeepSeek API，
   这是严重安全漏洞。所有后端交互必须改为调用云函数 URL。

2. 新建 lib/services/api_client.dart，封装 8 个云函数的 HTTP 调用。

3. 重写 backend_config.dart，只保留云函数 URL 和高德 Key。

4. 移除 postgres、dart_jsonwebtoken、crypto、google_maps_flutter 依赖。

5. 删除 Cloudflare R2 相关代码，存储改用 COS 临时凭证上传。

6. 移除社区、挑战、预算相关代码到 archive/。

7. 合并重复的 poi_translation_service 和地图页面。

参考文档：WANDERCHINA_TENCENT_CLOUD_CONFIG_v2.md §7（云函数代码）和 §11（Flutter .env）
```
