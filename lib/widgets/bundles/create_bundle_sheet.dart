import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../providers/bundle_provider.dart';
import '../../providers/household_provider.dart';
import '../../services/supabase_service.dart';

/// Bottom sheet for creating a new task bundle.
class CreateBundleSheet extends StatefulWidget {
  const CreateBundleSheet({super.key});

  @override
  State<CreateBundleSheet> createState() => _CreateBundleSheetState();
}

class _CreateBundleSheetState extends State<CreateBundleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedIcon = 'list';
  String _selectedColor = '#009688';
  bool _isLoading = false;

  final _icons = [
    ('list', Icons.list),
    ('cleaning', Icons.cleaning_services),
    ('kitchen', Icons.kitchen),
    ('laundry', Icons.local_laundry_service),
    ('garden', Icons.yard),
    ('shopping', Icons.shopping_cart),
    ('pet', Icons.pets),
    ('car', Icons.directions_car),
    ('home', Icons.home),
    ('event', Icons.event),
  ];

  final _colors = [
    '#009688', // Teal
    '#F67280', // Rose
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#FF9800', // Orange
    '#9C27B0', // Purple
    '#E91E63', // Pink
    '#795548', // Brown
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createBundle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final householdId = context.read<HouseholdProvider>().currentHousehold?.id;
    final userId = SupabaseService.currentUser?.id;

    if (householdId == null || userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final bundle = await context.read<BundleProvider>().createBundle(
      householdId: householdId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
      createdBy: userId,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (bundle != null) {
        Navigator.pop(context, bundle);
      }
    }
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  IconData _getIconData(String iconName) {
    return _icons.firstWhere((i) => i.$1 == iconName, orElse: () => _icons.first).$2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),

                // Title
                Text(
                  'Create Bundle',
                  style: theme.textTheme.titleLarge,
                ),
                SizedBox(height: AppSpacing.md),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Bundle Name',
                    hintText: 'e.g., Morning Routine, Weekly Cleaning',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.md),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'What is this bundle for?',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                SizedBox(height: AppSpacing.md),

                // Icon picker
                Text(
                  'Icon',
                  style: theme.textTheme.titleSmall,
                ),
                SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _icons.map((icon) {
                    final isSelected = _selectedIcon == icon.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon.$1),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _parseColor(_selectedColor).withValues(alpha: 0.2)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: isSelected
                              ? Border.all(color: _parseColor(_selectedColor), width: 2)
                              : null,
                        ),
                        child: Icon(
                          icon.$2,
                          color: isSelected
                              ? _parseColor(_selectedColor)
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: AppSpacing.md),

                // Color picker
                Text(
                  'Color',
                  style: theme.textTheme.titleSmall,
                ),
                SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colors.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _parseColor(color),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _parseColor(color).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: AppSpacing.lg),

                // Preview
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _parseColor(_selectedColor).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: _parseColor(_selectedColor).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _parseColor(_selectedColor),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          _getIconData(_selectedIcon),
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text.isEmpty
                                  ? 'Bundle Name'
                                  : _nameController.text,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: _parseColor(_selectedColor),
                              ),
                            ),
                            Text(
                              '0 tasks',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Create button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _createBundle,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Bundle'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
