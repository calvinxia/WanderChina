import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Voice Translation FAB - Floating Action Button for Voice
///
/// 右下角语音翻译悬浮按钮
/// 短按：打开全屏语音翻译
/// 长按：就地录音翻译
enum VoiceFABState {
  idle,
  recording,
  processing,
  playing,
}

class VoiceFAB extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDirectionSwap;
  final String fromLanguage;
  final String toLanguage;
  final VoiceFABState state;
  final double bottomOffset;

  const VoiceFAB({
    super.key,
    this.onTap,
    this.onLongPress,
    this.onDirectionSwap,
    this.fromLanguage = 'EN',
    this.toLanguage = '中',
    this.state = VoiceFABState.idle,
    this.bottomOffset = 90.0,
  });

  @override
  State<VoiceFAB> createState() => _VoiceFABState();
}

class _VoiceFABState extends State<VoiceFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: widget.bottomOffset + MediaQuery.of(context).padding.bottom,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Language direction pill
          GestureDetector(
            onTap: widget.onDirectionSwap,
            child: Container(
              width: 80,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${widget.fromLanguage}-${widget.toLanguage}',
                  style: AppTextStyles.caption(
                    color: AppColors.gray900,
                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Main FAB
          GestureDetector(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: _buildFABByState(),
          ),
        ],
      ),
    );
  }

  Widget _buildFABByState() {
    switch (widget.state) {
      case VoiceFABState.idle:
        return _buildFAB(
          color: AppColors.orange,
          icon: Icons.mic,
          iconColor: Colors.white,
        );

      case VoiceFABState.recording:
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: _buildFAB(
                color: AppColors.error500,
                icon: Icons.mic,
                iconColor: Colors.white,
              ),
            );
          },
        );

      case VoiceFABState.processing:
        return _buildFAB(
          color: AppColors.orange,
          icon: Icons.hourglass_empty,
          iconColor: Colors.white,
          showSpinner: true,
        );

      case VoiceFABState.playing:
        return _buildFAB(
          color: AppColors.success500,
          icon: Icons.volume_up,
          iconColor: Colors.white,
        );
    }
  }

  Widget _buildFAB({
    required Color color,
    required IconData icon,
    required Color iconColor,
    bool showSpinner = false,
  }) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: showSpinner
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : Icon(
              icon,
              size: 28,
              color: iconColor,
            ),
    );
  }
}
