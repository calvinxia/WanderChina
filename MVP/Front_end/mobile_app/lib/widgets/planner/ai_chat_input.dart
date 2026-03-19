import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// AI Chat Input Widget - allows users to ask AI to adjust the itinerary
///
/// Specifications from FLUTTER_UI_REDESIGN_INSTRUCTIONS.md:
/// - Height: 52px
/// - Background: Jade 50
/// - Border: 1px Jade 200
/// - Placeholder: "Ask AI to adjust..."
/// - Send icon: Jade 500
class AiChatInput extends StatefulWidget {
  final Function(String) onSend;
  final String? placeholder;

  const AiChatInput({
    super.key,
    required this.onSend,
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
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.jade50,
        border: Border.all(color: AppColors.jade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // AI icon
          const Icon(
            Icons.auto_awesome,
            size: 20,
            color: AppColors.jade500,
          ),
          const SizedBox(width: 8),

          // Text input
          Expanded(
            child: TextField(
              controller: _controller,
              style: AppTextStyles.body(color: AppColors.gray900),
              decoration: InputDecoration(
                hintText: widget.placeholder ?? 'Ask AI to adjust...',
                hintStyle: AppTextStyles.body(color: AppColors.gray400).copyWith(
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          IconButton(
            onPressed: _hasText ? _handleSend : null,
            icon: Icon(
              Icons.send,
              size: 20,
              color: _hasText ? AppColors.jade500 : AppColors.gray300,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
