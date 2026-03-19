import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Map Search Bar - Top overlay search input
///
/// 地图顶部搜索框，用于搜索地点和地址
/// 点击后展开搜索结果列表
class MapSearchBar extends StatefulWidget {
  final VoidCallback? onTap;
  final Function(String)? onSearch;
  final bool enabled;

  const MapSearchBar({
    super.key,
    this.onTap,
    this.onSearch,
    this.enabled = true,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              decoration: InputDecoration(
                hintText: 'Search places or address...',
                hintStyle: AppTextStyles.body(color: AppColors.gray500),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTextStyles.body(color: AppColors.gray900),
              onTap: widget.onTap,
              onSubmitted: (value) {
                if (value.isNotEmpty && widget.onSearch != null) {
                  widget.onSearch!(value);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.gray600, size: 22),
            onPressed: () {
              if (_controller.text.isNotEmpty && widget.onSearch != null) {
                widget.onSearch!(_controller.text);
              } else if (widget.onTap != null) {
                widget.onTap!();
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
