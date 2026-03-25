import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/api_client.dart';
import '../../services/backend/auth_service.dart';
import '../../core/config/backend_config.dart';
import '../../models/itinerary.dart';
import 'itinerary_detail_screen.dart';

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
  String? _selectedCity;
  int _selectedDays = 3;
  final Set<String> _selectedInterests = {};
  final TextEditingController _customInput = TextEditingController();
  List<Map<String, dynamic>> _savedTrips = [];
  bool _isLoadingTrips = true;

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

  @override
  void initState() {
    super.initState();
    _loadSavedTrips();
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
      if (mounted) {
        setState(() {
          _savedTrips = List<Map<String, dynamic>>.from(result['trips'] ?? []);
          _isLoadingTrips = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load trips error: $e');
      if (mounted) setState(() => _isLoadingTrips = false);
    }
  }

  @override
  void dispose() {
    _customInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Plan Your Trip'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.gray900,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                // Show help dialog
              },
            ),
          ],
        ),
      body: SingleChildScrollView(
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
                    style: AppTextStyles.caption(color: AppColors.gray600),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.gray300)),
              ],
            ),

            const SizedBox(height: 16),

            // Custom Input
            Container(
              height: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gray300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _customInput,
                maxLength: 200,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. "3 days in Chengdu, love pandas and spicy food, budget traveller"',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppColors.gray400,
                  ),
                  border: InputBorder.none,
                  counterText: '',
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
                  backgroundColor: AppColors.jade500,
                  disabledBackgroundColor: AppColors.gray200,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: AppColors.gray400,
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
                    child: Text('View All', style: AppTextStyles.body(color: AppColors.jade500)),
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
                  onTap: () async {
                    try {
                      // 先从后端拉取完整行程数据
                      debugPrint('📋 Loading trip: ${trip['trip_id']}');
                      final detail = await ApiClient.post(BackendConfig.tripUrl, {
                        'action': 'get',
                        'trip_id': trip['trip_id'],
                      });

                      debugPrint('📋 Trip detail response keys: ${detail.keys.toList()}');
                      debugPrint('📋 Trip detail response: $detail');

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
                              tripId: trip['trip_id'] as String?,
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
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to load trip: $e')),
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
        final isSelected = _selectedCity == city['zh'];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCity = city['zh'];
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.jade500 : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.jade500 : AppColors.gray300,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  city['zh']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  city['en']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white70 : AppColors.gray600,
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
      children: List.generate(5, (index) {
        final day = index + 1;
        final isSelected = _selectedDays == day;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 4 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDays = day;
                });
              },
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.jade500 : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppColors.jade500 : AppColors.gray300,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.gray900,
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
              color: isSelected ? AppColors.jade100 : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.jade500 : AppColors.gray300,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                  color: isSelected ? AppColors.jade700 : AppColors.gray400,
                ),
                const SizedBox(width: 6),
                Text(
                  interest,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.jade700 : AppColors.gray900,
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.jade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: AppColors.jade500,
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

  Future<void> _generatePlan() async {
    final loadingText = ValueNotifier<String>('AI is planning your trip...');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ValueListenableBuilder<String>(
        valueListenable: loadingText,
        builder: (_, text, __) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.jade500),
                const SizedBox(height: 16),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 将选中的中文城市名转换为英文完整名
      final selectedCityMap = _cities.firstWhere(
        (city) => city['zh'] == _selectedCity,
        orElse: () => {'zh': '', 'en': '', 'fullName': 'Beijing'},
      );
      final cityEnglishName = selectedCityMap['fullName']!;

      // Step 1: 公网函数生成行程
      debugPrint('🗺️ Step 1: Calling generate_itinerary (public)');
      final genResponse = await ApiClient.post(
        ApiClient.generateItineraryUrl,
        {
          'cities': [cityEnglishName],
          'days': _selectedDays,
          'interests': _selectedInterests.toList(),
          'language': 'english',
        },
        timeout: const Duration(seconds: 75),  // 云函数 60s + 网络延迟
      );

      debugPrint('🗺️ generate_itinerary response: $genResponse');
      debugPrint('🗺️ response type: ${genResponse.runtimeType}');
      debugPrint('🗺️ response keys: ${genResponse.keys.toList()}');

      final itineraryJson = genResponse['itinerary'];
      final title = genResponse['title'] ?? 'My Trip';
      debugPrint('🗺️ Generated title: $title');

      if (!mounted) return;

      // 关闭 loading 对话框
      Navigator.pop(context);

      // 使用 fromCloudData 解析云函数返回的行程数据
      final itinerary = Itinerary.fromCloudData({
        ...itineraryJson,
        'title': title,
        'cities': [cityEnglishName],
        'totalDays': _selectedDays,
        'interests': _selectedInterests.toList(),
      });

      debugPrint('🗺️ Itinerary parsed successfully (preview mode): ${itinerary.title}');

      // 导航到行程详情页（预览模式，传入保存所需参数）
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ItineraryDetailScreen(
            itinerary: itinerary,
            tripId: null,  // null 表示未保存（预览模式）
            cities: [cityEnglishName],
            days: _selectedDays,
            interests: _selectedInterests.toList(),
          ),
        ),
      );
      // 返回后重新加载保存的行程列表
      _loadSavedTrips();
    } catch (e, stackTrace) {
      debugPrint('🗺️ generate_plan error: $e');
      debugPrint('🗺️ error type: ${e.runtimeType}');
      debugPrint('🗺️ stack trace: $stackTrace');

      if (!mounted) return;

      // 关闭 loading 对话框
      Navigator.pop(context);

      // 收起键盘
      FocusScope.of(context).unfocus();

      // 显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate itinerary: ${e.toString()}'),
          backgroundColor: AppColors.error500,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
