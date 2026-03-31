import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/city_theme.dart';
import '../../services/api_client.dart';
import '../../core/config/backend_config.dart';

class ActivityDetailSheet extends StatefulWidget {
  final String nameEn;
  final String nameZh;
  final String description;
  final String duration;
  final String cost;
  final String city;
  final CityTheme? theme;

  const ActivityDetailSheet({
    super.key,
    required this.nameEn,
    required this.nameZh,
    required this.description,
    required this.duration,
    required this.cost,
    required this.city,
    this.theme,
  });

  @override
  State<ActivityDetailSheet> createState() => _ActivityDetailSheetState();
}

class _ActivityDetailSheetState extends State<ActivityDetailSheet> {
  String? _photoUrl;
  bool _isLoadingPhoto = true;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    try {
      // 第一次尝试：用完整中文名
      var result = await ApiClient.post(BackendConfig.poiPhotoUrl, {
        'action': 'single',
        'name_zh': widget.nameZh,
        'city': widget.city,
      });

      String? photoUrl = result['photo_url'] as String?;

      // 第二次尝试：如果无结果，用英文名搜
      if (photoUrl == null && widget.nameEn.isNotEmpty) {
        // 提取核心名称（去掉 "Lunch at"、"Dinner at" 等前缀）
        String cleanName = widget.nameEn
            .replaceAll(RegExp(r'^(Lunch|Dinner|Breakfast|Visit|Explore)\s+(at|to|in)\s+', caseSensitive: false), '');

        result = await ApiClient.post(BackendConfig.poiPhotoUrl, {
          'action': 'single',
          'name_zh': cleanName,
          'city': widget.city,
        });
        photoUrl = result['photo_url'] as String?;
      }

      if (mounted) {
        setState(() {
          _photoUrl = photoUrl;
          _isLoadingPhoto = false;
        });
      }
    } catch (e) {
      debugPrint('📷 Photo load failed: $e');
      if (mounted) setState(() => _isLoadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.theme ?? CityTheme.defaultTheme;
    final backgroundColor = Color.lerp(Colors.white, currentTheme.pillActiveColor, 0.15)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children: [
            // 拖拽指示条
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: widget.theme?.pillActiveColor.withOpacity(0.3) ?? Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 图片区域
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoadingPhoto
                  ? const Center(child: CircularProgressIndicator(color: AppColors.jade500))
                  : _photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _photoUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          ),
                        )
                      : _buildPlaceholder(),
            ),

            const SizedBox(height: 16),

            // 英文名（大标题）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.nameEn,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),

            // 中文名
            if (widget.nameZh.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.nameZh,
                  style: TextStyle(fontSize: 15, color: currentTheme.secondaryTextColor),
                ),
              ),

            const SizedBox(height: 12),

            // 时长 + 费用标签
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (widget.duration.isNotEmpty)
                    _buildTag(Icons.timer, widget.duration),
                  if (widget.duration.isNotEmpty && widget.cost.isNotEmpty)
                    const SizedBox(width: 12),
                  if (widget.cost.isNotEmpty)
                    _buildTag(Icons.attach_money, widget.cost),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 描述
            if (widget.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.description,
                  style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.5),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text('No photo available', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    final tagColor = widget.theme?.pillActiveColor ?? AppColors.jade500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: tagColor),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 13, color: tagColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
