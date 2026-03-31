import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/city_theme.dart';

/// Map Search Bar - Top overlay search input
///
/// 地图顶部搜索框，用于搜索地点和地址
/// 点击后展开搜索结果列表
class MapSearchBar extends StatefulWidget {
  final VoidCallback? onTap;
  final Function(String)? onSearch;
  final VoidCallback? onClear;  // 清除按钮回调
  final bool enabled;
  final TextEditingController? controller;  // 支持外部传入 controller
  final CityTheme? theme;

  const MapSearchBar({
    super.key,
    this.onTap,
    this.onSearch,
    this.onClear,
    this.enabled = true,
    this.controller,
    this.theme,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    // 如果外部传入了 controller，使用外部的，否则创建内部的
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() => setState(() {})); // Rebuild on focus change
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    // 只有内部创建的 controller 才需要 dispose
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.theme ?? CityTheme.defaultTheme;
    final searchBarBg = Color.lerp(Colors.white, currentTheme.pillActiveColor, 0.05)!.withOpacity(0.9);

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: searchBarBg,
        borderRadius: BorderRadius.circular(24),
        border: _focusNode.hasFocus ? Border.all(color: currentTheme.pillActiveColor, width: 2) : null,
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
                // 根据文本状态显示清除或搜索图标
                suffixIcon: _hasText
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.gray600),
                        onPressed: () {
                          _controller.clear();
                          FocusScope.of(context).unfocus();
                          widget.onClear?.call();
                        },
                      )
                    : IconButton(
                        icon: Icon(Icons.search, size: 18, color: currentTheme.pillActiveColor),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          if (_controller.text.isNotEmpty && widget.onSearch != null) {
                            widget.onSearch!(_controller.text);
                          } else if (widget.onTap != null) {
                            widget.onTap!();
                          }
                        },
                      ),
              ),
              style: AppTextStyles.body(color: AppColors.gray900),
              onTap: widget.onTap,
              onSubmitted: (value) {
                FocusScope.of(context).unfocus(); // 收起键盘
                if (value.isNotEmpty && widget.onSearch != null) {
                  widget.onSearch!(value);
                }
              },
              textInputAction: TextInputAction.search,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}
