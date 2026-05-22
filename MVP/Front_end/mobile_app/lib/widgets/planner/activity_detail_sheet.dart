import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/city_theme.dart';
import '../../services/api_client.dart';
import '../../core/config/backend_config.dart';
import '../../services/deeplink_service.dart';
import '../../services/analytics_service.dart';
import '../../screens/main/main_screen.dart';

class ActivityDetailSheet extends StatefulWidget {
  final String nameEn;
  final String nameZh;
  final String description;
  final String duration;
  final String cost;
  final String city;
  final CityTheme? theme;
  final String category;
  final String imageKeyword;

  const ActivityDetailSheet({
    super.key,
    required this.nameEn,
    required this.nameZh,
    required this.description,
    required this.duration,
    required this.cost,
    required this.city,
    this.theme,
    this.category = '',
    this.imageKeyword = '',
  });

  @override
  State<ActivityDetailSheet> createState() => _ActivityDetailSheetState();
}

class _ActivityDetailSheetState extends State<ActivityDetailSheet> {
  String? _photoUrl;
  String? _photographer;
  String? _photographerUrl;
  String? _source;
  bool _isLoadingPhoto = true;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    try {
      // 传 category + imageKeyword 给后端，Unsplash 搜索用
      var result = await ApiClient.post(BackendConfig.poiPhotoUrl, {
        'action': 'single',
        'name_zh': widget.nameZh,
        'name_en': widget.nameEn,
        'city': widget.city,
        'category': widget.category,
        'image_keyword': widget.imageKeyword,
      });

      String? photoUrl = result['photo_url'] as String?;
      String? photographer = result['photographer'] as String?;
      String? photographerUrl = result['photographer_url'] as String?;
      String? source = result['source'] as String?;

      // 第二次尝试：如果无结果，用英文名搜（现有 fallback 逻辑）
      if (photoUrl == null && widget.nameEn.isNotEmpty) {
        String cleanName = widget.nameEn
            .replaceAll(RegExp(r'^(Lunch|Dinner|Breakfast|Visit|Explore)\s+(at|to|in)\s+', caseSensitive: false), '');

        result = await ApiClient.post(BackendConfig.poiPhotoUrl, {
          'action': 'single',
          'name_zh': cleanName,
          'name_en': cleanName,
          'city': widget.city,
          'category': widget.category,
          'image_keyword': widget.imageKeyword,
        });
        photoUrl = result['photo_url'] as String?;
        photographer = result['photographer'] as String?;
        photographerUrl = result['photographer_url'] as String?;
        source = result['source'] as String?;
      }

      if (mounted) {
        setState(() {
          _photoUrl = photoUrl;
          _photographer = photographer;
          _photographerUrl = photographerUrl;
          _source = source;
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

            // 仅 Unsplash 来源时显示摄影师署名（合规要求）
            if (_source == 'unsplash' && _photographer != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      children: [
                        const TextSpan(text: 'Photo by '),
                        TextSpan(
                          text: _photographer,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              if (_photographerUrl != null && _photographerUrl!.isNotEmpty) {
                                launchUrl(Uri.parse(_photographerUrl!));
                              }
                            },
                        ),
                        const TextSpan(text: ' on '),
                        TextSpan(
                          text: 'Unsplash',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              launchUrl(Uri.parse('https://unsplash.com/?utm_source=wanderchina&utm_medium=referral'));
                            },
                        ),
                      ],
                    ),
                  ),
                ),
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

            // ── Action Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Navigate — 跳 Map tab 搜索目的地
                      _buildActionButton(
                        icon: Icons.navigation_rounded,
                        label: 'Navigate',
                        onTap: () {
                          AnalyticsService.instance.track('deeplink_navigate', {
                            'destination': widget.nameZh,
                          });
                          Navigator.of(context).pop();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                          MainScreen.globalKey.currentState?.switchToMapAndSearch(
                            widget.nameEn.isNotEmpty ? widget.nameEn : widget.nameZh,
                            displayName: widget.nameEn.isNotEmpty ? widget.nameEn : widget.nameZh,
                            city: widget.city,
                            fallbackQuery: widget.nameZh.isNotEmpty ? widget.nameZh : null,
                          );
                        },
                      ),

                      // Ride — DiDi 打车（直接跳 DiDi App，剪贴板传目的地）
                      _buildActionButton(
                        icon: Icons.local_taxi,
                        label: 'Ride',
                        onTap: () async {
                          AnalyticsService.instance.track('deeplink_didi', {
                            'destination': widget.nameZh,
                          });
                          final destName = widget.nameEn.isNotEmpty ? widget.nameEn : widget.nameZh;
                          final success = await DeeplinkService.openDidi(destName);
                          if (context.mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Destination copied! Paste it in DiDi\'s search bar')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please install DiDi to use ride hailing')),
                              );
                            }
                          }
                        },
                      ),

                      // Pay — 仅有消费的 activity 显示
                      if (_hasCost())
                        _buildActionButton(
                          icon: Icons.qr_code_scanner,
                          label: 'Pay',
                          onTap: () async {
                            AnalyticsService.instance.track('deeplink_alipay_pay', {
                              'venue': widget.nameZh,
                              'cost': widget.cost,
                            });
                            final success = await DeeplinkService.openAlipayScanner();
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please install Alipay to pay in China')),
                              );
                            }
                          },
                        ),
                    ],
                  ),

                  // Pay 提示文案
                  if (_hasCost())
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '💡 Scan the QR code at checkout with Alipay',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool _hasCost() {
    final cost = widget.cost.toLowerCase().trim();
    return cost.isNotEmpty && cost != 'free' && cost != '¥0' && cost != '0';
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final color = widget.theme?.pillActiveColor ?? const Color(0xFF2D6A4F);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
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
