# WanderChina MVP 开发进度追踪

**最后更新：** 2026-02-23
**当前阶段：** MVP 开发
**目标发布：** Beta Launch

---

## 📊 总体进度

| 类别 | 完成度 | 状态 |
|------|--------|------|
| **设计阶段** | 95% | ✅ 完成 |
| **代码实现** | 40% | 🟡 进行中 |
| **MVP范围调整** | 30% | 🟡 进行中 |
| **总体进度** | **55%** | 🟡 进行中 |

---

## 🎯 关键里程碑

- [x] 技术架构设计完成
- [x] UI/UX规范v2.0完成
- [x] 语音翻译服务实现
- [x] 地图翻译UI组件实现
- [ ] 数据库配置与数据导入 ← **当前重点**
- [ ] 地图翻译服务完整实现
- [ ] AI行程规划服务实现
- [ ] MVP范围调整完成
- [ ] 内测版本发布

---

## 📋 任务清单

### **P0 - 核心功能（必须完成）**

#### ✅ 已完成

- [x] 设计腾讯云架构 (`WANDERCHINA_TENCENT_CLOUD_CONFIG.md`)
- [x] 设计百度语音API方案 (`WANDERCHINA_BAIDU_SPEECH_CONFIG.md`)
- [x] 设计地图翻译蒙层规范 (`WANDERCHINA_MAP_TRANSLATION_SPEC.md`)
- [x] 设计UI/UX规范v2.0 (`SCREEN_SPECIFICATIONS_v2.md`)
- [x] 实现VoiceTranslationService (`lib/services/voice/voice_translation_service.dart`)
- [x] 实现WanderMap组件 (`lib/widgets/map/wander_map.dart`)
- [x] 实现TranslationOverlay组件 (`lib/widgets/map/translation_overlay_widget.dart`)
- [x] 实现VoiceTranslationOverlay组件 (`lib/widgets/map/voice_translation_overlay.dart`)
- [x] 配置BackendConfig (`lib/core/config/backend_config.dart`)

#### 🔴 待办 - 第一阶段（本周）

- [ ] **任务1：配置腾讯云PostgreSQL数据库连接**
  - [ ] 在腾讯云创建PostgreSQL实例 (TDSQL-C Serverless)
  - [ ] 配置VPC私有网络 (`wanderchina-vpc`, `172.16.0.0/16`)
  - [ ] 获取数据库连接信息（host, port, username, password）
  - [ ] 创建 `.env` 文件并配置数据库凭证
  - [ ] 测试数据库连接
  - **预计时间：** 2-3小时
  - **参考文档：** `docs/design/WANDERCHINA_TENCENT_CLOUD_CONFIG.md` 第3节
  - **状态：** ⏳ Pending

- [ ] **任务2：执行POI翻译数据库初始化脚本**
  - [ ] 连接腾讯云PostgreSQL
  - [ ] 执行 `database/map_translation_schema.sql`
  - [ ] 验证PostGIS扩展已安装 (`CREATE EXTENSION postgis`)
  - [ ] 验证索引已创建 (`idx_poi_city`, `idx_poi_priority`, `idx_poi_location`)
  - [ ] 验证触发器已创建 (`update_updated_at`)
  - **预计时间：** 30分钟
  - **参考文档：** `docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md` 第6节
  - **状态：** ⏳ Pending

- [ ] **任务3：实现MapTranslationService (三级缓存+DeepSeek批量翻译)**
  - [ ] 重构 `lib/services/map_translation_service.dart`
  - [ ] 实现内存缓存 (`Map<String, POITranslation>`)
  - [ ] 实现数据库查询层
  - [ ] 实现DeepSeek批量翻译接口 (`_callDeepSeekBatch()`)
  - [ ] 实现 `translateRawPOIs()` 方法
  - [ ] 实现 `_preloadCorePOIs()` - 预加载2000条核心POI
  - [ ] 实现防抖机制(300ms)
  - **预计时间：** 4-6小时
  - **参考文档：** `docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md` 第7.2节 (完整代码)
  - **文件位置：** `lib/services/map/map_translation_service.dart` (新建)
  - **状态：** ⏳ Pending

- [ ] **任务4：完善WanderMap高德POI搜索集成**
  - [ ] 集成高德 `AMapPOISearch` API
  - [ ] 实现 `_fetchVisiblePOIs()` 方法 (替换当前的TODO占位符)
  - [ ] 实现POI类型筛选 (景点/地铁/餐饮/购物等)
  - [ ] 实现视窗边界计算
  - [ ] 测试POI搜索功能
  - **预计时间：** 2-3小时
  - **参考文档：** `docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md` 第7.6节 line 1770-1805
  - **文件位置：** `lib/widgets/map/wander_map.dart` line 93-114
  - **状态：** ⏳ Pending

- [ ] **任务5：配置百度语音API密钥并测试Token获取**
  - [ ] 在百度智能云注册并完成实名认证
  - [ ] 创建语音服务应用
  - [ ] 获取API Key和Secret Key
  - [ ] 更新 `.env` 文件
    ```env
    BAIDU_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxx
    BAIDU_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    ```
  - [ ] 运行测试代码验证Token获取成功
  - **预计时间：** 1-2小时
  - **参考文档：** `docs/design/WANDERCHINA_BAIDU_SPEECH_CONFIG.md` 第2-3节
  - **状态：** ⏳ Pending

- [ ] **任务6：配置DeepSeek API密钥**
  - [ ] 在DeepSeek官网注册
  - [ ] 获取API密钥
  - [ ] 更新 `.env` 文件
    ```env
    DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxxxx
    ```
  - [ ] 测试API调用 (翻译测试)
  - **预计时间：** 30分钟
  - **参考文档：** `docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md` 第7.2节
  - **状态：** ⏳ Pending

---

### **P1 - 重要功能**

#### 🟡 待办 - 第二阶段（下周）

- [ ] **任务7：实现AI行程规划服务 (DeepSeek驱动)**
  - [ ] 创建 `lib/services/ai/ai_trip_planner_service.dart`
  - [ ] 实现DeepSeek对话接口
  - [ ] 实现城市+天数+兴趣标签解析
  - [ ] 实现行程JSON生成
  - [ ] 实现行程保存到数据库
  - [ ] 集成到PlannerScreen
  - **预计时间：** 6-8小时
  - **参考文档：** `docs/design/SCREEN_SPECIFICATIONS_v2.md` Screen 9-10
  - **状态：** ⏳ Pending

- [ ] **任务8：生成并导入6城市核心POI翻译数据 (~2900条)**
  - [ ] 生成地铁站数据 (~2200条)
    - [ ] 北京 (~450站)
    - [ ] 上海 (~420站)
    - [ ] 广州 (~280站)
    - [ ] 深圳 (~230站)
    - [ ] 成都 (~210站)
    - [ ] 西安 (~130站)
  - [ ] 生成交通枢纽数据 (~60条)
    - [ ] 机场、火车站、长途汽车站
  - [ ] 生成核心景点数据 (~300条)
    - [ ] 博物馆、公园、历史遗址
  - [ ] 生成涉外医院数据 (~40条)
  - [ ] 生成 `sql/poi_translations_seed.sql`
  - [ ] 执行SQL导入数据库
  - [ ] 验证数据导入 (运行验证SQL)
  - **预计时间：** 8-10小时 (可使用高德API批量查询加速)
  - **参考文档：** `docs/design/WANDERCHINA_TRANSLATION_DATA_SPEC.md` 第3-6节
  - **状态：** ⏳ Pending

- [ ] **任务9：实现道路名翻译规则引擎**
  - [ ] 创建 `lib/services/map/road_name_translator.dart`
  - [ ] 实现方位词映射 (东→East, 西→West, 南→South, 北→North)
  - [ ] 实现路型后缀映射 (大道→Avenue, 路→Road, 街→Street)
  - [ ] 实现特殊地名映射 (中关村→Zhongguancun)
  - [ ] 实现数字路名处理 (一环路→1st Ring Road)
  - [ ] 集成拼音转换包 (`lpinyin` 或 `pinyin4dart`)
  - [ ] 更新 `pubspec.yaml` 添加依赖
  - [ ] 测试翻译规则
  - **预计时间：** 3-4小时
  - **参考文档：** `docs/design/WANDERCHINA_TRANSLATION_DATA_SPEC.md` 第7节
  - **状态：** ⏳ Pending

---

### **P2 - MVP范围调整**

#### 🟢 待办 - 第三阶段（优化）

- [ ] **任务10：更新底部导航栏为v2.0规范**
  - [ ] 找到主导航组件 (`lib/widgets/navigation/` 或主screen)
  - [ ] 将5个tab从 `[Home][Discover][Community][Planner][Me]` 更新为 `[Home][Map][Planner][Voice][Me]`
  - [ ] 添加Voice tab - 打开 `VoiceTranslationScreen` 全屏模式
  - [ ] 将Discover tab 替换为 Map tab
  - [ ] 移除Community tab
  - [ ] 更新导航图标
  - **预计时间：** 2小时
  - **参考文档：** `docs/design/SCREEN_SPECIFICATIONS_v2.md` Line 22, Screen 6
  - **状态：** ⏳ Pending

- [ ] **任务11：移除社区功能相关代码**
  - [ ] 删除 `lib/screens/community/` 目录 (如存在)
  - [ ] 删除 `lib/screens/posts/` 目录 (如存在)
  - [ ] 删除 `lib/models/post.dart` (如存在)
  - [ ] 删除 `lib/models/comment.dart` (如存在)
  - [ ] 从HomeScreen中移除Community卡片
  - [ ] 从导航栏中移除Community入口
  - **预计时间：** 1-2小时
  - **参考文档：** `docs/design/SCREEN_SPECIFICATIONS_v2.md` Line 14-16 (v2.0变更说明)
  - **状态：** ⏳ Pending

- [ ] **任务12：移除挑战系统相关代码**
  - [ ] 删除 `lib/screens/challenges/` 目录
  - [ ] 删除 `lib/models/challenge.dart`
  - [ ] 删除 `lib/models/achievement.dart`
  - [ ] 从HomeScreen中移除Challenge卡片
  - [ ] 从快捷工具中移除Challenge入口
  - **预计时间：** 1小时
  - **参考文档：** `docs/design/SCREEN_SPECIFICATIONS_v2.md` Line 14-16 (v2.0变更说明)
  - **状态：** ⏳ Pending

---

## 🚀 执行计划

### 第一阶段（本周 2026-02-23 ~ 02-29）
**目标：** 完成基础设施 + 地图翻译核心功能

**Day 1-2:**
- ✅ 任务1：配置腾讯云PostgreSQL数据库
- ✅ 任务2：执行数据库初始化脚本

**Day 3-4:**
- ✅ 任务3：实现MapTranslationService
- ✅ 任务4：完善高德POI搜索

**Day 5:**
- ✅ 任务5：配置百度语音API
- ✅ 任务6：配置DeepSeek API

**验收标准：**
- [ ] 地图可正常显示高德底图
- [ ] 放大地图至zoom≥14时，显示英文/法文/西班牙文翻译标签
- [ ] 点击语音按钮可录音并翻译
- [ ] 数据库已连接并包含种子数据

---

### 第二阶段（下周 2026-03-01 ~ 03-07）
**目标：** 完成AI功能 + 数据预存

**Day 1-3:**
- ✅ 任务7：实现AI行程规划服务

**Day 4-6:**
- ✅ 任务8：生成并导入POI翻译数据

**Day 7:**
- ✅ 任务9：实现道路名翻译引擎

**验收标准：**
- [ ] 用户可通过AI生成1-5天行程
- [ ] 地图翻译响应速度 < 500ms (预存数据命中)
- [ ] 道路名可正确翻译 (如"长安街" → "Chang'an Avenue")

---

### 第三阶段（2026-03-08 ~ 03-10）
**目标：** MVP范围调整 + 代码清理

**Day 1:**
- ✅ 任务10：更新底部导航栏

**Day 2:**
- ✅ 任务11：移除社区功能
- ✅ 任务12：移除挑战系统

**验收标准：**
- [ ] 底部导航栏为5个tab (Home·Map·Planner·Voice·Me)
- [ ] 代码库中无社区/挑战相关代码
- [ ] 编译通过，无遗留错误

---

## 📌 关键注意事项

### 环境变量管理
创建 `.env` 文件 (不提交到git):
```env
# Database
DB_HOST=your-tencentcloud-host.com
DB_PORT=5432
DB_NAME=wanderchina
DB_USERNAME=wc_readonly
DB_PASSWORD=your_password_here
DB_SSL=true

# DeepSeek
DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxxxx

# Baidu Speech
BAIDU_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxx
BAIDU_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 高德地图 (Android/iOS分开)
AMAP_KEY_IOS=xxxxxxxxxxxxxxxxxx
AMAP_KEY_ANDROID=xxxxxxxxxxxxxxxxxx
```

### 依赖包版本
确保 `pubspec.yaml` 包含：
```yaml
dependencies:
  postgres: ^3.0.2
  record: ^5.1.2
  audioplayers: ^6.0.0
  path_provider: ^2.1.1
  http: ^1.1.0
  amap_flutter_map: ^3.0.0
  amap_flutter_base: ^3.0.0

  # 待添加 (任务9)
  # lpinyin: ^2.0.2  # 道路名拼音转换
```

### 技术难点
1. **高德地图API版本差异：** 不同版本的 `amap_flutter_map` POI搜索API可能有差异，需查阅当前版本文档
2. **DeepSeek批量翻译：** 单次最多翻译20个POI，避免超过token限制
3. **PostgreSQL连接池：** MVP阶段最大连接数5-10即可，避免资源浪费
4. **地图标签去重：** 屏幕坐标最小距离80px，避免标签重叠

---

## 📚 参考文档

| 文档 | 路径 | 用途 |
|------|------|------|
| 腾讯云配置 | `docs/design/WANDERCHINA_TENCENT_CLOUD_CONFIG.md` | 任务1-2 |
| 百度语音配置 | `docs/design/WANDERCHINA_BAIDU_SPEECH_CONFIG.md` | 任务5 |
| 地图翻译规范 | `docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md` | 任务3-4, 6 |
| UI规范v2.0 | `docs/design/SCREEN_SPECIFICATIONS_v2.md` | 任务7, 10-12 |
| 翻译数据规范 | `docs/design/WANDERCHINA_TRANSLATION_DATA_SPEC.md` | 任务8-9 |
| 初始化SQL | `database/map_translation_schema.sql` | 任务2 |

---

## ✅ 任务完成检查清单

每完成一个任务后，在对应任务前打勾 `[x]`，并更新以下内容：

1. **更新总体进度百分比** (顶部)
2. **标记任务状态**：⏳ Pending → 🔄 In Progress → ✅ Done
3. **记录实际耗时** vs 预计时间
4. **记录遇到的问题和解决方案** (文件末尾)
5. **更新下一步计划**

---

## 🐛 问题与解决方案记录

### 任务1相关问题
<!-- 完成任务1后在此记录遇到的问题 -->

### 任务2相关问题
<!-- 完成任务2后在此记录遇到的问题 -->

<!-- 其他任务问题记录... -->

---

**最后更新人：** Claude
**下次review时间：** 第一阶段完成后 (预计 2026-02-29)
