import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/backend/auth_service.dart';
import '../../services/purchase_service.dart';
import '../../services/subscription_service.dart';
import '../../services/app_event_bus.dart';
import '../../services/analytics_service.dart';
import '../../services/api_client.dart';
import '../../core/config/backend_config.dart';
import '../../services/amap_service.dart';
import '../../models/itinerary.dart';
import '../auth/login_screen.dart';
import '../auth/delete_account_screen.dart';
import '../planner/itinerary_detail_screen.dart';
import 'edit_profile_screen.dart';
import '../../core/theme/city_theme.dart';
import '../main/main_screen.dart';

/// Screen 12: Profile / Me Page
///
/// 规范来自 FLUTTER_UI_REDESIGN_INSTRUCTIONS.md Step UI-7
/// - Simplified profile header with 2 stats (Places + Trips)
/// - 3-tab layout: Trips · Saved Places · History
/// - Removed non-MVP features: Challenges, Budget Tracker, Points
/// - Trip cards with View/Edit/Share actions
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _analytics = AnalyticsService.instance;
  late TabController _tabController;
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;
  List<Map<String, dynamic>> _userTrips = [];
  bool _isLoadingTrips = true;
  String _currentCity = 'China';
  StreamSubscription? _subEventSub;
  StreamSubscription? _loginEventSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
    _loadTrips();
    _loadCurrentCity();
    // [PB4] SubscriptionService 是全局单例，setState 仅触发 build 重读最新状态
    _subEventSub = AppEventBus.instance.on<PurchaseSuccessEvent>().listen((_) {
      if (mounted) setState(() {});
    });
    _loginEventSub = AppEventBus.instance.on<LoginStatusChangedEvent>().listen((_) {
      if (mounted) _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.getProfile();
      debugPrint('📷 avatar_url: ${profile?['avatar_url']}');
      debugPrint('👤 Profile data: $profile');
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load profile error: $e');
      // 网络失败时尝试读 SharedPreferences 缓存
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('user_display_name');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          if (cachedName != null) {
            _userProfile = {'display_name': cachedName, 'username': cachedName};
          }
        });
        if (e is SocketException || e.toString().contains('host lookup')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offline mode. Some data may be outdated.')),
          );
        }
      }
    }
  }

  Future<void> _loadTrips() async {
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
          _userTrips = List<Map<String, dynamic>>.from(result['trips'] ?? []);
          _isLoadingTrips = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load trips error: $e');
      if (mounted) {
        setState(() => _isLoadingTrips = false);
        if (e is SocketException || e.toString().contains('host lookup')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load trips. Check your connection.')),
          );
        }
      }
    }
  }

  Future<void> _loadCurrentCity() async {
    try {
      final amapService = AMapService();
      await amapService.initialize();
      final location = await amapService.getLocation();
      if (location != null && mounted) {
        final lat = double.tryParse(location['latitude'].toString()) ?? 0;
        final lng = double.tryParse(location['longitude'].toString()) ?? 0;
        setState(() {
          _currentCity = _detectCity(lat, lng);
        });
      }
    } catch (e) {
      debugPrint('📍 Profile location failed: $e');
    }
  }

  String _detectCity(double lat, double lng) {
    if (lat > 39.4 && lat < 40.4 && lng > 115.7 && lng < 117.0) return 'Beijing';
    if (lat > 30.8 && lat < 31.8 && lng > 120.8 && lng < 122.0) return 'Shanghai';
    if (lat > 22.5 && lat < 23.6 && lng > 112.9 && lng < 114.0) return 'Guangzhou';
    if (lat > 22.3 && lat < 22.9 && lng > 113.7 && lng < 114.5) return 'Shenzhen';
    if (lat > 30.0 && lat < 31.0 && lng > 103.5 && lng < 104.8) return 'Chengdu';
    if (lat > 33.8 && lat < 34.6 && lng > 108.5 && lng < 109.5) return "Xi'an";
    return 'China';
  }

  @override
  void dispose() {
    _subEventSub?.cancel();
    _loginEventSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildAnonymousProfile() {
    final color = MainScreen.globalKey.currentState?.cityTheme.pillActiveColor
        ?? const Color(0xFF2D6A4F);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Sign in for the full experience',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Save trips, sync across devices, and unlock premium features',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: Image.asset(
                    'assets/icons/oauth/apple_logo_white.png',
                    width: 20,
                    height: 20,
                  ),
                  label: const Text('Continue with Apple'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    try {
                      await AuthService.signInWithApple();
                      if (mounted) setState(() {});
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sign in failed: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: Icon(Icons.email_outlined, color: color),
                  label: Text('Continue with Email', style: TextStyle(color: color)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: color),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const LoginScreen(fromSoftLogin: true)),
                    );
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 匿名用户显示登录引导页
    if (AuthService.isAnonymous) {
      return _buildAnonymousProfile();
    }

    // Get city theme from MainScreen
    final mainState = context.findAncestorStateOfType<MainScreenState>();
    final cityTheme = mainState?.cityTheme ?? CityTheme.defaultTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('My Profile'),
        foregroundColor: AppColors.gray900,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.gray700),
            onPressed: _handleSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Profile Header
                _buildProfileHeader(),

                const SizedBox(height: 24),

                // Stats
                _buildStats(),

                const SizedBox(height: 16),

                // Edit Profile Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _handleEditProfile,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cityTheme.pillActiveColor,
                        side: BorderSide(color: cityTheme.pillActiveColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Text(
                        'Edit Profile',
                        style: AppTextStyles.button(color: cityTheme.pillActiveColor),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tab Bar
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.gray200, width: 1),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: cityTheme.pillActiveColor,
                    unselectedLabelColor: AppColors.gray600,
                    labelStyle: TextStyle(
                      color: cityTheme.pillActiveColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      color: AppColors.gray600,
                      fontSize: 15,
                    ),
                    indicatorColor: cityTheme.pillActiveColor,
                    indicatorWeight: 2,
                    tabs: const [
                      Tab(text: 'Trips'),
                      Tab(text: 'Saved Places'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTripsTab(),
                      _buildSavedPlacesTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),

                // Log Out Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        // Analytics tracking
                        _analytics.clearUser();
                        _analytics.track('logout');

                        // 标记此设备曾有注册用户（下次冷启动直接显示 LoginScreen）
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('was_registered', true);

                        await AuthService.logout();

                        // 跳回 LoginScreen，清空导航栈
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Log Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),

                // 订阅状态卡片
                _buildSubscriptionCard(),

                // Restore Purchases
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore Purchases'),
                  onTap: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            cityTheme.pillActiveColor,
                          ),
                        ),
                      ),
                    );

                    bool restoreSuccess = true;
                    String? restoreError;
                    try {
                      await PurchaseService.instance.restorePurchases();
                      await Future.delayed(const Duration(seconds: 2));
                    } catch (e) {
                      debugPrint('❌ Restore purchases error: $e');
                      restoreSuccess = false;
                      restoreError = (e is SocketException || e.toString().contains('host lookup'))
                          ? 'No internet connection. Please check your network and try again.'
                          : 'Something went wrong. Please try again.';
                    } finally {
                      if (context.mounted) Navigator.of(context).pop();
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(restoreSuccess
                              ? 'If you have a valid purchase, your subscription has been restored.'
                              : restoreError!),
                        ),
                      );
                    }
                  },
                ),

                // Delete Account Text Link
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: _confirmDeleteAccount,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.gray600,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    child: const Text(
                      'Delete Account',
                      style: TextStyle(
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.gray600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Avatar
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey[200],
          backgroundImage: _userProfile?['avatar_url'] != null
              ? NetworkImage(_userProfile!['avatar_url'])
              : null,
          child: _userProfile?['avatar_url'] == null
              ? const Icon(Icons.person, size: 40, color: Colors.grey)
              : null,
        ),

        const SizedBox(height: 12),

        // Name
        Text(
          _userProfile?['username'] ?? _userProfile?['display_name'] ?? 'Traveler',
          style: AppTextStyles.h2(color: AppColors.gray900),
        ),

        const SizedBox(height: 4),

        // Bio
        Text(
          _userProfile?['bio'] ?? '',
          style: AppTextStyles.bodySmall(color: AppColors.gray600),
        ),

        const SizedBox(height: 8),

        // Location
        Builder(
          builder: (context) {
            final mainState = context.findAncestorStateOfType<MainScreenState>();
            final cityTheme = mainState?.cityTheme ?? CityTheme.defaultTheme;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 16, color: cityTheme.pillActiveColor),
                const SizedBox(width: 4),
                Text(
                  '📍 $_currentCity',
                  style: AppTextStyles.caption(color: cityTheme.pillActiveColor),
                ),
              ],
            );
          }
        ),
      ],
    );
  }

  Widget _buildStats() {
    final tripsCount = _userProfile?['trips_count'] ?? 0;
    final translationsCount = _userProfile?['translations_count'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatItem('🗺️ $tripsCount Trips'),
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: AppColors.gray300,
          ),
          _buildStatItem('🌐 $translationsCount Translations'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String text) {
    return Text(
      text,
      style: AppTextStyles.body(color: AppColors.gray700).copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTripsTab() {
    if (_isLoadingTrips) {
      return const Center(child: CircularProgressIndicator());
    } else if (_userTrips.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.luggage, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('No trips yet', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
              const SizedBox(height: 4),
              Text('Your saved trips will appear here', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ],
          ),
        ),
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _userTrips.length,
        itemBuilder: (context, index) {
          final trip = _userTrips[index];
          return _buildTripCard(trip);
        },
      );
    }
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final title = trip['title'] ?? 'My Trip';
    final createdAt = _formatDate(trip['created_at']);

    // Get theme based on trip's city
    final tripCity = (trip['cities'] as List?)?.first ?? '';
    final tripTheme = CityTheme.fromCityKey(_getCityKey(tripCity));

    return Builder(
      builder: (context) {
        final cityTheme = tripTheme;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: Colors.white.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          child: ListTile(
            leading: Icon(Icons.calendar_today, color: cityTheme.pillActiveColor),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(createdAt, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () async {
                try {
                  final detail = await ApiClient.post(BackendConfig.tripUrl, {
                    'action': 'get',
                    'trip_id': trip['trip_id'],
                  });

                  final itinerary = Itinerary.fromCloudData({
                    'days': detail['days'],
                    'title': detail['title'],
                    'cities': detail['cities'],
                    'duration_days': detail['duration_days'],
                    'interests': detail['interests'],
                    'trip_id': detail['trip_id'],
                    'status': detail['status'],
                  });

                  if (mounted) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItineraryDetailScreen(
                          itinerary: itinerary,
                          tripId: detail['trip_id'],
                        ),
                      ),
                    );
                    _loadTrips(); // 返回后刷新
                  }
                } catch (e) {
                  debugPrint('❌ View trip error: $e');
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
              child: Text('View', style: TextStyle(color: cityTheme.pillActiveColor)),
            ),
          ],
        ),
      ),
    );
      }
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    try {
      // Handle different timestamp formats
      DateTime date;
      if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else if (timestamp is int) {
        date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else {
        return 'Unknown date';
      }

      // Format as "Jan 12, 2026"
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return 'Unknown date';
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

  Widget _buildSavedPlacesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('No saved places yet', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          const SizedBox(height: 4),
          Text('Places you save will appear here', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('No history yet', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          const SizedBox(height: 4),
          Text('Your translation and navigation history will appear here', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  void _handleSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings page coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Navigate to settings screen (Screen 13)
  }

  Future<void> _handleEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    _loadProfile();  // 返回后重新加载
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all your data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
      );
    }
  }

  Widget _buildSubscriptionCard() {
    final sub = SubscriptionService.instance;
    final isPremium = sub.isPremium;

    // 跟随 city theme（和 paywall_dialog 一致）
    final mainState = MainScreen.globalKey.currentState;
    final cityTheme = mainState?.cityTheme;
    final activeColor = cityTheme?.pillActiveColor ?? const Color(0xFF2D6A4F);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activeColor.withOpacity(isPremium ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activeColor.withOpacity(isPremium ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPremium ? Icons.workspace_premium_rounded : Icons.lock_outline,
            color: activeColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'Trip Pass Active' : 'Free Plan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: activeColor,
                  ),
                ),
                if (isPremium && sub.premiumExpiresAt != null)
                  Text(
                    'Active until ${sub.premiumExpiresAt!.toString().substring(0, 10)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                if (!isPremium)
                  Text(
                    'Upgrade for unlimited features',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
