/// Currency Conversion Service
class CurrencyService {
  // Exchange rates relative to CNY (Chinese Yuan)
  // In production, these would be fetched from an API
  static const Map<String, double> _exchangeRates = {
    'CNY': 1.0,
    'USD': 0.14, // 1 CNY = 0.14 USD
    'EUR': 0.13, // 1 CNY = 0.13 EUR
    'GBP': 0.11, // 1 CNY = 0.11 GBP
    'JPY': 20.5, // 1 CNY = 20.5 JPY
    'KRW': 188.0, // 1 CNY = 188 KRW
    'HKD': 1.08, // 1 CNY = 1.08 HKD
    'TWD': 4.35, // 1 CNY = 4.35 TWD
    'AUD': 0.21, // 1 CNY = 0.21 AUD
    'CAD': 0.19, // 1 CNY = 0.19 CAD
    'SGD': 0.19, // 1 CNY = 0.19 SGD
    'THB': 4.85, // 1 CNY = 4.85 THB
    'MYR': 0.63, // 1 CNY = 0.63 MYR
  };

  static const Map<String, String> _currencySymbols = {
    'CNY': '¥',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'KRW': '₩',
    'HKD': 'HK\$',
    'TWD': 'NT\$',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'SGD': 'S\$',
    'THB': '฿',
    'MYR': 'RM',
  };

  static const Map<String, String> _currencyNames = {
    'CNY': 'Chinese Yuan',
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'KRW': 'Korean Won',
    'HKD': 'Hong Kong Dollar',
    'TWD': 'Taiwan Dollar',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
    'SGD': 'Singapore Dollar',
    'THB': 'Thai Baht',
    'MYR': 'Malaysian Ringgit',
  };

  /// Convert amount from one currency to another
  static double convert({
    required double amount,
    required String from,
    required String to,
  }) {
    if (from == to) return amount;

    final fromRate = _exchangeRates[from] ?? 1.0;
    final toRate = _exchangeRates[to] ?? 1.0;

    // Convert to CNY first, then to target currency
    final amountInCNY = amount / fromRate;
    return amountInCNY * toRate;
  }

  /// Get currency symbol
  static String getSymbol(String currency) {
    return _currencySymbols[currency] ?? currency;
  }

  /// Get currency name
  static String getName(String currency) {
    return _currencyNames[currency] ?? currency;
  }

  /// Get all available currencies
  static List<String> getAllCurrencies() {
    return _exchangeRates.keys.toList();
  }

  /// Get exchange rate between two currencies
  static double getRate({
    required String from,
    required String to,
  }) {
    if (from == to) return 1.0;

    final fromRate = _exchangeRates[from] ?? 1.0;
    final toRate = _exchangeRates[to] ?? 1.0;

    return toRate / fromRate;
  }

  /// Format amount with currency symbol
  static String formatAmount({
    required double amount,
    required String currency,
    int decimals = 2,
  }) {
    final symbol = getSymbol(currency);
    return '$symbol${amount.toStringAsFixed(decimals)}';
  }
}
