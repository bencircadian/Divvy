import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_theme.dart';
import '../../models/recurrence_rule.dart';
import '../../models/task.dart';
import '../../models/task_history.dart';
import '../../models/task_note.dart';
import '../../providers/household_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/tasks/history_timeline.dart';
import '../../widgets/tasks/note_input.dart';
import '../../widgets/tasks/note_tile.dart';
import '../../widgets/tasks/recurrence_picker.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskPriority _priority = TaskPriority.normal;
  DateTime? _dueDate;
  DuePeriod? _duePeriod;
  String? _assignedTo;
  RecurrenceRule? _recurrenceRule;
  bool _clearRecurrence = false;

  // Notes and history
  List<TaskNote> _notes = [];
  List<TaskHistory> _history = [];
  bool _isLoadingNotes = false;
  bool _isAddingNote = false;
  bool _showHistory = false;

  // Cover image
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingCover = false;
  String? _signedCoverUrl;
  bool _isLoadingCoverUrl = false;

  @override
  void initState() {
    super.initState();
    _loadNotesAndHistory();
    _loadCoverImageUrl();
  }

  Future<void> _loadCoverImageUrl() async {
    final task = _getTask();
    if (task?.coverImageUrl == null || task!.coverImageUrl!.isEmpty) {
      setState(() {
        _signedCoverUrl = null;
        _isLoadingCoverUrl = false;
      });
      return;
    }

    // Check if it's already a full URL (legacy data) or a file path
    if (task.coverImageUrl!.startsWith('http')) {
      setState(() => _signedCoverUrl = task.coverImageUrl);
      return;
    }

    setState(() => _isLoadingCoverUrl = true);

    final signedUrl = await context.read<TaskProvider>().getSignedCoverUrl(task.coverImageUrl!);

    if (mounted) {
      setState(() {
        _signedCoverUrl = signedUrl;
        _isLoadingCoverUrl = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadNotesAndHistory() async {
    setState(() => _isLoadingNotes = true);

    final taskProvider = context.read<TaskProvider>();
    final notes = await taskProvider.loadNotes(widget.taskId);
    final history = await taskProvider.loadHistory(widget.taskId);

    if (mounted) {
      setState(() {
        _notes = notes;
        _history = history;
        _isLoadingNotes = false;
      });
    }
  }

  Future<void> _pickAndUploadCoverImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingCover = true);

      final taskProvider = context.read<TaskProvider>();
      await taskProvider.uploadCoverImage(widget.taskId, image);

      if (mounted) {
        setState(() => _isUploadingCover = false);
        // Reload the signed URL for the new image
        await _loadCoverImageUrl();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingCover = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _removeCoverImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Cover'),
        content: const Text('Are you sure you want to remove the cover image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<TaskProvider>().removeCoverImage(widget.taskId);
      setState(() => _signedCoverUrl = null);
    }
  }

  Future<void> _addNote(String content) async {
    setState(() => _isAddingNote = true);

    final success = await context.read<TaskProvider>().addNote(
      taskId: widget.taskId,
      content: content,
    );

    if (success && mounted) {
      await _loadNotesAndHistory();
    }

    if (mounted) {
      setState(() => _isAddingNote = false);
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<TaskProvider>().deleteNote(noteId);
      if (success) {
        await _loadNotesAndHistory();
      }
    }
  }

  void _initEditState(Task task) {
    _titleController.text = task.title;
    _descriptionController.text = task.description ?? '';
    _priority = task.priority;
    _dueDate = task.dueDate;
    _duePeriod = task.duePeriod;
    _assignedTo = task.assignedTo;
    _recurrenceRule = task.recurrenceRule;
    _clearRecurrence = false;
  }

  void _startEditing() {
    final task = _getTask();
    if (task != null) {
      _initEditState(task);
      setState(() => _isEditing = true);
    }
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _saveChanges() async {
    final task = _getTask();
    if (task == null || !_formKey.currentState!.validate()) return;

    final success = await context.read<TaskProvider>().updateTask(
          taskId: task.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          priority: _priority,
          dueDate: _dueDate,
          duePeriod: _duePeriod,
          assignedTo: _assignedTo,
          recurrenceRule: _recurrenceRule,
          clearRecurrence: _clearRecurrence,
        );

    if (mounted && success) {
      setState(() => _isEditing = false);
      // Reload to get updated data
      final householdId = context.read<HouseholdProvider>().currentHousehold?.id;
      if (householdId != null) {
        context.read<TaskProvider>().loadTasks(householdId);
      }
    }
  }

  Future<void> _deleteTask() async {
    final task = _getTask();
    if (task == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<TaskProvider>().deleteTask(task.id);
      if (success && mounted) {
        context.pop();
      }
    }
  }

  void _toggleComplete() {
    final task = _getTask();
    if (task != null) {
      context.read<TaskProvider>().toggleTaskComplete(task);
    }
  }

  void _goBack() {
    context.pop();
  }

  Task? _getTask() {
    final tasks = context.read<TaskProvider>().tasks;
    return tasks.where((t) => t.id == widget.taskId).firstOrNull;
  }

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    // Show loading if tasks are being loaded
    if (taskProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
          title: const Text('Task'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final task = taskProvider.tasks.where((t) => t.id == widget.taskId).firstOrNull;

    if (task == null) {
      debugPrint('Task not found. TaskId: ${widget.taskId}, Tasks count: ${taskProvider.tasks.length}');
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
          title: const Text('Task'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Task not found'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _goBack,
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        title: Text(_isEditing ? 'Edit Task' : 'Task Details'),
        actions: _buildAppBarActions(),
      ),
      body: _isEditing ? _buildEditView(task) : _buildDetailView(task),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isEditing) {
      return [
        TextButton(
          onPressed: _cancelEditing,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveChanges,
          child: const Text('Save'),
        ),
      ];
    } else {
      return [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _startEditing,
          tooltip: 'Edit',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _deleteTask,
          tooltip: 'Delete',
        ),
      ];
    }
  }

  Widget _buildDetailView(Task task) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image section
          _buildCoverImageSection(task),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Status and complete button
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: task.isCompleted ? Colors.green : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.isCompleted ? 'Completed' : 'Pending',
                            style: theme.textTheme.titleMedium,
                          ),
                          if (task.completedAt != null)
                            Text(
                              'Completed ${DateFormat('MMM d, yyyy').format(task.completedAt!)}',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: _toggleComplete,
                      child: Text(task.isCompleted ? 'Mark Pending' : 'Mark Complete'),
                    ),
                  ),
                  if (!task.isCompleted) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: _buildTakeOwnershipButton(task),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            task.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          if (task.description != null && task.description!.isNotEmpty) ...[
            Text(
              task.description!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Divider(),
          const SizedBox(height: 8),

          // Due date
          _buildDetailRow(
            icon: Icons.schedule,
            label: 'Due',
            value: task.dueDate != null
                ? _formatDueDate(task.dueDate!, task.duePeriod)
                : 'No due date',
            isOverdue: task.isOverdue,
          ),

          // Priority
          _buildDetailRow(
            icon: Icons.flag_outlined,
            label: 'Priority',
            value: task.priority.name[0].toUpperCase() + task.priority.name.substring(1),
            valueColor: task.priority == TaskPriority.high
                ? Colors.red
                : task.priority == TaskPriority.low
                    ? Colors.grey
                    : null,
          ),

          // Assigned to
          _buildDetailRow(
            icon: Icons.person_outline,
            label: 'Assigned to',
            value: task.assignedToName ?? 'Unassigned',
          ),

          // Created by
          _buildDetailRow(
            icon: Icons.create_outlined,
            label: 'Created by',
            value: task.createdByName ?? 'Unknown',
          ),

          // Created at
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Created',
            value: DateFormat('MMM d, yyyy').format(task.createdAt),
          ),

          const SizedBox(height: 24),
          const Divider(),

          // Notes section
          _buildNotesSection(),

          const SizedBox(height: 24),
          const Divider(),

          // History section
          _buildHistorySection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImageSection(Task task) {
    final hasCover = _signedCoverUrl != null && _signedCoverUrl!.isNotEmpty;

    return GestureDetector(
      onTap: _pickAndUploadCoverImage,
      child: Container(
        width: double.infinity,
        height: hasCover ? 200 : 120,
        decoration: BoxDecoration(
          color: hasCover ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
          image: hasCover
              ? DecorationImage(
                  image: NetworkImage(_signedCoverUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Gradient overlay for readability when there's an image
            if (hasCover)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),

            // Loading/Upload indicator
            if (_isUploadingCover || _isLoadingCoverUrl)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),

            // Add/Change cover button
            if (!_isUploadingCover && !_isLoadingCoverUrl)
              Positioned(
                bottom: 12,
                right: 12,
                child: Row(
                  children: [
                    if (hasCover)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: _removeCoverImage,
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete, color: Colors.white, size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    'Remove',
                                    style: TextStyle(color: Colors.white, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Material(
                      color: hasCover
                          ? Colors.black.withValues(alpha: 0.6)
                          : AppColors.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: _pickAndUploadCoverImage,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasCover ? Icons.edit : Icons.add_photo_alternate,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasCover ? 'Change' : 'Add Cover',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Empty state hint
            if (!hasCover && !_isUploadingCover && !_isLoadingCoverUrl)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to add a cover photo',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    final currentUserId = SupabaseService.currentUser?.id;
    final householdMembers = context.watch<HouseholdProvider>().members;

    // Convert to MemberInfo list for the note input
    final memberInfoList = householdMembers
        .map((m) => MemberInfo(
              id: m.userId,
              displayName: m.displayName ?? 'Unknown',
            ))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notes, size: 20),
            const SizedBox(width: 8),
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            Text(
              '(${_notes.length})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Note input
        NoteInput(
          onSubmit: _addNote,
          isLoading: _isAddingNote,
          members: memberInfoList,
        ),
        const SizedBox(height: 12),

        // Notes list
        if (_isLoadingNotes)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_notes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No notes yet. Add one above!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _notes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final note = _notes[index];
              return NoteTile(
                note: note,
                canDelete: note.userId == currentUserId,
                onDelete: () => _deleteNote(note.id),
              );
            },
          ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showHistory = !_showHistory),
          child: Row(
            children: [
              const Icon(Icons.history, size: 20),
              const SizedBox(width: 8),
              Text(
                'Activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Icon(
                _showHistory ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        if (_showHistory) ...[
          const SizedBox(height: 12),
          HistoryTimeline(history: _history),
        ],
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isOverdue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isOverdue ? Colors.red : Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: isOverdue ? Colors.red : valueColor,
              fontWeight: isOverdue ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeOwnershipButton(Task task) {
    final currentUserId = SupabaseService.currentUser?.id;
    final isOwnedByMe = task.assignedTo == currentUserId;
    final taskProvider = context.read<TaskProvider>();

    if (isOwnedByMe) {
      return OutlinedButton.icon(
        onPressed: () => taskProvider.releaseOwnership(task.id),
        icon: const Icon(Icons.person_off),
        label: const Text('Release task'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange[700],
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: () => taskProvider.takeOwnership(task.id),
        icon: const Icon(Icons.person_add),
        label: const Text('I\'ll do this'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Widget _buildEditView(Task task) {
    final members = context.watch<HouseholdProvider>().members;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Task title',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Due Date
            Text(
              'Due Date',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDateChip('Today', DateTime.now()),
                _buildDateChip(
                  'Tomorrow',
                  DateTime.now().add(const Duration(days: 1)),
                ),
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_dueDate != null
                      ? DateFormat('MMM d').format(_dueDate!)
                      : 'Pick date'),
                  onPressed: _selectDueDate,
                ),
                if (_dueDate != null)
                  ActionChip(
                    avatar: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear'),
                    onPressed: () {
                      setState(() {
                        _dueDate = null;
                        _duePeriod = null;
                      });
                    },
                  ),
              ],
            ),

            // Time of day
            if (_dueDate != null) ...[
              const SizedBox(height: 16),
              Text(
                'Time of Day',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildPeriodChip('Morning', DuePeriod.morning),
                  _buildPeriodChip('Afternoon', DuePeriod.afternoon),
                  _buildPeriodChip('Evening', DuePeriod.evening),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Priority
            Text(
              'Priority',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<TaskPriority>(
              segments: const [
                ButtonSegment(value: TaskPriority.low, label: Text('Low')),
                ButtonSegment(value: TaskPriority.normal, label: Text('Normal')),
                ButtonSegment(value: TaskPriority.high, label: Text('High')),
              ],
              selected: {_priority},
              onSelectionChanged: (selected) {
                setState(() => _priority = selected.first);
              },
            ),
            const SizedBox(height: 24),

            // Assign to
            Text(
              'Assign to',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _assignedTo,
              decoration: const InputDecoration(
                hintText: 'Unassigned',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Unassigned')),
                ...members.map((m) => DropdownMenuItem(
                      value: m.userId,
                      child: Text(m.displayName ?? 'Unknown'),
                    )),
              ],
              onChanged: (value) {
                setState(() => _assignedTo = value);
              },
            ),
            const SizedBox(height: 24),

            // Recurrence
            Text(
              'Recurrence',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            RecurrencePicker(
              initialValue: _recurrenceRule,
              onChanged: (rule) {
                setState(() {
                  _recurrenceRule = rule;
                  _clearRecurrence = rule == null;
                });
              },
            ),
            const SizedBox(height: 32),
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

  String _formatDueDate(DateTime dueDate, DuePeriod? period) {
    final dateStr = DateFormat('EEEE, MMM d').format(dueDate);
    if (period != null) {
      return '$dateStr (${period.name})';
    }
    return dateStr;
  }
}
