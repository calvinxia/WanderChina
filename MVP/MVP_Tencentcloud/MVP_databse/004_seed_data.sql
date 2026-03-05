-- ============================================================================
-- WanderChina MVP — Step 4: 种子数据
-- ============================================================================
-- 执行身份: wanderchina_pg_prod
-- 依赖:     002_tables.sql
-- ============================================================================
--
-- 数据来源:
--   地铁站: 旧版 transit_station_translations 转换，人工校对
--   景点:   人工整理，6 城市核心景点
--   道路/区域: 无坐标，不适合 poi_translations，存入单独参考表
--
-- 说明:
--   gaode_poi_id 使用 SEED_XX_NNN 格式标识种子数据
--   Phase 6 高德 API 批量导入时会用真实 gaode_poi_id 替换
--   location + geohash 由触发器 trg_poi_sync_spatial 自动计算
--
-- ============================================================================


-- ========================================================================
-- Part 1: 核心景点（priority_score = 90-100）
-- ========================================================================

INSERT INTO poi_translations
    (gaode_poi_id, name_zh, name_en, name_fr, name_es, category_zh, category_en, city, latitude, longitude, priority_score, source, verified)
VALUES
-- 北京
('SEED_BJ_A01', '故宫博物院',       'Palace Museum',               'Cité Interdite',                'Ciudad Prohibida',              '景点', 'Attraction',    '北京', 39.9163000, 116.3972000, 100, 'manual', true),
('SEED_BJ_A02', '天安门广场',       'Tiananmen Square',            'Place Tiananmen',               'Plaza de Tiananmen',            '景点', 'Attraction',    '北京', 39.9054000, 116.3976000, 100, 'manual', true),
('SEED_BJ_A03', '天坛公园',         'Temple of Heaven',            'Temple du Ciel',                'Templo del Cielo',              '公园', 'Park',          '北京', 39.8822000, 116.4066000, 95,  'manual', true),
('SEED_BJ_A04', '颐和园',           'Summer Palace',               'Palais d''Été',                 'Palacio de Verano',             '公园', 'Park',          '北京', 39.9995000, 116.2753000, 95,  'manual', true),
('SEED_BJ_A05', '鸟巢',             'Bird''s Nest (National Stadium)', 'Nid d''Oiseau',              'Nido de Pájaro',                '景点', 'Attraction',    '北京', 39.9929000, 116.3966000, 85,  'manual', true),
('SEED_BJ_A06', '国家博物馆',       'National Museum of China',    'Musée national de Chine',       'Museo Nacional de China',       '博物馆','Museum',        '北京', 39.9046000, 116.4016000, 90,  'manual', true),
('SEED_BJ_A07', '798艺术区',        '798 Art District',            'District artistique 798',       'Distrito de Arte 798',          '景点', 'Attraction',    '北京', 39.9829000, 116.4936000, 80,  'manual', true),
('SEED_BJ_A08', '南锣鼓巷',         'Nanluoguxiang',               'Nanluoguxiang',                 'Nanluoguxiang',                 '景点', 'Attraction',    '北京', 39.9373000, 116.4019000, 80,  'manual', true),

-- 上海
('SEED_SH_A01', '外滩',             'The Bund',                    'Le Bund',                       'El Bund',                       '景点', 'Attraction',    '上海', 31.2320000, 121.4905000, 100, 'manual', true),
('SEED_SH_A02', '东方明珠',         'Oriental Pearl Tower',        'Tour Perle de l''Orient',       'Torre Perla Oriental',          '景点', 'Attraction',    '上海', 31.2397000, 121.4995000, 95,  'manual', true),
('SEED_SH_A03', '豫园',             'Yu Garden',                   'Jardin Yu',                     'Jardín Yu',                     '公园', 'Park',          '上海', 31.2275000, 121.4925000, 90,  'manual', true),
('SEED_SH_A04', '上海博物馆',       'Shanghai Museum',             'Musée de Shanghai',             'Museo de Shanghái',             '博物馆','Museum',        '上海', 31.2350000, 121.4747000, 85,  'manual', true),
('SEED_SH_A05', '新天地',           'Xintiandi',                   'Xintiandi',                     'Xintiandi',                     '景点', 'Attraction',    '上海', 31.2193000, 121.4741000, 85,  'manual', true),
('SEED_SH_A06', '田子坊',           'Tianzifang',                  'Tianzifang',                    'Tianzifang',                    '景点', 'Attraction',    '上海', 31.2104000, 121.4673000, 80,  'manual', true),

-- 广州
('SEED_GZ_A01', '广州塔',           'Canton Tower',                'Tour de Canton',                'Torre de Cantón',               '景点', 'Attraction',    '广州', 23.1061000, 113.3243000, 100, 'manual', true),
('SEED_GZ_A02', '陈家祠',           'Chen Clan Ancestral Hall',    'Temple ancestral du clan Chen', 'Salón Ancestral del Clan Chen', '博物馆','Museum',        '广州', 23.1261000, 113.2451000, 90,  'manual', true),
('SEED_GZ_A03', '沙面岛',           'Shamian Island',              'Île de Shamian',                'Isla Shamian',                  '景点', 'Attraction',    '广州', 23.1062000, 113.2341000, 85,  'manual', true),
('SEED_GZ_A04', '北京路步行街',     'Beijing Road Pedestrian Street','Rue piétonne de Pékin',        'Calle peatonal de Beijing',     '景点', 'Attraction',    '广州', 23.1250000, 113.2660000, 80,  'manual', true),
('SEED_GZ_A05', '白云山',           'Baiyun Mountain',             'Montagne Baiyun',               'Montaña Baiyun',                '公园', 'Park',          '广州', 23.1760000, 113.2925000, 85,  'manual', true),

-- 深圳
('SEED_SZ_A01', '世界之窗',         'Window of the World',         'Fenêtre sur le Monde',          'Ventana del Mundo',             '景点', 'Attraction',    '深圳', 22.5370000, 113.9748000, 90,  'manual', true),
('SEED_SZ_A02', '大梅沙海滨公园',   'Dameisha Beach Park',         'Parc de plage de Dameisha',     'Parque de playa Dameisha',      '公园', 'Park',          '深圳', 22.5945000, 114.3152000, 80,  'manual', true),
('SEED_SZ_A03', '华强北',           'Huaqiangbei Electronics Market','Marché électronique Huaqiangbei','Mercado electrónico Huaqiangbei','购物','Shopping',     '深圳', 22.5454000, 114.0872000, 85,  'manual', true),

-- 成都
('SEED_CD_A01', '武侯祠',           'Wuhou Shrine',                'Temple de Wuhou',               'Templo de Wuhou',               '博物馆','Museum',        '成都', 30.6433000, 104.0500000, 90,  'manual', true),
('SEED_CD_A02', '宽窄巷子',         'Kuanzhai Alley',              'Ruelle Kuanzhai',               'Callejón Kuanzhai',             '景点', 'Attraction',    '成都', 30.6695000, 104.0555000, 90,  'manual', true),
('SEED_CD_A03', '大熊猫繁育研究基地','Chengdu Research Base of Giant Panda Breeding','Base de recherche du panda géant','Base de cría del panda gigante','景点','Attraction','成都', 30.7373000, 104.1459000, 100, 'manual', true),
('SEED_CD_A04', '锦里古街',         'Jinli Ancient Street',        'Ancienne rue Jinli',            'Calle antigua Jinli',           '景点', 'Attraction',    '成都', 30.6425000, 104.0476000, 85,  'manual', true),
('SEED_CD_A05', '春熙路',           'Chunxi Road',                 'Rue Chunxi',                    'Calle Chunxi',                  '购物', 'Shopping',      '成都', 30.6567000, 104.0815000, 85,  'manual', true),

-- 西安
('SEED_XA_A01', '兵马俑',           'Terracotta Army',             'Armée de terre cuite',          'Ejército de Terracota',         '博物馆','Museum',        '西安', 34.3842000, 109.2781000, 100, 'manual', true),
('SEED_XA_A02', '大雁塔',           'Big Wild Goose Pagoda',       'Grande Pagode de l''Oie Sauvage','Gran Pagoda del Ganso Salvaje', '景点', 'Attraction',    '西安', 34.2185000, 108.9654000, 95,  'manual', true),
('SEED_XA_A03', '钟楼',             'Bell Tower',                  'Tour de la Cloche',             'Torre de la Campana',           '景点', 'Attraction',    '西安', 34.2585000, 108.9468000, 95,  'manual', true),
('SEED_XA_A04', '城墙',             'Ancient City Wall',           'Muraille de la ville antique',  'Muralla de la ciudad antigua',  '景点', 'Attraction',    '西安', 34.2566000, 108.9407000, 90,  'manual', true),
('SEED_XA_A05', '回民街',           'Muslim Quarter',              'Quartier musulman',             'Barrio musulmán',               '景点', 'Attraction',    '西安', 34.2628000, 108.9424000, 90,  'manual', true),
('SEED_XA_A06', '陕西历史博物馆',   'Shaanxi History Museum',      'Musée d''histoire du Shaanxi',  'Museo de Historia de Shaanxi',  '博物馆','Museum',        '西安', 34.2282000, 108.9537000, 90,  'manual', true);


-- ========================================================================
-- Part 2: 地铁站（priority_score = 70，category_en = 'Metro Station'）
-- ========================================================================
-- 转换自旧版 transit_station_translations
-- 原始线路信息存入 address_zh 字段（如 "1号线/2号线"）

INSERT INTO poi_translations
    (gaode_poi_id, name_zh, name_en, category_zh, category_en, address_zh, city, latitude, longitude, priority_score, source, verified)
VALUES
-- 北京地铁
('SEED_BJ_M01', '天安门东站',   'Tian''anmen East Station',          '地铁站', 'Metro Station', '1号线',           '北京', 39.9075000, 116.4011000, 70, 'manual', true),
('SEED_BJ_M02', '天安门西站',   'Tian''anmen West Station',          '地铁站', 'Metro Station', '1号线',           '北京', 39.9068000, 116.3971000, 70, 'manual', true),
('SEED_BJ_M03', '王府井站',     'Wangfujing Station',                '地铁站', 'Metro Station', '1号线',           '北京', 39.9097000, 116.4108000, 70, 'manual', true),
('SEED_BJ_M04', '东单站',       'Dongdan Station',                   '地铁站', 'Metro Station', '1号线/5号线',     '北京', 39.9041000, 116.4175000, 70, 'manual', true),
('SEED_BJ_M05', '西单站',       'Xidan Station',                     '地铁站', 'Metro Station', '1号线/4号线',     '北京', 39.9056000, 116.3742000, 70, 'manual', true),
('SEED_BJ_M06', '建国门站',     'Jianguomen Station',                '地铁站', 'Metro Station', '1号线/2号线',     '北京', 39.9059000, 116.4350000, 70, 'manual', true),
('SEED_BJ_M07', '国贸站',       'Guomao Station',                    '地铁站', 'Metro Station', '1号线/10号线',    '北京', 39.9083000, 116.4581000, 70, 'manual', true),
('SEED_BJ_M08', '三里屯站',     'Sanlitun Station',                  '地铁站', 'Metro Station', '10号线',          '北京', 39.9386000, 116.4489000, 70, 'manual', true),
('SEED_BJ_M09', '中关村站',     'Zhongguancun Station',              '地铁站', 'Metro Station', '4号线',           '北京', 39.9828000, 116.3153000, 70, 'manual', true),
('SEED_BJ_M10', '北京西站',     'Beijing West Railway Station',      '火车站', 'Transport Hub', '7号线/9号线',     '北京', 39.8951000, 116.3221000, 75, 'manual', true),
('SEED_BJ_M11', '北京南站',     'Beijing South Railway Station',     '火车站', 'Transport Hub', '4号线/14号线',    '北京', 39.8654000, 116.3784000, 75, 'manual', true),
('SEED_BJ_M12', '首都机场',     'Capital Airport',                   '机场',   'Transport Hub', '机场线',          '北京', 40.0723000, 116.5983000, 80, 'manual', true),

-- 上海地铁
('SEED_SH_M01', '人民广场站',   'People''s Square Station',          '地铁站', 'Metro Station', '1/2/8号线',       '上海', 31.2354000, 121.4759000, 70, 'manual', true),
('SEED_SH_M02', '南京东路站',   'East Nanjing Road Station',         '地铁站', 'Metro Station', '2/10号线',        '上海', 31.2346000, 121.4813000, 70, 'manual', true),
('SEED_SH_M03', '静安寺站',     'Jing''an Temple Station',           '地铁站', 'Metro Station', '2/7号线',         '上海', 31.2267000, 121.4475000, 70, 'manual', true),
('SEED_SH_M04', '徐家汇站',     'Xujiahui Station',                  '地铁站', 'Metro Station', '1/9/11号线',      '上海', 31.1953000, 121.4365000, 70, 'manual', true),
('SEED_SH_M05', '陆家嘴站',     'Lujiazui Station',                  '地铁站', 'Metro Station', '2号线',           '上海', 31.2408000, 121.4998000, 70, 'manual', true),
('SEED_SH_M06', '世纪大道站',   'Century Avenue Station',            '地铁站', 'Metro Station', '2/4/6/9号线',     '上海', 31.2372000, 121.5358000, 70, 'manual', true),
('SEED_SH_M07', '豫园站',       'Yu Garden Station',                 '地铁站', 'Metro Station', '10号线',          '上海', 31.2284000, 121.4922000, 70, 'manual', true),
('SEED_SH_M08', '虹桥火车站',   'Hongqiao Railway Station',          '火车站', 'Transport Hub', '2/10/17号线',     '上海', 31.1944000, 121.3206000, 75, 'manual', true),
('SEED_SH_M09', '浦东国际机场', 'Pudong International Airport',      '机场',   'Transport Hub', '2号线/磁悬浮',    '上海', 31.1534000, 121.8054000, 80, 'manual', true),

-- 广州地铁
('SEED_GZ_M01', '体育西路站',   'Tiyu Xilu Station',                 '地铁站', 'Metro Station', '1/3号线',         '广州', 23.1373000, 113.3258000, 70, 'manual', true),
('SEED_GZ_M02', '广州塔站',     'Canton Tower Station',              '地铁站', 'Metro Station', '3号线/APM',       '广州', 23.1057000, 113.3192000, 70, 'manual', true),
('SEED_GZ_M03', '珠江新城站',   'Zhujiang New Town Station',         '地铁站', 'Metro Station', '3/5号线',         '广州', 23.1193000, 113.3244000, 70, 'manual', true),
('SEED_GZ_M04', '公园前站',     'Gongyuanqian Station',              '地铁站', 'Metro Station', '1/2号线',         '广州', 23.1294000, 113.2645000, 70, 'manual', true),
('SEED_GZ_M05', '广州东站',     'Guangzhou East Railway Station',    '火车站', 'Transport Hub', '1/3号线',         '广州', 23.1556000, 113.3237000, 75, 'manual', true),
('SEED_GZ_M06', '广州南站',     'Guangzhou South Railway Station',   '火车站', 'Transport Hub', '2/7号线',         '广州', 23.0058000, 113.2644000, 75, 'manual', true),

-- 深圳地铁
('SEED_SZ_M01', '老街站',       'Laojie Station',                    '地铁站', 'Metro Station', '1/3号线',         '深圳', 22.5454000, 114.1167000, 70, 'manual', true),
('SEED_SZ_M02', '国贸站',       'Guomao Station',                    '地铁站', 'Metro Station', '1号线',           '深圳', 22.5424000, 114.1093000, 70, 'manual', true),
('SEED_SZ_M03', '会展中心站',   'Convention Center Station',         '地铁站', 'Metro Station', '1/4号线',         '深圳', 22.5390000, 114.0517000, 70, 'manual', true),
('SEED_SZ_M04', '深圳北站',     'Shenzhen North Railway Station',   '火车站', 'Transport Hub', '4/5/6号线',       '深圳', 22.6101000, 114.0301000, 75, 'manual', true),
('SEED_SZ_M05', '福田站',       'Futian Station',                    '地铁站', 'Metro Station', '2/3/11号线',      '深圳', 22.5370000, 114.0550000, 70, 'manual', true),
('SEED_SZ_M06', '世界之窗站',   'Window of the World Station',       '地铁站', 'Metro Station', '1/2号线',         '深圳', 22.5368000, 113.9760000, 70, 'manual', true),

-- 成都地铁
('SEED_CD_M01', '天府广场站',   'Tianfu Square Station',             '地铁站', 'Metro Station', '1/2号线',         '成都', 30.6620000, 104.0660000, 70, 'manual', true),
('SEED_CD_M02', '春熙路站',     'Chunxi Road Station',               '地铁站', 'Metro Station', '2/3号线',         '成都', 30.6596000, 104.0815000, 70, 'manual', true),
('SEED_CD_M03', '骡马市站',     'Luomashi Station',                  '地铁站', 'Metro Station', '1/4号线',         '成都', 30.6621000, 104.0738000, 70, 'manual', true),
('SEED_CD_M04', '火车南站',     'South Railway Station',             '火车站', 'Transport Hub', '1/7号线',         '成都', 30.6153000, 104.0715000, 75, 'manual', true),
('SEED_CD_M05', '成都东站',     'Chengdu East Railway Station',      '火车站', 'Transport Hub', '2/7号线',         '成都', 30.6372000, 104.1472000, 75, 'manual', true),

-- 西安地铁
('SEED_XA_M01', '钟楼站',       'Bell Tower Station',                '地铁站', 'Metro Station', '2号线',           '西安', 34.2580000, 108.9485000, 70, 'manual', true),
('SEED_XA_M02', '小寨站',       'Xiaozhai Station',                  '地铁站', 'Metro Station', '2/3号线',         '西安', 34.2248000, 108.9453000, 70, 'manual', true),
('SEED_XA_M03', '大雁塔站',     'Big Wild Goose Pagoda Station',     '地铁站', 'Metro Station', '3/4号线',         '西安', 34.2176000, 108.9649000, 70, 'manual', true),
('SEED_XA_M04', '西安北站',     'Xi''an North Railway Station',      '火车站', 'Transport Hub', '2/4号线',         '西安', 34.3741000, 108.9619000, 75, 'manual', true),
('SEED_XA_M05', '西安站',       'Xi''an Railway Station',            '火车站', 'Transport Hub', '4号线',           '西安', 34.2725000, 108.9515000, 75, 'manual', true);


-- ========================================================================
-- Part 3: 导航指令参考表（独立表，客户端翻译用）
-- ========================================================================
-- 这些不是 POI，不适合放在 poi_translations
-- 创建单独的轻量参考表，客户端启动时一次性加载

CREATE TABLE IF NOT EXISTS nav_instructions_i18n (
    id          SERIAL PRIMARY KEY,
    text_zh     VARCHAR(100) NOT NULL UNIQUE,
    text_en     VARCHAR(200) NOT NULL,
    text_fr     VARCHAR(200),
    text_es     VARCHAR(200),
    category    VARCHAR(20) NOT NULL     -- depart / arrive / turn / straight / transit / distance
);

INSERT INTO nav_instructions_i18n (text_zh, text_en, category) VALUES
-- 出发/到达
('从起点出发',   'Start from origin',       'depart'),
('到达终点',     'Arrive at destination',   'arrive'),
('到达途经点',   'Arrive at waypoint',      'arrive'),
-- 转弯
('左转',         'Turn left',               'turn'),
('右转',         'Turn right',              'turn'),
('向左转',       'Turn left',               'turn'),
('向右转',       'Turn right',              'turn'),
('左前方转弯',   'Turn left ahead',         'turn'),
('右前方转弯',   'Turn right ahead',        'turn'),
('掉头',         'Make a U-turn',           'turn'),
-- 直行
('直行',         'Go straight',             'straight'),
('继续前进',     'Continue straight',       'straight'),
('保持直行',     'Keep going straight',     'straight'),
-- 道路
('进入',         'Enter',                   'straight'),
('驶入',         'Enter',                   'straight'),
('驶出',         'Exit',                    'straight'),
('上匝道',       'Take the ramp',           'straight'),
('下匝道',       'Exit the ramp',           'straight'),
('进入环岛',     'Enter the roundabout',    'turn'),
('驶出环岛',     'Exit the roundabout',     'turn'),
-- 公交
('步行至',       'Walk to',                 'transit'),
('乘坐',         'Take',                    'transit'),
('换乘',         'Transfer to',             'transit'),
('上车',         'Get on',                  'transit'),
('下车',         'Get off',                 'transit'),
-- 距离
('前方',         'ahead',                   'distance'),
('约',           'approximately',           'distance');

-- 授权
GRANT SELECT ON nav_instructions_i18n TO wc_scf_service;
GRANT SELECT ON nav_instructions_i18n TO wc_readonly;


-- ========================================================================
-- 验证
-- ========================================================================

-- 统计种子数据
SELECT city, category_en, COUNT(*) AS count
FROM poi_translations
GROUP BY city, category_en
ORDER BY city, category_en;

-- 验证 geohash 触发器是否生效（应该有值）
SELECT gaode_poi_id, name_en, city, geohash, ST_AsText(location::geometry)
FROM poi_translations
LIMIT 5;

-- 总计
SELECT
    (SELECT COUNT(*) FROM poi_translations) AS total_pois,
    (SELECT COUNT(*) FROM nav_instructions_i18n) AS total_nav_instructions;
-- 预期: total_pois = 76, total_nav_instructions ≈ 26
