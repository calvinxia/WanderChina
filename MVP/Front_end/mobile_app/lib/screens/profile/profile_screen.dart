import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray900),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.gray700),
            onPressed: _handleSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
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
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gray200, width: 2),
          ),
          child: const Icon(
            Icons.person,
            size: 40,
            color: AppColors.gray600,
          ),
        ),

        const SizedBox(height: 12),

        // Name
        Text(
          'Alex Chen',
          style: AppTextStyles.h2(color: AppColors.gray900),
        ),

        const SizedBox(height: 4),

        // Bio
        Text(
          '"Backpacker from NYC"',
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
              'Beijing',
              style: AppTextStyles.caption(color: AppColors.jade500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatItem('📍 12 Places'),
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: AppColors.gray300,
          ),
          _buildStatItem('🗺️ 3 Trips'),
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
    // Mock trip data
    final trips = [
      {
        'destination': 'Beijing',
        'days': 3,
        'type': 'Culture',
        'date': 'Jan 12, 2026',
      },
      {
        'destination': 'Shanghai',
        'days': 5,
        'type': 'Food',
        'date': 'Dec 28, 2025',
      },
    ];

    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: AppColors.gray300),
            const SizedBox(height: 16),
            Text(
              'No trips yet',
              style: AppTextStyles.body(color: AppColors.gray500),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first itinerary in the Planner',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(color: AppColors.gray400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return _buildTripCard(
          destination: trip['destination'] as String,
          days: trip['days'] as int,
          type: trip['type'] as String,
          date: trip['date'] as String,
        );
      },
    );
  }

  Widget _buildTripCard({
    required String destination,
    required int days,
    required String type,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$destination · $days Days · $type',
                  style: AppTextStyles.h4(color: AppColors.gray900),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Date
          Text(
            date,
            style: AppTextStyles.caption(color: AppColors.gray600),
          ),

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleViewTrip(destination),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.jade500,
                    side: const BorderSide(color: AppColors.jade500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleEditTrip(destination),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray700,
                    side: const BorderSide(color: AppColors.gray300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleShareTrip(destination),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray700,
                    side: const BorderSide(color: AppColors.gray300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPlacesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: AppColors.gray300),
          const SizedBox(height: 16),
          Text(
            'No saved places yet',
            style: AppTextStyles.body(color: AppColors.gray500),
          ),
          const SizedBox(height: 8),
          Text(
            'Save places from the Map to see them here',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppColors.gray300),
          const SizedBox(height: 16),
          Text(
            'No history yet',
            style: AppTextStyles.body(color: AppColors.gray500),
          ),
          const SizedBox(height: 8),
          Text(
            'Your translation and navigation history will appear here',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(color: AppColors.gray400),
          ),
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

  void _handleEditProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit profile functionality coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Navigate to edit profile screen
  }

  void _handleViewTrip(String destination) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View trip: $destination'),
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Navigate to itinerary detail screen
  }

  void _handleEditTrip(String destination) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit trip: $destination'),
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Navigate to trip edit/regeneration
  }

  void _handleShareTrip(String destination) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share trip: $destination'),
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Implement share functionality
  }
}
