# WanderChina — 翻译数据预存规范

> **写给 Claude Code：** 本文档是完整的数据录入任务书。按优先级顺序执行，所有数据最终生成一个可直接在腾讯云 PostgreSQL 执行的 `.sql` 文件。

---

## 1. 任务概述

### 1.1 目标

向 `poi_translations` 表预存 WanderChina MVP 所需的翻译数据，覆盖北京、上海、广州、深圳、成都、西安 6 个城市，确保外国游客使用地图翻译蒙层时的核心体验流畅、翻译准确。

### 1.2 数据库表结构

参考已有建表脚本（`sql/poi_translations_init.sql`），核心字段如下：

```sql
CREATE TABLE poi_translations (
  id              SERIAL PRIMARY KEY,
  gaode_poi_id    TEXT NOT NULL UNIQUE,   -- 高德 POI 唯一 ID
  name_zh         TEXT NOT NULL,           -- 中文名称
  name_en         TEXT NOT NULL,           -- 英文名称
  name_fr         TEXT,                    -- 法文名称
  name_es         TEXT,                    -- 西班牙文名称
  category_en     TEXT,                    -- 分类（见下方枚举）
  city            TEXT NOT NULL,           -- 城市（见下方枚举）
  lat             DECIMAL(10, 8) NOT NULL, -- GCJ-02 纬度
  lng             DECIMAL(11, 8) NOT NULL, -- GCJ-02 经度
  source          TEXT DEFAULT 'manual',   -- 预存数据统一用 'manual'
  priority_score  INT DEFAULT 0,           -- 优先级（影响标签渲染顺序）
  cached_at       TIMESTAMP DEFAULT NOW(),
  updated_at      TIMESTAMP DEFAULT NOW()
);
```

### 1.3 枚举值约定

**city 字段：**
`北京` / `上海` / `广州` / `深圳` / `成都` / `西安`

**category_en 字段（严格使用以下值）：**
`Attraction` / `Metro Station` / `Transport Hub` / `Museum` / `Park` / `Restaurant` / `Shopping` / `Hospital` / `Hotel` / `Other`

**source 字段：**
本文档所有数据统一填写 `manual`（人工校对），priority_score 见各节说明。

---

## 2. 数据优先级与范围

| 优先级 | 类别 | 城市 | 预估条数 | priority_score |
|--------|------|------|---------|---------------|
| **P0** | 地铁站（全线） | 6城全部 | ~2200条 | 80 |
| **P0** | 核心景点/博物馆/公园 | 6城全部 | ~300条 | 90–100 |
| **P0** | 交通枢纽（机场/火车站） | 6城全部 | ~60条 | 95 |
| **P1** | 热门商圈/购物中心 | 6城全部 | ~120条 | 70 |
| **P1** | 主要医院（涉外/国际） | 6城全部 | ~40条 | 75 |
| **P2** | 知名餐厅/美食街 | 6城全部 | ~180条 | 60 |

**总计预存约 2900 条。**

---

## 3. P0 数据：地铁站

### 3.1 翻译规则（必须遵守）

```
格式：[站名拼音/英文] + "Station"

规则1：有官方英文名的站，使用官方名
  例：天安门东 → Tian'anmen East Station（非 Tiananmen East Station）
      人民广场 → People's Square Station
      外滩     → 上海无此站名（注意辨别）

规则2：地名含方位词的翻译
  东 → East   西 → West   南 → South   北 → North
  上 → Upper  下 → Lower  中 → Central

规则3：普通地名用拼音
  浦东大道 → Pudong Avenue Station
  龙华     → Longhua Station

规则4：含数字的线路站
  一号线 → Line 1（不翻译到站名里）
  
规则5：换乘站名称不变，只翻译一次
```

### 3.2 法文/西班牙文翻译规则

地铁站法文/西班牙文 **不翻译地名**，统一格式为：

```
法文：  [英文站名（去掉 Station）] + " Station"  →  直接沿用英文，不做音译
        例：Tian'anmen East Station（FR 和 ES 均与 EN 相同）

说明：  地铁站名是专有名词，强行音译反而会造成混乱。
        FR/ES 字段填写与 EN 相同的值即可。
```

### 3.3 数据来源与格式

Claude Code 需要：

1. 通过高德地图 API `searchPOIByType` 按城市批量查询地铁站 POI（类型代码 `150500`），获取 `gaode_poi_id`、`name`、`location`（经纬度）
2. 按上述翻译规则生成 `name_en`
3. `name_fr` 和 `name_es` 与 `name_en` 相同
4. 插入数据库

**如无高德 API 访问权限，** 使用下方手动数据 + 公开资料补全。

### 3.4 各城市地铁线路范围

| 城市 | 截至 2025 年底运营线路 | 预计站点数 |
|------|----------------------|-----------|
| 北京 | 1–19号线、房山线、亦庄线、首都机场线等 | ~450 |
| 上海 | 1–18号线、浦江线、金山铁路 | ~420 |
| 广州 | 1–21号线、APM线、有轨电车 | ~280 |
| 深圳 | 1–14号线 | ~230 |
| 成都 | 1–12号线、17号线、18号线 | ~210 |
| 西安 | 1–6号线、14号线 | ~130 |

### 3.5 种子数据（P0 必录，人工校对）

以下为各城市核心地铁站，**必须人工校对**，其余站点可批量生成后 review：

```sql
-- ================================================================
-- 地铁站种子数据（P0 核心，人工校对）
-- priority_score = 85（主要枢纽站）或 80（普通站）
-- ================================================================

-- ── 北京 ──────────────────────────────────────────────────────

-- 主要换乘/枢纽站
('BJ_METRO_001', '北京首都国际机场站', 'Capital Airport Station',
  'Capital Airport Station', 'Capital Airport Station',
  'Metro Station', '北京', 40.07308, 116.58781, 'manual', 90),

('BJ_METRO_002', '北京大兴国际机场站', 'Daxing International Airport Station',
  'Daxing International Airport Station', 'Daxing International Airport Station',
  'Metro Station', '北京', 39.50929, 116.41110, 'manual', 90),

('BJ_METRO_003', '天安门东站', 'Tian''anmen East Station',
  'Tian''anmen East Station', 'Tian''anmen East Station',
  'Metro Station', '北京', 39.90757, 116.40132, 'manual', 88),

('BJ_METRO_004', '天安门西站', 'Tian''anmen West Station',
  'Tian''anmen West Station', 'Tian''anmen West Station',
  'Metro Station', '北京', 39.90815, 116.39133, 'manual', 85),

('BJ_METRO_005', '故宫站', 'Palace Museum Station',
  'Palace Museum Station', 'Palace Museum Station',
  'Metro Station', '北京', 39.91880, 116.39167, 'manual', 85),

('BJ_METRO_006', '王府井站', 'Wangfujing Station',
  'Wangfujing Station', 'Wangfujing Station',
  'Metro Station', '北京', 39.91400, 116.41100, 'manual', 85),

('BJ_METRO_007', '西单站', 'Xidan Station',
  'Xidan Station', 'Xidan Station',
  'Metro Station', '北京', 39.91333, 116.37861, 'manual', 83),

('BJ_METRO_008', '北京站', 'Beijing Railway Station',
  'Beijing Railway Station', 'Beijing Railway Station',
  'Metro Station', '北京', 39.90349, 116.42711, 'manual', 88),

('BJ_METRO_009', '北京西站', 'Beijing West Railway Station',
  'Beijing West Railway Station', 'Beijing West Railway Station',
  'Metro Station', '北京', 39.89491, 116.32219, 'manual', 88),

('BJ_METRO_010', '北京南站', 'Beijing South Railway Station',
  'Beijing South Railway Station', 'Beijing South Railway Station',
  'Metro Station', '北京', 39.86503, 116.37990, 'manual', 88),

('BJ_METRO_011', '三里屯站', 'Sanlitun Station',
  'Sanlitun Station', 'Sanlitun Station',
  'Metro Station', '北京', 39.93083, 116.45278, 'manual', 82),

('BJ_METRO_012', '国贸站', 'Guomao Station',
  'Guomao Station', 'Guomao Station',
  'Metro Station', '北京', 39.90883, 116.46163, 'manual', 83),

('BJ_METRO_013', '颐和园站', 'Summer Palace Station',
  'Summer Palace Station', 'Summer Palace Station',
  'Metro Station', '北京', 40.00175, 116.27612, 'manual', 85),

('BJ_METRO_014', '圆明园站', 'Yuanmingyuan Park Station',
  'Yuanmingyuan Park Station', 'Yuanmingyuan Park Station',
  'Metro Station', '北京', 40.00822, 116.30167, 'manual', 83),

-- ── 上海 ──────────────────────────────────────────────────────

('SH_METRO_001', '人民广场站', 'People''s Square Station',
  'People''s Square Station', 'People''s Square Station',
  'Metro Station', '上海', 31.23031, 121.47324, 'manual', 88),

('SH_METRO_002', '南京东路站', 'East Nanjing Road Station',
  'East Nanjing Road Station', 'East Nanjing Road Station',
  'Metro Station', '上海', 31.23613, 121.48302, 'manual', 85),

('SH_METRO_003', '陆家嘴站', 'Lujiazui Station',
  'Lujiazui Station', 'Lujiazui Station',
  'Metro Station', '上海', 31.23529, 121.50342, 'manual', 88),

('SH_METRO_004', '外滩站', 'The Bund Station',
  'The Bund Station', 'The Bund Station',
  'Metro Station', '上海', 31.24021, 121.48830, 'manual', 87),

('SH_METRO_005', '上海虹桥站', 'Shanghai Hongqiao Station',
  'Shanghai Hongqiao Station', 'Shanghai Hongqiao Station',
  'Metro Station', '上海', 31.19393, 121.32291, 'manual', 90),

('SH_METRO_006', '浦东国际机场站', 'Pudong International Airport Station',
  'Pudong International Airport Station', 'Pudong International Airport Station',
  'Metro Station', '上海', 31.14766, 121.80523, 'manual', 90),

('SH_METRO_007', '上海火车站', 'Shanghai Railway Station',
  'Shanghai Railway Station', 'Shanghai Railway Station',
  'Metro Station', '上海', 31.24944, 121.45571, 'manual', 88),

('SH_METRO_008', '豫园站', 'Yuyuan Garden Station',
  'Yuyuan Garden Station', 'Yuyuan Garden Station',
  'Metro Station', '上海', 31.22549, 121.49217, 'manual', 85),

('SH_METRO_009', '徐家汇站', 'Xujiahui Station',
  'Xujiahui Station', 'Xujiahui Station',
  'Metro Station', '上海', 31.19429, 121.43285, 'manual', 85),

('SH_METRO_010', '迪士尼站', 'Disney Resort Station',
  'Disney Resort Station', 'Disney Resort Station',
  'Metro Station', '上海', 31.14508, 121.66426, 'manual', 88),

-- ── 广州 ──────────────────────────────────────────────────────

('GZ_METRO_001', '广州南站', 'Guangzhou South Railway Station',
  'Guangzhou South Railway Station', 'Guangzhou South Railway Station',
  'Metro Station', '广州', 22.99794, 113.26681, 'manual', 90),

('GZ_METRO_002', '广州白云国际机场站', 'Guangzhou Baiyun International Airport Station',
  'Guangzhou Baiyun International Airport Station', 'Guangzhou Baiyun International Airport Station',
  'Metro Station', '广州', 23.39338, 113.28998, 'manual', 90),

('GZ_METRO_003', '广州东站', 'Guangzhou East Railway Station',
  'Guangzhou East Railway Station', 'Guangzhou East Railway Station',
  'Metro Station', '广州', 23.15014, 113.32444, 'manual', 88),

('GZ_METRO_004', '体育西路站', 'Tiyu Xilu Station',
  'Tiyu Xilu Station', 'Tiyu Xilu Station',
  'Metro Station', '广州', 23.13228, 113.32375, 'manual', 83),

('GZ_METRO_005', '公园前站', 'Gongyuanqian Station',
  'Gongyuanqian Station', 'Gongyuanqian Station',
  'Metro Station', '广州', 23.12863, 113.26567, 'manual', 83),

('GZ_METRO_006', '广州塔站', 'Canton Tower Station',
  'Canton Tower Station', 'Canton Tower Station',
  'Metro Station', '广州', 23.10742, 113.32422, 'manual', 87),

('GZ_METRO_007', '陈家祠站', 'Chen Clan Ancestral Hall Station',
  'Chen Clan Ancestral Hall Station', 'Chen Clan Ancestral Hall Station',
  'Metro Station', '广州', 23.12611, 113.24030, 'manual', 85),

-- ── 深圳 ──────────────────────────────────────────────────────

('SZ_METRO_001', '深圳北站', 'Shenzhen North Railway Station',
  'Shenzhen North Railway Station', 'Shenzhen North Railway Station',
  'Metro Station', '深圳', 22.60906, 114.02988, 'manual', 90),

('SZ_METRO_002', '福田站', 'Futian Station',
  'Futian Station', 'Futian Station',
  'Metro Station', '深圳', 22.52184, 114.05486, 'manual', 88),

('SZ_METRO_003', '罗湖站', 'Luohu Station',
  'Luohu Station', 'Luohu Station',
  'Metro Station', '深圳', 22.54787, 114.11683, 'manual', 87),

('SZ_METRO_004', '深圳湾公园站', 'Shenzhen Bay Park Station',
  'Shenzhen Bay Park Station', 'Shenzhen Bay Park Station',
  'Metro Station', '深圳', 22.51138, 113.95034, 'manual', 83),

('SZ_METRO_005', '华强路站', 'Huaqianglu Station',
  'Huaqianglu Station', 'Huaqianglu Station',
  'Metro Station', '深圳', 22.54650, 114.08892, 'manual', 82),

-- ── 成都 ──────────────────────────────────────────────────────

('CD_METRO_001', '成都东站', 'Chengdu East Railway Station',
  'Chengdu East Railway Station', 'Chengdu East Railway Station',
  'Metro Station', '成都', 30.63175, 104.14163, 'manual', 90),

('CD_METRO_002', '成都天府国际机场站', 'Chengdu Tianfu International Airport Station',
  'Chengdu Tianfu International Airport Station', 'Chengdu Tianfu International Airport Station',
  'Metro Station', '成都', 30.32253, 104.44413, 'manual', 90),

('CD_METRO_003', '春熙路站', 'Chunxi Road Station',
  'Chunxi Road Station', 'Chunxi Road Station',
  'Metro Station', '成都', 30.65744, 104.08014, 'manual', 87),

('CD_METRO_004', '天府广场站', 'Tianfu Square Station',
  'Tianfu Square Station', 'Tianfu Square Station',
  'Metro Station', '成都', 30.65841, 104.06476, 'manual', 87),

('CD_METRO_005', '宽窄巷子站', 'Wide and Narrow Alleys Station',
  'Wide and Narrow Alleys Station', 'Wide and Narrow Alleys Station',
  'Metro Station', '成都', 30.67197, 104.05558, 'manual', 85),

('CD_METRO_006', '大熊猫基地站', 'Giant Panda Base Station',
  'Giant Panda Base Station', 'Giant Panda Base Station',
  'Metro Station', '成都', 30.73601, 104.14401, 'manual', 88),

('CD_METRO_007', '锦里站', 'Jinli Station',
  'Jinli Station', 'Jinli Station',
  'Metro Station', '成都', 30.64200, 104.07300, 'manual', 83),

-- ── 西安 ──────────────────────────────────────────────────────

('XA_METRO_001', '西安北站', 'Xi''an North Railway Station',
  'Xi''an North Railway Station', 'Xi''an North Railway Station',
  'Metro Station', '西安', 34.38502, 108.92247, 'manual', 90),

('XA_METRO_002', '西安咸阳国际机场站', 'Xi''an Xianyang International Airport Station',
  'Xi''an Xianyang International Airport Station', 'Xi''an Xianyang International Airport Station',
  'Metro Station', '西安', 34.44611, 108.75208, 'manual', 90),

('XA_METRO_003', '钟楼站', 'Bell Tower Station',
  'Bell Tower Station', 'Bell Tower Station',
  'Metro Station', '西安', 34.26019, 108.94528, 'manual', 88),

('XA_METRO_004', '大雁塔站', 'Big Wild Goose Pagoda Station',
  'Big Wild Goose Pagoda Station', 'Big Wild Goose Pagoda Station',
  'Metro Station', '西安', 34.21980, 108.96126, 'manual', 88),

('XA_METRO_005', '兵马俑站', 'Terracotta Army Station',
  'Terracotta Army Station', 'Terracotta Army Station',
  'Metro Station', '西安', 34.38309, 109.25893, 'manual', 88),

('XA_METRO_006', '城南客运站', 'South Bus Terminal Station',
  'South Bus Terminal Station', 'South Bus Terminal Station',
  'Metro Station', '西安', 34.21413, 108.93627, 'manual', 80)
```

---

## 4. P0 数据：交通枢纽

### 4.1 翻译规则

```
机场：[城市英文名] + [机场名] + "International Airport"
      例：广州白云国际机场 → Guangzhou Baiyun International Airport

火车站：[城市英文名] + [方位（如有）] + "Railway Station"
       例：北京西站 → Beijing West Railway Station
           成都东站 → Chengdu East Railway Station

长途汽车站：[地名拼音] + "Long-distance Bus Station"
           或直接 "[City] [方位] Bus Terminal"
```

### 4.2 交通枢纽完整数据

```sql
-- ================================================================
-- 交通枢纽（P0，priority_score = 95）
-- ================================================================

-- ── 北京机场与火车站 ──
('BJ_HUB_001', '北京首都国际机场', 'Beijing Capital International Airport',
  'Aéroport International de Pékin-Capital', 'Aeropuerto Internacional de Pekín Capital',
  'Transport Hub', '北京', 40.07997, 116.58454, 'manual', 95),

('BJ_HUB_002', '北京大兴国际机场', 'Beijing Daxing International Airport',
  'Aéroport International de Daxing Pékin', 'Aeropuerto Internacional de Daxing Beijing',
  'Transport Hub', '北京', 39.50930, 116.41108, 'manual', 95),

('BJ_HUB_003', '北京站', 'Beijing Railway Station',
  'Gare de Beijing', 'Estación de Tren de Beijing',
  'Transport Hub', '北京', 39.90349, 116.42711, 'manual', 92),

('BJ_HUB_004', '北京西站', 'Beijing West Railway Station',
  'Gare de l''Ouest de Beijing', 'Estación Oeste de Beijing',
  'Transport Hub', '北京', 39.89491, 116.32219, 'manual', 92),

('BJ_HUB_005', '北京南站', 'Beijing South Railway Station',
  'Gare du Sud de Beijing', 'Estación Sur de Beijing',
  'Transport Hub', '北京', 39.86503, 116.37990, 'manual', 92),

('BJ_HUB_006', '北京朝阳站', 'Beijing Chaoyang Railway Station',
  'Gare de Chaoyang Beijing', 'Estación Chaoyang de Beijing',
  'Transport Hub', '北京', 39.93580, 116.55070, 'manual', 88),

-- ── 上海 ──
('SH_HUB_001', '上海浦东国际机场', 'Shanghai Pudong International Airport',
  'Aéroport International de Pudong Shanghai', 'Aeropuerto Internacional de Pudong Shanghái',
  'Transport Hub', '上海', 31.14346, 121.80525, 'manual', 95),

('SH_HUB_002', '上海虹桥国际机场', 'Shanghai Hongqiao International Airport',
  'Aéroport International de Hongqiao Shanghai', 'Aeropuerto Internacional de Hongqiao Shanghái',
  'Transport Hub', '上海', 31.19793, 121.33608, 'manual', 95),

('SH_HUB_003', '上海虹桥火车站', 'Shanghai Hongqiao Railway Station',
  'Gare de Hongqiao Shanghai', 'Estación Hongqiao de Shanghái',
  'Transport Hub', '上海', 31.19393, 121.32291, 'manual', 92),

('SH_HUB_004', '上海火车站', 'Shanghai Railway Station',
  'Gare de Shanghai', 'Estación de Tren de Shanghái',
  'Transport Hub', '上海', 31.24944, 121.45571, 'manual', 92),

('SH_HUB_005', '上海南站', 'Shanghai South Railway Station',
  'Gare du Sud de Shanghai', 'Estación Sur de Shanghái',
  'Transport Hub', '上海', 31.15966, 121.42649, 'manual', 88),

-- ── 广州 ──
('GZ_HUB_001', '广州白云国际机场', 'Guangzhou Baiyun International Airport',
  'Aéroport International de Baiyun Guangzhou', 'Aeropuerto Internacional de Baiyun Guangzhou',
  'Transport Hub', '广州', 23.39338, 113.28998, 'manual', 95),

('GZ_HUB_002', '广州南站', 'Guangzhou South Railway Station',
  'Gare du Sud de Guangzhou', 'Estación Sur de Guangzhou',
  'Transport Hub', '广州', 22.99794, 113.26681, 'manual', 92),

('GZ_HUB_003', '广州东站', 'Guangzhou East Railway Station',
  'Gare de l''Est de Guangzhou', 'Estación Este de Guangzhou',
  'Transport Hub', '广州', 23.15014, 113.32444, 'manual', 90),

('GZ_HUB_004', '广州站', 'Guangzhou Railway Station',
  'Gare de Guangzhou', 'Estación de Tren de Guangzhou',
  'Transport Hub', '广州', 23.14527, 113.25981, 'manual', 90),

-- ── 深圳 ──
('SZ_HUB_001', '深圳宝安国际机场', 'Shenzhen Bao''an International Airport',
  'Aéroport International de Bao''an Shenzhen', 'Aeropuerto Internacional de Bao''an Shenzhen',
  'Transport Hub', '深圳', 22.63978, 113.81286, 'manual', 95),

('SZ_HUB_002', '深圳北站', 'Shenzhen North Railway Station',
  'Gare du Nord de Shenzhen', 'Estación Norte de Shenzhen',
  'Transport Hub', '深圳', 22.60906, 114.02988, 'manual', 92),

('SZ_HUB_003', '深圳站', 'Shenzhen Railway Station',
  'Gare de Shenzhen', 'Estación de Tren de Shenzhen',
  'Transport Hub', '深圳', 22.53205, 114.11897, 'manual', 90),

('SZ_HUB_004', '福田口岸', 'Futian Port (HK Border)',
  'Poste Frontière de Futian (Hong Kong)', 'Puesto Fronterizo de Futian (Hong Kong)',
  'Transport Hub', '深圳', 22.52177, 114.05611, 'manual', 85),

-- ── 成都 ──
('CD_HUB_001', '成都天府国际机场', 'Chengdu Tianfu International Airport',
  'Aéroport International de Tianfu Chengdu', 'Aeropuerto Internacional de Tianfu Chengdu',
  'Transport Hub', '成都', 30.32253, 104.44413, 'manual', 95),

('CD_HUB_002', '成都双流国际机场', 'Chengdu Shuangliu International Airport',
  'Aéroport International de Shuangliu Chengdu', 'Aeropuerto Internacional de Shuangliu Chengdu',
  'Transport Hub', '成都', 30.57841, 103.94726, 'manual', 93),

('CD_HUB_003', '成都东站', 'Chengdu East Railway Station',
  'Gare de l''Est de Chengdu', 'Estación Este de Chengdu',
  'Transport Hub', '成都', 30.63175, 104.14163, 'manual', 92),

('CD_HUB_004', '成都站', 'Chengdu Railway Station',
  'Gare de Chengdu', 'Estación de Tren de Chengdu',
  'Transport Hub', '成都', 30.68097, 104.08103, 'manual', 90),

-- ── 西安 ──
('XA_HUB_001', '西安咸阳国际机场', 'Xi''an Xianyang International Airport',
  'Aéroport International de Xianyang Xi''an', 'Aeropuerto Internacional de Xianyang Xi''an',
  'Transport Hub', '西安', 34.44611, 108.75208, 'manual', 95),

('XA_HUB_002', '西安北站', 'Xi''an North Railway Station',
  'Gare du Nord de Xi''an', 'Estación Norte de Xi''an',
  'Transport Hub', '西安', 34.38502, 108.92247, 'manual', 92),

('XA_HUB_003', '西安站', 'Xi''an Railway Station',
  'Gare de Xi''an', 'Estación de Tren de Xi''an',
  'Transport Hub', '西安', 34.26584, 108.93064, 'manual', 90)
```

---

## 5. P0 数据：核心景点/博物馆/公园

### 5.1 翻译规则

```
规则1：有通用英文名的景点，使用通用名
  故宫     → Palace Museum（不用 Forbidden City 的原因：故宫官网用名）
  颐和园   → Summer Palace
  天坛     → Temple of Heaven
  西湖     → West Lake（成都无此景点，仅供参考规则）

规则2：无通用英文名的，描述性翻译
  大唐不夜城 → Tang Paradise Night Market
  宽窄巷子   → Wide and Narrow Alleys

规则3：法文/西班牙文需实际翻译（不能简单照抄英文）
  Palace Museum → FR: Musée du Palais  ES: Museo del Palacio

规则4：category 区分
  室内展览类  → Museum
  自然/园林类 → Park 或 Attraction
  历史遗址类  → Attraction
```

### 5.2 核心景点数据

```sql
-- ================================================================
-- 核心景点/博物馆/公园（P0，priority_score 90-100）
-- ================================================================

-- ── 北京 ──
('BJ_ATT_001', '故宫博物院', 'Palace Museum (Forbidden City)',
  'Musée du Palais (Cité Interdite)', 'Museo del Palacio (Ciudad Prohibida)',
  'Museum', '北京', 39.91633, 116.39720, 'manual', 100),

('BJ_ATT_002', '天安门广场', 'Tiananmen Square',
  'Place Tiananmen', 'Plaza de Tiananmen',
  'Attraction', '北京', 39.90527, 116.39723, 'manual', 100),

('BJ_ATT_003', '颐和园', 'Summer Palace',
  'Palais d''Été', 'Palacio de Verano',
  'Park', '北京', 39.99901, 116.27551, 'manual', 98),

('BJ_ATT_004', '天坛公园', 'Temple of Heaven',
  'Temple du Ciel', 'Templo del Cielo',
  'Park', '北京', 39.88249, 116.41115, 'manual', 98),

('BJ_ATT_005', '圆明园遗址公园', 'Old Summer Palace (Ruins)',
  'Ancien Palais d''Été (Ruines)', 'Antiguo Palacio de Verano (Ruinas)',
  'Park', '北京', 40.00902, 116.29794, 'manual', 92),

('BJ_ATT_006', '北海公园', 'Beihai Park',
  'Parc Beihai', 'Parque Beihai',
  'Park', '北京', 39.92519, 116.38524, 'manual', 90),

('BJ_ATT_007', '国家博物馆', 'National Museum of China',
  'Musée National de Chine', 'Museo Nacional de China',
  'Museum', '北京', 39.90391, 116.40326, 'manual', 95),

('BJ_ATT_008', '长城（慕田峪）', 'Great Wall (Mutianyu)',
  'Grande Muraille (Mutianyu)', 'Gran Muralla (Mutianyu)',
  'Attraction', '北京', 40.43292, 116.56484, 'manual', 100),

('BJ_ATT_009', '长城（八达岭）', 'Great Wall (Badaling)',
  'Grande Muraille (Badaling)', 'Gran Muralla (Badaling)',
  'Attraction', '北京', 40.35399, 116.01920, 'manual', 100),

('BJ_ATT_010', '南锣鼓巷', 'Nanluoguxiang (Historic Hutong)',
  'Nanluoguxiang (Hutong Historique)', 'Nanluoguxiang (Callejón Histórico)',
  'Attraction', '北京', 39.93702, 116.40341, 'manual', 90),

('BJ_ATT_011', '鸟巢（国家体育场）', 'Bird''s Nest (National Stadium)',
  'Nid d''Oiseau (Stade National)', 'Nido de Pájaro (Estadio Nacional)',
  'Attraction', '北京', 40.00892, 116.39175, 'manual', 93),

('BJ_ATT_012', '水立方（国家游泳中心）', 'Water Cube (National Aquatics Centre)',
  'Cube d''Eau (Centre National de Natation)', 'Cubo de Agua (Centro Nacional de Acuática)',
  'Attraction', '北京', 40.00843, 116.38728, 'manual', 90),

-- ── 上海 ──
('SH_ATT_001', '外滩', 'The Bund',
  'Le Bund', 'El Bund',
  'Attraction', '上海', 31.23963, 121.48910, 'manual', 100),

('SH_ATT_002', '东方明珠广播电视塔', 'Oriental Pearl Tower',
  'Tour de la Perle Orientale', 'Torre de la Perla Oriental',
  'Attraction', '上海', 31.23957, 121.49993, 'manual', 98),

('SH_ATT_003', '豫园', 'Yuyuan Garden',
  'Jardin Yu', 'Jardín Yu',
  'Park', '上海', 31.22740, 121.49214, 'manual', 95),

('SH_ATT_004', '上海迪士尼乐园', 'Shanghai Disneyland',
  'Disneyland Shanghai', 'Disneyland Shanghái',
  'Attraction', '上海', 31.14461, 121.66363, 'manual', 100),

('SH_ATT_005', '上海博物馆', 'Shanghai Museum',
  'Musée de Shanghai', 'Museo de Shanghái',
  'Museum', '上海', 31.22866, 121.47389, 'manual', 93),

('SH_ATT_006', '新天地', 'Xintiandi',
  'Xintiandi', 'Xintiandi',
  'Attraction', '上海', 31.21971, 121.47347, 'manual', 90),

('SH_ATT_007', '田子坊', 'Tianzifang',
  'Tianzifang', 'Tianzifang',
  'Attraction', '上海', 31.20824, 121.46586, 'manual', 90),

('SH_ATT_008', '上海中心大厦', 'Shanghai Tower',
  'Tour de Shanghai', 'Torre de Shanghái',
  'Attraction', '上海', 31.23565, 121.50108, 'manual', 95),

('SH_ATT_009', '南京路步行街', 'Nanjing Road Pedestrian Street',
  'Rue Piétonne de Nanjing', 'Calle Peatonal de Nanjing',
  'Shopping', '上海', 31.23530, 121.47330, 'manual', 90),

-- ── 广州 ──
('GZ_ATT_001', '广州塔', 'Canton Tower',
  'Tour de Canton', 'Torre de Cantón',
  'Attraction', '广州', 23.10592, 113.32385, 'manual', 100),

('GZ_ATT_002', '陈家祠', 'Chen Clan Ancestral Hall',
  'Salle Ancestrale du Clan Chen', 'Sala Ancestral del Clan Chen',
  'Museum', '广州', 23.12663, 113.23897, 'manual', 93),

('GZ_ATT_003', '广州博物馆（镇海楼）', 'Guangzhou Museum (Zhenhai Tower)',
  'Musée de Guangzhou (Tour Zhenhai)', 'Museo de Guangzhou (Torre Zhenhai)',
  'Museum', '广州', 23.13571, 113.27527, 'manual', 88),

('GZ_ATT_004', '北京路步行街', 'Beijing Road Pedestrian Street',
  'Rue Piétonne de Beijing (Guangzhou)', 'Calle Peatonal de Beijing (Guangzhou)',
  'Shopping', '广州', 23.12667, 113.26611, 'manual', 87),

('GZ_ATT_005', '沙面岛', 'Shamian Island',
  'Île Shamian', 'Isla Shamian',
  'Attraction', '广州', 23.10927, 113.23980, 'manual', 90),

('GZ_ATT_006', '越秀公园', 'Yuexiu Park',
  'Parc Yuexiu', 'Parque Yuexiu',
  'Park', '广州', 23.13559, 113.27489, 'manual', 88),

-- ── 深圳 ──
('SZ_ATT_001', '深圳湾公园', 'Shenzhen Bay Park',
  'Parc de la Baie de Shenzhen', 'Parque de la Bahía de Shenzhen',
  'Park', '深圳', 22.50877, 113.95045, 'manual', 90),

('SZ_ATT_002', '世界之窗', 'Window of the World',
  'Fenêtre sur le Monde', 'Ventana al Mundo',
  'Attraction', '深圳', 22.53565, 113.97317, 'manual', 90),

('SZ_ATT_003', '大梅沙海滨公园', 'Dameisha Beach Park',
  'Parc de Plage de Dameisha', 'Parque de Playa Dameisha',
  'Park', '深圳', 22.59767, 114.30527, 'manual', 88),

('SZ_ATT_004', '华强北电子市场', 'Huaqiangbei Electronics Market',
  'Marché Électronique de Huaqiangbei', 'Mercado Electrónico de Huaqiangbei',
  'Shopping', '深圳', 22.54650, 114.08892, 'manual', 85),

('SZ_ATT_005', '深圳博物馆', 'Shenzhen Museum',
  'Musée de Shenzhen', 'Museo de Shenzhen',
  'Museum', '深圳', 22.54124, 114.05858, 'manual', 85),

-- ── 成都 ──
('CD_ATT_001', '成都大熊猫繁育研究基地', 'Chengdu Giant Panda Breeding Research Base',
  'Base de Recherche sur l''Élevage des Pandas Géants de Chengdu',
  'Base de Investigación de Cría de Pandas Gigantes de Chengdu',
  'Attraction', '成都', 30.73660, 104.14573, 'manual', 100),

('CD_ATT_002', '宽窄巷子', 'Wide and Narrow Alleys',
  'Les Ruelles Larges et Étroites', 'Callejones Anchos y Estrechos',
  'Attraction', '成都', 30.67139, 104.05626, 'manual', 95),

('CD_ATT_003', '锦里古街', 'Jinli Ancient Street',
  'Rue Ancienne de Jinli', 'Calle Antigua de Jinli',
  'Attraction', '成都', 30.64106, 104.07366, 'manual', 93),

('CD_ATT_004', '武侯祠博物馆', 'Wuhou Shrine Museum',
  'Musée du Sanctuaire de Wuhou', 'Museo del Santuario Wuhou',
  'Museum', '成都', 30.64090, 104.04600, 'manual', 90),

('CD_ATT_005', '都江堰', 'Dujiangyan Irrigation System',
  'Système d''Irrigation de Dujiangyan', 'Sistema de Irrigación de Dujiangyan',
  'Attraction', '成都', 30.99689, 103.59037, 'manual', 93),

('CD_ATT_006', '青城山', 'Qingcheng Mountain',
  'Mont Qingcheng', 'Monte Qingcheng',
  'Attraction', '成都', 30.90119, 103.56791, 'manual', 90),

('CD_ATT_007', '成都博物馆', 'Chengdu Museum',
  'Musée de Chengdu', 'Museo de Chengdu',
  'Museum', '成都', 30.65942, 104.06253, 'manual', 88),

('CD_ATT_008', '春熙路太古里', 'Chunxi Road Taikoo Li',
  'Taikoo Li de la Rue Chunxi', 'Taikoo Li de la Calle Chunxi',
  'Shopping', '成都', 30.65613, 104.08168, 'manual', 88),

-- ── 西安 ──
('XA_ATT_001', '秦始皇兵马俑博物馆', 'Terracotta Army Museum',
  'Musée de l''Armée de Terre Cuite', 'Museo del Ejército de Terracota',
  'Museum', '西安', 34.38441, 109.27350, 'manual', 100),

('XA_ATT_002', '西安城墙', 'Xi''an City Wall',
  'Rempart de Xi''an', 'Muralla de Xi''an',
  'Attraction', '西安', 34.25919, 108.93060, 'manual', 100),

('XA_ATT_003', '大雁塔', 'Big Wild Goose Pagoda',
  'Grande Pagode de l''Oie Sauvage', 'Gran Pagoda del Ganso Salvaje',
  'Attraction', '西安', 34.22349, 108.96003, 'manual', 97),

('XA_ATT_004', '大唐不夜城', 'Tang Paradise Night Market',
  'Quartier de Nuit de la Dynastie Tang', 'Mercado Nocturno de la Dinastía Tang',
  'Attraction', '西安', 34.21950, 108.96302, 'manual', 93),

('XA_ATT_005', '钟楼', 'Bell Tower',
  'Tour de la Cloche', 'Torre de la Campana',
  'Attraction', '西安', 34.25917, 108.94750, 'manual', 95),

('XA_ATT_006', '鼓楼', 'Drum Tower',
  'Tour du Tambour', 'Torre del Tambor',
  'Attraction', '西安', 34.26001, 108.94103, 'manual', 93),

('XA_ATT_007', '回民街', 'Muslim Quarter',
  'Quartier Musulman', 'Barrio Musulmán',
  'Attraction', '西安', 34.26238, 108.94019, 'manual', 95),

('XA_ATT_008', '陕西历史博物馆', 'Shaanxi History Museum',
  'Musée d''Histoire du Shaanxi', 'Museo de Historia de Shaanxi',
  'Museum', '西安', 34.22368, 108.95428, 'manual', 95),

('XA_ATT_009', '小雁塔', 'Small Wild Goose Pagoda',
  'Petite Pagode de l''Oie Sauvage', 'Pequeña Pagoda del Ganso Salvaje',
  'Attraction', '西安', 34.23357, 108.94043, 'manual', 88),

('XA_ATT_010', '华清宫景区', 'Huaqing Palace Scenic Area',
  'Palais de Huaqing (Site Touristique)', 'Área Escénica del Palacio Huaqing',
  'Attraction', '西安', 34.35963, 109.21380, 'manual', 90)
```

---

## 6. P1 数据：主要医院（涉外/国际）

### 6.1 翻译规则

```
外资/国际医院：保留原英文名
  北京和睦家医院 → Beijing United Family Hospital

国内大型三甲医院：描述性翻译
  北京协和医院 → Peking Union Medical College Hospital（官方英文名）

格式统一：无需附加 "Hospital" 如英文名已包含
```

### 6.2 涉外医院数据

```sql
-- ================================================================
-- 主要涉外医院（P1，priority_score = 80）
-- ================================================================

-- 北京
('BJ_HOS_001', '北京和睦家医院', 'Beijing United Family Hospital',
  'Hôpital Beijing United Family', 'Hospital Beijing United Family',
  'Hospital', '北京', 39.95489, 116.44371, 'manual', 80),

('BJ_HOS_002', '北京协和医院', 'Peking Union Medical College Hospital',
  'Hôpital du Collège Médical de Pékin', 'Hospital Médico de Peking Union',
  'Hospital', '北京', 39.90963, 116.41609, 'manual', 78),

('BJ_HOS_003', '北京国际SOS诊所', 'International SOS Clinic Beijing',
  'Clinique SOS International Pékin', 'Clínica Internacional SOS Beijing',
  'Hospital', '北京', 39.95391, 116.46175, 'manual', 80),

-- 上海
('SH_HOS_001', '上海和睦家医院', 'Shanghai United Family Hospital',
  'Hôpital Shanghai United Family', 'Hospital Shanghai United Family',
  'Hospital', '上海', 31.22568, 121.44391, 'manual', 80),

('SH_HOS_002', '复旦大学附属中山医院', 'Zhongshan Hospital Fudan University',
  'Hôpital Zhongshan Université Fudan', 'Hospital Zhongshan Universidad Fudan',
  'Hospital', '上海', 31.19805, 121.44613, 'manual', 78),

-- 广州
('GZ_HOS_001', '广州和睦家医院', 'Guangzhou United Family Hospital',
  'Hôpital Guangzhou United Family', 'Hospital Guangzhou United Family',
  'Hospital', '广州', 23.13241, 113.33058, 'manual', 80),

-- 深圳
('SZ_HOS_001', '深圳希玛林顺潮眼科医院', 'C-MER Dennis Lam Eye Hospital Shenzhen',
  'Hôpital Ophtalmologique Shenzhen', 'Hospital Oftalmológico Shenzhen',
  'Hospital', '深圳', 22.54827, 114.05880, 'manual', 75),

('SZ_HOS_002', '深圳北京大学香港大学医学院附属医院', 'HKU-PKU United Shenzhen Hospital',
  'Hôpital HKU-PKU Shenzhen', 'Hospital HKU-PKU Shenzhen',
  'Hospital', '深圳', 22.57960, 114.00770, 'manual', 78),

-- 成都
('CD_HOS_001', '成都和睦家医院', 'Chengdu United Family Hospital',
  'Hôpital Chengdu United Family', 'Hospital Chengdu United Family',
  'Hospital', '成都', 30.68156, 104.07233, 'manual', 80),

-- 西安
('XA_HOS_001', '西安国际医学中心医院', 'Xi''an International Medical Center Hospital',
  'Centre Médical International de Xi''an', 'Centro Médico Internacional de Xi''an',
  'Hospital', '西安', 34.25870, 108.97680, 'manual', 78)
```

---

## 7. 道路名翻译规则引擎（不录入数据库）

道路名在**前端 Dart 代码**中用规则引擎处理，不预存数据库。

### 7.1 规则代码位置

新建文件：`lib/services/map/road_name_translator.dart`

### 7.2 规则逻辑规范

```dart
// 道路名翻译规则（按匹配优先级排序）
class RoadNameTranslator {

  // 规则1：方位词替换（最高优先级）
  static const Map<String, String> _directions = {
    '东': 'East', '西': 'West', '南': 'South', '北': 'North',
    '中': 'Central', '上': 'Upper', '下': 'Lower', '内': 'Inner', '外': 'Outer',
  };

  // 规则2：路型后缀映射
  static const Map<String, String> _suffixes = {
    '大道': 'Avenue',
    '路':   'Road',
    '街':   'Street',
    '巷':   'Lane',
    '胡同': 'Hutong',       // 胡同保留拼音
    '弄':   'Alley',
    '环路': 'Ring Road',
    '高速': 'Expressway',
    '桥':   'Bridge',
    '隧道': 'Tunnel',
  };

  // 规则3：特殊地名（需人工指定，不走拼音）
  static const Map<String, String> _specialNames = {
    '长安': "Chang'an",
    '中关村': 'Zhongguancun',
    '陆家嘴': 'Lujiazui',
    '外滩': 'Bund',
    '南京': 'Nanjing',
    '北京': 'Beijing',
    '上海': 'Shanghai',
    // 更多特殊名称按需添加
  };

  // 规则4：数字路名
  // "一环路" → "1st Ring Road"
  // "二环路" → "2nd Ring Road"
  static const Map<String, String> _chineseNumbers = {
    '一': '1st', '二': '2nd', '三': '3rd',
    '四': '4th', '五': '5th', '六': '6th', '七': '7th',
  };

  // 主方法：中文道路名 → 英文
  // 对于法文/西班牙文，道路名直接沿用英文（专有名词不翻译）
  static String translate(String chineseName) {
    // 实现步骤：
    // 1. 检查 _specialNames，如命中则替换对应部分
    // 2. 提取路型后缀并从 _suffixes 映射
    // 3. 处理方位词
    // 4. 处理数字
    // 5. 剩余中文字符转拼音（接入 pinyin 包）
    // 6. 拼接最终英文名
  }
}

// 拼音依赖：
// dependencies:
//   lpinyin: ^2.0.2   或   pinyin4dart: ^1.0.0
```

---

## 8. 完整 SQL 文件生成规范

Claude Code 需要生成一个文件：`sql/poi_translations_seed.sql`

### 8.1 文件结构

```sql
-- WanderChina POI Translations Seed Data
-- Version: 1.0
-- Generated: [日期]
-- Cities: 北京 上海 广州 深圳 成都 西安
-- Total records: [数量]
-- DO NOT EDIT MANUALLY — use the spec doc to regenerate

BEGIN;

-- ── Section 1: Metro Stations ────────────────────────────────
-- [地铁站数据，约 2200 条]

INSERT INTO poi_translations
  (gaode_poi_id, name_zh, name_en, name_fr, name_es,
   category_en, city, lat, lng, source, priority_score)
VALUES
-- [数据]
ON CONFLICT (gaode_poi_id) DO UPDATE SET
  name_en        = EXCLUDED.name_en,
  name_fr        = EXCLUDED.name_fr,
  name_es        = EXCLUDED.name_es,
  priority_score = EXCLUDED.priority_score,
  source         = EXCLUDED.source,
  updated_at     = NOW();

-- ── Section 2: Transport Hubs ────────────────────────────────
-- [交通枢纽数据，约 60 条]

-- ── Section 3: Core Attractions ─────────────────────────────
-- [核心景点数据，约 300 条]

-- ── Section 4: Hospitals ─────────────────────────────────────
-- [医院数据，约 40 条]

COMMIT;
```

### 8.2 数据验证检查（生成后执行）

```sql
-- 验证数量
SELECT city, category_en, COUNT(*) as count
FROM poi_translations
WHERE source = 'manual'
GROUP BY city, category_en
ORDER BY city, category_en;

-- 验证无空英文名
SELECT COUNT(*) FROM poi_translations WHERE name_en IS NULL OR name_en = '';

-- 验证坐标在合理范围内（中国大陆）
SELECT COUNT(*) FROM poi_translations
WHERE lat NOT BETWEEN 18.0 AND 54.0
   OR lng NOT BETWEEN 73.0 AND 135.0;

-- 验证 category 枚举值合法
SELECT DISTINCT category_en FROM poi_translations
WHERE category_en NOT IN (
  'Attraction','Metro Station','Transport Hub','Museum',
  'Park','Restaurant','Shopping','Hospital','Hotel','Other'
);
```

---

## 9. gaode_poi_id 说明

本文档中的 `gaode_poi_id` 格式为项目内部约定的占位符（如 `BJ_METRO_001`）。

**Claude Code 需要做的：**

1. 若有高德 API 访问权限，用真实的高德 POI UID 替换这些占位符
2. 若无 API 权限，保留占位符格式，上线后由系统自动用真实高德 POI 搜索结果覆盖（`ON CONFLICT DO UPDATE` 会通过 name_zh + city + 坐标匹配合并）
3. 占位符命名规则：`{城市缩写}_{类别缩写}_{三位序号}`，例如 `BJ_METRO_001`、`SH_ATT_003`

**城市缩写：** BJ / SH / GZ / SZ / CD / XA

---

## 10. 执行顺序

```
Step 1  先执行建表脚本（如未执行）：
        sql/poi_translations_init.sql

Step 2  执行本文件生成的种子数据：
        sql/poi_translations_seed.sql

Step 3  执行验证 SQL，确认数据完整

Step 4  实现道路名规则引擎：
        lib/services/map/road_name_translator.dart

Step 5  补全剩余地铁站（目标：6城全量）
        使用高德 API 批量查询 + 规则翻译 + 写入

Step 6  P1 数据补充（热门商圈/购物中心）
        参照第 5 节格式继续录入
```

---

**文档版本：** 1.0
**生成日期：** 2026-02-13
**关联文档：** `WANDERCHINA_MAP_TRANSLATION_SPEC.md` · `SCREEN_SPECIFICATIONS_v2.md`
