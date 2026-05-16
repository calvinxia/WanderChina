import 'package:flutter/material.dart';
import '../core/theme/city_theme.dart';
import '../services/purchase_service.dart';

/// Paywall Dialog for Trip Pass Non-Renewing Subscriptions
///
/// Displays 3 product tiers using current city theme colors:
/// - 7-Day Trip Pass (light variant)
/// - 14-Day Trip Pass (mid variant, recommended)
/// - 30-Day Trip Pass (dark variant, best value)
class PaywallDialog extends StatefulWidget {
  final CityTheme theme;
  final String feature; // 'itinerary', 'voice_translate', or 'ai_edit'
  final Function(String productId)? onPurchase;

  const PaywallDialog({
    super.key,
    required this.theme,
    required this.feature,
    this.onPurchase,
  });

  @override
  State<PaywallDialog> createState() => _PaywallDialogState();
}

class _PaywallDialogState extends State<PaywallDialog> {
  bool _isPurchasing = false;
  String? _selectedProductId;

  // Product definitions
  static const products = [
    {
      'id': 'wanderchina.trip_pass.7d',
      'duration': '7-Day',
      'price': '\$9.99',
      'variant': 'light',
      'badge': null,
    },
    {
      'id': 'wanderchina.trip_pass.14d',
      'duration': '14-Day',
      'price': '\$14.99',
      'variant': 'mid',
      'badge': 'Recommended',
    },
    {
      'id': 'wanderchina.trip_pass.30d',
      'duration': '30-Day',
      'price': '\$24.99',
      'variant': 'dark',
      'badge': 'Best Value',
    },
  ];

  String _getFeatureTitle() {
    switch (widget.feature) {
      case 'itinerary':
        return 'Unlock Unlimited Trip Planning';
      case 'voice_translate':
        return 'Unlock Unlimited Voice Translation';
      case 'ai_edit':
        return 'Unlock AI Itinerary Editing';
      default:
        return 'Unlock Premium Features';
    }
  }

  String _getFeatureDescription() {
    switch (widget.feature) {
      case 'itinerary':
        return 'Generate as many personalized trip plans as you want. '
            'Perfect for exploring multiple cities in China.';
      case 'voice_translate':
        return 'Translate conversations without daily limits. '
            'Navigate China with confidence.';
      case 'ai_edit':
        return 'Refine your itineraries with AI assistance. '
            'Get the perfect travel plan.';
      default:
        return 'Access all premium features for your China adventure.';
    }
  }

  Future<void> _handlePurchase(String productId) async {
    if (_isPurchasing) return;

    setState(() {
      _isPurchasing = true;
      _selectedProductId = productId;
    });

    try {
      if (widget.onPurchase != null) {
        await widget.onPurchase!(productId);
      } else {
        // 默认走 PurchaseService
        final initiated = await PurchaseService.instance.buy(productId);
        if (!initiated) throw Exception('Purchase could not be initiated');
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Purchase failed: $e');
      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _selectedProductId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed. Please try again.'),
            backgroundColor: Color(0xFFFF6B6B),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.theme.pillActiveColor.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Header icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: widget.theme.pillActiveColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 28,
                color: widget.theme.pillActiveColor,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _getFeatureTitle(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              _getFeatureDescription(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Product cards
            ...products.map((product) {
              final variant = product['variant'] as String;
              final badge = product['badge'] as String?;
              final productId = product['id'] as String;
              final isSelected = _selectedProductId == productId;
              final isLoading = _isPurchasing && isSelected;

              // Variant-specific styling
              final bgOpacity = variant == 'light' ? 0.06 : (variant == 'mid' ? 0.12 : 0.20);
              final borderOpacity = variant == 'light' ? 0.20 : (variant == 'mid' ? 0.35 : 0.50);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: isLoading ? null : () => _handlePurchase(productId),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.theme.pillActiveColor.withOpacity(bgOpacity),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.theme.pillActiveColor.withOpacity(borderOpacity),
                        width: variant == 'mid' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (badge != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: widget.theme.pillActiveColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        badge,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    '${product['duration']} Trip Pass',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: widget.theme.pillActiveColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'One-time purchase',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: widget.theme.pillActiveColor,
                              strokeWidth: 2,
                            ),
                          )
                        else
                          Text(
                            product['price'] as String,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: widget.theme.pillActiveColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 16),

            // Non-Renewing disclaimer
            Text(
              'No auto-renewal. Subscription expires after the period.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                height: 1.3,
              ),
            ),

            const SizedBox(height: 16),

            // "Maybe later" option
            GestureDetector(
              onTap: _isPurchasing ? null : () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Maybe later',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isPurchasing ? Colors.grey[300] : Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to show paywall dialog
Future<void> showPaywallDialog(
  BuildContext context,
  CityTheme theme,
  String feature, {
  Function(String productId)? onPurchase,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => PaywallDialog(
      theme: theme,
      feature: feature,
      onPurchase: onPurchase,
    ),
  );
}
