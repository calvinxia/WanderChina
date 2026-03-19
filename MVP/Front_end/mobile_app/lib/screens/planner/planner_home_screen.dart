import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/api_client.dart';
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

  final List<Map<String, String>> _cities = [
    {'zh': '北京', 'en': 'BJ'},
    {'zh': '上海', 'en': 'SH'},
    {'zh': '广州', 'en': 'GZ'},
    {'zh': '深圳', 'en': 'SZ'},
    {'zh': '成都', 'en': 'CD'},
    {'zh': '西安', 'en': 'XA'},
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
  void dispose() {
    _customInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                onPressed: _canGenerate() ? _generatePlan : null,
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
                  'My Saved Trips (2)',
                  style: AppTextStyles.h4(color: AppColors.gray900),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All',
                    style: AppTextStyles.body(color: AppColors.jade500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSavedTripCard(
              city: 'Beijing',
              days: '5 days',
              focus: 'Culture',
              date: 'Created Jan 12',
            ),
          ],
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
  }) {
    return Container(
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
                Text(
                  '$city · $days · $focus',
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
    );
  }

  bool _canGenerate() {
    return _selectedCity != null &&
        (_selectedInterests.isNotEmpty || _customInput.text.trim().isNotEmpty);
  }

  Future<void> _generatePlan() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.jade500),
              SizedBox(height: 16),
              Text(
                'Generating your itinerary...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 构建请求参数
      final requestBody = {
        'city': _selectedCity,
        'days': _selectedDays,
        'interests': _selectedInterests.toList(),
        'customInput': _customInput.text.trim(),
        'language': 'en',
      };

      // 调用 create_trip 云函数
      final response = await ApiClient.post(
        ApiClient.tripUrl,
        requestBody,
        timeout: const Duration(seconds: 30),
      );

      if (!mounted) return;

      // 解析返回的行程数据
      final itinerary = Itinerary.fromJson(response['itinerary']);

      // 关闭 loading 对话框
      Navigator.pop(context);

      // 导航到行程详情页
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ItineraryDetailScreen(itinerary: itinerary),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // 关闭 loading 对话框
      Navigator.pop(context);

      // 显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate itinerary: ${e.toString()}'),
          backgroundColor: AppColors.error500,
        ),
      );
    }
  }
}
