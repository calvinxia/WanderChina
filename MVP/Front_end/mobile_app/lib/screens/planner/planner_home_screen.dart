import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/api_client.dart';
import '../../services/backend/auth_service.dart';
import '../../services/analytics_service.dart';
import '../../core/config/backend_config.dart';
import '../../models/itinerary.dart';
import 'itinerary_detail_screen.dart';
import '../../core/theme/city_theme.dart';
import '../main/main_screen.dart';
import '../../widgets/planner/willingness_survey_dialog.dart';
import '../../utils/quota_helper.dart';
import '../../services/itinerary_stream_service.dart';
import '../../widgets/soft_login_sheet.dart';
import '../../services/app_event_bus.dart';

/// Screen 9: AI Trip Planner Home
///
/// 规范来自 SCREEN_SPECIFICATIONS_v2.md
/// - 6个城市选择（北京/上海/广州/深圳/成都/西安）
/// - 1-5天行程选择
/// - 兴趣标签选择（Culture, Food, Nature等）
/// - 自由文本输入
/// - DeepSeek驱动的AI生成
class PlannerHomeScreen extends StatefulWidget {
  const PlannerHomeScreen({super.key});

  @override
  State<PlannerHomeScreen> createState() => _PlannerHomeScreenState();
}

class _PlannerHomeScreenState extends State<PlannerHomeScreen> {
  final _analytics = AnalyticsService.instance;
  String? _selectedCity;
  int _selectedDays = 3;
  final Set<String> _selectedInterests = {};
  final TextEditingController _customInput = TextEditingController();
  List<Map<String, dynamic>> _savedTrips = [];
  bool _isLoadingTrips = true;
  CityTheme? _plannerTheme;

  // Loading animation state
  bool _isGenerating = false;
  String _loadingText = 'Finding best attractions...';
  String _funFact = '';
  int _loadingStep = 0;
  Timer? _loadingTimer;
  StreamSubscription? _loginSub;
  Map<String, dynamic>? _streamingItinerary;
  bool _isStreaming = false;

  /// Get active theme: use selected city theme if available, otherwise fallback to GPS city theme
  CityTheme get _activeTheme {
    if (_plannerTheme != null) return _plannerTheme!;
    final mainState = context.findAncestorStateOfType<MainScreenState>();
    return mainState?.cityTheme ?? CityTheme.defaultTheme;
  }

  final List<Map<String, String>> _cities = [
    {'zh': '北京', 'en': 'BJ', 'fullName': 'Beijing'},
    {'zh': '上海', 'en': 'SH', 'fullName': 'Shanghai'},
    {'zh': '广州', 'en': 'GZ', 'fullName': 'Guangzhou'},
    {'zh': '深圳', 'en': 'SZ', 'fullName': 'Shenzhen'},
    {'zh': '成都', 'en': 'CD', 'fullName': 'Chengdu'},
    {'zh': '西安', 'en': 'XA', 'fullName': 'Xian'},
  ];

  final List<String> _interests = [
    'Culture',
    'Food',
    'Nature',
    'Shopping',
    'Nightlife',
    'History',
  ];

  // Fun facts for each city (4 facts per city)
  final Map<String, List<String>> _cityFunFacts = {
    '北京': [
      'Beijing has over 3,000 years of history and was the capital of 6 dynasties',
      'The Forbidden City has 9,999 rooms - just one short of heaven\'s 10,000',
      'Beijing\'s subway system is the world\'s 2nd busiest with 4 billion rides per year',
      'Peking Duck was originally a royal dish served only to emperors',
    ],
    '上海': [
      'Shanghai means "upon the sea" and was once a fishing village',
      'The Bund features 52 buildings in different architectural styles',
      'Shanghai Tower (632m) is the world\'s 2nd tallest building',
      'Shanghai Disneyland is the first Disney park in mainland China',
    ],
    '广州': [
      'Guangzhou has been a trading port for over 2,200 years',
      'Dim sum originated in Guangzhou tea houses along the Silk Road',
      'Canton Tower (600m) offers the world\'s highest Ferris wheel',
      'Guangzhou has more than 150 traditional markets',
    ],
    '深圳': [
      'Shenzhen transformed from a fishing village to a megacity in just 40 years',
      'Shenzhen is called "China\'s Silicon Valley" with Tencent and Huawei HQs',
      'Window of the World park features 130 world landmarks in miniature',
      'Shenzhen has over 1,000 parks - more than any other Chinese city',
    ],
    '成都': [
      'Chengdu is home to over 80% of the world\'s wild giant pandas',
      'Sichuan cuisine has over 5,000 different dishes and 23 unique flavors',
      'Chengdu was the world\'s first city to use paper money (11th century)',
      'The city has over 30,000 teahouses - more than any other city globally',
    ],
    '西安': [
      'Xi\'an was China\'s capital for 13 dynasties spanning 1,100 years',
      'The Terracotta Army has 8,000 soldiers, each with unique facial features',
      'Xi\'an marks the starting point of the ancient Silk Road',
      'The city walls are the most complete ancient fortification in China',
    ],
  };

  // Loading step messages (6 stages)
  final List<String> _loadingSteps = [
    'Analyzing your preferences...',
    'Finding best attractions...',
    'Planning optimal routes...',
    'Calculating travel times...',
    'Adding local recommendations...',
    'Finalizing your itinerary...',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedTrips();
    _loginSub = AppEventBus.instance.on<LoginStatusChangedEvent>().listen((_) {
      if (mounted) {
        _loadSavedTrips();
        setState(() {});
      }
    });
  }

  Future<void> _loadSavedTrips() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        setState(() => _isLoadingTrips = false);
        return;
      }
      final result = await ApiClient.post(BackendConfig.tripUrl, {
        'action': 'list',
        'user_id': userId,
      });
      final trips = result['trips'] as List? ?? [];

      // 成功后缓存到本地
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_trips_${userId}', json.encode(trips));

      if (mounted) {
        setState(() {
          _savedTrips = List<Map<String, dynamic>>.from(trips);
          _isLoadingTrips = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load trips error: $e');
      // 网络失败 → 读本地缓存
      final userId = AuthService.currentUserId;
      final prefs = await SharedPreferences.getInstance();
      final cached = userId != null ? prefs.getString('cached_trips_${userId}') : null;
      if (cached != null && mounted) {
        final trips = json.decode(cached) as List;
        setState(() {
          _savedTrips = List<Map<String, dynamic>>.from(trips);
          _isLoadingTrips = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingTrips = false);
      }
      if (mounted && (e is SocketException || e.toString().contains('host lookup'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(cached != null
              ? 'Offline mode. Showing cached trips.'
              : 'Could not load saved trips. Check your connection.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _customInput.dispose();
    _loadingTimer?.cancel();
    _loginSub?.cancel();
    super.dispose();
  }

  void _startLoadingAnimation() {
    setState(() {
      _isGenerating = true;
      _loadingStep = 0;
      _loadingText = 'Finding best attractions...';
      final cityFacts = _cityFunFacts[_selectedCity] ?? _cityFunFacts['北京']!;
      _funFact = cityFacts[0];
      _streamingItinerary = null;
      _isStreaming = false;
    });

    _loadingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _loadingStep = (_loadingStep + 1) % _loadingSteps.length;

        // Cycle through fun facts
        final cityFacts = _cityFunFacts[_selectedCity] ?? _cityFunFacts['北京']!;
        final factIndex = (timer.tick - 1) % cityFacts.length;
        _funFact = cityFacts[factIndex];
      });
    });
  }

  void _stopLoadingAnimation() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
    if (mounted) {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Plan Your Trip'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.gray900,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                // Show help dialog
              },
            ),
          ],
        ),
      body: _isGenerating
          ? _buildGeneratingView()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // City Selection
            Text(
              'Which city?',
              style: AppTextStyles.h4(color: AppColors.gray900),
            ),
            const SizedBox(height: 12),
            _buildCityGrid(),

            const SizedBox(height: 32),

            // Days Selection
            Text(
              'How many days?',
              style: AppTextStyles.h4(color: AppColors.gray900),
            ),
            const SizedBox(height: 12),
            _buildDaySelector(),

            const SizedBox(height: 32),

            // Interests Selection
            Text(
              "What's your focus?",
              style: AppTextStyles.h4(color: AppColors.gray900),
            ),
            const SizedBox(height: 12),
            _buildInterestTags(),

            const SizedBox(height: 32),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.gray300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Or describe in your words',
                    style: AppTextStyles.caption(color: _activeTheme.primaryTextColor.withOpacity(0.6)),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.gray300)),
              ],
            ),

            const SizedBox(height: 16),

            // Custom Input
            TextField(
              controller: _customInput,
              maxLength: 200,
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.25),
                hintText: 'e.g. "3 days in Chengdu, love pandas and spicy food, budget traveller"',
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: _activeTheme.primaryTextColor.withOpacity(0.4),
                ),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _activeTheme.pillActiveColor),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _canGenerate()
                    ? () {
                        FocusScope.of(context).unfocus();
                        _generatePlan();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _activeTheme.pillActiveColor,
                  disabledBackgroundColor: _activeTheme.pillActiveColor.withOpacity(0.3),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: _activeTheme.primaryTextColor.withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '✨',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Generate Plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Saved Trips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Saved Trips (${_savedTrips.length})',
                  style: AppTextStyles.h4(color: AppColors.gray900),
                ),
                if (_savedTrips.length > 3)
                  TextButton(
                    onPressed: () {
                      // MVP: 滚动到列表或 SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Showing all trips below')),
                      );
                    },
                    child: Text('View All', style: AppTextStyles.body(color: _activeTheme.pillActiveColor)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingTrips)
              const Center(child: CircularProgressIndicator())
            else if (_savedTrips.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No saved trips yet. Generate your first plan!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ...(_savedTrips.take(5).map((trip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSavedTripCard(
                  city: (trip['cities'] as List?)?.join(', ') ?? '',
                  days: '${trip['duration_days'] ?? 0} days',
                  focus: trip['title'] ?? '',
                  date: _formatDate(trip['created_at']),
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Trip'),
                        content: Text('Delete "${trip['title'] ?? 'this trip'}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel',
                              style: TextStyle(color: _activeTheme.pillActiveColor)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Delete',
                              style: TextStyle(color: _activeTheme.pillActiveColor)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !mounted) return;
                    try {
                      await ApiClient.post(ApiClient.tripUrl, {
                        'action': 'delete',
                        'trip_id': trip['trip_id'],
                        'user_id': AuthService.currentUserId,
                      });
                      setState(() {
                        _savedTrips.removeWhere((t) => t['trip_id'] == trip['trip_id']);
                      });
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete trip: $e')),
                        );
                      }
                    }
                  },
                  onTap: () async {
                    final tripId = trip['trip_id'] as String?;
                    try {
                      // 先从后端拉取完整行程数据
                      debugPrint('📋 Loading trip: $tripId');
                      final detail = await ApiClient.post(BackendConfig.tripUrl, {
                        'action': 'get',
                        'trip_id': tripId,
                      });

                      debugPrint('📋 Trip detail response keys: ${detail.keys.toList()}');
                      debugPrint('📋 Trip detail response: $detail');

                      // 成功后缓存到本地
                      if (tripId != null) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('cached_trip_$tripId', json.encode(detail));
                      }

                      // 尝试多个可能的字段名（itinerary_json 是数据库列名，itinerary/days 是可能的返回字段）
                      final itineraryJson = detail['itinerary_json'] ?? detail['itinerary'] ?? detail['days'];

                      if (itineraryJson != null && mounted) {
                        // 支持 JSON 字符串或对象两种格式
                        final itineraryData = itineraryJson is String
                            ? json.decode(itineraryJson)
                            : itineraryJson;

                        // 详细检查数据类型
                        debugPrint('📋 itineraryData type: ${itineraryData.runtimeType}');
                        if (itineraryData is Map && itineraryData.containsKey('days')) {
                          debugPrint('📋 days type: ${itineraryData['days'].runtimeType}');
                          if (itineraryData['days'] is List && (itineraryData['days'] as List).isNotEmpty) {
                            debugPrint('📋 day[0] type: ${itineraryData['days'][0].runtimeType}');
                            final firstDay = itineraryData['days'][0];
                            if (firstDay is Map && firstDay.containsKey('activities')) {
                              debugPrint('📋 day[0] activities type: ${firstDay['activities'].runtimeType}');
                              if (firstDay['activities'] is List && (firstDay['activities'] as List).isNotEmpty) {
                                debugPrint('📋 day[0] activity[0] type: ${firstDay['activities'][0].runtimeType}');
                              }
                            }
                          }
                        }

                        final itinerary = Itinerary.fromCloudData({
                          'days': itineraryData,  // itineraryData 本身就是 days 数组
                          'title': detail['title'],
                          'cities': detail['cities'],
                          'duration_days': detail['duration_days'],
                          'interests': detail['interests'],
                          'trip_id': detail['trip_id'],
                          'status': detail['status'],
                        });

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItineraryDetailScreen(
                              itinerary: itinerary,
                              tripId: tripId,
                            ),
                          ),
                        );
                        _loadSavedTrips();
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Trip itinerary data not available'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    } catch (e, stackTrace) {
                      debugPrint('❌ Load trip detail error: $e');
                      debugPrint('❌ Stack trace: $stackTrace');

                      // 网络失败 → 读本地缓存
                      if (tripId != null) {
                        final prefs = await SharedPreferences.getInstance();
                        final cached = prefs.getString('cached_trip_$tripId');
                        if (cached != null && mounted) {
                          final detail = json.decode(cached) as Map<String, dynamic>;
                          final itineraryJson = detail['itinerary_json'] ?? detail['itinerary'] ?? detail['days'];
                          if (itineraryJson != null) {
                            final itineraryData = itineraryJson is String
                                ? json.decode(itineraryJson)
                                : itineraryJson;
                            final itinerary = Itinerary.fromCloudData({
                              'days': itineraryData,
                              'title': detail['title'],
                              'cities': detail['cities'],
                              'duration_days': detail['duration_days'],
                              'interests': detail['interests'],
                              'trip_id': detail['trip_id'],
                              'status': detail['status'],
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Offline mode. Showing cached trip.')),
                            );
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ItineraryDetailScreen(
                                  itinerary: itinerary,
                                  tripId: tripId,
                                ),
                              ),
                            );
                            return;
                          }
                        }
                      }

                      // 无缓存 → 友好提示
                      if (mounted) {
                        final message = (e is SocketException || e.toString().contains('host lookup'))
                            ? 'No internet connection. Please check your network and try again.'
                            : 'Something went wrong. Please try again.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      }
                    }
                  },
                ),
              ))),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCityGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _cities.length,
      itemBuilder: (context, index) {
        final city = _cities[index];
        final blockTheme = CityTheme.fromCityKey(city['en'] as String);
        final isSelected = _selectedCity == city['zh'];

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedCity == city['zh']) {
                // 再次点击 → 取消选择 → 恢复当前定位城市主题
                _selectedCity = null;
                _plannerTheme = null;  // null 时 _activeTheme 自动 fallback 到 GPS 城市
                // 通知 MainScreen 恢复 GPS 主题
                final mainState = context.findAncestorStateOfType<MainScreenState>();
                mainState?.loadCityTheme();  // 重新用 GPS 定位
              } else {
                // 选择新城市
                _selectedCity = city['zh'];
                _plannerTheme = CityTheme.fromCityKey(city['en'] as String);
                // 通知 MainScreen 切换背景
                final mainState = context.findAncestorStateOfType<MainScreenState>();
                mainState?.updateCityTheme(_plannerTheme!);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? blockTheme.pillActiveColor.withOpacity(0.2)
                  : Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? blockTheme.pillActiveColor
                    : blockTheme.pillActiveColor.withOpacity(0.3),
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  city['zh']!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: blockTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  city['en']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: blockTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDaySelector() {
    return Row(
      children: List.generate(7, (index) {
        final day = index + 1;
        final isSelected = _selectedDays == day;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 6 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDays = day;
                });
              },
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _activeTheme.pillActiveColor
                      : Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? _activeTheme.pillActiveColor
                        : Colors.white.withOpacity(0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _activeTheme.primaryTextColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInterestTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _interests.map((interest) {
        final isSelected = _selectedInterests.contains(interest);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedInterests.remove(interest);
              } else {
                _selectedInterests.add(interest);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                  color: isSelected ? _activeTheme.pillActiveColor : AppColors.gray400,
                ),
                const SizedBox(width: 6),
                Text(
                  interest,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? _activeTheme.pillActiveColor : _activeTheme.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSavedTripCard({
    required String city,
    required String days,
    required String focus,
    required String date,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    // Get theme based on trip city
    final tripCity = city.split(',').first.trim(); // Extract first city if multiple
    final tripTheme = CityTheme.fromCityKey(_getCityKey(tripCity));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tripTheme.pillActiveColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                color: tripTheme.pillActiveColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 直接用 title，不再拼接
                  Text(
                    focus.isNotEmpty ? focus : 'My Trip',
                    style: AppTextStyles.body(color: AppColors.gray900)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: AppTextStyles.caption(color: AppColors.gray600),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.gray400, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDelete,
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  bool _canGenerate() {
    return _selectedCity != null &&
        (_selectedInterests.isNotEmpty || _customInput.text.trim().isNotEmpty);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr.split(' ').first;  // fallback: 只取日期部分
    }
  }

  String _getCityKey(String cityName) {
    if (cityName.contains('Beijing') || cityName.contains('北京')) return 'BJ';
    if (cityName.contains('Shanghai') || cityName.contains('上海')) return 'SH';
    if (cityName.contains('Guangzhou') || cityName.contains('广州')) return 'GZ';
    if (cityName.contains('Shenzhen') || cityName.contains('深圳')) return 'SZ';
    if (cityName.contains('Chengdu') || cityName.contains('成都')) return 'CD';
    if (cityName.contains("Xi'an") || cityName.contains('西安')) return 'XA';
    return 'GZ'; // Default to Guangzhou
  }

  Future<void> _generatePlan() async {
    // 软登录检查：匿名用户弹注册引导
    if (!await requireLogin(context, 'itinerary_generate', theme: _activeTheme)) return;
    // Quota check (Phase 2)
    if (!await requireQuotaCheck(
      context,
      'itinerary',
      _activeTheme,
      userId: AuthService.currentUserId,
    )) return;

    // Start loading animation
    _startLoadingAnimation();

    try {
      final selectedCityMap = _cities.firstWhere(
        (city) => city['zh'] == _selectedCity,
        orElse: () => {'zh': '', 'en': '', 'fullName': 'Beijing'},
      );
      final cityEnglishName = selectedCityMap['fullName']!;

      Map<String, dynamic>? finalData;

      // 流式生成
      await for (final event in ItineraryStreamService.generateStream(
        cities: [cityEnglishName],
        days: _selectedDays,
        interests: _selectedInterests.toList(),
        language: 'english',
      )) {
        switch (event['event']) {
          case 'partial':
            final dayCount = (event['data'] as Map)['days']?.length ?? 0;
            if (mounted) setState(() {
              _loadingText = 'Planning Day $dayCount of $_selectedDays...';
              _streamingItinerary = event['data'] as Map<String, dynamic>;
              _isStreaming = true;
            });
            debugPrint('📡 Partial: $dayCount days');
            break;
          case 'complete':
            if (mounted) setState(() {
              _isStreaming = false;
              _streamingItinerary = null;
            });
            finalData = event['data'] as Map<String, dynamic>;
            debugPrint('✅ Stream complete: ${finalData['title']}');
            break;
          case 'error':
            throw Exception(event['message'] ?? 'Generation failed');
        }
      }

      if (finalData == null) throw Exception('No complete event received');
      if (!mounted) return;

      final itineraryJson = finalData['itinerary'];
      final title = finalData['title'] ?? 'My Trip';

      // 自动保存到 DB（保存失败则 fallback 到预览模式）
      String? savedTripId;
      try {
        debugPrint('💾 Auto-saving trip to DB...');
        final saveResult = await ApiClient.post(
          ApiClient.tripUrl,
          {
            'action': 'create',
            'user_id': AuthService.currentUserId,
            'title': title,
            'cities': [cityEnglishName],
            'duration_days': _selectedDays,
            'interests': _selectedInterests.toList(),
            'itinerary': itineraryJson,
            'description': null,
          },
          timeout: const Duration(seconds: 10),
        );
        savedTripId = saveResult['trip_id'] as String?;
        debugPrint('💾 Trip saved: $savedTripId');
      } catch (saveError) {
        // 保存失败 → 不阻塞用户，fallback 到预览模式（tripId: null）
        // 用户可在详情页手动点 Save
        debugPrint('⚠️ Auto-save failed, falling back to preview mode: $saveError');
        Sentry.captureException(saveError);
      }

      if (!mounted) return;
      _stopLoadingAnimation();

      // 解析 Itinerary model
      final itinerary = Itinerary.fromCloudData({
        ...itineraryJson,
        'title': title,
        'cities': [cityEnglishName],
        'totalDays': _selectedDays,
        'interests': _selectedInterests.toList(),
      });

      // Analytics tracking
      _analytics.itineraryGenerated(
        cityEnglishName,
        _selectedDays,
        _selectedInterests.toList(),
      );

      // 跳转详情页
      // savedTripId != null → 已保存，详情页无 Save 按钮
      // savedTripId == null → 保存失败 fallback 到预览模式，用户可手动 Save
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ItineraryDetailScreen(
            itinerary: itinerary,
            tripId: savedTripId,  // null = 预览模式（保存失败时的 fallback）
            cities: [cityEnglishName],
            days: _selectedDays,
            interests: _selectedInterests.toList(),
          ),
        ),
      );

      // 付费意愿调研
      if (mounted) {
        await _checkAndShowSurvey();
      }

      // 刷新已保存行程列表
      _loadSavedTrips();

    } catch (e, stackTrace) {
      debugPrint('🗺️ generate_plan error: $e');
      if (!mounted) return;
      _stopLoadingAnimation();

      final message = (e is SocketException || e.toString().contains('host lookup'))
          ? 'No internet connection. Please check your network and try again.'
          : 'Something went wrong. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
      );

      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// 检查是否应弹出付费意愿调研，并在满足条件时弹出
  Future<void> _checkAndShowSurvey() async {
    final prefs = await SharedPreferences.getInstance();

    // 已弹过，不再弹
    final surveyed = prefs.getBool('wtp_survey_shown') ?? false;
    if (surveyed) return;

    // 递增生成计数
    final count = (prefs.getInt('itinerary_generate_count') ?? 0) + 1;
    await prefs.setInt('itinerary_generate_count', count);

    // 第 2 次生成后弹出
    if (count < 2) return;

    // 标记已弹出（无论用户是否回答）
    await prefs.setBool('wtp_survey_shown', true);

    if (!mounted) return;

    // 获取当前城市主题
    final mainState = context.findAncestorStateOfType<MainScreenState>();
    final cityTheme = mainState?.cityTheme ?? CityTheme.defaultTheme;

    // 延迟 500ms 让页面过渡完成后再弹
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillingnessSurveyDialog(
        theme: cityTheme,
        onResponse: (response) {
          Navigator.of(ctx).pop();
          _recordSurveyResponse(response);
        },
      ),
    );
  }

  /// 记录调研结果 — 本地 + Sentry
  void _recordSurveyResponse(String response) async {
    // 1. 本地存储（备份）
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wtp_survey_response', response);

    // 2. Sentry 上报
    Sentry.captureMessage(
      'WTP Survey: $response',
      level: SentryLevel.info,
      withScope: (scope) {
        scope.setTag('survey_type', 'wtp');
        scope.setTag('survey_response', response);
      },
    );

    // 3. 控制台输出
    debugPrint('💰 [WTP Survey] User responded: $response');
  }

  Widget _buildGeneratingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '✨ Creating your perfect itinerary...',
            style: AppTextStyles.h3(color: AppColors.gray900),
          ),
          const SizedBox(height: 8),
          Text(
            'This usually takes 10-30 seconds',
            style: AppTextStyles.bodySmall(color: AppColors.gray600),
          ),

          const SizedBox(height: 24),

          // Progress bar
          LinearProgressIndicator(
            backgroundColor: _activeTheme.pillActiveColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(_activeTheme.pillActiveColor),
          ),

          const SizedBox(height: 16),

          // Loading message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _loadingText,
              key: ValueKey<String>(_loadingText),
              style: AppTextStyles.body(color: _activeTheme.pillActiveColor)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 32),

          // Fun fact card — fades out when first real card arrives
          AnimatedOpacity(
            opacity: _isStreaming ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Container(
                key: ValueKey<String>(_funFact),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _activeTheme.pillActiveColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _activeTheme.pillActiveColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: _activeTheme.pillActiveColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Did you know?',
                            style: AppTextStyles.caption(
                              color: _activeTheme.pillActiveColor,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _funFact,
                            style: AppTextStyles.bodySmall(color: AppColors.gray700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Real day cards (streaming) or skeleton cards
          Text(
            'Preview',
            style: AppTextStyles.h4(color: AppColors.gray900),
          ),
          const SizedBox(height: 12),
          if (_isStreaming && _streamingItinerary != null) ...[
            ...(_streamingItinerary!['days'] as List).map((day) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildStreamingDayCard(day as Map<String, dynamic>),
            )),
            ...List.generate(
              (_selectedDays - (_streamingItinerary!['days'] as List).length).clamp(0, _selectedDays),
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSkeletonActivityCard(),
              ),
            ),
          ] else ...[
            ...[1, 2, 3].map((_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSkeletonActivityCard(),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildStreamingDayCard(Map<String, dynamic> day) {
    final activities = (day['activities'] as List?) ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _activeTheme.pillActiveColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _activeTheme.pillActiveColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Day ${day['day_number']} · ${day['title'] ?? ''}',
            style: AppTextStyles.bodySmall(color: _activeTheme.pillActiveColor)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          if (activities.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...activities.take(3).map((act) {
              final activity = act as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      activity['time'] ?? '',
                      style: AppTextStyles.caption(color: AppColors.gray600),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activity['name'] ?? '',
                        style: AppTextStyles.caption(color: AppColors.gray900),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeletonActivityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _activeTheme.pillActiveColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _activeTheme.pillActiveColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time shimmer
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: _activeTheme.pillActiveColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          // Title shimmer
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: _activeTheme.pillActiveColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          // Description shimmer
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: _activeTheme.pillActiveColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 200,
            height: 12,
            decoration: BoxDecoration(
              color: _activeTheme.pillActiveColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
