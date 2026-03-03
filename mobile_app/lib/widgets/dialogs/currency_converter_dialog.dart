import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../services/currency_service.dart';
import '../buttons/primary_button.dart';

/// Currency Converter Dialog
/// Allows users to convert between different currencies
class CurrencyConverterDialog extends StatefulWidget {
  const CurrencyConverterDialog({Key? key}) : super(key: key);

  @override
  State<CurrencyConverterDialog> createState() =>
      _CurrencyConverterDialogState();
}

class _CurrencyConverterDialogState extends State<CurrencyConverterDialog> {
  final TextEditingController _amountController = TextEditingController();
  String _fromCurrency = 'CNY';
  String _toCurrency = 'USD';
  double _convertedAmount = 0.0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _convert() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount > 0) {
      setState(() {
        _convertedAmount = CurrencyService.convert(
          amount: amount,
          from: _fromCurrency,
          to: _toCurrency,
        );
      });
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _convert();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencies = CurrencyService.getAllCurrencies();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Currency Converter',
                  style: AppTextStyles.h2(color: AppColors.gray900),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.gray700),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),

            AppSpacing.gapHeightL,

            // From Currency Section
            Text(
              'From',
              style: AppTextStyles.bodySmall(color: AppColors.gray600),
            ),
            AppSpacing.gapHeightS,
            _buildCurrencyInput(
              controller: _amountController,
              currency: _fromCurrency,
              currencies: currencies,
              onCurrencyChanged: (value) {
                setState(() => _fromCurrency = value!);
                _convert();
              },
              onChanged: (value) => _convert(),
            ),

            AppSpacing.gapHeightM,

            // Swap Button
            Center(
              child: GestureDetector(
                onTap: _swapCurrencies,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Icon(
                    Icons.swap_vert,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ),

            AppSpacing.gapHeightM,

            // To Currency Section
            Text(
              'To',
              style: AppTextStyles.bodySmall(color: AppColors.gray600),
            ),
            AppSpacing.gapHeightS,
            _buildResultDisplay(
              amount: _convertedAmount,
              currency: _toCurrency,
              currencies: currencies,
              onCurrencyChanged: (value) {
                setState(() => _toCurrency = value!);
                _convert();
              },
            ),

            AppSpacing.gapHeightL,

            // Exchange Rate Info
            Container(
              padding: EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.info100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                border: Border.all(color: AppColors.info300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info700, size: 20),
                  AppSpacing.gapWidthS,
                  Expanded(
                    child: Text(
                      '1 $_fromCurrency = ${CurrencyService.getRate(from: _fromCurrency, to: _toCurrency).toStringAsFixed(4)} $_toCurrency',
                      style: AppTextStyles.bodySmall(color: AppColors.info700),
                    ),
                  ),
                ],
              ),
            ),

            AppSpacing.gapHeightL,

            // Close Button
            PrimaryButton(
              text: 'Done',
              onPressed: () => Navigator.pop(context),
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyInput({
    required TextEditingController controller,
    required String currency,
    required List<String> currencies,
    required ValueChanged<String?> onCurrencyChanged,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Currency Dropdown
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.s,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusM),
            ),
            child: DropdownButton<String>(
              value: currency,
              onChanged: onCurrencyChanged,
              underline: SizedBox(),
              isDense: true,
              items: currencies.map((String currency) {
                return DropdownMenuItem<String>(
                  value: currency,
                  child: Row(
                    children: [
                      Text(
                        CurrencyService.getSymbol(currency),
                        style: AppTextStyles.h4(color: AppColors.primary),
                      ),
                      SizedBox(width: 4),
                      Text(
                        currency,
                        style: AppTextStyles.button(color: AppColors.primary),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          AppSpacing.gapWidthM,

          // Amount Input
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: AppTextStyles.h3(color: AppColors.gray900),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0.00',
                hintStyle: AppTextStyles.h3(color: AppColors.gray300),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultDisplay({
    required double amount,
    required String currency,
    required List<String> currencies,
    required ValueChanged<String?> onCurrencyChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Currency Dropdown
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.s,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusM),
            ),
            child: DropdownButton<String>(
              value: currency,
              onChanged: onCurrencyChanged,
              underline: SizedBox(),
              isDense: true,
              dropdownColor: AppColors.primary,
              items: currencies.map((String currency) {
                return DropdownMenuItem<String>(
                  value: currency,
                  child: Row(
                    children: [
                      Text(
                        CurrencyService.getSymbol(currency),
                        style: AppTextStyles.h4(color: Colors.white),
                      ),
                      SizedBox(width: 4),
                      Text(
                        currency,
                        style: AppTextStyles.button(color: Colors.white),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          AppSpacing.gapWidthM,

          // Converted Amount Display
          Expanded(
            child: Text(
              amount.toStringAsFixed(2),
              style: AppTextStyles.h2(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
