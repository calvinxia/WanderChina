import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/itinerary.dart';
import '../../widgets/buttons/primary_button.dart';

/// Create/Edit Trip Screen
/// 创建/编辑行程页面
class CreateTripScreen extends StatefulWidget {
  final Itinerary? itinerary; // null for new trip, not null for editing

  const CreateTripScreen({
    super.key,
    this.itinerary,
  });

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.itinerary != null) {
      _titleController.text = widget.itinerary!.title;
      _descriptionController.text = widget.itinerary!.description ?? '';
      _destinationController.text = widget.itinerary!.destination;
      _startDate = widget.itinerary!.startDate;
      _endDate = widget.itinerary!.endDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itinerary != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.gray900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Trip' : 'Create New Trip',
          style: AppTextStyles.h4(color: AppColors.gray900),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              Text(
                'Trip Title *',
                style: AppTextStyles.button(color: AppColors.gray900),
              ),
              AppSpacing.gapHeightS,
              TextFormField(
                controller: _titleController,
                style: AppTextStyles.body(color: AppColors.gray900),
                decoration: InputDecoration(
                  hintText: 'e.g., Beijing Cultural Journey',
                  hintStyle: AppTextStyles.body(color: AppColors.gray300),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    borderSide: const BorderSide(color: AppColors.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    borderSide: const BorderSide(color: AppColors.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a trip title';
                  }
                  return null;
                },
              ),

              AppSpacing.gapHeightL,

              // Destination field
              Text(
                'Destination *',
                style: AppTextStyles.button(color: AppColors.gray900),
              ),
              AppSpacing.gapHeightS,
              TextFormField(
                controller: _destinationController,
                style: AppTextStyles.body(color: AppColors.gray900),
                decoration: InputDecoration(
                  hintText: 'e.g., Beijing, China',
                  hintStyle: AppTextStyles.body(color: AppColors.gray300),
                  prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    borderSide: const BorderSide(color: AppColors.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    borderSide: const BorderSide(color: AppColors.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a destination';
                  }
                  return null;
                },
              ),

              AppSpacing.gapHeightL,

              // Date range
              Text(
                'Travel Dates *',
                style: AppTextStyles.button(color: AppColors.gray900),
              ),
              AppSpacing.gapHeightS,
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: () => _selectStartDate(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: _buildDateField(
                      label: 'End Date',
                      date: _endDate,
                      onTap: () => _selectEndDate(context),
                    ),
                  ),
                ],
              ),

              AppSpacing.gapHeightL,

              // Description field
              Text(
                'Description',
                style: AppTextStyles.button(color: AppColors.gray900),
              ),
              AppSpacing.gapHeightS,
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: AppTextStyles.body(color: AppColors.gray900),
                decoration: InputDecoration(
                  hintText: 'Tell us about your trip plans...',
                  hintStyle: AppTextStyles.body(color: AppColors.gray300),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    borderSide: const BorderSide(color: AppColors.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    borderSide: const BorderSide(color: AppColors.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),

              AppSpacing.gapHeightXL,

              // Info card
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.info100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                  border: Border.all(color: AppColors.info300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info700, size: 24),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Text(
                        'You can add daily activities and details after creating the trip',
                        style: AppTextStyles.bodySmall(color: AppColors.info700),
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.gapHeightXL,

              // Create/Save button
              PrimaryButton(
                text: isEditing ? 'Save Changes' : 'Create Trip',
                onPressed: _saveTrip,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption(color: AppColors.gray600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                      : 'Select date',
                  style: date != null
                      ? AppTextStyles.button(color: AppColors.gray900)
                      : AppTextStyles.button(color: AppColors.gray400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.gray900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, clear it
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.gray900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _saveTrip() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select travel dates'),
          backgroundColor: AppColors.error500,
        ),
      );
      return;
    }

    // TODO: Save to state management/database
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(widget.itinerary != null
                ? 'Trip updated successfully!'
                : 'Trip created successfully!'),
          ],
        ),
        backgroundColor: AppColors.success500,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
