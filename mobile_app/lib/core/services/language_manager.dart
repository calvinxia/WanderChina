import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言管理器
///
/// 管理应用的语言设置，支持中英文切换
class LanguageManager extends ChangeNotifier {
  static final LanguageManager _instance = LanguageManager._internal();
  factory LanguageManager() => _instance;
  LanguageManager._internal();

  // 当前语言
  String _currentLanguage = 'zh'; // zh: 中文, en: 英文

  // SharedPreferences实例
  SharedPreferences? _prefs;

  // 语言代码
  static const String languageKey = 'app_language';

  /// 初始化
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentLanguage = _prefs?.getString(languageKey) ?? 'zh';
    notifyListeners();
    print('✅ 语言管理器初始化: $_currentLanguage');
  }

  /// 获取当前语言
  String get currentLanguage => _currentLanguage;

  /// 是否为英文
  bool get isEnglish => _currentLanguage == 'en';

  /// 是否为中文
  bool get isChinese => _currentLanguage == 'zh';

  /// 设置语言
  Future<void> setLanguage(String language) async {
    if (language != 'zh' && language != 'en') {
      print('⚠️ 不支持的语言: $language');
      return;
    }

    if (_currentLanguage == language) {
      return;
    }

    _currentLanguage = language;

    // 保存到本地
    await _prefs?.setString(languageKey, language);

    // 通知监听器
    notifyListeners();

    print('✅ 语言切换为: $language');
  }

  /// 切换语言（中英文）
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLanguage == 'zh' ? 'en' : 'zh';
    await setLanguage(newLanguage);
  }

  /// 获取语言显示名称
  String getLanguageDisplayName() {
    return _currentLanguage == 'zh' ? '中文' : 'English';
  }

  /// 获取对方语言显示名称（用于切换按钮）
  String getOtherLanguageDisplayName() {
    return _currentLanguage == 'zh' ? 'English' : '中文';
  }

  /// 根据当前语言返回文本
  String text(String chinese, String english) {
    return _currentLanguage == 'en' ? english : chinese;
  }
}

/// 静态文本翻译
class AppTexts {
  static String get(String chinese, String english) {
    return LanguageManager().text(chinese, english);
  }

  // 地图相关
  static String get mapTitle => get('地图', 'Map');
  static String get standardMap => get('标准地图', 'Standard Map');
  static String get satelliteMap => get('卫星地图', 'Satellite Map');
  static String get nightMap => get('夜间模式', 'Night Mode');
  static String get traffic => get('交通', 'Traffic');
  static String get search => get('搜索', 'Search');
  static String get myLocation => get('我的位置', 'My Location');
  static String get locating => get('定位中...', 'Locating...');
  static String get locationFailed => get('定位失败', 'Location Failed');

  // POI相关
  static String get nearbyAttractions => get('附近景点', 'Nearby Attractions');
  static String get foodRecommendations => get('美食推荐', 'Food Recommendations');
  static String get routePlanning => get('路线规划', 'Route Planning');
  static String get openingHours => get('营业时间', 'Opening Hours');
  static String get phoneNumber => get('电话', 'Phone');
  static String get address => get('地址', 'Address');
  static String get rating => get('评分', 'Rating');
  static String get reviews => get('评论', 'Reviews');

  // 常用操作
  static String get ok => get('确定', 'OK');
  static String get cancel => get('取消', 'Cancel');
  static String get close => get('关闭', 'Close');
  static String get save => get('保存', 'Save');
  static String get delete => get('删除', 'Delete');
  static String get edit => get('编辑', 'Edit');
  static String get share => get('分享', 'Share');

  // 提示信息
  static String get loading => get('加载中...', 'Loading...');
  static String get noData => get('暂无数据', 'No Data');
  static String get error => get('错误', 'Error');
  static String get success => get('成功', 'Success');
  static String get networkError => get('网络错误', 'Network Error');
  static String get retry => get('重试', 'Retry');
}
