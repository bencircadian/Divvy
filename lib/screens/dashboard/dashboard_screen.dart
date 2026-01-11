import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/task.dart';
import '../../utils/date_utils.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/task_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _upcomingExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final householdId = context.read<HouseholdProvider>().currentHousehold?.id;
    if (householdId != null) {
      context.read<DashboardProvider>().loadDashboardData(householdId);
      context.read<TaskProvider>().loadTasks(householdId);
    }
  }

  void _showUnassignedTasksSheet(TaskProvider provider, List members) {
    final unassignedTasks = provider.pendingTasks.where((t) => t.assignedTo == null).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
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
              child: Row(
                children: [
                  Icon(Icons.assignment_late, color: Colors.orange[700]),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Unassigned Tasks (${unassignedTasks.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Task list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: unassignedTasks.length,
                itemBuilder: (context, index) {
                  final task = unassignedTasks[index];
                  return ListTile(
                    key: ValueKey(task.id),
                    leading: CircleAvatar(
                      backgroundColor: _getPriorityColor(task.priority).withValues(alpha: 0.2),
                      child: Icon(
                        Icons.task_alt,
                        color: _getPriorityColor(task.priority),
                        size: 20,
                      ),
                    ),
                    title: Text(task.title),
                    subtitle: task.dueDate != null ? Text(TaskDateUtils.formatDueDateShort(task.dueDate!)) : null,
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.person_add),
                      tooltip: 'Assign to',
                      onSelected: (userId) async {
                        await provider.assignTask(task.id, userId);
                        if (context.mounted) Navigator.pop(context);
                      },
                      itemBuilder: (context) => [
                        ...members.map((m) => PopupMenuItem(
                              value: m.userId,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    child: Text(
                                      (m.displayName ?? 'U')[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.sm),
                                  Text(m.displayName ?? 'Unknown'),
                                ],
                              ),
                            )),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/task/${task.id}');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final householdProvider = context.watch<HouseholdProvider>();
    final members = householdProvider.members;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: AppColors.primary,
        child: dashboardProvider.isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: EdgeInsets.all(AppSpacing.md),
                children: [
                  // Stats Row
                  _buildStatsRow(taskProvider),
                  SizedBox(height: AppSpacing.lg),

                  // Today's Tasks Section (incomplete only)
                  _buildSectionHeader(context, 'Today', Icons.today),
                  const SizedBox(height: 12),
                  _buildTodaysTasks(taskProvider.incompleteTodayTasks),
                  SizedBox(height: AppSpacing.lg),

                  // Upcoming Tasks Section (collapsible, unique tasks)
                  _buildSectionHeader(context, 'Upcoming', Icons.date_range),
                  const SizedBox(height: 12),
                  _buildUpcomingTasks(taskProvider.upcomingUniqueTasks),
                  SizedBox(height: AppSpacing.lg),

                  // Streaks Section
                  _buildSectionHeader(context, 'Streaks', Icons.local_fire_department),
                  const SizedBox(height: 12),
                  _buildStreaksCard(dashboardProvider, members),
                  SizedBox(height: AppSpacing.lg),

                  // Workload Distribution Section
                  _buildSectionHeader(context, 'Workload', Icons.pie_chart),
                  const SizedBox(height: 12),
                  _buildWorkloadCard(taskProvider, members),
                  SizedBox(height: AppSpacing.lg),

                  // Weekly Summary Section
                  _buildSectionHeader(context, 'This Week', Icons.bar_chart),
                  const SizedBox(height: 12),
                  _buildWeeklySummary(dashboardProvider, members),
                  const SizedBox(height: 80), // Space for bottom nav
                ],
              ),
      ),
    );
  }

  Widget _buildStatsRow(TaskProvider taskProvider) {
    final activeTasks = taskProvider.incompleteTodayTasks.length;
    final upcomingTasks = taskProvider.upcomingUniqueTasks.length;
    final completedTasks = taskProvider.completedTasks.length;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Active', '$activeTasks', AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Upcoming', '$upcomingTasks', AppColors.warning)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Done', '$completedTasks', AppColors.success)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!,
        ),
        boxShadow: AppShadows.cardShadow(isDark),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildTodaysTasks(List<Task> tasks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (tasks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: AppColors.success, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'All caught up! No tasks due today.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: tasks.asMap().entries.map((entry) {
          final index = entry.key;
          final task = entry.value;
          final isLast = index == tasks.length - 1;

          return Column(
            children: [
              _buildTaskListItem(task),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 56,
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskListItem(Task task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priorityColor = _getPriorityColor(task.priority);

    String subtitle = '';
    Color subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    if (task.isOverdue) {
      subtitle = 'Overdue • High Priority';
      subtitleColor = AppColors.error;
    } else if (task.duePeriod != null) {
      subtitle = task.duePeriod!.name[0].toUpperCase() + task.duePeriod!.name.substring(1);
      if (task.priority == TaskPriority.high) {
        subtitle += ' • High Priority';
        subtitleColor = AppColors.error;
      }
    } else if (task.priority == TaskPriority.high) {
      subtitle = 'Due Today • High Priority';
      subtitleColor = AppColors.error;
    } else {
      subtitle = 'Due Today';
    }

    return InkWell(
      onTap: () => context.push('/task/${task.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Checkbox placeholder
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                  width: 2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Task content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            // Priority dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: priorityColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTasks(List<Task> tasks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (tasks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.event_available, color: AppColors.info, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'No upcoming tasks scheduled.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final previewTasks = tasks.take(3).toList();
    final hasMore = tasks.length > 3;

    return Card(
      child: Column(
        children: [
          // Always show first 3 tasks
          ...previewTasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            final isLast = index == previewTasks.length - 1 && !hasMore && !_upcomingExpanded;

            return Column(
              children: [
                _buildUpcomingTaskItem(task),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 40,
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
                  ),
              ],
            );
          }),

          // Expandable section for remaining tasks
          if (hasMore) ...[
            InkWell(
              onTap: () => setState(() => _upcomingExpanded = !_upcomingExpanded),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _upcomingExpanded
                          ? 'Show less'
                          : 'Show ${tasks.length - 3} more',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Icon(
                      _upcomingExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_upcomingExpanded)
              ...tasks.skip(3).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final task = entry.value;
                final isLast = index == tasks.length - 4;

                return Column(
                  children: [
                    _buildUpcomingTaskItem(task),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 40,
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
                      ),
                  ],
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingTaskItem(Task task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priorityColor = _getPriorityColor(task.priority);

    return InkWell(
      onTap: () => context.push('/task/${task.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Priority dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: priorityColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            // Task content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  if (task.dueDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      TaskDateUtils.formatDueDateShort(task.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Recurring indicator or chevron
            if (task.isRecurring)
              Icon(Icons.repeat, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[500])
            else
              Icon(Icons.chevron_right, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildStreaksCard(DashboardProvider provider, List members) {
    final streaks = provider.streaksSorted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (streaks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Complete tasks daily to build your streak!',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: streaks.asMap().entries.map((entry) {
            final index = entry.key;
            final streak = entry.value;
            final isTopStreak = streak == streaks.first && streak.currentStreak > 0;
            final isLast = index == streaks.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isTopStreak
                            ? Colors.orange.withValues(alpha: 0.15)
                            : (isDark ? AppColors.surfaceDark : Colors.grey[100]),
                        child: Text(
                          (streak.displayName ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            color: isTopStreak ? Colors.orange[700] : (isDark ? Colors.grey[300] : Colors.grey[700]),
                            fontWeight: isTopStreak ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              streak.displayName ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Best: ${streak.longestStreak} days',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: streak.currentStreak > 0 ? Colors.orange : (isDark ? Colors.grey[600] : Colors.grey[300]),
                            size: 20,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            '${streak.currentStreak}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: streak.currentStreak > 0 ? Colors.orange : (isDark ? Colors.grey[600] : Colors.grey[400]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWorkloadCard(TaskProvider provider, List members) {
    final pendingTasks = provider.pendingTasks;
    final workload = <String, int>{};
    int unassigned = 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    for (final task in pendingTasks) {
      if (task.assignedTo != null) {
        workload[task.assignedTo!] = (workload[task.assignedTo!] ?? 0) + 1;
      } else {
        unassigned++;
      }
    }

    if (pendingTasks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.celebration, color: AppColors.success, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'All caught up! No pending tasks.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxTasks = workload.values.fold(unassigned, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            ...members.map((member) {
              final count = workload[member.userId] ?? 0;
              final percentage = maxTasks > 0 ? count / maxTasks : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        member.displayName ?? 'Unknown',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 12,
                          backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(
                            _getWorkloadColor(count, maxTasks),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$count',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (unassigned > 0) ...[
              SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: () => _showUnassignedTasksSheet(provider, members),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '$unassigned unassigned task${unassigned > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: Colors.orange[700]),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary(DashboardProvider provider, List members) {
    final taskCounts = provider.taskCounts;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (taskCounts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hourglass_empty, color: Colors.grey[500], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'No tasks completed this week yet.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalCompleted = taskCounts.values.fold(0, (a, b) => a + b);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/trophy.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    Colors.amber[600]!,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$totalCompleted tasks completed this week',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            Divider(
              height: 24,
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
            ),
            ...members.asMap().entries.map((entry) {
              final index = entry.key;
              final member = entry.value;
              final count = taskCounts[member.userId] ?? 0;
              final isLast = index == members.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey[100],
                          child: Text(
                            (member.displayName ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            member.displayName ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[300] : Colors.grey[800],
                            ),
                          ),
                        ),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: count > 0 ? AppColors.primary : (isDark ? Colors.grey[500] : Colors.grey[400]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 40,
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.error;
      case TaskPriority.normal:
        return AppColors.warning;
      case TaskPriority.low:
        return AppColors.primary.withValues(alpha: 0.6);
    }
  }

  Color _getWorkloadColor(int count, int max) {
    if (max == 0) return Colors.grey;
    final ratio = count / max;
    if (ratio > 0.7) return AppColors.error;
    if (ratio > 0.4) return AppColors.warning;
    return AppColors.primary;
  }
}
