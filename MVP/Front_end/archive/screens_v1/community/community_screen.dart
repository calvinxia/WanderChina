import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';

/// Community Screen - Social feed and posts
/// Based on Figma design - Screen 6 (Community)
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Community',
          style: AppTextStyles.h3(color: AppColors.gray900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray600,
          tabs: [
            Tab(text: 'Feed'),
            Tab(text: 'Companions'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedTab(),
          _buildCompanionsTab(),
          _buildGroupsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFeedTab() {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.m),
      children: [
        _buildPostCard(
          userName: 'Sarah Chen',
          userAvatar: null,
          timeAgo: '2h ago',
          content:
              'Just visited the Forbidden City! The architecture is absolutely stunning. Here are some tips for first-time visitors...',
          likes: 234,
          comments: 45,
          hasImage: true,
        ),
        AppSpacing.gapHeightM,
        _buildPostCard(
          userName: 'Michael Zhang',
          userAvatar: null,
          timeAgo: '5h ago',
          content:
              'Looking for travel companions to visit Xi\'an next week. Anyone interested in exploring the Terracotta Warriors?',
          likes: 89,
          comments: 23,
          hasImage: false,
        ),
      ],
    );
  }

  Widget _buildCompanionsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 80, color: AppColors.gray300),
          AppSpacing.gapHeightM,
          Text(
            'Find Travel Companions',
            style: AppTextStyles.h3(color: AppColors.gray600),
          ),
          AppSpacing.gapHeightS,
          Text(
            'Connect with fellow travelers',
            style: AppTextStyles.body(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups, size: 80, color: AppColors.gray300),
          AppSpacing.gapHeightM,
          Text(
            'Join Travel Groups',
            style: AppTextStyles.h3(color: AppColors.gray600),
          ),
          AppSpacing.gapHeightS,
          Text(
            'Discover communities with similar interests',
            style: AppTextStyles.body(color: AppColors.gray500),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard({
    required String userName,
    String? userAvatar,
    required String timeAgo,
    required String content,
    required int likes,
    required int comments,
    required bool hasImage,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    userName[0],
                    style: AppTextStyles.button(color: Colors.white),
                  ),
                ),
                SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppTextStyles.button(color: AppColors.gray900),
                      ),
                      Text(
                        timeAgo,
                        style: AppTextStyles.caption(color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, color: AppColors.gray500),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Text(
              content,
              style: AppTextStyles.body(color: AppColors.gray800),
            ),
          ),

          // Image
          if (hasImage) ...[
            AppSpacing.gapHeightM,
            Container(
              height: 200,
              color: AppColors.gray100,
              child: Center(
                child: Icon(Icons.image, size: 64, color: AppColors.gray300),
              ),
            ),
          ],

          // Actions
          Padding(
            padding: EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                _buildActionButton(Icons.favorite_border, likes.toString()),
                SizedBox(width: AppSpacing.l),
                _buildActionButton(Icons.comment_outlined, comments.toString()),
                SizedBox(width: AppSpacing.l),
                _buildActionButton(Icons.share_outlined, 'Share'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gray600),
          SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption(color: AppColors.gray600),
          ),
        ],
      ),
    );
  }
}
