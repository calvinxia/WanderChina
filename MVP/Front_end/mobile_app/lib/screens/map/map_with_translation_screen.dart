import 'package:flutter/material.dart';
import 'package:x_amap_base/x_amap_base.dart';
import '../../widgets/map/wander_map.dart';
import '../../widgets/map/translation_overlay_widget.dart';
import '../../models/poi_translation.dart';

/// 带翻译功能的地图页面示例
///
/// 展示如何使用WanderMap组件实现：
/// - 多语言地图标签翻译
/// - 实时语音翻译
/// - 自定义POI标记
class MapWithTranslationScreen extends StatefulWidget {
  final String? cityName;
  final LatLng? initialLocation;
  final AppLanguage language;

  const MapWithTranslationScreen({
    super.key,
    this.cityName,
    this.initialLocation,
    this.language = AppLanguage.english,
  });

  @override
  State<MapWithTranslationScreen> createState() => _MapWithTranslationScreenState();
}

class _MapWithTranslationScreenState extends State<MapWithTranslationScreen> {
  final GlobalKey<WanderMapState> _mapKey = GlobalKey<WanderMapState>();

  late AppLanguage _currentLanguage;
  LabelStyle _currentLabelStyle = LabelStyle.badge;
  bool _showTranslationOverlay = true;
  bool _showVoiceButton = true;

  // 预设城市坐标
  static const Map<String, LatLng> _cityCoordinates = {
    '北京': LatLng(39.9042, 116.4074),  // 天安门
    '上海': LatLng(31.2304, 121.4737),  // 外滩
    '广州': LatLng(23.1291, 113.2644),  // 广州塔
    '深圳': LatLng(22.5431, 114.0579),  // 市民中心
    '成都': LatLng(30.6598, 104.0633),  // 天府广场
    '西安': LatLng(34.2655, 108.9541),  // 钟楼
  };

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.language;
  }

  LatLng get _initialCenter {
    if (widget.initialLocation != null) {
      return widget.initialLocation!;
    }
    if (widget.cityName != null && _cityCoordinates.containsKey(widget.cityName)) {
      return _cityCoordinates[widget.cityName]!;
    }
    return _cityCoordinates['北京']!; // 默认北京
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cityName ?? "地图"} - ${_getLanguageName(_currentLanguage)}'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          // 语言切换
          PopupMenuButton<AppLanguage>(
            icon: const Icon(Icons.language),
            tooltip: 'Change Language',
            onSelected: (language) {
              setState(() => _currentLanguage = language);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: AppLanguage.english,
                child: Row(
                  children: [
                    Text('🇬🇧', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text('English'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: AppLanguage.french,
                child: Row(
                  children: [
                    Text('🇫🇷', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text('Français'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: AppLanguage.spanish,
                child: Row(
                  children: [
                    Text('🇪🇸', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text('Español'),
                  ],
                ),
              ),
            ],
          ),

          // 标签样式切换
          PopupMenuButton<LabelStyle>(
            icon: const Icon(Icons.style),
            tooltip: 'Label Style',
            onSelected: (style) {
              setState(() => _currentLabelStyle = style);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: LabelStyle.badge,
                child: Row(
                  children: [
                    Icon(Icons.label, size: 20),
                    SizedBox(width: 8),
                    Text('Badge Style'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: LabelStyle.minimal,
                child: Row(
                  children: [
                    Icon(Icons.text_fields, size: 20),
                    SizedBox(width: 8),
                    Text('Minimal Style'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: LabelStyle.floating,
                child: Row(
                  children: [
                    Icon(Icons.card_travel, size: 20),
                    SizedBox(width: 8),
                    Text('Floating Style'),
                  ],
                ),
              ),
            ],
          ),

          // 设置
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),

      body: WanderMap(
        key: _mapKey,
        initialCenter: _initialCenter,
        initialZoom: 15.0,
        language: _currentLanguage,
        labelStyle: _currentLabelStyle,
        showTranslationOverlay: _showTranslationOverlay,
        showVoiceButton: _showVoiceButton,
        onMapTap: (latLng) {
          debugPrint('地图点击: ${latLng.latitude}, ${latLng.longitude}');
        },
      ),

      // 底部城市快速切换
      bottomNavigationBar: _buildCitySelector(),

      // 浮动操作按钮
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 回到当前城市中心
          FloatingActionButton.small(
            heroTag: 'recenter',
            onPressed: () {
              _mapKey.currentState?.moveTo(_initialCenter, zoom: 15.0);
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Color(0xFFFF6B35)),
          ),
          const SizedBox(height: 8),

          // 清除搜索标记
          FloatingActionButton.small(
            heroTag: 'clear',
            onPressed: () {
              _mapKey.currentState?.clearSearchMarkers();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cleared search markers'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.clear_all, color: Color(0xFFFF6B35)),
          ),
        ],
      ),
    );
  }

  Widget _buildCitySelector() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: _cityCoordinates.entries.map((entry) {
          final isSelected = widget.cityName == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.key),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _mapKey.currentState?.moveTo(entry.value, zoom: 15.0);
                }
              },
              selectedColor: const Color(0xFFFF6B35),
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Translation Overlay'),
              subtitle: const Text('Show translated labels on map'),
              value: _showTranslationOverlay,
              onChanged: (value) {
                setState(() => _showTranslationOverlay = value);
                Navigator.pop(context);
              },
              activeColor: const Color(0xFFFF6B35),
            ),
            SwitchListTile(
              title: const Text('Voice Translation'),
              subtitle: const Text('Show voice translation button'),
              value: _showVoiceButton,
              onChanged: (value) {
                setState(() => _showVoiceButton = value);
                Navigator.pop(context);
              },
              activeColor: const Color(0xFFFF6B35),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.french:
        return 'Français';
      case AppLanguage.spanish:
        return 'Español';
    }
  }
}
