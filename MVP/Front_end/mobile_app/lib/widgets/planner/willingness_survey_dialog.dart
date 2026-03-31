import 'package:flutter/material.dart';
import '../../core/theme/city_theme.dart';

/// 付费意愿调研弹窗
class WillingnessSurveyDialog extends StatelessWidget {
  final CityTheme theme;
  final Function(String response) onResponse;

  const WillingnessSurveyDialog({
    super.key,
    required this.theme,
    required this.onResponse,
  });

  @override
  Widget build(BuildContext context) {
    final prices = ['\$4.99', '\$9.99', '\$14.99', '\$19.99'];

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
              color: theme.pillActiveColor.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.pillActiveColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.favorite_outline_rounded,
                size: 28,
                color: theme.pillActiveColor,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Enjoying WanderChina?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'We\'re building the ultimate travel companion for China. '
              'What would feel like a fair price for full access?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Price options — 2x2 grid
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: prices.map((price) {
                return GestureDetector(
                  onTap: () => onResponse(price),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.pillActiveColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.pillActiveColor.withOpacity(0.20),
                      ),
                    ),
                    child: Text(
                      price,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: theme.pillActiveColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // "Not right now" option
            GestureDetector(
              onTap: () => onResponse('not_now'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Maybe later',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // "I wouldn't pay" option
            GestureDetector(
              onTap: () => onResponse('would_not_pay'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'I wouldn\'t pay for this',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[350],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
