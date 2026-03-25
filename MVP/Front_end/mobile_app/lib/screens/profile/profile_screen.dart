import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/backend/auth_service.dart';
import '../../services/api_client.dart';
import '../../core/config/backend_config.dart';
import '../../services/amap_service.dart';
import '../../models/itinerary.dart';
import '../auth/login_screen.dart';
import '../planner/itinerary_detail_screen.dart';
import 'edit_profile_screen.dart';

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
  late TabController _tabController;
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;
  List<Map<String, dynamic>> _userTrips = [];
  bool _isLoadingTrips = true;
  String _currentCity = 'China';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
    _loadTrips();
    _loadCurrentCity();
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
      if (mounted) setState(() => _isLoadingProfile = false);
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
      if (mounted) setState(() => _isLoadingTrips = false);
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                        foregroundColor: AppColors.jade500,
                        side: const BorderSide(color: AppColors.jade500, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Text(
                        'Edit Profile',
                        style: AppTextStyles.button(color: AppColors.jade500),
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
                    labelColor: AppColors.jade500,
                    unselectedLabelColor: AppColors.gray600,
                    labelStyle: AppTextStyles.body(color: AppColors.jade500).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: AppTextStyles.body(color: AppColors.gray600),
                    indicatorColor: AppColors.jade500,
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
                        await AuthService.logout();
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 16, color: AppColors.jade500),
            const SizedBox(width: 4),
            Text(
              '📍 $_currentCity',
              style: AppTextStyles.caption(color: AppColors.jade500),
            ),
          ],
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: AppColors.jade500),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to load trip: $e')),
                    );
                  }
                }
              },
              child: const Text('View', style: TextStyle(color: AppColors.jade500)),
            ),
          ],
        ),
      ),
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
}
