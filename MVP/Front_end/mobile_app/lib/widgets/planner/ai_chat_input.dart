import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/city_theme.dart';

/// AI Chat Input Widget - allows users to ask AI to adjust the itinerary
///
/// Specifications from FLUTTER_UI_REDESIGN_INSTRUCTIONS.md:
/// - Height: 52px
/// - Background: 25% transparent white
/// - Border: themed color
/// - Placeholder: "Ask AI to adjust..."
/// - Send icon: themed color
class AiChatInput extends StatefulWidget {
  final Function(String) onSend;
  final String? placeholder;
  final CityTheme theme;

  const AiChatInput({
    super.key,
    required this.onSend,
    required this.theme,
    this.placeholder,
  });

  @override
  State<AiChatInput> createState() => _AiChatInputState();
}

class _AiChatInputState extends State<AiChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 52,
        maxHeight: 120, // 最多展开到 120px（约 4 行）
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        border: Border.all(color: widget.theme.pillActiveColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // 图标底部对齐
        children: [
          // AI icon
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Icon(
              Icons.auto_awesome,
              size: 20,
              color: widget.theme.pillActiveColor,
            ),
          ),
          const SizedBox(width: 8),

          // Text input — 多行
          Expanded(
            child: TextField(
              controller: _controller,
              style: AppTextStyles.body(color: AppColors.gray900),
              maxLines: 4, // 最多 4 行
              minLines: 1, // 最少 1 行
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: widget.placeholder ?? 'Ask AI to adjust...',
                hintStyle: AppTextStyles.body(color: AppColors.gray400).copyWith(
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                isDense: true,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: IconButton(
              onPressed: _hasText ? _handleSend : null,
              icon: Icon(
                Icons.send,
                size: 20,
                color: _hasText ? widget.theme.pillActiveColor : AppColors.gray300,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}
