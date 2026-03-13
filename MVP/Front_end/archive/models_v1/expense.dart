/// Expense Model for Budget Tracking
class Expense {
  final String id;
  final String category;
  final double amount;
  final String currency;
  final DateTime date;
  final String? note;
  final String? location;
  final String? receiptUrl;
  final bool isShared; // For group expenses
  final List<String>? sharedWith; // User IDs for split bills

  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.currency,
    required this.date,
    this.note,
    this.location,
    this.receiptUrl,
    this.isShared = false,
    this.sharedWith,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      location: json['location'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      isShared: json['isShared'] as bool? ?? false,
      sharedWith: (json['sharedWith'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'note': note,
      'location': location,
      'receiptUrl': receiptUrl,
      'isShared': isShared,
      'sharedWith': sharedWith,
    };
  }

  // Convert amount to another currency
  double convertTo(String targetCurrency, Map<String, double> rates) {
    if (currency == targetCurrency) return amount;
    final baseAmount = amount / (rates[currency] ?? 1.0);
    return baseAmount * (rates[targetCurrency] ?? 1.0);
  }
}

/// Expense Category with icon and color
class ExpenseCategory {
  final String id;
  final String name;
  final String icon;
  final int color;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<ExpenseCategory> defaults = [
    ExpenseCategory(
      id: 'food',
      name: 'Food & Drinks',
      icon: '🍜',
      color: 0xFFFF6B6B,
    ),
    ExpenseCategory(
      id: 'transport',
      name: 'Transportation',
      icon: '🚇',
      color: 0xFF4ECDC4,
    ),
    ExpenseCategory(
      id: 'accommodation',
      name: 'Accommodation',
      icon: '🏨',
      color: 0xFF45B7D1,
    ),
    ExpenseCategory(
      id: 'attractions',
      name: 'Attractions',
      icon: '🎭',
      color: 0xFF96CEB4,
    ),
    ExpenseCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: '🛍️',
      color: 0xFFFECEA8,
    ),
    ExpenseCategory(
      id: 'entertainment',
      name: 'Entertainment',
      icon: '🎉',
      color: 0xFFFF8B94,
    ),
    ExpenseCategory(
      id: 'health',
      name: 'Health & Medical',
      icon: '💊',
      color: 0xFFA8E6CF,
    ),
    ExpenseCategory(
      id: 'other',
      name: 'Other',
      icon: '📝',
      color: 0xFFDFE4EA,
    ),
  ];
}

/// Budget Model
class Budget {
  final String id;
  final double totalAmount;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final double spentAmount;
  final Map<String, double>? categoryLimits; // Category-specific budgets

  const Budget({
    required this.id,
    required this.totalAmount,
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.spentAmount,
    this.categoryLimits,
  });

  double get remainingAmount => totalAmount - spentAmount;
  double get percentageUsed => (spentAmount / totalAmount * 100).clamp(0, 100);
  bool get isOverBudget => spentAmount > totalAmount;

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  double get dailyBudget {
    if (daysRemaining <= 0) return 0;
    return remainingAmount / daysRemaining;
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      currency: json['currency'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      spentAmount: (json['spentAmount'] as num).toDouble(),
      categoryLimits: (json['categoryLimits'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'totalAmount': totalAmount,
      'currency': currency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'spentAmount': spentAmount,
      'categoryLimits': categoryLimits,
    };
  }
}
