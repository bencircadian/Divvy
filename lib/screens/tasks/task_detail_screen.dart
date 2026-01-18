import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_theme.dart';
import '../../models/appreciation.dart';
import '../../models/recurrence_rule.dart';
import '../../models/schedule_suggestion.dart';
import '../../models/task.dart';
import '../../models/task_contributor.dart';
import '../../models/task_history.dart';
import '../../models/task_note.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/appreciation_service.dart';
import '../../services/smart_recurrence_service.dart';
import '../../services/supabase_service.dart';
import '../../services/task_contributor_service.dart';
import '../../widgets/bundles/add_to_bundle_sheet.dart';
import '../../widgets/common/appreciation_button.dart';
import '../../widgets/tasks/claim_credit_sheet.dart';
import '../../widgets/tasks/contributor_chips.dart';
import '../../widgets/tasks/history_timeline.dart';
import '../../widgets/tasks/note_input.dart';
import '../../widgets/tasks/note_tile.dart';
import '../../widgets/tasks/recurrence_picker.dart';
import '../../widgets/common/undo_completion_snackbar.dart';
import '../../widgets/tasks/schedule_suggestion_dialog.dart';
import '../../utils/category_utils.dart';
import '../../utils/date_utils.dart';

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
  String? _category;

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

  // Notes and history
  List<TaskNote> _notes = [];
  List<TaskHistory> _history = [];
  bool _isLoadingNotes = false;
  bool _isAddingNote = false;
  bool _showHistory = false;

  // Recurring task completion history
  List<Map<String, dynamic>> _recurringHistory = [];
  bool _isLoadingRecurringHistory = false;
  bool _showRecurringHistory = false;

  // Cover image
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingCover = false;
  String? _signedCoverUrl;
  bool _isLoadingCoverUrl = false;

  // Contributors (claim credit)
  List<TaskContributor> _contributors = [];
  late TaskContributorService _contributorService;

  // Appreciation
  late AppreciationService _appreciationService;
  Appreciation? _myAppreciation;
  int _appreciationCount = 0;
  bool _isAppreciationLoading = false;

  // Schedule suggestion
  late SmartRecurrenceService _recurrenceService;
  ScheduleSuggestion? _scheduleSuggestion;

  @override
  void initState() {
    super.initState();
    _contributorService = TaskContributorService(SupabaseService.client);
    _appreciationService = AppreciationService(SupabaseService.client);
    _recurrenceService = SmartRecurrenceService(SupabaseService.client);
    _loadNotesAndHistory();
    _loadCoverImageUrl();
    _loadContributors();
    _loadAppreciation();
    _loadScheduleSuggestion();
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

    // Load recurring history if applicable
    _loadRecurringHistory();
  }

  Future<void> _loadRecurringHistory() async {
    final task = _getTask();
    if (task == null || !task.isRecurring) return;

    setState(() => _isLoadingRecurringHistory = true);

    try {
      // Get the root parent ID - either this task's parent or this task itself
      final rootParentId = task.parentTaskId ?? task.id;

      // Query all completed tasks with this parent
      final response = await SupabaseService.client
          .from('tasks')
          .select('id, title, completed_at, completed_by, profiles:completed_by(display_name)')
          .or('parent_task_id.eq.$rootParentId,id.eq.$rootParentId')
          .eq('is_complete', true)
          .not('completed_at', 'is', null)
          .order('completed_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _recurringHistory = List<Map<String, dynamic>>.from(response);
          _isLoadingRecurringHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRecurringHistory = false);
      }
    }
  }

  Future<void> _loadContributors() async {
    final contributors = await _contributorService.getTaskContributors(widget.taskId);

    if (mounted) {
      setState(() {
        _contributors = contributors;
      });
    }
  }

  Future<void> _loadAppreciation() async {
    final currentUserId = SupabaseService.currentUser?.id;
    if (currentUserId == null) return;

    final appreciation = await _appreciationService.getAppreciation(
      taskId: widget.taskId,
      fromUserId: currentUserId,
    );

    final allAppreciations = await _appreciationService.getTaskAppreciations(widget.taskId);

    if (mounted) {
      setState(() {
        _myAppreciation = appreciation;
        _appreciationCount = allAppreciations.length;
      });
    }
  }

  Future<void> _sendAppreciation(String reactionType) async {
    final task = _getTask();
    if (task == null) return;

    final currentUserId = SupabaseService.currentUser?.id;
    final toUserId = task.completedBy;
    if (currentUserId == null || toUserId == null) return;

    // Don't allow appreciating yourself
    if (currentUserId == toUserId) return;

    setState(() => _isAppreciationLoading = true);

    final appreciation = await _appreciationService.sendAppreciation(
      taskId: task.id,
      fromUserId: currentUserId,
      toUserId: toUserId,
      reactionType: reactionType,
    );

    if (mounted) {
      setState(() {
        _myAppreciation = appreciation;
        if (appreciation != null && _myAppreciation == null) {
          _appreciationCount++;
        }
        _isAppreciationLoading = false;
      });
    }
  }

  Future<void> _loadScheduleSuggestion() async {
    final task = _getTask();
    if (task == null || !task.isRecurring || task.recurrenceRule == null) return;

    final suggestion = await _recurrenceService.generateSuggestion(
      taskId: task.id,
      taskTitle: task.title,
      currentSchedule: task.recurrenceRule!,
    );

    if (mounted && suggestion != null) {
      setState(() => _scheduleSuggestion = suggestion);
    }
  }

  void _showSuggestionDialog() {
    if (_scheduleSuggestion == null) return;

    showDialog(
      context: context,
      builder: (ctx) => ScheduleSuggestionDialog(
        suggestion: _scheduleSuggestion!,
        onAccept: () async {
          Navigator.pop(ctx);
          final success = await _recurrenceService.acceptSuggestion(
            taskId: _scheduleSuggestion!.taskId,
            newSchedule: _scheduleSuggestion!.suggestedSchedule,
          );
          if (success && mounted) {
            setState(() => _scheduleSuggestion = null);
            // Reload task to get updated recurrence
            final householdId = context.read<HouseholdProvider>().currentHousehold?.id;
            if (householdId != null) {
              context.read<TaskProvider>().loadTasks(householdId);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Schedule updated!')),
            );
          }
        },
        onDismiss: () async {
          Navigator.pop(ctx);
          await _recurrenceService.dismissSuggestion(_scheduleSuggestion!.taskId);
          if (mounted) {
            setState(() => _scheduleSuggestion = null);
          }
        },
      ),
    );
  }

  Future<void> _showAddToBundleSheet(Task task) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddToBundleSheet(
        taskId: task.id,
        currentBundleId: task.bundleId,
      ),
    );

    // Reload tasks to reflect bundle changes
    if (mounted) {
      final householdId = context.read<HouseholdProvider>().currentHousehold?.id;
      if (householdId != null) {
        context.read<TaskProvider>().loadTasks(householdId);
      }
    }
  }

  Future<void> _pickAndUploadCoverImage() async {
    // Capture provider before async gap to avoid use_build_context_synchronously
    final taskProvider = context.read<TaskProvider>();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
              width: 40,
              height: AppSpacing.xs,
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
            SizedBox(height: AppSpacing.sm),
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
    _category = task.category;
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

    if (kDebugMode) {
      debugPrint('Saving task with category: $_category');
    }

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
          category: _category,
        );

    if (kDebugMode) {
      debugPrint('Update result: $success');
    }

    if (mounted) {
      if (success) {
        setState(() => _isEditing = false);
        // Reload to get updated data
        final householdId = context.read<HouseholdProvider>().currentHousehold?.id;
        if (householdId != null) {
          context.read<TaskProvider>().loadTasks(householdId);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save changes')),
        );
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

  void _toggleComplete() async {
    final task = _getTask();
    if (task != null) {
      final wasCompleted = task.isCompleted;
      final taskProvider = context.read<TaskProvider>();
      await taskProvider.toggleTaskComplete(task);

      // Show undo snackbar only when completing (not uncompleting)
      if (!wasCompleted && mounted) {
        UndoCompletionSnackbar.show(
          context: context,
          task: task,
          taskProvider: taskProvider,
        );
      }
    }
  }

  Future<void> _showClaimCreditSheet(Task task) async {
    final currentUserId = SupabaseService.currentUser?.id;
    if (currentUserId == null) return;

    final hasClaimedCredit = _contributors.any((c) => c.userId == currentUserId);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ClaimCreditSheet(
        task: task,
        contributors: _contributors,
        currentUserId: currentUserId,
        hasClaimedCredit: hasClaimedCredit,
        onClaimCredit: (note) async {
          final contributor = await _contributorService.claimCredit(
            taskId: task.id,
            userId: currentUserId,
            contributionNote: note,
          );
          return contributor != null;
        },
        onRemoveCredit: () async {
          return await _contributorService.removeCredit(
            taskId: task.id,
            userId: currentUserId,
          );
        },
      ),
    );

    if (result == true && mounted) {
      await _loadContributors();
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
      if (kDebugMode) {
        debugPrint('Task not found. TaskId: ${widget.taskId}, Tasks count: ${taskProvider.tasks.length}');
      }
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
              SizedBox(height: AppSpacing.md),
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
          _buildCoverImageSection(task),
          if (_scheduleSuggestion != null) _buildScheduleSuggestionBanner(),
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(task, theme),
                SizedBox(height: AppSpacing.md),
                _buildTitleSection(task, theme),
                _buildCategoryBadge(task),
                SizedBox(height: AppSpacing.md),
                if (task.description != null && task.description!.isNotEmpty)
                  _buildDescriptionSection(task, theme),
                SizedBox(height: AppSpacing.md),
                _buildMetadataChips(task),
                SizedBox(height: AppSpacing.lg),
                const Divider(),
                _buildNotesSection(),
                SizedBox(height: AppSpacing.lg),
                const Divider(),
                _buildHistorySection(),
                if (_getTask()?.isRecurring == true) ...[
                  SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  _buildRecurringHistorySection(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSuggestionBanner() {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: ScheduleSuggestionBanner(
        suggestion: _scheduleSuggestion!,
        onTap: _showSuggestionDialog,
        onDismiss: () async {
          await _recurrenceService.dismissSuggestion(_scheduleSuggestion!.taskId);
          if (mounted) {
            setState(() => _scheduleSuggestion = null);
          }
        },
      ),
    );
  }

  Widget _buildStatusCard(Task task, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(task, theme),
            const SizedBox(height: 12),
            _buildStatusButtons(task),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Task task, ThemeData theme) {
    return Semantics(
      label: task.isCompleted
          ? 'Task completed${task.completedAt != null ? ' on ${DateFormat('MMM d, yyyy').format(task.completedAt!)}' : ''}'
          : 'Task pending',
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(
              task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: task.isCompleted ? Colors.green : Colors.grey,
              size: 32,
            ),
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
    );
  }

  Widget _buildStatusButtons(Task task) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: _toggleComplete,
            child: Text(task.isCompleted ? 'Mark Pending' : 'Mark Complete'),
          ),
        ),
        if (context.watch<AuthProvider>().bundlesEnabled ?? true) ...[
          SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddToBundleSheet(task),
              icon: const Icon(Icons.folder_outlined),
              label: Text(task.bundleId != null ? 'In Bundle' : 'Add to Bundle'),
            ),
          ),
        ],
        if (!task.isCompleted) ...[
          SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: _buildTakeOwnershipButton(task),
          ),
        ] else ...[
          SizedBox(height: AppSpacing.sm),
          _buildCompletedTaskActions(task),
        ],
      ],
    );
  }

  Widget _buildCompletedTaskActions(Task task) {
    return Column(
      children: [
        Row(
          children: [
            if (task.completedBy != null &&
                task.completedBy != SupabaseService.currentUser?.id) ...[
              AppreciationButton(
                hasAppreciated: _myAppreciation != null,
                reactionType: _myAppreciation?.reactionType,
                appreciationCount: _appreciationCount,
                isLoading: _isAppreciationLoading,
                onTap: () => _sendAppreciation(
                  _myAppreciation?.reactionType ?? 'thanks',
                ),
                onLongPress: _sendAppreciation,
              ),
              SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showClaimCreditSheet(task),
                icon: const Icon(Icons.people_outline),
                label: Text(_contributors.isEmpty
                    ? 'Claim Credit'
                    : 'Contributors (${_contributors.length})'),
              ),
            ),
          ],
        ),
        if (_contributors.isNotEmpty) ...[
          SizedBox(height: AppSpacing.sm),
          ContributorChips(contributors: _contributors),
        ],
      ],
    );
  }

  Widget _buildTitleSection(Task task, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildDescriptionSection(Task task, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.description!,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildMetadataChips(Task task) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _buildDetailChip(
          icon: Icons.schedule,
          label: 'Due',
          value: task.dueDate != null
              ? TaskDateUtils.formatDueDate(task.dueDate!, period: task.duePeriod)
              : 'No due date',
          iconColor: task.isOverdue ? Colors.red : Colors.blue,
          isOverdue: task.isOverdue,
        ),
        _buildDetailChip(
          icon: Icons.flag_rounded,
          label: 'Priority',
          value: task.priority.name[0].toUpperCase() + task.priority.name.substring(1),
          iconColor: task.priority == TaskPriority.high
              ? Colors.red
              : task.priority == TaskPriority.low
                  ? Colors.grey
                  : Colors.orange,
        ),
        _buildDetailChip(
          icon: Icons.person_rounded,
          label: 'Assigned to',
          value: task.assignedToName ?? 'Unassigned',
          iconColor: task.assignedTo != null ? AppColors.success : Colors.grey,
        ),
        _buildDetailChip(
          icon: Icons.edit_rounded,
          label: 'Created by',
          value: task.createdByName ?? 'Unknown',
          iconColor: Colors.purple,
        ),
        _buildDetailChip(
          icon: Icons.calendar_today_rounded,
          label: 'Created',
          value: DateFormat('MMM d, yyyy').format(task.createdAt),
          iconColor: Colors.teal,
        ),
      ],
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
                              SizedBox(width: AppSpacing.xs),
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
            SizedBox(width: AppSpacing.sm),
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(width: AppSpacing.sm),
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
            separatorBuilder: (context, index) => SizedBox(height: AppSpacing.sm),
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
              SizedBox(width: AppSpacing.sm),
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

  Widget _buildRecurringHistorySection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showRecurringHistory = !_showRecurringHistory),
          child: Row(
            children: [
              Icon(Icons.repeat_rounded, size: 20, color: AppColors.primary),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Completion History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (_isLoadingRecurringHistory)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  _showRecurringHistory ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
        if (_showRecurringHistory) ...[
          const SizedBox(height: 12),
          if (_recurringHistory.isEmpty)
            Text(
              'No completions recorded yet',
              style: TextStyle(
                color: isDark ? AppColors.textSecondary : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recurringHistory.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _recurringHistory[index];
                final completedAt = item['completed_at'] != null
                    ? DateTime.parse(item['completed_at'] as String)
                    : null;
                final completedByName =
                    item['profiles']?['display_name'] as String? ?? 'Unknown';

                return Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.grey[50],
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: isDark ? AppColors.cardBorder : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              completedByName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (completedAt != null)
                              Text(
                                DateFormat('MMM d, yyyy • h:mm a').format(completedAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textSecondary : Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ],
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    Color? backgroundColor,
    bool isOverdue = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = isOverdue ? Colors.red : (iconColor ?? AppColors.primary);
    final effectiveBgColor = backgroundColor ??
        (isDark ? AppColors.cardDark : Colors.grey[100]);

    return Semantics(
      label: '$label: $value${isOverdue ? ', overdue' : ''}',
      child: Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isOverdue ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: effectiveIconColor),
          ),
          SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: isDark ? AppColors.textSecondary : Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isOverdue
                      ? Colors.red
                      : (isDark ? AppColors.textPrimary : Colors.grey[800]),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
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
        padding: EdgeInsets.all(AppSpacing.md),
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
            SizedBox(height: AppSpacing.md),

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
            SizedBox(height: AppSpacing.lg),

            // Category
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _category == cat;
                final color = CategoryUtils.getColorForCategory(cat);
                final displayName = cat[0].toUpperCase() + cat.substring(1);
                return FilterChip(
                  avatar: Icon(
                    _getCategoryIcon(displayName),
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

            // Due Date
            Text(
              'Due Date',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: AppSpacing.sm),
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
              SizedBox(height: AppSpacing.md),
              Text(
                'Time of Day',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                children: [
                  _buildPeriodChip('Morning', DuePeriod.morning),
                  _buildPeriodChip('Afternoon', DuePeriod.afternoon),
                  _buildPeriodChip('Evening', DuePeriod.evening),
                ],
              ),
            ],
            SizedBox(height: AppSpacing.lg),

            // Priority
            Text(
              'Priority',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: AppSpacing.sm),
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
            SizedBox(height: AppSpacing.lg),

            // Recurrence
            Text(
              'Recurrence',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: AppSpacing.sm),
            RecurrencePicker(
              initialValue: _recurrenceRule,
              onChanged: (rule) {
                setState(() {
                  _recurrenceRule = rule;
                  _clearRecurrence = rule == null;
                });
              },
            ),
            SizedBox(height: AppSpacing.xl),
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

  Widget _buildCategoryBadge(Task task) {
    final categoryColor = CategoryUtils.getCategoryColor(task);
    final categoryName = CategoryUtils.getCategoryName(task);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(categoryName),
            size: 16,
            color: categoryColor,
          ),
          const SizedBox(width: 6),
          Text(
            categoryName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: categoryColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'kitchen':
        return Icons.kitchen;
      case 'bathroom':
        return Icons.bathroom;
      case 'living':
        return Icons.weekend;
      case 'outdoor':
        return Icons.yard;
      case 'pet':
        return Icons.pets;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'grocery':
        return Icons.shopping_cart;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.task_alt;
    }
  }

}
