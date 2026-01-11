import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/recurrence_rule.dart';
import '../../models/task_template.dart';
import '../../providers/household_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/supabase_service.dart';

class QuickSetupScreen extends StatefulWidget {
  const QuickSetupScreen({super.key});

  @override
  State<QuickSetupScreen> createState() => _QuickSetupScreenState();
}

class _QuickSetupScreenState extends State<QuickSetupScreen> {
  // Quiz state
  int _currentStep = 0;
  bool? _hasPets;
  bool? _hasChildren;
  final List<String> _petNames = [];
  final List<String> _childrenNames = [];
  final _nameController = TextEditingController();

  // Template state
  List<TaskTemplate> _templates = [];
  final Map<String, _EditableTask> _selectedTasks = {};
  bool _isLoading = false;
  bool _isCreating = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() => _currentStep++);
    if (_currentStep == 4) {
      _loadTemplates();
    }
  }

  void _addName(List<String> list) {
    final name = _nameController.text.trim();
    if (name.isNotEmpty && !list.contains(name)) {
      setState(() {
        list.add(name);
        _nameController.clear();
      });
    }
  }

  void _removeName(List<String> list, String name) {
    setState(() => list.remove(name));
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);

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
      setState(() {
        _error = 'Failed to load templates';
        _isLoading = false;
      });
    }
  }

  List<TaskTemplate> get _filteredTemplates {
    return _templates.where((t) {
      // Hide pet templates if no pets
      if (t.category == 'pet' && (_hasPets != true || _petNames.isEmpty)) {
        return false;
      }
      // Hide children templates if no children
      if (t.category == 'children' && (_hasChildren != true || _childrenNames.isEmpty)) {
        return false;
      }
      return true;
    }).toList();
  }

  Map<String, List<TaskTemplate>> get _templatesByCategory {
    final map = <String, List<TaskTemplate>>{};
    for (final template in _filteredTemplates) {
      map.putIfAbsent(template.category, () => []).add(template);
    }
    // Sort templates within each category by frequency
    for (final templates in map.values) {
      templates.sort((a, b) {
        final orderA = _getFrequencyOrder(a.suggestedRecurrence);
        final orderB = _getFrequencyOrder(b.suggestedRecurrence);
        return orderA.compareTo(orderB);
      });
    }
    return map;
  }

  int _getFrequencyOrder(Map<String, dynamic>? recurrence) {
    if (recurrence == null) return 99;
    final frequency = recurrence['frequency'] as String?;
    switch (frequency) {
      case 'daily':
        return 0;
      case 'weekly':
        return 1;
      case 'monthly':
        return 2;
      case 'yearly':
        return 3;
      default:
        return 99;
    }
  }

  void _toggleTemplate(TaskTemplate template) {
    setState(() {
      final key = _getTaskKey(template);
      if (_selectedTasks.containsKey(key)) {
        _selectedTasks.remove(key);
      } else {
        // Create editable task with name substitution
        String title = template.title;
        String description = template.description ?? '';

        // For pet templates, create one task per pet
        if (template.needsPetName) {
          for (final petName in _petNames) {
            final petKey = '${template.id}_pet_$petName';
            _selectedTasks[petKey] = _EditableTask(
              templateId: template.id,
              title: title.replaceAll('{pet_name}', petName),
              description: description.replaceAll('{pet_name}', petName),
              recurrence: template.suggestedRecurrence,
            );
          }
        }
        // For children templates, create one task per child
        else if (template.needsChildName) {
          for (final childName in _childrenNames) {
            final childKey = '${template.id}_child_$childName';
            _selectedTasks[childKey] = _EditableTask(
              templateId: template.id,
              title: title.replaceAll('{child_name}', childName),
              description: description.replaceAll('{child_name}', childName),
              recurrence: template.suggestedRecurrence,
            );
          }
        }
        // Regular template
        else {
          _selectedTasks[key] = _EditableTask(
            templateId: template.id,
            title: title,
            description: description,
            recurrence: template.suggestedRecurrence,
          );
        }
      }
    });
  }

  String _getTaskKey(TaskTemplate template) {
    return template.id;
  }

  bool _isTemplateSelected(TaskTemplate template) {
    if (template.needsPetName) {
      return _petNames.any((name) => _selectedTasks.containsKey('${template.id}_pet_$name'));
    }
    if (template.needsChildName) {
      return _childrenNames.any((name) => _selectedTasks.containsKey('${template.id}_child_$name'));
    }
    return _selectedTasks.containsKey(template.id);
  }

  void _selectAllInCategory(String category) {
    setState(() {
      final categoryTemplates = _templatesByCategory[category] ?? [];
      final allSelected = categoryTemplates.every(_isTemplateSelected);

      if (allSelected) {
        // Deselect all in category
        for (final t in categoryTemplates) {
          if (t.needsPetName) {
            for (final name in _petNames) {
              _selectedTasks.remove('${t.id}_pet_$name');
            }
          } else if (t.needsChildName) {
            for (final name in _childrenNames) {
              _selectedTasks.remove('${t.id}_child_$name');
            }
          } else {
            _selectedTasks.remove(t.id);
          }
        }
      } else {
        // Select all in category
        for (final t in categoryTemplates) {
          _toggleTemplate(t);
        }
      }
    });
  }

  void _editTask(String key, _EditableTask task) async {
    final result = await showDialog<_EditableTask>(
      context: context,
      builder: (context) => _EditTaskDialog(task: task),
    );

    if (result != null) {
      setState(() {
        _selectedTasks[key] = result;
      });
    }
  }

  Future<void> _createTasks() async {
    if (_selectedTasks.isEmpty) {
      context.go('/home');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final householdId = context.read<HouseholdProvider>().currentHousehold?.id;
      if (householdId == null) return;

      final taskProvider = context.read<TaskProvider>();

      for (final task in _selectedTasks.values) {
        RecurrenceRule? recurrence;
        if (task.recurrence != null) {
          recurrence = RecurrenceRule.fromJson(task.recurrence!);
        }

        await taskProvider.createTask(
          householdId: householdId,
          title: task.title,
          description: task.description.isNotEmpty ? task.description : null,
          recurrenceRule: recurrence,
        );
      }

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to create tasks';
        _isCreating = false;
      });
    }
  }

  void _skip() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep < 4 ? 'Quick Setup' : 'Choose Tasks'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case 0:
        return _buildPetsQuestion();
      case 1:
        return _buildPetNamesEntry();
      case 2:
        return _buildChildrenQuestion();
      case 3:
        return _buildChildrenNamesEntry();
      case 4:
        return _buildTemplateSelection();
      case 5:
        return _buildReviewTasks();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget? _buildBottomBar() {
    if (_currentStep < 4) return null;
    if (_isLoading || _error != null) return null;

    if (_currentStep == 4) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: FilledButton(
            onPressed: _selectedTasks.isEmpty
                ? _skip
                : () => setState(() => _currentStep = 5),
            child: Text(
              _selectedTasks.isEmpty
                  ? 'Continue without tasks'
                  : 'Review ${_selectedTasks.length} task${_selectedTasks.length == 1 ? '' : 's'}',
            ),
          ),
        ),
      );
    }

    if (_currentStep == 5) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 4),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _isCreating ? null : _createTasks,
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Create ${_selectedTasks.length} tasks'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return null;
  }

  Widget _buildPetsQuestion() {
    return _buildQuestionCard(
      icon: Icons.pets,
      iconColor: Colors.pink,
      question: 'Do you have any pets?',
      subtitle: 'We\'ll suggest pet care tasks for you',
      options: [
        _QuizOption(
          label: 'Yes, I have pets',
          icon: Icons.check_circle,
          onTap: () {
            setState(() => _hasPets = true);
            _nextStep();
          },
        ),
        _QuizOption(
          label: 'No pets',
          icon: Icons.cancel,
          onTap: () {
            setState(() {
              _hasPets = false;
              _currentStep = 2; // Skip pet names
            });
          },
        ),
      ],
    );
  }

  Widget _buildPetNamesEntry() {
    return _buildNameEntryCard(
      icon: Icons.pets,
      iconColor: Colors.pink,
      question: 'What are your pets\' names?',
      hint: 'e.g., Max, Bella, Charlie',
      names: _petNames,
      onAdd: () => _addName(_petNames),
      onRemove: (name) => _removeName(_petNames, name),
      onContinue: () {
        if (_petNames.isNotEmpty) {
          _nextStep();
        }
      },
      canContinue: _petNames.isNotEmpty,
    );
  }

  Widget _buildChildrenQuestion() {
    return _buildQuestionCard(
      icon: Icons.child_care,
      iconColor: Colors.purple,
      question: 'Do you have any children?',
      subtitle: 'We\'ll suggest kid-related tasks for you',
      options: [
        _QuizOption(
          label: 'Yes, I have children',
          icon: Icons.check_circle,
          onTap: () {
            setState(() => _hasChildren = true);
            _nextStep();
          },
        ),
        _QuizOption(
          label: 'No children',
          icon: Icons.cancel,
          onTap: () {
            setState(() {
              _hasChildren = false;
              _currentStep = 4; // Skip to templates
            });
            _loadTemplates();
          },
        ),
      ],
    );
  }

  Widget _buildChildrenNamesEntry() {
    return _buildNameEntryCard(
      icon: Icons.child_care,
      iconColor: Colors.purple,
      question: 'What are your children\'s names?',
      hint: 'e.g., Emma, Liam, Sophie',
      names: _childrenNames,
      onAdd: () => _addName(_childrenNames),
      onRemove: (name) => _removeName(_childrenNames, name),
      onContinue: () {
        if (_childrenNames.isNotEmpty) {
          _nextStep();
        }
      },
      canContinue: _childrenNames.isNotEmpty,
    );
  }

  Widget _buildQuestionCard({
    required IconData icon,
    required Color iconColor,
    required String question,
    required String subtitle,
    required List<_QuizOption> options,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              question,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ...options.map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: opt.onTap,
                      icon: Icon(opt.icon),
                      label: Text(opt.label),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildNameEntryCard({
    required IconData icon,
    required Color iconColor,
    required String question,
    required String hint,
    required List<String> names,
    required VoidCallback onAdd,
    required void Function(String) onRemove,
    required VoidCallback onContinue,
    required bool canContinue,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              question,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: hint,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => onAdd(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(80, 50),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (names.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: names
                    .map((name) => Chip(
                          label: Text(name),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () => onRemove(name),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canContinue ? onContinue : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSelection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red[700])),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadTemplates,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select tasks to add to your household',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can change the frequency of tasks on the next page',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: _templatesByCategory.entries.map((entry) {
              final category = entry.key;
              final templates = entry.value;
              final allSelected = templates.every(_isTemplateSelected);
              final someSelected = templates.any(_isTemplateSelected);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _selectAllInCategory(category),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            templates.first.categoryIconPath,
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              AppColors.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              templates.first.categoryDisplayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Checkbox(
                            value: allSelected
                                ? true
                                : (someSelected ? null : false),
                            tristate: true,
                            onChanged: (_) => _selectAllInCategory(category),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...templates.map((template) {
                    final isSelected = _isTemplateSelected(template);
                    String displayTitle = template.title;

                    // Show preview with first name
                    if (template.needsPetName && _petNames.isNotEmpty) {
                      displayTitle = template.title.replaceAll(
                        '{pet_name}',
                        _petNames.length == 1
                            ? _petNames.first
                            : '${_petNames.first} (+${_petNames.length - 1})',
                      );
                    }
                    if (template.needsChildName && _childrenNames.isNotEmpty) {
                      displayTitle = template.title.replaceAll(
                        '{child_name}',
                        _childrenNames.length == 1
                            ? _childrenNames.first
                            : '${_childrenNames.first} (+${_childrenNames.length - 1})',
                      );
                    }

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => _toggleTemplate(template),
                      title: Text(displayTitle),
                      subtitle: template.description != null
                          ? Text(
                              template.description!.replaceAll('{pet_name}', _petNames.isNotEmpty ? _petNames.first : '').replaceAll('{child_name}', _childrenNames.isNotEmpty ? _childrenNames.first : ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      secondary: _buildRecurrenceChip(template.suggestedRecurrence),
                      controlAffinity: ListTileControlAffinity.trailing,
                    );
                  }),
                  const Divider(),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewTasks() {
    final sortedTasks = _selectedTasks.entries.toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                Icons.edit_note,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Review and edit your tasks before creating them',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: sortedTasks.length,
            itemBuilder: (context, index) {
              final entry = sortedTasks[index];
              final task = entry.value;

              return Card(
                key: ValueKey(entry.key),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(task.title),
                  subtitle: task.description.isNotEmpty
                      ? Text(
                          task.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (task.recurrence != null && _buildRecurrenceChip(task.recurrence) != null)
                        _buildRecurrenceChip(task.recurrence)!,
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editTask(entry.key, task),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() => _selectedTasks.remove(entry.key));
                        },
                      ),
                    ],
                  ),
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

    String label;
    switch (frequency) {
      case 'daily':
        label = 'Daily';
      case 'weekly':
        label = 'Weekly';
      case 'monthly':
        label = 'Monthly';
      case 'yearly':
        label = 'Yearly';
      default:
        label = frequency;
    }

    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }
}

class _QuizOption {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  _QuizOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _EditableTask {
  final String templateId;
  String title;
  String description;
  Map<String, dynamic>? recurrence;

  _EditableTask({
    required this.templateId,
    required this.title,
    required this.description,
    this.recurrence,
  });

  _EditableTask copyWith({
    String? title,
    String? description,
    Map<String, dynamic>? recurrence,
  }) {
    return _EditableTask(
      templateId: templateId,
      title: title ?? this.title,
      description: description ?? this.description,
      recurrence: recurrence ?? this.recurrence,
    );
  }
}

class _EditTaskDialog extends StatefulWidget {
  final _EditableTask task;

  const _EditTaskDialog({required this.task});

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String? _selectedFrequency;

  static const _frequencies = [
    ('daily', 'Daily'),
    ('weekly', 'Weekly'),
    ('monthly', 'Monthly'),
    ('yearly', 'Yearly'),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _selectedFrequency = widget.task.recurrence?['frequency'] as String?;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Frequency',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._frequencies.map((f) => ChoiceChip(
                      label: Text(f.$2),
                      selected: _selectedFrequency == f.$1,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFrequency = selected ? f.$1 : null;
                        });
                      },
                    )),
                ChoiceChip(
                  label: const Text('One-time'),
                  selected: _selectedFrequency == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFrequency = null;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Map<String, dynamic>? newRecurrence;
            if (_selectedFrequency != null) {
              newRecurrence = {'frequency': _selectedFrequency};
            }
            Navigator.pop(
              context,
              _EditableTask(
                templateId: widget.task.templateId,
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                recurrence: newRecurrence,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
