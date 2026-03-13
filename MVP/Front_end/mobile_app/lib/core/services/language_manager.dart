import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/poi_translation.dart'; // for AppLanguage enum

/// 语言管理器
///
/// 管理应用的语言设置，支持 en/fr/es 三种语言
/// 注：APP面向外国用户，中文内容通过翻译蒙层提供
class LanguageManager extends ChangeNotifier {
  static final LanguageManager _instance = LanguageManager._internal();
  factory LanguageManager() => _instance;
  LanguageManager._internal();

  // 当前语言（默认英语）
  AppLanguage _currentLanguage = AppLanguage.english;

  // SharedPreferences实例
  SharedPreferences? _prefs;

  // 语言代码
  static const String languageKey = 'app_language';

  /// 初始化
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final savedLang = _prefs?.getString(languageKey) ?? 'en';
    _currentLanguage = _parseLanguage(savedLang);
    notifyListeners();
    print('✅ 语言管理器初始化: ${_currentLanguage.name}');
  }

  /// 获取当前语言
  AppLanguage get currentLanguage => _currentLanguage;

  /// 获取语言代码字符串（用于API调用）
  String get languageCode {
    switch (_currentLanguage) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.french:
        return 'fr';
      case AppLanguage.spanish:
        return 'es';
    }
  }

  /// 是否为英文
  bool get isEnglish => _currentLanguage == AppLanguage.english;

  /// 是否为法语
  bool get isFrench => _currentLanguage == AppLanguage.french;

  /// 是否为西班牙语
  bool get isSpanish => _currentLanguage == AppLanguage.spanish;

  /// 设置语言
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) {
      return;
    }

    _currentLanguage = language;

    // 保存到本地
    await _prefs?.setString(languageKey, languageCode);

    // 通知监听器
    notifyListeners();

    print('✅ 语言切换为: ${language.name}');
  }

  /// 循环切换语言（en → fr → es → en）
  Future<void> toggleLanguage() async {
    final newLanguage = switch (_currentLanguage) {
      AppLanguage.english => AppLanguage.french,
      AppLanguage.french => AppLanguage.spanish,
      AppLanguage.spanish => AppLanguage.english,
    };
    await setLanguage(newLanguage);
  }

  /// 获取语言显示名称
  String getLanguageDisplayName() {
    return switch (_currentLanguage) {
      AppLanguage.english => 'English',
      AppLanguage.french => 'Français',
      AppLanguage.spanish => 'Español',
    };
  }

  /// 获取下一个语言显示名称（用于切换按钮）
  String getNextLanguageDisplayName() {
    final nextLang = switch (_currentLanguage) {
      AppLanguage.english => AppLanguage.french,
      AppLanguage.french => AppLanguage.spanish,
      AppLanguage.spanish => AppLanguage.english,
    };
    return switch (nextLang) {
      AppLanguage.english => 'English',
      AppLanguage.french => 'Français',
      AppLanguage.spanish => 'Español',
    };
  }

  /// 根据当前语言返回文本
  String text(String english, {String? french, String? spanish}) {
    switch (_currentLanguage) {
      case AppLanguage.english:
        return english;
      case AppLanguage.french:
        return french ?? english; // fallback to English
      case AppLanguage.spanish:
        return spanish ?? english; // fallback to English
    }
  }

  /// 解析语言代码字符串
  AppLanguage _parseLanguage(String code) {
    switch (code) {
      case 'fr':
        return AppLanguage.french;
      case 'es':
        return AppLanguage.spanish;
      case 'en':
      default:
        return AppLanguage.english;
    }
  }
}

/// 静态文本翻译（三语支持：en/fr/es）
class AppTexts {
  static String _get(String en, {String? fr, String? es}) {
    return LanguageManager().text(en, french: fr, spanish: es);
  }

  // Map-related
  static String get mapTitle => _get('Map', fr: 'Carte', es: 'Mapa');
  static String get standardMap => _get('Standard Map', fr: 'Carte standard', es: 'Mapa estándar');
  static String get satelliteMap => _get('Satellite Map', fr: 'Carte satellite', es: 'Mapa satélite');
  static String get nightMap => _get('Night Mode', fr: 'Mode nuit', es: 'Modo nocturno');
  static String get traffic => _get('Traffic', fr: 'Trafic', es: 'Tráfico');
  static String get search => _get('Search', fr: 'Rechercher', es: 'Buscar');
  static String get myLocation => _get('My Location', fr: 'Ma position', es: 'Mi ubicación');
  static String get locating => _get('Locating...', fr: 'Localisation...', es: 'Localizando...');
  static String get locationFailed => _get('Location Failed', fr: 'Échec de localisation', es: 'Ubicación fallida');

  // POI-related
  static String get nearbyAttractions => _get('Nearby Attractions', fr: 'Attractions à proximité', es: 'Atracciones cercanas');
  static String get foodRecommendations => _get('Food Recommendations', fr: 'Recommandations culinaires', es: 'Recomendaciones gastronómicas');
  static String get routePlanning => _get('Route Planning', fr: 'Planification d\'itinéraire', es: 'Planificación de ruta');
  static String get openingHours => _get('Opening Hours', fr: 'Horaires d\'ouverture', es: 'Horario de apertura');
  static String get phoneNumber => _get('Phone', fr: 'Téléphone', es: 'Teléfono');
  static String get address => _get('Address', fr: 'Adresse', es: 'Dirección');
  static String get rating => _get('Rating', fr: 'Note', es: 'Calificación');
  static String get reviews => _get('Reviews', fr: 'Avis', es: 'Reseñas');

  // Common actions
  static String get ok => _get('OK', fr: 'OK', es: 'OK');
  static String get cancel => _get('Cancel', fr: 'Annuler', es: 'Cancelar');
  static String get close => _get('Close', fr: 'Fermer', es: 'Cerrar');
  static String get save => _get('Save', fr: 'Sauvegarder', es: 'Guardar');
  static String get delete => _get('Delete', fr: 'Supprimer', es: 'Eliminar');
  static String get edit => _get('Edit', fr: 'Modifier', es: 'Editar');
  static String get share => _get('Share', fr: 'Partager', es: 'Compartir');

  // Status messages
  static String get loading => _get('Loading...', fr: 'Chargement...', es: 'Cargando...');
  static String get noData => _get('No Data', fr: 'Aucune donnée', es: 'Sin datos');
  static String get error => _get('Error', fr: 'Erreur', es: 'Error');
  static String get success => _get('Success', fr: 'Succès', es: 'Éxito');
  static String get networkError => _get('Network Error', fr: 'Erreur réseau', es: 'Error de red');
  static String get retry => _get('Retry', fr: 'Réessayer', es: 'Reintentar');

  // Additional UI texts
  static String get details => _get('Details', fr: 'Détails', es: 'Detalles');
}
