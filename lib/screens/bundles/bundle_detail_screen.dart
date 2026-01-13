import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/task.dart';
import '../../models/task_bundle.dart';
import '../../providers/bundle_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/task_provider.dart';

/// Screen for viewing and managing a task bundle.
class BundleDetailScreen extends StatefulWidget {
  final String bundleId;

  const BundleDetailScreen({super.key, required this.bundleId});

  @override
  State<BundleDetailScreen> createState() => _BundleDetailScreenState();
}

class _BundleDetailScreenState extends State<BundleDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BundleProvider>().loadBundle(widget.bundleId);
    });
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  IconData _getIconData(String iconName) {
    final icons = {
      'list': Icons.list,
      'cleaning': Icons.cleaning_services,
      'kitchen': Icons.kitchen,
      'laundry': Icons.local_laundry_service,
      'garden': Icons.yard,
      'shopping': Icons.shopping_cart,
      'pet': Icons.pets,
      'car': Icons.directions_car,
      'home': Icons.home,
      'event': Icons.event,
    };
    return icons[iconName] ?? Icons.folder;
  }

  Future<void> _removeTaskFromBundle(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Bundle'),
        content: Text('Remove "${task.title}" from this bundle?'),
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
      await context.read<BundleProvider>().removeTaskFromBundle(task.id);
    }
  }

  Future<void> _deleteBundle(TaskBundle bundle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bundle'),
        content: Text(
          'Delete "${bundle.name}"? Tasks in this bundle will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<BundleProvider>().deleteBundle(bundle.id);
      if (success && mounted) {
        // Refresh tasks so they appear on the dashboard with bundle_id = null
        final householdId = context.read<HouseholdProvider>().currentHousehold?.id;
        if (householdId != null) {
          context.read<TaskProvider>().loadTasks(householdId);
        }
        context.pop();
      }
    }
  }

  Future<void> _showAddTasksSheet(TaskBundle bundle) async {
    final householdId = context.read<HouseholdProvider>().currentHousehold?.id;
    if (householdId == null) return;

    // Load tasks if not already loaded
    await context.read<TaskProvider>().loadTasks(householdId);

    if (!mounted) return;

    final taskProvider = context.read<TaskProvider>();
    final bundleTaskIds = (bundle.tasks ?? []).map((t) => t.id).toSet();

    // Get unique tasks (not instances of recurring tasks) that aren't in any bundle
    // For recurring tasks, only show the parent task, not individual instances
    final availableTasks = taskProvider.tasks
        .where((t) =>
            !bundleTaskIds.contains(t.id) &&
            t.bundleId == null &&
            t.parentTaskId == null)  // Only parent/original tasks, not instances
        .toList();

    // Remove duplicates by title (in case there are multiple non-recurring tasks with same name)
    final seenTitles = <String>{};
    final uniqueTasks = availableTasks.where((t) {
      if (seenTitles.contains(t.title)) return false;
      seenTitles.add(t.title);
      return true;
    }).toList();

    final color = _parseColor(bundle.color);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: AppSpacing.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Text(
                      'Add Tasks to Bundle',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              // Task list
              if (uniqueTasks.isEmpty)
                Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'All tasks are already in bundles',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push('/create-task');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Task'),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: uniqueTasks.length,
                    itemBuilder: (context, index) {
                      final task = uniqueTasks[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.1),
                            child: Icon(
                              task.isRecurring ? Icons.repeat : Icons.task_alt,
                              color: color,
                              size: 20,
                            ),
                          ),
                          title: Text(task.title),
                          subtitle: task.isRecurring
                              ? const Text('Recurring task')
                              : (task.category != null ? Text(task.category!) : null),
                          trailing: IconButton(
                            icon: Icon(Icons.add_circle, color: color),
                            onPressed: () async {
                              final success = await context.read<BundleProvider>().addTaskToBundle(
                                taskId: task.id,
                                bundleId: bundle.id,
                              );
                              if (success && ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                            },
                          ),
                          onTap: () async {
                            final success = await context.read<BundleProvider>().addTaskToBundle(
                              taskId: task.id,
                              bundleId: bundle.id,
                            );
                            if (success && ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );

    // Reload bundle after adding tasks
    if (mounted) {
      context.read<BundleProvider>().loadBundle(widget.bundleId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bundleProvider = context.watch<BundleProvider>();
    final bundle = bundleProvider.selectedBundle;

    if (bundleProvider.isLoading || bundle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bundle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final color = _parseColor(bundle.color);
    final tasks = bundle.tasks ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(bundle.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: 'Add Tasks',
            onPressed: () => _showAddTasksSheet(bundle),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteBundle(bundle);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Bundle', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTasksSheet(bundle),
        backgroundColor: color,
        icon: const Icon(Icons.add),
        label: const Text('Add Tasks'),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          // Bundle header
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        _getIconData(bundle.icon),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bundle.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (bundle.description != null)
                            Text(
                              bundle.description!,
                              style: theme.textTheme.bodyMedium,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Tasks in bundle
          if (tasks.isNotEmpty) ...[
            Text(
              'Tasks (${tasks.length})',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: AppSpacing.sm),
            ...tasks.map((task) => _buildTaskTile(task, color)),
          ],

          // Empty state
          if (tasks.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'No tasks in this bundle',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tap the button below to add existing tasks',
                      style: theme.textTheme.bodySmall,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => _showAddTasksSheet(bundle),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Tasks'),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(Task task, Color bundleColor) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppSpacing.md),
        color: Colors.red,
        child: const Icon(Icons.remove_circle, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _removeTaskFromBundle(task);
        return false; // We handle removal ourselves
      },
      child: Card(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: bundleColor.withValues(alpha: 0.1),
            child: Icon(
              task.isRecurring ? Icons.repeat : Icons.task_alt,
              color: bundleColor,
              size: 20,
            ),
          ),
          title: Text(task.title),
          subtitle: task.isRecurring
              ? const Text('Recurring task')
              : (task.category != null ? Text(task.category!) : null),
          trailing: IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => context.push('/task/${task.id}'),
          ),
          onTap: () => context.push('/task/${task.id}'),
        ),
      ),
    );
  }

}
