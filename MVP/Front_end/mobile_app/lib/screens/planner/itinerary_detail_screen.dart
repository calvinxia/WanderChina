import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/itinerary.dart';
import '../../widgets/planner/activity_card.dart';
import '../../widgets/planner/transit_connector.dart';
import '../../widgets/planner/ai_chat_input.dart';
import '../../widgets/planner/activity_detail_sheet.dart';
import '../../services/api_client.dart';
import '../../services/analytics_service.dart';
import '../../core/config/backend_config.dart';
import '../../services/backend/auth_service.dart';
import '../main/main_screen.dart';
import '../../core/theme/city_theme.dart';
import '../../widgets/common/city_background.dart';
import '../../utils/quota_helper.dart';
import '../../widgets/soft_login_sheet.dart';

/// Screen 10: AI-Generated Itinerary Detail Page
///
/// 规范来自 FLUTTER_UI_REDESIGN_INSTRUCTIONS.md Step UI-5.2
/// - Day Tab Bar (swipeable)
/// - Activity Cards with Navigate/Details buttons
/// - Transit Connectors between activities
/// - AI Chat Input for adjustments
/// - View on Map button
/// - Manual Save for preview mode
class ItineraryDetailScreen extends StatefulWidget {
  final Itinerary itinerary;
  final String? tripId;           // null = 未保存（预览模式）
  final List<String>? cities;     // 用于保存时传给后端
  final int? days;                // 用于保存时传给后端
  final List<String>? interests;  // 用于保存时传给后端

  const ItineraryDetailScreen({
    super.key,
    required this.itinerary,
    this.tripId,
    this.cities,
    this.days,
    this.interests,
  });

  @override
  State<ItineraryDetailScreen> createState() => _ItineraryDetailScreenState();
}

class _ItineraryDetailScreenState extends State<ItineraryDetailScreen>
    with SingleTickerProviderStateMixin {
  final _analytics = AnalyticsService.instance;
  late TabController _tabController;
  late Itinerary _itinerary;
  bool _isSaved = false;
  bool _isSaving = false;
  late CityTheme _itineraryTheme;

  // AI editing state
  bool _isModifying = false;
  String _modifyingMessage = '';
  final List<String> _chatHistory = [];
  Set<String> _recentlyChangedIds = {};

  @override
  void initState() {
    super.initState();
    _itinerary = widget.itinerary;
    _tabController = TabController(
      length: _itinerary.days.length,
      vsync: this,
    );
    // 检查是否已保存：有 tripId 且不是 preview_ 开头
    _isSaved = widget.tripId != null && !widget.tripId!.startsWith('preview_');
    // 根据行程目的地检测城市主题
    _itineraryTheme = _detectTheme();
  }

  CityTheme _detectTheme() {
    final dest = _itinerary.destination.toLowerCase();
    if (dest.contains('beijing') || dest.contains('北京')) return CityTheme.beijing;
    if (dest.contains('shanghai') || dest.contains('上海')) return CityTheme.shanghai;
    if (dest.contains('guangzhou') || dest.contains('广州')) return CityTheme.guangzhou;
    if (dest.contains('shenzhen') || dest.contains('深圳')) return CityTheme.shenzhen;
    if (dest.contains('chengdu') || dest.contains('成都')) return CityTheme.chengdu;
    if (dest.contains("xi'an") || dest.contains('西安')) return CityTheme.xian;
    return CityTheme.defaultTheme;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CityBackground(
      theme: _itineraryTheme,
      child: PopScope(
        canPop: _isSaved,
        onPopInvoked: (bool didPop) async {
          if (didPop) return;

          final discard = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Color.lerp(Colors.white, _itineraryTheme.pillActiveColor, 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Discard itinerary?', style: TextStyle(color: _itineraryTheme.primaryTextColor)),
              content: Text(
                'This trip has not been saved. Are you sure you want to leave?',
                style: TextStyle(color: _itineraryTheme.secondaryTextColor),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel', style: TextStyle(color: _itineraryTheme.pillActiveColor)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Discard', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          if (discard == true && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray900),
          onPressed: () async {
            if (!_isSaved) {
              final discard = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Color.lerp(Colors.white, _itineraryTheme.pillActiveColor, 0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text('Discard itinerary?', style: TextStyle(color: _itineraryTheme.primaryTextColor)),
                  content: Text(
                    'This trip has not been saved. Are you sure you want to leave?',
                    style: TextStyle(color: _itineraryTheme.secondaryTextColor),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancel', style: TextStyle(color: _itineraryTheme.pillActiveColor)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Discard', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (discard == true && mounted) Navigator.pop(context);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          '${_itinerary.destination} · ${_itinerary.totalDays} Days',
          style: AppTextStyles.h4(color: AppColors.gray900),
        ),
        actions: [
          if (!_isSaved)
            TextButton.icon(
              onPressed: (_isSaving || _isSaved) ? null : _saveTrip,
              icon: Icon(Icons.bookmark_add, color: _itineraryTheme.pillActiveColor, size: 20),
              label: Text(
                _isSaving ? 'Saving...' : 'Save',
                style: TextStyle(color: _itineraryTheme.pillActiveColor, fontWeight: FontWeight.w600),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.bookmark, color: _itineraryTheme.pillActiveColor, size: 24),
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.gray700),
            onPressed: _handleShare,
            tooltip: 'Share',
          ),
        ],
      ),
      body: Column(
        children: [
          // AI Generated Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: _itineraryTheme.pillActiveColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
              ),
            ),
            child: Center(
              child: Text(
                '✨ Generated by AI',
                style: TextStyle(color: _itineraryTheme.pillActiveColor, fontSize: 14),
              ),
            ),
          ),

          // Day Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: _itinerary.days.length > 3,
              labelColor: _itineraryTheme.pillActiveColor,
              unselectedLabelColor: _itineraryTheme.secondaryTextColor,
              labelStyle: TextStyle(
                color: _itineraryTheme.pillActiveColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              unselectedLabelStyle: TextStyle(
                color: _itineraryTheme.secondaryTextColor,
                fontSize: 15,
              ),
              indicatorColor: _itineraryTheme.pillActiveColor,
              indicatorWeight: 2,
              tabs: _itinerary.days.map((day) {
                return Tab(text: 'Day ${day.dayNumber}');
              }).toList(),
            ),
          ),

          // Day Content (swipeable)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _itinerary.days.map((day) {
                return _buildDayContent(day);
              }).toList(),
            ),
          ),

          // Chat History + Loading State (above AiChatInput)
          if (_chatHistory.isNotEmpty || _isModifying)
            Container(
              constraints: const BoxConstraints(maxHeight: 80),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                ),
              ),
              child: ListView.builder(
                reverse: true,
                shrinkWrap: true,
                itemCount: _chatHistory.length + (_isModifying ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isModifying && index == 0) {
                    // Loading 状态
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _itineraryTheme.pillActiveColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _modifyingMessage,
                            style: TextStyle(
                              fontSize: 12,
                              color: _itineraryTheme.pillActiveColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final msgIndex = _isModifying ? index - 1 : index;
                  final reversedIndex = _chatHistory.length - 1 - msgIndex;
                  if (reversedIndex < 0 || reversedIndex >= _chatHistory.length) {
                    return const SizedBox();
                  }
                  final msg = _chatHistory[reversedIndex];
                  final isUser = msg.startsWith('You:');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isUser
                            ? _itineraryTheme.pillActiveColor.withOpacity(0.08)
                            : Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isUser
                              ? _itineraryTheme.pillActiveColor.withOpacity(0.15)
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 角色标签
                          Text(
                            isUser ? 'You' : 'AI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isUser
                                  ? _itineraryTheme.pillActiveColor
                                  : _itineraryTheme.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // 消息内容（去掉 "You: " / "AI: " 前缀）
                          Text(
                            msg.replaceFirst(RegExp(r'^(You|AI): '), ''),
                            style: TextStyle(
                              fontSize: 13,
                              color: _itineraryTheme.primaryTextColor.withOpacity(0.85),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // AI Chat Input (fixed at bottom)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '✏️ Type below to edit your itinerary with AI',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ),
                AiChatInput(
                  theme: _itineraryTheme,
                  onSend: _isModifying ? (text) {} : (text) => _modifyItinerary(text),
                  placeholder: _isModifying ? 'AI is updating...' : 'e.g. "add more food stops"',
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildDayContent(ItineraryDay day) {
    // Show skeleton screens during AI modification
    if (_isModifying) {
      return _buildModifyingSkeletonView();
    }

    // Limit activities to max 10 to prevent UI issues
    final activities = day.activities.take(10).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Title
          if (day.title != null) ...[
            Text(
              '${day.title}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.gray900),
            ),
            const SizedBox(height: 16),
          ],

          // Activities with Transit Connectors
          ...List.generate(activities.length, (index) {
            final activity = activities[index];
            final isLast = index == activities.length - 1;

            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    border: _recentlyChangedIds.contains(activity.id)
                        ? Border.all(color: _itineraryTheme.pillActiveColor, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ActivityCard(
                    activity: activity,
                    theme: _itineraryTheme,
                    onNavigate: () => _handleNavigate(activity),
                    onDetails: () => _showActivityDetail(activity.toJson()),
                    onDelete: () => _deleteActivity(day.dayNumber, index),
                  ),
                ),
                if (!isLast) _buildTransitConnector(activity, activities[index + 1]),
              ],
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTransitConnector(Activity from, Activity to) {
    // Calculate time difference between activities
    final durationMinutes = to.startTime.difference(from.endTime).inMinutes;

    // If no gap or invalid time difference, show blank spacing
    if (durationMinutes <= 0) {
      return const SizedBox(height: 16);
    }

    // Show time gap between activities
    if (durationMinutes <= 30) {
      return TransitConnector(
        transitText: '$durationMinutes min 🚶',
        icon: Icons.access_time,
      );
    } else if (durationMinutes <= 60) {
      return TransitConnector(
        transitText: '$durationMinutes min 🚕',
        icon: Icons.access_time,
      );
    } else {
      final hours = (durationMinutes / 60).floor();
      final mins = durationMinutes % 60;
      final timeText = mins > 0 ? '${hours}h ${mins}m 🚕' : '${hours}h 🚕';
      return TransitConnector(
        transitText: timeText,
        icon: Icons.schedule,
      );
    }
  }

  void _handleNavigate(Activity activity) {
    final nameZh = activity.notes ?? activity.location ?? '';
    final nameEn = activity.title;
    debugPrint('🧭 Navigate tapped: nameZh=$nameZh, nameEn=$nameEn, city=${_itinerary.destination}');

    // Analytics tracking
    _analytics.poiNavigate(nameEn.isNotEmpty ? nameEn : nameZh);

    // 搜索用中文（精确匹配），搜索框显示英文（用户可读）
    final searchQuery = nameZh.isNotEmpty ? nameZh : nameEn;
    final fallbackQuery = nameEn.isNotEmpty ? nameEn : null;
    final displayName = nameEn.isNotEmpty ? nameEn : nameZh;

    // itinerary_detail 压在 MainScreen 上，需要 pop 才能看到 Map tab
    Navigator.of(context).popUntil((route) => route.isFirst);
    MainScreen.globalKey.currentState?.switchToMapAndSearch(
      searchQuery,
      displayName: displayName,
      city: _itinerary.destination,
      fallbackQuery: fallbackQuery,
    );
  }

  Future<void> _showActivityDetail(Map<String, dynamic> activity) async {
    final nameZh = activity['name_zh'] ?? activity['notes'] ?? activity['location'] ?? '';
    final nameEn = activity['name'] ?? activity['title'] ?? '';

    // Analytics tracking
    _analytics.poiDetailViewed(nameEn.isNotEmpty ? nameEn : nameZh);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActivityDetailSheet(
        nameEn: nameEn,
        nameZh: nameZh,
        description: activity['description'] ?? '',
        duration: activity['duration'] ?? '',
        cost: activity['estimatedCost'] != null ? '¥${activity['estimatedCost']}' : '',
        city: _itinerary.destination,
        theme: _itineraryTheme,
      ),
    );
  }

  Future<void> _saveTrip() async {
    if (_isSaved || _isSaving) return;  // 防重复点击
    debugPrint('💾 Saving trip, user_id: ${AuthService.currentUserId}');
    debugPrint('💾 Itinerary days: ${_itinerary.toJson()['days']?.map((d) => d['day_number'])}');
    setState(() => _isSaving = true);
    try {
      await ApiClient.post(BackendConfig.tripUrl, {
        'action': 'create',
        'cities': widget.cities ?? [_itinerary.destination],
        'days': _itinerary.days.length,  // 用实际天数，不依赖 widget.days
        'interests': widget.interests ?? [],
        'title': _itinerary.title,
        'itinerary': _itinerary.toJson(),
        'user_id': AuthService.currentUserId,
      });

      if (mounted) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });

        // Analytics tracking
        _analytics.itinerarySaved(
          _itinerary.destination,
          _itinerary.days.length,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip saved to My Trips!')),
        );
      }
    } catch (e) {
      debugPrint('❌ Save trip error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
    // TODO: Implement share functionality
  }

  void _handleAddStop() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add stop functionality coming soon')),
    );
    // TODO: Add stop functionality
  }

  void _handleViewOnMap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View on map functionality coming soon')),
    );
    // TODO: Navigate to Map tab with all itinerary points
  }

  Map<String, dynamic> _buildItineraryJsonForModify() {
    // 构建精简的行程 JSON（DeepSeek 能理解的原始格式）
    final days = _itinerary.days.map((day) {
      return {
        'day_number': day.dayNumber,
        'title': day.title ?? '',
        'city': _itinerary.destination,
        'summary': day.notes ?? '',
        'activities': day.activities.map((activity) {
          final hour = activity.startTime.hour.toString().padLeft(2, '0');
          final minute = activity.startTime.minute.toString().padLeft(2, '0');
          final durationHours = activity.duration.inMinutes / 60;

          return {
            'time': '$hour:$minute',
            'name': activity.title,
            'name_zh': activity.notes ?? activity.location ?? '',
            'duration': durationHours >= 1
                ? '${durationHours.toStringAsFixed(durationHours == durationHours.toInt() ? 0 : 1)} hrs'
                : '${activity.duration.inMinutes} min',
            'cost': activity.estimatedCost != null ? '¥${activity.estimatedCost!.toStringAsFixed(0)}' : '¥0',
            'description': activity.description ?? '',
          };
        }).toList(),
      };
    }).toList();

    return {'days': days};
  }

  Future<void> _modifyItinerary(String instruction) async {
    if (instruction.trim().isEmpty) return;

    // 软登录检查：匿名用户弹注册引导
    if (!await requireLogin(context, 'ai_edit', theme: _itineraryTheme)) return;
    // AI Edit Quota Check
    if (!await requireQuotaCheck(
      context,
      'ai_edit',
      _itineraryTheme,
      userId: AuthService.currentUserId,
    )) return;

    setState(() {
      _isModifying = true;
      _modifyingMessage = 'AI is updating your itinerary...';
      _chatHistory.add('You: $instruction');
    });

    // Analytics tracking
    _analytics.itineraryModified(instruction);

    try {
      // 把当前行程转为 DeepSeek 能理解的 JSON
      final currentJson = _buildItineraryJsonForModify();

      final result = await ApiClient.post(
        ApiClient.generateItineraryUrl,
        {
          'action': 'modify',
          'itinerary': currentJson,
          'instruction': instruction,
          'language': 'english',
        },
        timeout: const Duration(seconds: 60),
      );

      final modifiedJson = result['itinerary'];
      if (modifiedJson != null && mounted) {
        // 解析修改后的行程
        final newItinerary = Itinerary.fromCloudData({
          ...modifiedJson,
          'title': _itinerary.title,
          'cities': [_itinerary.destination],
          'duration_days': _itinerary.days.length,
          'trip_id': widget.tripId,
        });

        // 找出变更的 activity ids，高亮 2 秒
        final changedIds = _findChangedActivities(_itinerary, newItinerary);

        setState(() {
          _chatHistory.add('AI: Itinerary updated ✓');
          _isModifying = false;
          _modifyingMessage = '';
          _itinerary = newItinerary;
          _recentlyChangedIds = changedIds;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _recentlyChangedIds = {});
        });
      }
    } catch (e) {
      debugPrint('❌ Modify itinerary error: $e');
      if (mounted) {
        setState(() {
          _chatHistory.add('AI: Sorry, update failed. Try again.');
          _isModifying = false;
          _modifyingMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update itinerary: $e')),
        );
      }
    }
  }

  void _deleteActivity(int dayNumber, int activityIndex) {
    setState(() {
      final dayIndex = _itinerary.days.indexWhere((d) => d.dayNumber == dayNumber);
      if (dayIndex >= 0) {
        final updatedActivities = List<Activity>.from(_itinerary.days[dayIndex].activities);
        if (activityIndex < updatedActivities.length) {
          updatedActivities.removeAt(activityIndex);
          // 需要重建 ItineraryDay（因为 activities 是 final）
          final updatedDay = ItineraryDay(
            id: _itinerary.days[dayIndex].id,
            dayNumber: _itinerary.days[dayIndex].dayNumber,
            date: _itinerary.days[dayIndex].date,
            title: _itinerary.days[dayIndex].title,
            activities: updatedActivities,
            notes: _itinerary.days[dayIndex].notes,
          );
          _itinerary.days[dayIndex] = updatedDay;
          // 标记为未保存
          _isSaved = false;
        }
      }
    });
  }

  Set<String> _findChangedActivities(Itinerary oldItin, Itinerary newItin) {
    final oldNames = {
      for (final day in oldItin.days)
        for (final act in day.activities) act.title,
    };
    final changed = <String>{};
    for (final day in newItin.days) {
      for (final act in day.activities) {
        if (!oldNames.contains(act.title)) changed.add(act.id);
      }
    }
    return changed;
  }

  Widget _buildModifyingSkeletonView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _modifyingMessage,
          style: TextStyle(
            fontSize: 14,
            color: _itineraryTheme.pillActiveColor,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            backgroundColor: _itineraryTheme.pillActiveColor.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(_itineraryTheme.pillActiveColor),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 20),
        // 只显示 2 个骨架卡片（不是 4 个），减少高度
        ...List.generate(2, (i) => _buildSkeletonCard()),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 12,
            decoration: BoxDecoration(
              color: _itineraryTheme.pillActiveColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 16,
            decoration: BoxDecoration(
              color: _itineraryTheme.pillActiveColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 120,
            height: 12,
            decoration: BoxDecoration(
              color: _itineraryTheme.pillActiveColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 70,
                height: 12,
                decoration: BoxDecoration(
                  color: _itineraryTheme.pillActiveColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 55,
                height: 12,
                decoration: BoxDecoration(
                  color: _itineraryTheme.pillActiveColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// POI Details Bottom Sheet with Photos
class _POIDetailsSheet extends StatefulWidget {
  final Activity activity;

  const _POIDetailsSheet({required this.activity});

  @override
  State<_POIDetailsSheet> createState() => _POIDetailsSheetState();
}

class _POIDetailsSheetState extends State<_POIDetailsSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _photos = [];
  String? _errorMessage;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    try {
      // Use Chinese name for photo search (Activity doesn't have poiId field)
      final nameZh = widget.activity.notes ?? widget.activity.location ?? widget.activity.title;

      final result = await ApiClient.post(
        BackendConfig.poiPhotoUrl,
        {
          'name_zh': nameZh,
          'limit': 5,
        },
        timeout: const Duration(seconds: 15),
      );

      if (mounted) {
        final photos = (result['photos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        setState(() {
          _photos = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Fetch POI photos failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load photos';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photos Carousel
                    if (_isLoading)
                      Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.jade500),
                        ),
                      )
                    else if (_photos.isNotEmpty)
                      _buildPhotoCarousel()
                    else
                      Container(
                        height: 200,
                        color: Colors.grey[100],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage ?? 'No photos available',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Content Padding
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            widget.activity.title,
                            style: AppTextStyles.h3(color: AppColors.gray900),
                          ),
                          const SizedBox(height: 12),

                          // Time
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: AppColors.gray600),
                              const SizedBox(width: 6),
                              Text(
                                '${_formatTime(widget.activity.startTime)} - ${_formatTime(widget.activity.endTime)}',
                                style: AppTextStyles.bodySmall(color: AppColors.gray600),
                              ),
                            ],
                          ),

                          // Description
                          if (widget.activity.description != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              widget.activity.description!,
                              style: AppTextStyles.body(color: AppColors.gray700),
                            ),
                          ],

                          // Address
                          if (widget.activity.address != null) ...[
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, size: 18, color: AppColors.jade500),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.activity.address!,
                                    style: AppTextStyles.body(color: AppColors.gray600),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Notes (Chinese name)
                          if (widget.activity.notes != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.jade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.translate, size: 16, color: AppColors.jade500),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.activity.notes!,
                                      style: AppTextStyles.bodySmall(color: AppColors.gray700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            itemCount: _photos.length,
            onPageChanged: (index) {
              setState(() => _currentPhotoIndex = index);
            },
            itemBuilder: (context, index) {
              final photo = _photos[index];
              final url = photo['url'] as String?;

              return GestureDetector(
                onTap: () {
                  // Full screen photo view
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _FullScreenPhotoView(
                        photos: _photos,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: Image.network(
                  url ?? '',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: AppColors.jade500,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),

        // Photo Counter & Caption
        if (_photos.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.black.withOpacity(0.6),
            child: Row(
              children: [
                // Counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPhotoIndex + 1}/${_photos.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),

                // Caption
                Expanded(
                  child: Text(
                    _photos[_currentPhotoIndex]['caption'] as String? ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Full Screen Photo Viewer
class _FullScreenPhotoView extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final int initialIndex;

  const _FullScreenPhotoView({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_FullScreenPhotoView> createState() => _FullScreenPhotoViewState();
}

class _FullScreenPhotoViewState extends State<_FullScreenPhotoView> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1}/${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              return InteractiveViewer(
                child: Center(
                  child: Image.network(
                    photo['url'] as String,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Caption at bottom
          if (widget.photos[_currentIndex]['caption'] != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Text(
                  widget.photos[_currentIndex]['caption'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
/// Activity Detail Sheet Widget
class _ActivityDetailSheet extends StatefulWidget {
  final String nameEn;
  final String nameZh;
  final String description;
  final String duration;
  final String cost;
  final String city;

  const _ActivityDetailSheet({
    required this.nameEn,
    required this.nameZh,
    required this.description,
    required this.duration,
    required this.cost,
    required this.city,
  });

  @override
  State<_ActivityDetailSheet> createState() => _ActivityDetailSheetState();
}

class _ActivityDetailSheetState extends State<_ActivityDetailSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _photos = [];
  String? _errorMessage;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    try {
      final result = await ApiClient.post(
        ApiClient.poiPhotoUrl,
        {
          'name_zh': widget.nameZh,
          'city': widget.city,
          'limit': 5,
        },
        timeout: const Duration(seconds: 15),
      );

      if (mounted) {
        final photos = (result['photos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        setState(() {
          _photos = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Fetch POI photos failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load photos';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photos Carousel
                    if (_isLoading)
                      Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.jade500),
                        ),
                      )
                    else if (_photos.isNotEmpty)
                      _buildPhotoCarousel()
                    else
                      Container(
                        height: 200,
                        color: Colors.grey[100],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage ?? 'No photos available',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // English Name
                          Text(
                            widget.nameEn,
                            style: AppTextStyles.h3(color: AppColors.gray900),
                          ),

                          // Chinese Name
                          if (widget.nameZh.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.jade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.translate, size: 14, color: AppColors.jade500),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.nameZh,
                                    style: AppTextStyles.bodySmall(color: AppColors.gray700),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Duration
                          if (widget.duration.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: AppColors.gray600),
                                const SizedBox(width: 6),
                                Text(
                                  widget.duration,
                                  style: AppTextStyles.bodySmall(color: AppColors.gray600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Cost
                          if (widget.cost.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(Icons.attach_money, size: 16, color: AppColors.gray600),
                                const SizedBox(width: 6),
                                Text(
                                  widget.cost,
                                  style: AppTextStyles.bodySmall(color: AppColors.gray600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Description
                          if (widget.description.isNotEmpty) ...[
                            Text(
                              widget.description,
                              style: AppTextStyles.body(color: AppColors.gray700),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            itemCount: _photos.length,
            onPageChanged: (index) {
              setState(() => _currentPhotoIndex = index);
            },
            itemBuilder: (context, index) {
              final photo = _photos[index];
              final url = photo['url'] as String?;

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _FullScreenPhotoView(
                        photos: _photos,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: Image.network(
                  url ?? '',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: AppColors.jade500,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),

        // Photo Counter & Caption
        if (_photos.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.black.withOpacity(0.6),
            child: Row(
              children: [
                // Counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPhotoIndex + 1}/${_photos.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),

                // Caption
                Expanded(
                  child: Text(
                    _photos[_currentPhotoIndex]['caption'] as String? ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
