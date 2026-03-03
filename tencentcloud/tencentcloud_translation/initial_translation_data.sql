-- ============================================================================
-- 地图翻译初始数据
-- ============================================================================
-- 包含6个主要城市的常用道路、公交站点、路线指令翻译
-- 城市：北京、上海、广州、深圳、成都、西安
-- 创建日期：2026-01-28
-- ============================================================================

-- ============================================================================
-- 1. 道路名称翻译数据
-- ============================================================================

-- 北京主要道路
INSERT INTO road_translations (road_name_zh, road_name_en, city, road_type, road_level, verified) VALUES
-- 环路
('二环路', 'Second Ring Road', '北京', '环路', 1, true),
('三环路', 'Third Ring Road', '北京', '环路', 1, true),
('四环路', 'Fourth Ring Road', '北京', '环路', 1, true),
('五环路', 'Fifth Ring Road', '北京', '环路', 1, true),
('六环路', 'Sixth Ring Road', '北京', '环路', 1, true),

-- 主要道路
('长安街', 'Chang''an Avenue', '北京', '大道', 1, true),
('东长安街', 'East Chang''an Avenue', '北京', '大道', 1, true),
('西长安街', 'West Chang''an Avenue', '北京', '大道', 1, true),
('建国门外大街', 'Jianguomenwai Avenue', '北京', '大道', 2, true),
('复兴门外大街', 'Fuxingmenwai Avenue', '北京', '大道', 2, true),
('王府井大街', 'Wangfujing Street', '北京', '街道', 2, true),
('西单北大街', 'Xidan North Street', '北京', '街道', 3, true),
('东单北大街', 'Dongdan North Street', '北京', '街道', 3, true),
('中关村大街', 'Zhongguancun Avenue', '北京', '大道', 2, true),
('学院路', 'Xueyuan Road', '北京', '道路', 3, true),

-- 上海主要道路
('南京路', 'Nanjing Road', '上海', '道路', 1, true),
('南京东路', 'East Nanjing Road', '上海', '道路', 1, true),
('南京西路', 'West Nanjing Road', '上海', '道路', 1, true),
('淮海路', 'Huaihai Road', '上海', '道路', 2, true),
('淮海中路', 'Middle Huaihai Road', '上海', '道路', 2, true),
('延安路', 'Yan''an Road', '上海', '道路', 1, true),
('延安高架', 'Yan''an Elevated Road', '上海', '高架', 1, true),
('内环线', 'Inner Ring Road', '上海', '环路', 1, true),
('中环线', 'Middle Ring Road', '上海', '环路', 1, true),
('外环线', 'Outer Ring Road', '上海', '环路', 1, true),
('世纪大道', 'Century Avenue', '上海', '大道', 2, true),
('陆家嘴环路', 'Lujiazui Ring Road', '上海', '环路', 3, true),
('衡山路', 'Hengshan Road', '上海', '道路', 3, true),

-- 广州主要道路
('中山路', 'Zhongshan Road', '广州', '道路', 2, true),
('人民路', 'Renmin Road', '广州', '道路', 2, true),
('天河路', 'Tianhe Road', '广州', '道路', 2, true),
('珠江新城', 'Zhujiang New Town', '广州', '区域', 2, true),
('内环路', 'Inner Ring Road', '广州', '环路', 1, true),
('环市路', 'Huanshi Road', '广州', '道路', 2, true),
('环市东路', 'East Huanshi Road', '广州', '道路', 2, true),
('环市西路', 'West Huanshi Road', '广州', '道路', 2, true),
('广州大道', 'Guangzhou Avenue', '广州', '大道', 1, true),
('北京路步行街', 'Beijing Road Pedestrian Street', '广州', '步行街', 3, true),

-- 深圳主要道路
('深南大道', 'Shennan Avenue', '深圳', '大道', 1, true),
('深南东路', 'East Shennan Road', '深圳', '道路', 1, true),
('深南中路', 'Middle Shennan Road', '深圳', '道路', 1, true),
('深南西路', 'West Shennan Road', '深圳', '道路', 1, true),
('滨河大道', 'Binhe Avenue', '深圳', '大道', 1, true),
('北环大道', 'North Ring Avenue', '深圳', '大道', 1, true),
('南环大道', 'South Ring Avenue', '深圳', '大道', 1, true),
('华强北路', 'Huaqiangbei Road', '深圳', '道路', 2, true),
('福田路', 'Futian Road', '深圳', '道路', 3, true),

-- 成都主要道路
('人民路', 'Renmin Road', '成都', '道路', 2, true),
('天府大道', 'Tianfu Avenue', '成都', '大道', 1, true),
('红星路', 'Hongxing Road', '成都', '道路', 2, true),
('春熙路', 'Chunxi Road', '成都', '道路', 2, true),
('一环路', 'First Ring Road', '成都', '环路', 1, true),
('二环路', 'Second Ring Road', '成都', '环路', 1, true),
('三环路', 'Third Ring Road', '成都', '环路', 1, true),
('蜀都大道', 'Shudu Avenue', '成都', '大道', 2, true),
('武侯大道', 'Wuhou Avenue', '成都', '大道', 2, true),

-- 西安主要道路
('长安路', 'Chang''an Road', '西安', '道路', 2, true),
('东大街', 'East Main Street', '西安', '街道', 2, true),
('西大街', 'West Main Street', '西安', '街道', 2, true),
('南大街', 'South Main Street', '西安', '街道', 2, true),
('北大街', 'North Main Street', '西安', '街道', 2, true),
('环城路', 'City Ring Road', '西安', '环路', 2, true),
('二环路', 'Second Ring Road', '西安', '环路', 1, true),
('雁塔路', 'Yanta Road', '西安', '道路', 3, true),
('小寨路', 'Xiaozhai Road', '西安', '道路', 3, true);

-- ============================================================================
-- 2. 公交站点翻译数据（地铁站为主）
-- ============================================================================

-- 北京地铁站
INSERT INTO transit_station_translations (station_name_zh, station_name_en, city, station_type, line_name_zh, line_name_en, line_number, latitude, longitude, verified) VALUES
('天安门东', 'Tian''anmen East', '北京', 'metro', '1号线', 'Line 1', '1', 39.9075, 116.4011, true),
('天安门西', 'Tian''anmen West', '北京', 'metro', '1号线', 'Line 1', '1', 39.9068, 116.3971, true),
('王府井', 'Wangfujing', '北京', 'metro', '1号线', 'Line 1', '1', 39.9097, 116.4108, true),
('东单', 'Dongdan', '北京', 'metro', '1号线/5号线', 'Line 1/5', '1,5', 39.9041, 116.4175, true),
('西单', 'Xidan', '北京', 'metro', '1号线/4号线', 'Line 1/4', '1,4', 39.9056, 116.3742, true),
('建国门', 'Jianguomen', '北京', 'metro', '1号线/2号线', 'Line 1/2', '1,2', 39.9059, 116.4350, true),
('国贸', 'Guomao', '北京', 'metro', '1号线/10号线', 'Line 1/10', '1,10', 39.9083, 116.4581, true),
('三里屯', 'Sanlitun', '北京', 'metro', '10号线', 'Line 10', '10', 39.9386, 116.4489, true),
('中关村', 'Zhongguancun', '北京', 'metro', '4号线', 'Line 4', '4', 39.9828, 116.3153, true),
('北京西站', 'Beijing West Railway Station', '北京', 'metro', '7号线/9号线', 'Line 7/9', '7,9', 39.8951, 116.3221, true),
('北京南站', 'Beijing South Railway Station', '北京', 'metro', '4号线/14号线', 'Line 4/14', '4,14', 39.8654, 116.3784, true),
('机场线', 'Airport Express', '北京', 'metro', '机场线', 'Airport Express', 'airport', 40.0723, 116.5983, true),

-- 上海地铁站
('人民广场', 'People''s Square', '上海', 'metro', '1号线/2号线/8号线', 'Line 1/2/8', '1,2,8', 31.2354, 121.4759, true),
('南京东路', 'East Nanjing Road', '上海', 'metro', '2号线/10号线', 'Line 2/10', '2,10', 31.2346, 121.4813, true),
('静安寺', 'Jing''an Temple', '上海', 'metro', '2号线/7号线', 'Line 2/7', '2,7', 31.2267, 121.4475, true),
('徐家汇', 'Xujiahui', '上海', 'metro', '1号线/9号线/11号线', 'Line 1/9/11', '1,9,11', 31.1953, 121.4365, true),
('陆家嘴', 'Lujiazui', '上海', 'metro', '2号线', 'Line 2', '2', 31.2408, 121.4998, true),
('世纪大道', 'Century Avenue', '上海', 'metro', '2号线/4号线/6号线/9号线', 'Line 2/4/6/9', '2,4,6,9', 31.2372, 121.5358, true),
('豫园', 'Yu Garden', '上海', 'metro', '10号线', 'Line 10', '10', 31.2284, 121.4922, true),
('虹桥火车站', 'Hongqiao Railway Station', '上海', 'metro', '2号线/10号线/17号线', 'Line 2/10/17', '2,10,17', 31.1944, 121.3206, true),
('浦东国际机场', 'Pudong International Airport', '上海', 'metro', '2号线', 'Line 2', '2', 31.1534, 121.8054, true),

-- 广州地铁站
('体育西路', 'Tiyu Xilu', '广州', 'metro', '1号线/3号线', 'Line 1/3', '1,3', 23.1373, 113.3258, true),
('广州塔', 'Canton Tower', '广州', 'metro', '3号线', 'Line 3', '3', 23.1057, 113.3192, true),
('珠江新城', 'Zhujiang New Town', '广州', 'metro', '3号线/5号线', 'Line 3/5', '3,5', 23.1193, 113.3244, true),
('公园前', 'Gongyuanqian', '广州', 'metro', '1号线/2号线', 'Line 1/2', '1,2', 23.1294, 113.2645, true),
('广州东站', 'Guangzhou East Railway Station', '广州', 'metro', '1号线/3号线', 'Line 1/3', '1,3', 23.1556, 113.3237, true),
('广州南站', 'Guangzhou South Railway Station', '广州', 'metro', '2号线/7号线', 'Line 2/7', '2,7', 23.0058, 113.2644, true),

-- 深圳地铁站
('老街', 'Laojie', '深圳', 'metro', '1号线/3号线', 'Line 1/3', '1,3', 22.5454, 114.1167, true),
('国贸', 'Guomao', '深圳', 'metro', '1号线', 'Line 1', '1', 22.5424, 114.1093, true),
('会展中心', 'Convention & Exhibition Center', '深圳', 'metro', '1号线/4号线', 'Line 1/4', '1,4', 22.5390, 114.0517, true),
('深圳北站', 'Shenzhen North Station', '深圳', 'metro', '4号线/5号线/6号线', 'Line 4/5/6', '4,5,6', 22.6101, 114.0301, true),
('福田', 'Futian', '深圳', 'metro', '2号线/3号线/11号线', 'Line 2/3/11', '2,3,11', 22.5370, 114.0550, true),
('世界之窗', 'Window of the World', '深圳', 'metro', '1号线/2号线', 'Line 1/2', '1,2', 22.5368, 113.9760, true),

-- 成都地铁站
('天府广场', 'Tianfu Square', '成都', 'metro', '1号线/2号线', 'Line 1/2', '1,2', 30.6620, 104.0660, true),
('春熙路', 'Chunxi Road', '成都', 'metro', '2号线/3号线', 'Line 2/3', '2,3', 30.6596, 104.0815, true),
('骡马市', 'Luomashi', '成都', 'metro', '1号线/4号线', 'Line 1/4', '1,4', 30.6621, 104.0738, true),
('火车南站', 'Railway South Station', '成都', 'metro', '1号线/7号线', 'Line 1/7', '1,7', 30.6153, 104.0715, true),
('成都东站', 'Chengdu East Railway Station', '成都', 'metro', '2号线/7号线', 'Line 2/7', '2,7', 30.6372, 104.1472, true),

-- 西安地铁站
('钟楼', 'Bell Tower', '西安', 'metro', '2号线', 'Line 2', '2', 34.2580, 108.9485, true),
('小寨', 'Xiaozhai', '西安', 'metro', '2号线/3号线', 'Line 2/3', '2,3', 34.2248, 108.9453, true),
('大雁塔', 'Big Wild Goose Pagoda', '西安', 'metro', '3号线/4号线', 'Line 3/4', '3,4', 34.2176, 108.9649, true),
('西安北站', 'Xi''an North Railway Station', '西安', 'metro', '2号线/4号线', 'Line 2/4', '2,4', 34.3741, 108.9619, true),
('西安站', 'Xi''an Railway Station', '西安', 'metro', '4号线', 'Line 4', '4', 34.2725, 108.9515, true);

-- ============================================================================
-- 3. 路线指令翻译数据
-- ============================================================================

INSERT INTO route_instruction_translations (instruction_zh, instruction_en, instruction_type, route_type, verified) VALUES
-- 出发/到达
('从起点出发', 'Start from origin', 'depart', NULL, true),
('到达终点', 'Arrive at destination', 'arrive', NULL, true),
('到达途经点', 'Arrive at waypoint', 'arrive', NULL, true),

-- 转弯指令
('左转', 'Turn left', 'turn', NULL, true),
('右转', 'Turn right', 'turn', NULL, true),
('向左转', 'Turn left', 'turn', NULL, true),
('向右转', 'Turn right', 'turn', NULL, true),
('左前方转弯', 'Turn left ahead', 'turn', NULL, true),
('右前方转弯', 'Turn right ahead', 'turn', NULL, true),
('掉头', 'Make a U-turn', 'turn', NULL, true),

-- 直行指令
('直行', 'Go straight', 'straight', NULL, true),
('继续前进', 'Continue straight', 'straight', NULL, true),
('保持直行', 'Keep going straight', 'straight', NULL, true),

-- 道路指令
('进入', 'Enter', 'straight', NULL, true),
('驶入', 'Enter', 'straight', NULL, true),
('驶出', 'Exit', 'straight', NULL, true),
('上匝道', 'Take the ramp', 'straight', 'driving', true),
('下匝道', 'Exit the ramp', 'straight', 'driving', true),
('进入环岛', 'Enter the roundabout', 'turn', 'driving', true),
('驶出环岛', 'Exit the roundabout', 'turn', 'driving', true),

-- 公交指令
('步行至', 'Walk to', 'straight', 'transit', true),
('乘坐', 'Take', 'straight', 'transit', true),
('换乘', 'Transfer to', 'straight', 'transit', true),
('在', 'at', 'straight', 'transit', true),
('上车', 'Get on', 'straight', 'transit', true),
('下车', 'Get off', 'straight', 'transit', true),

-- 距离描述
('前方', 'ahead', 'straight', NULL, true),
('后', 'after', 'straight', NULL, true),
('约', 'approximately', 'straight', NULL, true);

-- ============================================================================
-- 4. 区域/地名翻译数据
-- ============================================================================

INSERT INTO area_translations (area_name_zh, area_name_en, city, area_type, area_level, verified) VALUES
-- 北京
('朝阳区', 'Chaoyang District', '北京', 'district', 1, true),
('海淀区', 'Haidian District', '北京', 'district', 1, true),
('东城区', 'Dongcheng District', '北京', 'district', 1, true),
('西城区', 'Xicheng District', '北京', 'district', 1, true),
('丰台区', 'Fengtai District', '北京', 'district', 1, true),
('国贸', 'Guomao', '北京', 'business', 2, true),
('中关村', 'Zhongguancun', '北京', 'business', 2, true),
('三里屯', 'Sanlitun', '北京', 'business', 2, true),
('798艺术区', '798 Art District', '北京', 'landmark', 2, true),

-- 上海
('浦东新区', 'Pudong New Area', '上海', 'district', 1, true),
('黄浦区', 'Huangpu District', '上海', 'district', 1, true),
('徐汇区', 'Xuhui District', '上海', 'district', 1, true),
('静安区', 'Jing''an District', '上海', 'district', 1, true),
('陆家嘴', 'Lujiazui', '上海', 'business', 2, true),
('外滩', 'The Bund', '上海', 'landmark', 2, true),
('新天地', 'Xintiandi', '上海', 'business', 2, true),

-- 广州
('天河区', 'Tianhe District', '广州', 'district', 1, true),
('越秀区', 'Yuexiu District', '广州', 'district', 1, true),
('海珠区', 'Haizhu District', '广州', 'district', 1, true),
('珠江新城', 'Zhujiang New Town', '广州', 'business', 2, true),
('北京路', 'Beijing Road', '广州', 'business', 2, true),

-- 深圳
('福田区', 'Futian District', '深圳', 'district', 1, true),
('南山区', 'Nanshan District', '深圳', 'district', 1, true),
('罗湖区', 'Luohu District', '深圳', 'district', 1, true),
('华强北', 'Huaqiangbei', '深圳', 'business', 2, true),

-- 成都
('武侯区', 'Wuhou District', '成都', 'district', 1, true),
('锦江区', 'Jinjiang District', '成都', 'district', 1, true),
('青羊区', 'Qingyang District', '成都', 'district', 1, true),
('春熙路', 'Chunxi Road', '成都', 'business', 2, true),
('宽窄巷子', 'Kuanzhai Alley', '成都', 'landmark', 2, true),

-- 西安
('雁塔区', 'Yanta District', '西安', 'district', 1, true),
('碑林区', 'Beilin District', '西安', 'district', 1, true),
('莲湖区', 'Lianhu District', '西安', 'district', 1, true),
('回民街', 'Muslim Quarter', '西安', 'business', 2, true);

-- ============================================================================
-- 完成
-- ============================================================================

-- 统计插入的数据
SELECT
    '道路翻译' as category,
    count(*) as count
FROM road_translations

UNION ALL

SELECT
    '站点翻译' as category,
    count(*) as count
FROM transit_station_translations

UNION ALL

SELECT
    '指令翻译' as category,
    count(*) as count
FROM route_instruction_translations

UNION ALL

SELECT
    '区域翻译' as category,
    count(*) as count
FROM area_translations;
