import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/route_planning_service.dart';
import '../../services/deeplink_service.dart';
import '../../core/theme/city_theme.dart';

class RouteOverviewPanel extends StatefulWidget {
  final String originName;       // "My Location"
  final String destinationName;  // "Palace Museum (故宫)"
  final Function(RouteType) onRouteSelected; // 选择某种方式后的回调
  final VoidCallback onClose;
  final VoidCallback? onEditOrigin;  // 编辑起点回调
  final List<RouteInfo>? transitRoutes;
  final List<RouteInfo>? walkingRoutes;
  final List<RouteInfo>? drivingRoutes;
  final bool isLoading;
  final CityTheme? theme;

  const RouteOverviewPanel({
    super.key,
    required this.originName,
    required this.destinationName,
    required this.onRouteSelected,
    required this.onClose,
    this.onEditOrigin,
    this.transitRoutes,
    this.walkingRoutes,
    this.drivingRoutes,
    this.isLoading = false,
    this.theme,
  });

  @override
  State<RouteOverviewPanel> createState() => _RouteOverviewPanelState();
}

class _RouteOverviewPanelState extends State<RouteOverviewPanel> {
  RouteType _selectedType = RouteType.transit;
  bool _showStepDetails = false;

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.theme ?? CityTheme.defaultTheme;
    final bgColor = Color.lerp(Colors.white, currentTheme.pillActiveColor, 0.05)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示条
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // 起终点显示
          _buildEndpoints(),
          const SizedBox(height: 16),

          // 三种出行方式 tab
          _buildRouteTypeTabs(currentTheme),
          const SizedBox(height: 12),

          // 当前选中方式的路线详情
          if (widget.isLoading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(color: currentTheme.pillActiveColor),
            )
          else
            _buildSelectedRouteDetail(currentTheme),

          const SizedBox(height: 12),

          // DiDi 打车按钮
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.local_taxi, size: 20),
                label: const Text('Ride with DiDi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: currentTheme.pillActiveColor,
                  side: BorderSide(color: currentTheme.pillActiveColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final destName = widget.destinationName;
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
            ),
          ),

          // 开始导航按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onRouteSelected(_selectedType),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentTheme.pillActiveColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Show Route on Map', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpoints() {
    return Column(
      children: [
        // 起点（可编辑）
        GestureDetector(
          onTap: widget.onEditOrigin,
          child: Row(children: [
            const Icon(Icons.circle, size: 12, color: AppColors.jade500),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(widget.originName, style: const TextStyle(fontSize: 14))),
                    Icon(Icons.edit, size: 14, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Container(width: 2, height: 20, color: Colors.grey[300]),
        ),
        // 终点（保持不变）
        Row(children: [
          Icon(Icons.location_on, size: 14, color: Colors.red[400]),
          const SizedBox(width: 7),
          Expanded(child: Text(widget.destinationName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          IconButton(icon: const Icon(Icons.close, size: 20), onPressed: widget.onClose),
        ]),
      ],
    );
  }

  Widget _buildRouteTypeTabs(CityTheme theme) {
    return Row(
      children: [
        _buildTab(RouteType.transit, '🚇', 'Transit', widget.transitRoutes, theme),
        const SizedBox(width: 8),
        _buildTab(RouteType.walking, '🚶', 'Walk', widget.walkingRoutes, theme),
        const SizedBox(width: 8),
        _buildTab(RouteType.driving, '🚕', 'Cab', widget.drivingRoutes, theme),
      ],
    );
  }

  Widget _buildTab(RouteType type, String emoji, String label, List<RouteInfo>? routes, CityTheme theme) {
    final isSelected = _selectedType == type;
    final route = (routes != null && routes.isNotEmpty) ? routes.first : null;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.pillActiveColor.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.pillActiveColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? theme.pillActiveColor : Colors.grey[600],
              )),
              if (route != null) ...[
                const SizedBox(height: 2),
                Text(route.formattedDuration, style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? theme.pillActiveColor : Colors.grey[500],
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedRouteDetail(CityTheme theme) {
    List<RouteInfo>? routes;
    switch (_selectedType) {
      case RouteType.transit:
        routes = widget.transitRoutes;
        break;
      case RouteType.walking:
        routes = widget.walkingRoutes;
        break;
      case RouteType.driving:
        routes = widget.drivingRoutes;
        break;
      default:
        routes = null;
    }

    if (routes == null || routes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No routes available', style: TextStyle(color: Colors.grey[500])),
      );
    }

    final route = routes.first;

    return Column(
      children: [
        // 现有的摘要卡片
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailItem(Icons.timer, route.formattedDuration, theme),
              _buildDetailItem(Icons.straighten, route.formattedDistance, theme),
              if (route.taxiFee != null)
                _buildDetailItem(Icons.attach_money, '¥${route.taxiFee!.toStringAsFixed(0)}', theme),
              if (route.transitFee != null)
                _buildDetailItem(Icons.attach_money, '¥${route.transitFee!.toStringAsFixed(0)}', theme),
              // 步骤数可点击展开
              GestureDetector(
                onTap: () => setState(() => _showStepDetails = !_showStepDetails),
                child: Column(
                  children: [
                    Icon(
                      _showStepDetails ? Icons.expand_less : Icons.expand_more,
                      size: 18, color: theme.pillActiveColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${route.steps.length} steps',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.pillActiveColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 展开的步骤列表
        if (_showStepDetails && route.steps.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: route.steps.length,
              itemBuilder: (context, index) {
                final step = route.steps[index];
                return _buildStepItem(step, index + 1, route.steps.length, theme);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text, CityTheme theme) {
    return Column(
      children: [
        Icon(icon, size: 18, color: theme.pillActiveColor),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStepItem(RouteStep step, int number, int total, CityTheme theme) {
    final isLast = number == total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧时间轴
          Column(
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: isLast ? theme.pillActiveColor : Colors.white,
                  border: Border.all(color: theme.pillActiveColor, width: 2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isLast ? Colors.white : theme.pillActiveColor,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(width: 2, height: 30, color: theme.pillActiveColor.withOpacity(0.3)),
            ],
          ),
          const SizedBox(width: 10),
          // 右侧步骤信息
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.instruction,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${step.formattedDistance} · ${step.formattedDuration}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
