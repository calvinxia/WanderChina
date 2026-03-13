import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/itinerary.dart';
import '../../widgets/cards/itinerary_card.dart';
import '../../widgets/buttons/primary_button.dart';
import 'itinerary_detail_screen.dart';
import 'create_trip_screen.dart';

/// Planner Screen - Trip Planning and Management
/// 行程规划主界面
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({Key? key}) : super(key: key);

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data - will be replaced with provider
  final List<Itinerary> _upcomingTrips = [
    Itinerary(
      id: '1',
      title: 'Beijing Cultural Journey',
      description: 'Explore ancient palaces, temples, and modern Beijing',
      destination: 'Beijing',
      cities: ['Beijing'],
      startDate: DateTime.now().add(Duration(days: 15)),
      endDate: DateTime.now().add(Duration(days: 20)),
      coverImageUrl: null,
      days: [],
      status: 'planned',
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      tags: ['Culture', 'History', 'Food'],
    ),
    Itinerary(
      id: '2',
      title: 'Shanghai & Suzhou Highlights',
      description: 'Modern metropolis meets classical gardens',
      destination: 'Shanghai',
      cities: ['Shanghai', 'Suzhou'],
      startDate: DateTime.now().add(Duration(days: 45)),
      endDate: DateTime.now().add(Duration(days: 50)),
      coverImageUrl: null,
      days: [],
      status: 'draft',
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      tags: ['Urban', 'Gardens', 'Shopping'],
    ),
  ];

  final List<Itinerary> _pastTrips = [
    Itinerary(
      id: '3',
      title: 'Xi\'an Adventure',
      description: 'Terracotta Warriors and ancient city walls',
      destination: 'Xi\'an',
      cities: ['Xi\'an'],
      startDate: DateTime.now().subtract(Duration(days: 60)),
      endDate: DateTime.now().subtract(Duration(days: 55)),
      coverImageUrl: null,
      days: [],
      status: 'completed',
      createdAt: DateTime.now().subtract(Duration(days: 75)),
      tags: ['History', 'Culture'],
    ),
  ];

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Trip Planner',
          style: AppTextStyles.h3(color: AppColors.gray900),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.gray700),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: AppColors.gray700),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray500,
          labelStyle: AppTextStyles.button(color: AppColors.primary),
          unselectedLabelStyle: AppTextStyles.button(color: AppColors.gray500),
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Draft'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTab(),
          _buildDraftTab(),
          _buildPastTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTrip,
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Trip',
          style: AppTextStyles.button(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    final upcomingTrips =
        _upcomingTrips.where((t) => t.status == 'planned').toList();

    if (upcomingTrips.isEmpty) {
      return _buildEmptyState(
        icon: Icons.luggage,
        title: 'No Upcoming Trips',
        description: 'Start planning your next adventure to China!',
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: upcomingTrips.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.m),
          child: ItineraryCard(
            itinerary: upcomingTrips[index],
            onTap: () => _viewItinerary(upcomingTrips[index]),
            onEdit: () => _editItinerary(upcomingTrips[index]),
            onDelete: () => _deleteItinerary(upcomingTrips[index]),
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms, delay: (50 * index).ms)
            .slideY(begin: 0.2, end: 0, duration: 300.ms, delay: (50 * index).ms);
      },
    );
  }

  Widget _buildDraftTab() {
    final draftTrips = _upcomingTrips.where((t) => t.status == 'draft').toList();

    if (draftTrips.isEmpty) {
      return _buildEmptyState(
        icon: Icons.edit_note,
        title: 'No Draft Trips',
        description: 'Draft trips will appear here while you plan them',
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: draftTrips.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.m),
          child: ItineraryCard(
            itinerary: draftTrips[index],
            onTap: () => _viewItinerary(draftTrips[index]),
            onEdit: () => _editItinerary(draftTrips[index]),
            onDelete: () => _deleteItinerary(draftTrips[index]),
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms, delay: (50 * index).ms)
            .slideY(begin: 0.2, end: 0, duration: 300.ms, delay: (50 * index).ms);
      },
    );
  }

  Widget _buildPastTab() {
    if (_pastTrips.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Past Trips',
        description: 'Your completed trips will appear here',
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: _pastTrips.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.m),
          child: ItineraryCard(
            itinerary: _pastTrips[index],
            onTap: () => _viewItinerary(_pastTrips[index]),
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms, delay: (50 * index).ms)
            .slideY(begin: 0.2, end: 0, duration: 300.ms, delay: (50 * index).ms);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppColors.primary),
            ),
            AppSpacing.gapHeightL,
            Text(
              title,
              style: AppTextStyles.h3(color: AppColors.gray900),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapHeightS,
            Text(
              description,
              style: AppTextStyles.body(color: AppColors.gray600),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapHeightXL,
            PrimaryButton(
              text: 'Create Your First Trip',
              onPressed: _createNewTrip,
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }

  void _createNewTrip() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTripScreen(),
      ),
    );
  }

  void _viewItinerary(Itinerary itinerary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItineraryDetailScreen(itinerary: itinerary),
      ),
    );
  }

  void _editItinerary(Itinerary itinerary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTripScreen(itinerary: itinerary),
      ),
    );
  }

  void _deleteItinerary(Itinerary itinerary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Trip?'),
        content: Text(
            'Are you sure you want to delete "${itinerary.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Trip deleted'),
                  backgroundColor: AppColors.success500,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error500)),
          ),
        ],
      ),
    );
  }
}
