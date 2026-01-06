import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../providers/household_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/tasks/note_input.dart';
import '../../widgets/tasks/task_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _completedExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  void _loadTasks() {
    final householdId =
        context.read<HouseholdProvider>().currentHousehold?.id;
    if (householdId != null) {
      context.read<TaskProvider>().loadTasks(householdId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final householdProvider = context.watch<HouseholdProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final household = householdProvider.currentHousehold;
    final pendingTasks = taskProvider.pendingTasks;
    final completedTasks = taskProvider.completedTasksSortedByRecent;

    if (household == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasTasks = pendingTasks.isNotEmpty || completedTasks.isNotEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        await householdProvider.loadUserHousehold();
        _loadTasks();
      },
      child: !hasTasks
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    '${pendingTasks.length} pending, ${completedTasks.length} completed',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),

                // Pending tasks
                ...pendingTasks.map((task) => _buildTaskTile(task, taskProvider)),

                // Completed tasks section (collapsible)
                if (completedTasks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildCompletedSection(completedTasks, taskProvider),
                ],

                // Space for FAB
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _buildCompletedSection(List completedTasks, TaskProvider taskProvider) {
    return Column(
      children: [
        // Collapsible header
        InkWell(
          onTap: () => setState(() => _completedExpanded = !_completedExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Completed (${completedTasks.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Icon(
                  _completedExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),

        // Completed tasks list (shown when expanded)
        if (_completedExpanded)
          ...completedTasks.map((task) => _buildTaskTile(task, taskProvider)),
      ],
    );
  }

  Widget _buildTaskTile(Task task, TaskProvider taskProvider) {
    final currentUserId = SupabaseService.currentUser?.id;
    final isOwnedByMe = task.assignedTo == currentUserId;

    return TaskTile(
      task: task,
      onTap: () => context.push('/task/${task.id}'),
      onToggleComplete: () => taskProvider.toggleTaskComplete(task),
      isOwnedByMe: isOwnedByMe,
      onTakeOwnership: () {
        if (isOwnedByMe) {
          taskProvider.releaseOwnership(task.id);
        } else {
          taskProvider.takeOwnership(task.id);
        }
      },
      onAddNote: () => _showNotesModal(task, taskProvider),
      onDelete: () => taskProvider.deleteTask(task.id),
      onSnooze: () => _snoozeTask(task, taskProvider),
    );
  }

  void _showNotesModal(Task task, TaskProvider taskProvider) {
    final members = context.read<HouseholdProvider>().members;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a note or tag someone with @',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Quick tag buttons
                    if (members.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        children: members.map((m) => ActionChip(
                          avatar: CircleAvatar(
                            radius: 12,
                            child: Text(
                              (m.displayName ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          label: Text('@${m.displayName ?? 'Unknown'}'),
                          onPressed: () {
                            Navigator.pop(context);
                            _addQuickNote(task, taskProvider, '@${m.displayName}');
                          },
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: NoteInput(
                  onSubmit: (content) async {
                    await taskProvider.addNote(taskId: task.id, content: content);
                    if (context.mounted) Navigator.pop(context);
                  },
                  members: members.map((m) => MemberInfo(
                    id: m.userId,
                    displayName: m.displayName ?? 'Unknown',
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addQuickNote(Task task, TaskProvider taskProvider, String mention) async {
    await taskProvider.addNote(taskId: task.id, content: 'Tagging $mention');
  }

  Future<void> _snoozeTask(Task task, TaskProvider taskProvider) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final newDueDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
    await taskProvider.updateTask(taskId: task.id, dueDate: newDueDate);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task snoozed to tomorrow')),
      );
    }
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No tasks yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the button below to create your first task',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ],
    );
  }
}
