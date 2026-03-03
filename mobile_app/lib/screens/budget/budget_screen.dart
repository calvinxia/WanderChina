import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/expense.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/dialogs/currency_converter_dialog.dart';

/// Budget Management Screen
/// Based on Figma design and roadmap requirements
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data - will be replaced with provider
  final Budget _currentBudget = Budget(
    id: '1',
    totalAmount: 10000,
    currency: 'CNY',
    startDate: DateTime.now().subtract(Duration(days: 5)),
    endDate: DateTime.now().add(Duration(days: 25)),
    spentAmount: 4250.50,
  );

  final List<Expense> _recentExpenses = [
    Expense(
      id: '1',
      category: 'food',
      amount: 85.50,
      currency: 'CNY',
      date: DateTime.now(),
      note: 'Dinner at local restaurant',
      location: 'Beijing',
    ),
    Expense(
      id: '2',
      category: 'transport',
      amount: 15.00,
      currency: 'CNY',
      date: DateTime.now().subtract(Duration(hours: 2)),
      note: 'Metro ticket',
    ),
    Expense(
      id: '3',
      category: 'attractions',
      amount: 120.00,
      currency: 'CNY',
      date: DateTime.now().subtract(Duration(days: 1)),
      note: 'Forbidden City entrance',
      location: 'Beijing',
    ),
  ];

  // Add Expense form controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _selectedCategory = 'food';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Budget Tracker',
          style: AppTextStyles.h3(color: AppColors.gray900),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.currency_exchange, color: AppColors.primary),
            onPressed: _showCurrencyConverter,
          ),
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.gray700),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray500,
          labelStyle: AppTextStyles.button(color: AppColors.primary),
          unselectedLabelStyle: AppTextStyles.button(color: AppColors.gray500),
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Expenses'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildExpensesTab(),
          _buildAnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Expense',
          style: AppTextStyles.button(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget Summary Card
          _buildBudgetSummaryCard(),

          AppSpacing.gapHeightXL,

          // Daily Budget
          _buildDailyBudgetCard(),

          AppSpacing.gapHeightXL,

          // Category Breakdown
          Text(
            'Spending by Category',
            style: AppTextStyles.h3(color: AppColors.gray900),
          ),
          AppSpacing.gapHeightM,
          _buildCategoryBreakdown(),

          AppSpacing.gapHeightXL,

          // Quick Stats
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildBudgetSummaryCard() {
    final percentage = _currentBudget.percentageUsed;
    final remaining = _currentBudget.remainingAmount;

    return Container(
      padding: EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Budget',
            style: AppTextStyles.bodySmall(color: Colors.white.withOpacity(0.9)),
          ),
          AppSpacing.gapHeightS,
          Text(
            '¥${_currentBudget.totalAmount.toStringAsFixed(0)}',
            style: AppTextStyles.h1(color: Colors.white),
          ),
          AppSpacing.gapHeightXL,

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusS),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  Container(color: Colors.white.withOpacity(0.3)),
                  FractionallySizedBox(
                    widthFactor: (percentage / 100).clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: percentage > 90 ? AppColors.error500 : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          AppSpacing.gapHeightM,

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spent',
                    style: AppTextStyles.caption(color: Colors.white.withOpacity(0.8)),
                  ),
                  Text(
                    '¥${_currentBudget.spentAmount.toStringAsFixed(2)}',
                    style: AppTextStyles.h4(color: Colors.white),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Remaining',
                    style: AppTextStyles.caption(color: Colors.white.withOpacity(0.8)),
                  ),
                  Text(
                    '¥${remaining.toStringAsFixed(2)}',
                    style: AppTextStyles.h4(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBudgetCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.success100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        border: Border.all(color: AppColors.success500),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success500,
              borderRadius: BorderRadius.circular(AppSpacing.radiusM),
            ),
            child: Icon(Icons.calendar_today, color: Colors.white, size: 24),
          ),
          AppSpacing.gapWidthM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Budget',
                  style: AppTextStyles.bodySmall(color: AppColors.gray700),
                ),
                Text(
                  '¥${_currentBudget.dailyBudget.toStringAsFixed(2)}/day',
                  style: AppTextStyles.h3(color: AppColors.success700),
                ),
              ],
            ),
          ),
          Text(
            '${_currentBudget.daysRemaining} days left',
            style: AppTextStyles.caption(color: AppColors.gray600),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    // Mock category data
    final categories = ExpenseCategory.defaults.take(4).toList();
    final amounts = [1200.0, 850.0, 1500.0, 700.0];

    return Column(
      children: List.generate(categories.length, (index) {
        final category = categories[index];
        final amount = amounts[index];
        final percentage = (amount / _currentBudget.totalAmount * 100);

        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.m),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(category.color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                ),
                child: Center(
                  child: Text(category.icon, style: TextStyle(fontSize: 20)),
                ),
              ),
              AppSpacing.gapWidthM,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category.name,
                          style: AppTextStyles.body(color: AppColors.gray900),
                        ),
                        Text(
                          '¥${amount.toStringAsFixed(0)}',
                          style: AppTextStyles.button(color: AppColors.gray900),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusS),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: [
                            Container(color: AppColors.gray100),
                            FractionallySizedBox(
                              widthFactor: (percentage / 100).clamp(0, 1),
                              child: Container(color: Color(category.color)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up,
            label: 'Avg per Day',
            value: '¥${(_currentBudget.spentAmount / 5).toStringAsFixed(0)}',
            color: AppColors.info500,
          ),
        ),
        AppSpacing.gapWidthM,
        Expanded(
          child: _buildStatCard(
            icon: Icons.receipt,
            label: 'Transactions',
            value: '${_recentExpenses.length}',
            color: AppColors.warning500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          AppSpacing.gapHeightS,
          Text(label, style: AppTextStyles.caption(color: AppColors.gray600)),
          Text(value, style: AppTextStyles.h3(color: AppColors.gray900)),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: _recentExpenses.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.m),
            child: Text(
              'Recent Transactions',
              style: AppTextStyles.h3(color: AppColors.gray900),
            ),
          );
        }

        final expense = _recentExpenses[index - 1];
        final category = ExpenseCategory.defaults.firstWhere(
          (c) => c.id == expense.category,
        );

        return Card(
          margin: EdgeInsets.only(bottom: AppSpacing.s),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(category.color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusM),
              ),
              child: Center(
                child: Text(category.icon, style: TextStyle(fontSize: 24)),
              ),
            ),
            title: Text(
              category.name,
              style: AppTextStyles.button(color: AppColors.gray900),
            ),
            subtitle: Text(
              expense.note ?? 'No description',
              style: AppTextStyles.caption(color: AppColors.gray600),
            ),
            trailing: Text(
              '-¥${expense.amount.toStringAsFixed(2)}',
              style: AppTextStyles.h4(color: AppColors.error500),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: AppColors.gray300),
            AppSpacing.gapHeightL,
            Text(
              'Analytics Coming Soon',
              style: AppTextStyles.h3(color: AppColors.gray900),
            ),
            AppSpacing.gapHeightS,
            Text(
              'Advanced spending insights and reports',
              style: AppTextStyles.body(color: AppColors.gray600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _addExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddExpenseSheet(),
    );
  }

  Widget _buildAddExpenseSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXL)),
      ),
      child: Column(
        children: [
          // Header with drag handle
          Container(
            padding: EdgeInsets.all(AppSpacing.m),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AppSpacing.gapHeightM,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Expense',
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
              ],
            ),
          ),

          Divider(height: 1),

          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Field
                  Text(
                    'Amount *',
                    style: AppTextStyles.button(color: AppColors.gray900),
                  ),
                  AppSpacing.gapHeightS,
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    style: AppTextStyles.h3(color: AppColors.gray900),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: AppTextStyles.h3(color: AppColors.gray300),
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(AppSpacing.m),
                        child: Text(
                          '¥',
                          style: AppTextStyles.h3(color: AppColors.primary),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                        borderSide: BorderSide(color: AppColors.gray200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                        borderSide: BorderSide(color: AppColors.gray200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),

                  AppSpacing.gapHeightL,

                  // Category Selection
                  Text(
                    'Category *',
                    style: AppTextStyles.button(color: AppColors.gray900),
                  ),
                  AppSpacing.gapHeightS,
                  _buildCategorySelector(),

                  AppSpacing.gapHeightL,

                  // Date Field
                  Text(
                    'Date *',
                    style: AppTextStyles.button(color: AppColors.gray900),
                  ),
                  AppSpacing.gapHeightS,
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gray200),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                          AppSpacing.gapWidthM,
                          Text(
                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                            style: AppTextStyles.body(color: AppColors.gray900),
                          ),
                        ],
                      ),
                    ),
                  ),

                  AppSpacing.gapHeightL,

                  // Note Field
                  Text(
                    'Note',
                    style: AppTextStyles.button(color: AppColors.gray900),
                  ),
                  AppSpacing.gapHeightS,
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    style: AppTextStyles.body(color: AppColors.gray900),
                    decoration: InputDecoration(
                      hintText: 'Add a description...',
                      hintStyle: AppTextStyles.body(color: AppColors.gray300),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                        borderSide: BorderSide(color: AppColors.gray200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                        borderSide: BorderSide(color: AppColors.gray200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),

                  AppSpacing.gapHeightL,

                  // Location Field
                  Text(
                    'Location',
                    style: AppTextStyles.button(color: AppColors.gray900),
                  ),
                  AppSpacing.gapHeightS,
                  TextField(
                    controller: _locationController,
                    style: AppTextStyles.body(color: AppColors.gray900),
                    decoration: InputDecoration(
                      hintText: 'Where did you spend?',
                      hintStyle: AppTextStyles.body(color: AppColors.gray300),
                      prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                        borderSide: BorderSide(color: AppColors.gray200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                        borderSide: BorderSide(color: AppColors.gray200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom action buttons
          Container(
            padding: EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gray900.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: PrimaryButton(
              text: 'Save Expense',
              onPressed: _saveExpense,
              isFullWidth: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: ExpenseCategory.defaults.map((category) {
        final isSelected = _selectedCategory == category.id;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedCategory = category.id);
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Color(category.color).withOpacity(0.2)
                  : AppColors.gray50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusM),
              border: Border.all(
                color: isSelected ? Color(category.color) : AppColors.gray200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category.icon, style: TextStyle(fontSize: 20)),
                SizedBox(width: 6),
                Text(
                  category.name,
                  style: AppTextStyles.bodySmall(
                    color: isSelected ? Color(category.color) : AppColors.gray700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.gray900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveExpense() {
    // Validate amount
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: AppColors.error500,
        ),
      );
      return;
    }

    // Create new expense
    final newExpense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: _selectedCategory,
      amount: amount,
      currency: 'CNY',
      date: _selectedDate,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      location:
          _locationController.text.isNotEmpty ? _locationController.text : null,
    );

    // Add to list (in production, this would update state management)
    setState(() {
      _recentExpenses.insert(0, newExpense);
      // Update spent amount
      // _currentBudget.spentAmount += amount; // In production, update via provider
    });

    // Clear form
    _amountController.clear();
    _noteController.clear();
    _locationController.clear();
    _selectedCategory = 'food';
    _selectedDate = DateTime.now();

    // Close sheet
    Navigator.pop(context);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Expense saved successfully!'),
          ],
        ),
        backgroundColor: AppColors.success500,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCurrencyConverter() {
    showDialog(
      context: context,
      builder: (context) => CurrencyConverterDialog(),
    );
  }
}
