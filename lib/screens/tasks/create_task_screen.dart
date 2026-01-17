import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/recurrence_rule.dart';
import '../../models/task.dart';
import '../../models/task_template.dart';
import '../../providers/household_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/tasks/recurrence_picker.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskPriority _priority = TaskPriority.normal;
  DateTime? _dueDate;
  DuePeriod? _duePeriod;
  String? _assignedTo;
  RecurrenceRule? _recurrenceRule;
  String? _category;
  bool _isSubmitting = false;

  // Available categories
  static const List<String> _categories = [
    'kitchen',
    'bathroom',
    'living',
    'outdoor',
    'pet',
    'laundry',
    'grocery',
    'maintenance',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showTemplates() async {
    final template = await showModalBottomSheet<TaskTemplate>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _TemplatePickerSheet(),
    );

    if (template != null && mounted) {
      String title = template.title;
      String description = template.description ?? '';

      // Check if this is a pet template that needs name customization
      if (template.needsPetName) {
        final petName = await _askForName(
          title: "What's your pet's name?",
          hint: 'e.g., Max, Bella, Charlie',
          icon: Icons.pets,
        );
        if (petName == null || petName.isEmpty) return; // User cancelled
        title = title.replaceAll('{pet_name}', petName);
        description = description.replaceAll('{pet_name}', petName);
      }

      // Check if this is a child template that needs name customization
      if (template.needsChildName) {
        final childName = await _askForName(
          title: "What's your child's name?",
          hint: 'e.g., Emma, Liam, Sophie',
          icon: Icons.child_care,
        );
        if (childName == null || childName.isEmpty) return; // User cancelled
        title = title.replaceAll('{child_name}', childName);
        description = description.replaceAll('{child_name}', childName);
      }

      setState(() {
        _titleController.text = title;
        _descriptionController.text = description;
        _category = template.category;
        if (template.suggestedRecurrence != null) {
          _recurrenceRule = RecurrenceRule.fromJson(template.suggestedRecurrence!);
        }
      });
    }
  }

  Future<String?> _askForName({
    required String title,
    required String hint,
    required IconData icon,
  }) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
          ),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final householdId =
        context.read<HouseholdProvider>().currentHousehold?.id;
    if (householdId == null) return;

    setState(() => _isSubmitting = true);

    final success = await context.read<TaskProvider>().createTask(
          householdId: householdId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          assignedTo: _assignedTo,
          priority: _priority,
          dueDate: _dueDate,
          duePeriod: _duePeriod,
          recurrenceRule: _recurrenceRule,
          category: _category,
        );

    if (mounted) {
      if (success) {
        context.pop();
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create task')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<HouseholdProvider>().members;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Task'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.md),
          children: [
            // Template picker button
            OutlinedButton.icon(
              onPressed: _showTemplates,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Choose from templates'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.fromHeight(AppSpacing.xxl),
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Title
            TextFormField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Task title',
                hintText: 'What needs to be done?',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
            ),
            SizedBox(height: AppSpacing.md),

            // Description
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add more details...',
                alignLabelWithHint: true,
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Category
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _categories.map((cat) {
                final isSelected = _category == cat;
                final color = _getCategoryColor(cat);
                final displayName = cat[0].toUpperCase() + cat.substring(1);
                return FilterChip(
                  avatar: Icon(
                    _getCategoryIcon(cat),
                    size: 18,
                    color: isSelected ? Colors.white : color,
                  ),
                  label: Text(displayName),
                  selected: isSelected,
                  selectedColor: color,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                  ),
                  onSelected: (selected) {
                    setState(() => _category = selected ? cat : null);
                  },
                );
              }).toList(),
            ),
            SizedBox(height: AppSpacing.lg),

            // Due Date Section
            Text(
              'Due Date',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: AppSpacing.sm),

            // Quick date options
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildDateChip('Today', DateTime.now()),
                _buildDateChip(
                  'Tomorrow',
                  DateTime.now().add(const Duration(days: 1)),
                ),
                _buildDateChip(
                  'Next Week',
                  DateTime.now().add(const Duration(days: 7)),
                ),
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_dueDate != null &&
                          !_isQuickDate(_dueDate!)
                      ? DateFormat('MMM d').format(_dueDate!)
                      : 'Pick date'),
                  onPressed: _selectDueDate,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),

            // Time of day (only show if due date is set)
            if (_dueDate != null) ...[
              Text(
                'Time of Day',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  _buildPeriodChip('Morning', DuePeriod.morning),
                  _buildPeriodChip('Afternoon', DuePeriod.afternoon),
                  _buildPeriodChip('Evening', DuePeriod.evening),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
            ],

            // Recurrence
            Text(
              'Repeat',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: AppSpacing.sm),
            RecurrencePicker(
              initialValue: _recurrenceRule,
              onChanged: (rule) {
                setState(() => _recurrenceRule = rule);
              },
            ),
            SizedBox(height: AppSpacing.lg),

            // Priority
            Text(
              'Priority',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: AppSpacing.sm),
            SegmentedButton<TaskPriority>(
              segments: const [
                ButtonSegment(
                  value: TaskPriority.low,
                  label: Text('Low'),
                ),
                ButtonSegment(
                  value: TaskPriority.normal,
                  label: Text('Normal'),
                ),
                ButtonSegment(
                  value: TaskPriority.high,
                  label: Text('High'),
                ),
              ],
              selected: {_priority},
              onSelectionChanged: (selected) {
                setState(() => _priority = selected.first);
              },
            ),
            SizedBox(height: AppSpacing.lg),

            // Assign to
            Text(
              'Assign to',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String?>(
              initialValue: _assignedTo,
              decoration: const InputDecoration(
                hintText: 'Unassigned',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Unassigned'),
                ),
                ...members.map((m) => DropdownMenuItem(
                      value: m.userId,
                      child: Text(m.displayName ?? 'Unknown'),
                    )),
              ],
              onChanged: (value) {
                setState(() => _assignedTo = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, DateTime date) {
    final isSelected = _dueDate != null &&
        _dueDate!.year == date.year &&
        _dueDate!.month == date.month &&
        _dueDate!.day == date.day;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _dueDate = selected ? date : null;
          if (!selected) _duePeriod = null;
        });
      },
    );
  }

  Widget _buildPeriodChip(String label, DuePeriod period) {
    return FilterChip(
      label: Text(label),
      selected: _duePeriod == period,
      onSelected: (selected) {
        setState(() => _duePeriod = selected ? period : null);
      },
    );
  }

  bool _isQuickDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));
    final d = DateTime(date.year, date.month, date.day);

    return d == today || d == tomorrow || d == nextWeek;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'kitchen':
        return Icons.kitchen;
      case 'bathroom':
        return Icons.bathtub;
      case 'living':
        return Icons.weekend;
      case 'outdoor':
        return Icons.park;
      case 'pet':
        return Icons.pets;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'grocery':
        return Icons.shopping_cart;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'kitchen':
        return AppColors.kitchen;
      case 'bathroom':
        return AppColors.bathroom;
      case 'living':
        return AppColors.living;
      case 'outdoor':
        return AppColors.outdoor;
      case 'pet':
        return AppColors.pet;
      case 'laundry':
        return AppColors.laundry;
      case 'grocery':
        return AppColors.grocery;
      case 'maintenance':
        return AppColors.maintenance;
      default:
        return Colors.grey;
    }
  }
}

class _TemplatePickerSheet extends StatefulWidget {
  const _TemplatePickerSheet();

  @override
  State<_TemplatePickerSheet> createState() => _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends State<_TemplatePickerSheet> {
  List<TaskTemplate> _templates = [];
  bool _isLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final response = await SupabaseService.client
          .from('task_templates')
          .select()
          .eq('is_system', true)
          .order('category')
          .order('title');

      setState(() {
        _templates = (response as List)
            .map((json) => TaskTemplate.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<String> get _categories {
    return _templates.map((t) => t.category).toSet().toList();
  }

  List<TaskTemplate> get _filteredTemplates {
    if (_selectedCategory == null) return [];
    return _templates.where((t) => t.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: AppSpacing.md),
              width: 40,
              height: AppSpacing.xs,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Choose a template',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedCategory == null
                      ? _buildCategoryList()
                      : _buildTemplateList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final categoryInfo = {
      'kitchen': ('Kitchen', Icons.kitchen, Colors.orange),
      'bathroom': ('Bathroom', Icons.bathtub, Colors.blue),
      'living': ('Living Areas', Icons.weekend, Colors.green),
      'outdoor': ('Outdoor', Icons.park, Colors.teal),
      'pet': ('Pet Care', Icons.pets, Colors.pink),
      'children': ('Children', Icons.child_care, Colors.purple),
      'laundry': ('Laundry', Icons.local_laundry_service, Colors.indigo),
      'grocery': ('Grocery & Meals', Icons.shopping_cart, Colors.amber),
      'maintenance': ('Maintenance', Icons.build, Colors.brown),
      'admin': ('Finance & Admin', Icons.receipt_long, Colors.deepPurple),
    };

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: _categories.map((category) {
        final info = categoryInfo[category] ?? (category, Icons.list, Colors.grey);
        final count = _templates.where((t) => t.category == category).length;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (info.$3 as Color).withValues(alpha: 0.2),
              child: Icon(info.$2, color: info.$3 as Color),
            ),
            title: Text(info.$1),
            subtitle: Text('$count templates'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _selectedCategory = category),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTemplateList() {
    return Column(
      children: [
        // Back button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _selectedCategory = null),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              const Spacer(),
              Text(
                _filteredTemplates.first.categoryDisplayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              const SizedBox(width: 80), // Balance
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: _filteredTemplates.length,
            itemBuilder: (context, index) {
              final template = _filteredTemplates[index];
              return Card(
                key: ValueKey(template.id),
                child: ListTile(
                  title: Text(template.title),
                  subtitle: template.description != null
                      ? Text(
                          template.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: _buildRecurrenceChip(template.suggestedRecurrence),
                  onTap: () => Navigator.pop(context, template),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget? _buildRecurrenceChip(Map<String, dynamic>? recurrence) {
    if (recurrence == null) return null;
    final frequency = recurrence['frequency'] as String?;
    if (frequency == null) return null;

    return Chip(
      label: Text(
        frequency[0].toUpperCase() + frequency.substring(1),
        style: const TextStyle(fontSize: 11),
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
