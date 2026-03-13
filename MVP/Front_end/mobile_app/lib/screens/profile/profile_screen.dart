import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';

/// Profile Screen - User profile and settings
/// Based on Figma design - Screen 7 (Profile)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Profile Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(),
            ),
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                AppSpacing.gapHeightL,

                // Stats Section
                _buildStatsSection(),

                AppSpacing.gapHeightL,

                // Menu Section
                _buildMenuSection(),

                AppSpacing.gapHeightXL,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                size: 50,
                color: AppColors.primary,
              ),
            ),

            AppSpacing.gapHeightM,

            // Name
            Text(
              'John Traveler',
              style: AppTextStyles.h2(color: Colors.white),
            ),

            AppSpacing.gapHeightXS,

            // Email
            Text(
              'john@wanderchina.com',
              style: AppTextStyles.body(color: Colors.white.withOpacity(0.9)),
            ),

            AppSpacing.gapHeightM,

            // Edit Profile Button
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.l,
                vertical: AppSpacing.s,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                'Edit Profile',
                style: AppTextStyles.button(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: AppSpacing.screenPaddingH,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.m),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Places Visited', '23'),
            _buildDivider(),
            _buildStatItem('Challenges', '8'),
            _buildDivider(),
            _buildStatItem('Points', '1,240'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h2(color: AppColors.primary),
        ),
        AppSpacing.gapHeightXS,
        Text(
          label,
          style: AppTextStyles.caption(color: AppColors.gray600),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.gray200,
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: AppSpacing.screenPaddingH,
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.bookmark_border,
            title: 'Saved Places',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.emoji_events_outlined,
            title: 'My Challenges',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Budget Tracker',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.language,
            title: 'Language & Region',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {},
          ),
          AppSpacing.gapHeightM,
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Sign Out',
            onTap: () {},
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppColors.error500 : AppColors.gray700,
        ),
        title: Text(
          title,
          style: AppTextStyles.body(
            color: isDestructive ? AppColors.error500 : AppColors.gray900,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.gray400,
        ),
        onTap: onTap,
      ),
    );
  }
}
