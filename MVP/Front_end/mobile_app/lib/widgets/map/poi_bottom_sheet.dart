import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/poi_translation.dart';

class POIBottomSheet extends StatelessWidget {
  final POITranslation poi;
  final AppLanguage language;            // 当前语言
  final VoidCallback onDirections;   // 点击 Directions 的回调
  final VoidCallback onClose;

  const POIBottomSheet({
    super.key,
    required this.poi,
    required this.language,
    required this.onDirections,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖拽指示条
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // POI 名称（双语）
          Text(
            poi.localizedName(language),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            poi.nameZh,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),

          const SizedBox(height: 8),

          // 距离：POITranslation 无 distance 字段，需从当前位置计算
          // 如果有 _currentLocation，可以算直线距离；否则不显示
          // 此处先省略距离显示，MVP 可后续补充

          const SizedBox(height: 16),

          // 操作按钮
          Row(
            children: [
              // Directions 按钮（主操作）
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions, size: 20),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.jade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Details 按钮（次操作）
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // MVP: 展示更多信息或 coming soon
                  },
                  icon: const Icon(Icons.info_outline, size: 20),
                  label: const Text('Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.jade500,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.jade500),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
