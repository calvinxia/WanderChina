# WanderChina 地图翻译数据库

## 📋 概述

此文件夹包含WanderChina地图翻译功能的专用数据库表结构和初始数据。

**用途**: 为移动应用提供POI（地点）、道路、地铁站点等地图元素的多语言翻译支持。

---

## 📁 文件说明

### 1. `map_translation_schema.sql` (352行)
**数据库表结构定义**

包含6个核心表：
- `road_translations` - 道路名称翻译
- `transit_station_translations` - 公交/地铁站点翻译
- `route_instruction_translations` - 路线指令翻译（左转、右转等）
- `area_translations` - 区域/地名翻译
- `translation_cache` - 翻译结果缓存
- `translation_feedback` - 用户翻译反馈

**特性**:
- UUID主键
- 自动更新时间戳触发器
- 验证状态和置信度字段
- 使用统计追踪
- 高优先级道路和验证站点视图

### 2. `initial_translation_data.sql` (281行)
**初始种子数据**

包含6个城市的基础翻译数据：
- **道路翻译**: ~80条（环路、主干道、著名街道）
- **地铁站翻译**: ~45条（核心站点+换乘站）
- **路线指令**: ~30条（转弯、直行、公交等）
- **区域翻译**: ~30条（行政区、商圈、地标）

**覆盖城市**:
- 北京 (Beijing)
- 上海 (Shanghai)
- 广州 (Guangzhou)
- 深圳 (Shenzhen)
- 成都 (Chengdu)
- 西安 (Xi'an)

---

## 🚀 部署步骤

### 前置要求
- 腾讯云PostgreSQL 14+
- PostGIS扩展已启用
- 数据库连接权限

### 执行顺序

```bash
# 1. 连接到腾讯云PostgreSQL
psql -h your-host.tencentcloud.com -U postgres -d wanderchina

# 2. 执行建表脚本
\i map_translation_schema.sql

# 3. 导入初始数据
\i initial_translation_data.sql

# 4. 验证安装
SELECT
    '道路翻译' as category, count(*) as count FROM road_translations
UNION ALL
SELECT
    '站点翻译' as category, count(*) as count FROM transit_station_translations
UNION ALL
SELECT
    '指令翻译' as category, count(*) as count FROM route_instruction_translations
UNION ALL
SELECT
    '区域翻译' as category, count(*) as count FROM area_translations;
```

**预期结果**:
```
   category   | count
--------------+-------
 道路翻译     |    80
 站点翻译     |    45
 指令翻译     |    30
 区域翻译     |    30
```

---

## 🔗 集成说明

### 与主数据库的关系

此地图翻译数据库与主数据库（`../migrations/`）是独立的，但可以联合使用：

```sql
-- 示例：查询用户收藏的地点及其翻译
SELECT
    sp.user_id,
    p.name AS place_name,
    rt.road_name_en AS road_translation,
    at.area_name_en AS area_translation
FROM saved_places sp
JOIN places p ON sp.place_id = p.id
LEFT JOIN road_translations rt ON rt.road_name_zh = p.address
LEFT JOIN area_translations at ON at.area_name_zh = p.city;
```

### 移动应用集成

**服务**: `lib/services/map_translation_service.dart`

**三级缓存机制**:
1. **内存缓存** (<1ms) - Map<String, POITranslation>
2. **数据库查询** (~50ms) - 从这些表查询
3. **DeepSeek API** (~500ms) - 实时翻译兜底

---

## 📊 数据统计

| 表名 | 记录数 | 覆盖城市 | 验证状态 |
|------|--------|----------|----------|
| road_translations | 80 | 6 | 100% verified |
| transit_station_translations | 45 | 6 | 100% verified |
| route_instruction_translations | 30 | 通用 | 100% verified |
| area_translations | 30 | 6 | 100% verified |

---

## 🛠️ 扩展建议

### 添加新城市数据

```sql
-- 添加杭州道路翻译
INSERT INTO road_translations (road_name_zh, road_name_en, city, road_type, road_level, verified) VALUES
('西湖大道', 'West Lake Avenue', '杭州', '大道', 2, true),
('延安路', 'Yan''an Road', '杭州', '道路', 2, true);

-- 添加杭州地铁站
INSERT INTO transit_station_translations (station_name_zh, station_name_en, city, station_type, line_name_zh, line_name_en, line_number, latitude, longitude, verified) VALUES
('武林广场', 'Wulin Square', '杭州', 'metro', '1号线', 'Line 1', '1', 30.2808, 120.1664, true);
```

### 批量导入

使用高德API批量查询POI数据，然后通过DeepSeek翻译：

```bash
# 1. 导出高德POI数据
# 2. 调用DeepSeek API批量翻译
# 3. 生成SQL INSERT语句
# 4. 执行导入
```

参考文档: `../../mobile_app/MVP_PROGRESS_TRACKER.md` - 任务8

---

## 📝 维护说明

### 更新翻译

```sql
-- 更新某条翻译
UPDATE road_translations
SET road_name_en = 'Chang''an Avenue (Updated)',
    updated_at = NOW(),
    verified = true
WHERE road_name_zh = '长安街' AND city = '北京';
```

### 查看热门翻译

```sql
-- 查看使用次数最多的道路翻译
SELECT road_name_zh, road_name_en, city, usage_count
FROM road_translations
WHERE verified = true
ORDER BY usage_count DESC
LIMIT 20;
```

---

## 🔍 常见查询

### 查找特定城市的所有地铁站

```sql
SELECT
    station_name_zh,
    station_name_en,
    line_name_en,
    line_number
FROM transit_station_translations
WHERE city = '上海' AND station_type = 'metro'
ORDER BY line_number, station_name_zh;
```

### 查找高优先级道路

```sql
SELECT * FROM high_priority_roads
WHERE city = '北京';
```

### 获取未验证的翻译

```sql
SELECT * FROM road_translations
WHERE verified = false
ORDER BY usage_count DESC;
```

---

## 📚 相关文档

- **主数据库**: `../migrations/001_initial_schema.sql`
- **实施指南**: `../../mobile_app/TRANSLATION_OVERLAY_IMPLEMENTATION_GUIDE.md`
- **MVP进度**: `../../mobile_app/MVP_PROGRESS_TRACKER.md`
- **设计规范**: `../../docs/design/WANDERCHINA_MAP_TRANSLATION_SPEC.md`

---

**最后更新**: 2026-02-24
**版本**: 1.0.0
**维护者**: WanderChina Team
