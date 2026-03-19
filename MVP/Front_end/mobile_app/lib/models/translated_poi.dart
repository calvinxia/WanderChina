import 'poi.dart';

/// 双语POI模型
///
/// 扩展原有POI模型，添加英文翻译字段
class TranslatedPOI extends POI {
  /// 英文名称
  final String? nameEn;

  /// 英文地址
  final String? addressEn;

  /// 英文描述
  final String? descriptionEn;

  /// 英文标签
  final List<String>? tagsEn;

  /// 翻译置信度（0.0-1.0）
  final double? translationConfidence;

  /// 是否已翻译
  final bool isTranslated;

  /// 翻译来源（cache/api/manual）
  final String? translationSource;

  TranslatedPOI({
    required super.id,
    required super.name,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.category,
    super.rating,
    super.reviewCount,
    super.distance,
    super.phone,
    super.openingHours,
    super.priceLevel,
    super.photos,
    super.description,
    super.isOpen,
    super.tags,
    this.nameEn,
    this.addressEn,
    this.descriptionEn,
    this.tagsEn,
    this.translationConfidence,
    this.isTranslated = false,
    this.translationSource,
  });

  /// 从普通POI创建（待翻译）
  factory TranslatedPOI.fromPOI(POI poi) {
    return TranslatedPOI(
      id: poi.id,
      name: poi.name,
      address: poi.address,
      latitude: poi.latitude,
      longitude: poi.longitude,
      category: poi.category,
      rating: poi.rating,
      reviewCount: poi.reviewCount,
      distance: poi.distance,
      phone: poi.phone,
      openingHours: poi.openingHours,
      priceLevel: poi.priceLevel,
      photos: poi.photos,
      description: poi.description,
      isOpen: poi.isOpen,
      tags: poi.tags,
      isTranslated: false,
    );
  }

  /// 从JSON创建
  factory TranslatedPOI.fromJson(Map<String, dynamic> json) {
    final poi = POI.fromJson(json);
    return TranslatedPOI(
      id: poi.id,
      name: poi.name,
      address: poi.address,
      latitude: poi.latitude,
      longitude: poi.longitude,
      category: poi.category,
      rating: poi.rating,
      reviewCount: poi.reviewCount,
      distance: poi.distance,
      phone: poi.phone,
      openingHours: poi.openingHours,
      priceLevel: poi.priceLevel,
      photos: poi.photos,
      description: poi.description,
      isOpen: poi.isOpen,
      tags: poi.tags,
      nameEn: json['nameEn'],
      addressEn: json['addressEn'],
      descriptionEn: json['descriptionEn'],
      tagsEn: json['tagsEn'] != null ? List<String>.from(json['tagsEn']) : null,
      translationConfidence: json['translationConfidence']?.toDouble(),
      isTranslated: json['isTranslated'] ?? false,
      translationSource: json['translationSource'],
    );
  }

  /// 转换为JSON
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'nameEn': nameEn,
      'addressEn': addressEn,
      'descriptionEn': descriptionEn,
      'tagsEn': tagsEn,
      'translationConfidence': translationConfidence,
      'isTranslated': isTranslated,
      'translationSource': translationSource,
    });
    return json;
  }

  /// 复制并添加翻译
  TranslatedPOI copyWithTranslation({
    String? nameEn,
    String? addressEn,
    String? descriptionEn,
    List<String>? tagsEn,
    double? translationConfidence,
    String? translationSource,
  }) {
    return TranslatedPOI(
      id: id,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      category: category,
      rating: rating,
      reviewCount: reviewCount,
      distance: distance,
      phone: phone,
      openingHours: openingHours,
      priceLevel: priceLevel,
      photos: photos,
      description: description,
      isOpen: isOpen,
      tags: tags,
      nameEn: nameEn ?? this.nameEn,
      addressEn: addressEn ?? this.addressEn,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      tagsEn: tagsEn ?? this.tagsEn,
      translationConfidence: translationConfidence ?? this.translationConfidence,
      isTranslated: true,
      translationSource: translationSource ?? this.translationSource,
    );
  }

  /// 根据语言获取名称
  String getName(String language) {
    if (language == 'en' && nameEn != null) {
      return nameEn!;
    }
    return name;
  }

  /// 根据语言获取地址
  String getAddress(String language) {
    if (language == 'en' && addressEn != null) {
      return addressEn!;
    }
    return address;
  }

  /// 根据语言获取描述
  String? getDescription(String language) {
    if (language == 'en' && descriptionEn != null) {
      return descriptionEn;
    }
    return description;
  }

  /// 根据语言获取标签
  List<String>? getTags(String language) {
    if (language == 'en' && tagsEn != null) {
      return tagsEn;
    }
    return tags;
  }
}

/// POI类别翻译映射
class POICategoryTranslation {
  static const Map<POICategory, String> categoryToEnglish = {
    POICategory.attraction: 'Attraction',
    POICategory.restaurant: 'Restaurant',
    POICategory.hotel: 'Hotel',
    POICategory.shopping: 'Shopping',
    POICategory.transport: 'Transport',
    POICategory.hospital: 'Hospital',
    POICategory.bank: 'Bank',
    POICategory.cafe: 'Cafe',
    POICategory.bar: 'Bar',
    POICategory.park: 'Park',
    POICategory.museum: 'Museum',
    POICategory.temple: 'Temple',
    POICategory.emergency: 'Emergency',
    POICategory.other: 'Other',
  };

  static String getCategoryName(POICategory category, String language) {
    if (language == 'en') {
      return categoryToEnglish[category] ?? 'Other';
    }
    return category.label; // 返回中文
  }
}

/// 常见地点翻译字典
/// 针对6个支持城市的主要景点和地标
class CommonPlaceTranslations {
  static const Map<String, String> translations = {
    // ========== 北京 Beijing ==========
    // 景点
    '故宫博物院': 'Palace Museum',
    '天安门广场': 'Tiananmen Square',
    '长城': 'Great Wall',
    '八达岭长城': 'Badaling Great Wall',
    '慕田峪长城': 'Mutianyu Great Wall',
    '颐和园': 'Summer Palace',
    '天坛': 'Temple of Heaven',
    '北海公园': 'Beihai Park',
    '圆明园': 'Old Summer Palace',
    '鸟巢': "Bird's Nest",
    '水立方': 'Water Cube',
    '景山公园': 'Jingshan Park',
    '雍和宫': 'Lama Temple',
    '恭王府': 'Prince Gong Mansion',
    '南锣鼓巷': 'Nanluoguxiang',
    '什刹海': 'Shichahai',
    '798艺术区': '798 Art District',
    '国家博物馆': 'National Museum',
    '军事博物馆': 'Military Museum',
    // 餐饮
    '全聚德': 'Quanjude Roast Duck',
    '东来顺': 'Donglaishun',
    '护国寺小吃': 'Huguo Temple Snacks',
    // 购物
    '王府井': 'Wangfujing',
    '西单': 'Xidan',
    '三里屯': 'Sanlitun',
    '秀水街': 'Silk Street Market',
    // 交通
    '北京首都国际机场': 'Beijing Capital International Airport',
    '北京大兴国际机场': 'Beijing Daxing International Airport',
    '北京站': 'Beijing Railway Station',
    '北京西站': 'Beijing West Railway Station',
    '北京南站': 'Beijing South Railway Station',

    // ========== 上海 Shanghai ==========
    // 景点
    '外滩': 'The Bund',
    '东方明珠': 'Oriental Pearl Tower',
    '上海中心大厦': 'Shanghai Tower',
    '金茂大厦': 'Jin Mao Tower',
    '环球金融中心': 'World Financial Center',
    '豫园': 'Yu Garden',
    '南京路': 'Nanjing Road',
    '淮海路': 'Huaihai Road',
    '田子坊': 'Tianzifang',
    '新天地': 'Xintiandi',
    '城隍庙': 'City God Temple',
    '朱家角': 'Zhujiajiao Water Town',
    '上海迪士尼乐园': 'Shanghai Disneyland',
    '上海野生动物园': 'Shanghai Wild Animal Park',
    '上海海洋水族馆': 'Shanghai Ocean Aquarium',
    '上海博物馆': 'Shanghai Museum',
    '上海科技馆': 'Shanghai Science and Technology Museum',
    // 购物
    '南京东路': 'East Nanjing Road',
    '南京西路': 'West Nanjing Road',
    // 交通
    '上海浦东国际机场': 'Shanghai Pudong International Airport',
    '上海虹桥国际机场': 'Shanghai Hongqiao International Airport',
    '上海站': 'Shanghai Railway Station',
    '上海虹桥站': 'Shanghai Hongqiao Railway Station',

    // ========== 广州 Guangzhou ==========
    // 景点
    '广州塔': 'Canton Tower',
    '小蛮腰': 'Canton Tower',
    '越秀公园': 'Yuexiu Park',
    '白云山': 'Baiyun Mountain',
    '陈家祠': 'Chen Clan Ancestral Hall',
    '沙面': 'Shamian Island',
    '长隆野生动物世界': 'Chimelong Safari Park',
    '长隆欢乐世界': 'Chimelong Paradise',
    '珠江': 'Pearl River',
    '上下九步行街': 'Shangxiajiu Pedestrian Street',
    '北京路步行街': 'Beijing Road Pedestrian Street',
    // 餐饮
    '点都德': "Diandoude",
    '陶陶居': 'Taotaoju',
    '广州酒家': 'Guangzhou Restaurant',
    // 交通
    '广州白云国际机场': 'Guangzhou Baiyun International Airport',
    '广州站': 'Guangzhou Railway Station',
    '广州东站': 'Guangzhou East Railway Station',
    '广州南站': 'Guangzhou South Railway Station',

    // ========== 深圳 Shenzhen ==========
    // 景点
    '世界之窗': 'Window of the World',
    '欢乐谷': 'Happy Valley',
    '深圳湾公园': 'Shenzhen Bay Park',
    '莲花山公园': 'Lianhuashan Park',
    '东部华侨城': 'OCT East',
    '大梅沙': 'Dameisha Beach',
    '小梅沙': 'Xiaomeisha Beach',
    '深圳博物馆': 'Shenzhen Museum',
    '华强北': 'Huaqiangbei',
    '平安金融中心': 'Ping An Finance Centre',
    // 购物
    '东门': 'Dongmen',
    '华强北商业街': 'Huaqiangbei Commercial Street',
    '海岸城': 'Coastal City',
    // 交通
    '深圳宝安国际机场': 'Shenzhen Bao\'an International Airport',
    '深圳站': 'Shenzhen Railway Station',
    '深圳北站': 'Shenzhen North Railway Station',

    // ========== 成都 Chengdu ==========
    // 景点
    '武侯祠': 'Wuhou Temple',
    '锦里': 'Jinli Ancient Street',
    '宽窄巷子': 'Kuanzhai Alley',
    '杜甫草堂': 'Du Fu Thatched Cottage',
    '熊猫基地': 'Panda Base',
    '成都大熊猫繁育研究基地': 'Chengdu Research Base of Giant Panda Breeding',
    '青羊宫': 'Qingyang Palace',
    '文殊院': 'Wenshu Monastery',
    '春熙路': 'Chunxi Road',
    '太古里': 'Taikoo Li',
    '天府广场': 'Tianfu Square',
    '青城山': 'Mount Qingcheng',
    '都江堰': 'Dujiangyan Irrigation System',
    // 餐饮
    '大龙燚': 'Dalongyi Hotpot',
    '小龙坎': 'Xiaolongkan Hotpot',
    // 交通
    '成都双流国际机场': 'Chengdu Shuangliu International Airport',
    '成都天府国际机场': 'Chengdu Tianfu International Airport',
    '成都站': 'Chengdu Railway Station',
    '成都东站': 'Chengdu East Railway Station',

    // ========== 西安 Xi'an ==========
    // 景点
    '兵马俑': 'Terracotta Warriors',
    '秦始皇兵马俑博物馆': 'Museum of Qin Terracotta Warriors and Horses',
    '大雁塔': 'Big Wild Goose Pagoda',
    '小雁塔': 'Small Wild Goose Pagoda',
    '西安城墙': "Xi'an City Wall",
    '钟楼': 'Bell Tower',
    '鼓楼': 'Drum Tower',
    '回民街': 'Muslim Quarter',
    '华清池': 'Huaqing Pool',
    '华山': 'Mount Hua',
    '陕西历史博物馆': 'Shaanxi History Museum',
    '大唐芙蓉园': 'Tang Paradise',
    '大明宫': 'Daming Palace',
    // 交通
    '西安咸阳国际机场': "Xi'an Xianyang International Airport",
    '西安站': "Xi'an Railway Station",
    '西安北站': "Xi'an North Railway Station",

    // ========== 通用 ==========
    // 交通
    '地铁站': 'Metro Station',
    '火车站': 'Railway Station',
    '机场': 'Airport',
    '公交站': 'Bus Stop',
    '汽车站': 'Bus Terminal',
    '出租车': 'Taxi',

    // 餐饮
    '餐厅': 'Restaurant',
    '咖啡厅': 'Cafe',
    '快餐店': 'Fast Food',
    '茶馆': 'Tea House',
    '火锅': 'Hotpot',
    '烧烤': 'Barbecue',
    '小吃': 'Snacks',

    // 购物
    '商场': 'Shopping Mall',
    '超市': 'Supermarket',
    '便利店': 'Convenience Store',
    '百货': 'Department Store',

    // 服务
    '银行': 'Bank',
    '医院': 'Hospital',
    '药店': 'Pharmacy',
    '邮局': 'Post Office',
    '警察局': 'Police Station',
    '加油站': 'Gas Station',

    // 住宿
    '酒店': 'Hotel',
    '宾馆': 'Inn',
    '青年旅社': 'Hostel',
    '民宿': 'Guesthouse',

    // 方位
    '东': 'East',
    '南': 'South',
    '西': 'West',
    '北': 'North',
    '中': 'Central',
    '内': 'Inner',
    '外': 'Outer',
    '新': 'New',
    '老': 'Old',

    // 常用词
    '路': 'Road',
    '街': 'Street',
    '大道': 'Avenue',
    '巷': 'Alley',
    '胡同': 'Hutong',
    '广场': 'Square',
    '公园': 'Park',
    '大厦': 'Building',
    '中心': 'Center',
    '市场': 'Market',
    '步行街': 'Pedestrian Street',
    '商业街': 'Commercial Street',
    '古镇': 'Ancient Town',
    '博物馆': 'Museum',
    '美术馆': 'Art Museum',
    '图书馆': 'Library',
    '体育馆': 'Stadium',
    '剧院': 'Theater',
    '影院': 'Cinema',
    '景区': 'Scenic Area',
    '风景区': 'Scenic Spot',
  };

  /// 尝试从字典翻译
  static String? tryTranslate(String chinese) {
    // 完全匹配
    if (translations.containsKey(chinese)) {
      return translations[chinese];
    }

    // 部分匹配（包含关键词）
    for (var entry in translations.entries) {
      if (chinese.contains(entry.key)) {
        return chinese.replaceAll(entry.key, entry.value);
      }
    }

    return null;
  }
}
