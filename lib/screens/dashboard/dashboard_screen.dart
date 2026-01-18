import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/productivity_insights.dart';
import '../../models/task.dart';
import '../../services/onboarding_progress_service.dart';
import '../../utils/date_utils.dart';
import '../../widgets/bundles/bundle_card.dart';
import '../../widgets/bundles/create_bundle_sheet.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/member_avatar.dart';
import '../../widgets/tasks/organic_task_card.dart';
import '../../widgets/dashboard/dashboard_widgets.dart';
import '../../widgets/dashboard/insights_card.dart';
import '../../widgets/onboarding/onboarding_checklist.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bundle_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/insights_service.dart';
import '../../services/supabase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _upcomingExpanded = false;
  ProductivityInsights _insights = ProductivityInsights.empty;
  bool _insightsLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData({bool showFeedback = false}) async {
    if (showFeedback) {
      HapticFeedback.mediumImpact();
    }
    final householdProvider = context.read<HouseholdProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    final taskProvider = context.read<TaskProvider>();
    final bundleProvider = context.read<BundleProvider>();
    final householdId = householdProvider.currentHousehold?.id;
    if (householdId != null) {
      await dashboardProvider.loadDashboardData(householdId);
      await taskProvider.loadTasks(householdId);
      await bundleProvider.loadBundles(householdId);
      await _loadInsights(householdId);
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dashboard refreshed'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadInsights(String householdId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    setState(() => _insightsLoading = true);

    final service = InsightsService(SupabaseService.client);
    final insights = await service.getInsights(
      userId: userId,
      householdId: householdId,
    );

    if (mounted) {
      setState(() {
        _insights = insights;
        _insightsLoading = false;
      });
    }
  }

  Future<void> _showCreateBundleSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CreateBundleSheet(),
    );
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
                                  MemberAvatar(
                                    displayName: m.displayName,
                                    radius: 14,
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
    final authProvider = context.watch<AuthProvider>();
    final members = householdProvider.members;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDarkMode : AppColors.primary;
    final bundlesEnabled = authProvider.bundlesEnabled ?? true;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadData(showFeedback: true),
        color: primaryColor,
        child: dashboardProvider.isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : ListView(
                padding: EdgeInsets.all(AppSpacing.md),
                children: [
                  // Onboarding checklist (shown for new users)
                  OnboardingChecklist(
                    key: ValueKey('dashboard_checklist_${OnboardingProgressService.hasCompletedFirstTask}'),
                  ),

                  // Stats Row
                  _buildStatsRow(taskProvider),
                  SizedBox(height: AppSpacing.lg),

                  // Your Insights Section
                  if (!_insightsLoading) ...[
                    _buildSectionHeader(context, 'Your Insights', Icons.insights),
                    const SizedBox(height: 12),
                    InsightsCard(insights: _insights),
                    SizedBox(height: AppSpacing.lg),
                  ],

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

                  // Task Bundles Section (only shown if user has bundles enabled)
                  if (bundlesEnabled)
                    Builder(
                      builder: (context) {
                        final bundleProvider = context.watch<BundleProvider>();
                        // Show all bundles, not just active ones (which excludes empty bundles)
                        final allBundles = bundleProvider.bundles;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSectionHeader(context, 'Bundles', Icons.folder_special),
                                ),
                                TextButton.icon(
                                  onPressed: _showCreateBundleSheet,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Create'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (allBundles.isEmpty)
                              Card(child: CardEmptyState.noBundles())
                            else
                              ...allBundles.take(3).map((bundle) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: BundleCard(
                                  bundle: bundle,
                                  compact: true,
                                  onTap: () => context.push('/bundle/${bundle.id}'),
                                ),
                              )),
                            SizedBox(height: AppSpacing.lg),
                          ],
                        );
                      },
                    ),

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
    final completedTasks = taskProvider.completedTasks.length;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.checklist_rounded,
            label: 'Active Tasks',
            value: '$activeTasks',
            subtitle: 'Due today',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.check_circle_outline,
            label: 'Completed',
            value: '$completedTasks',
            subtitle: 'All time',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDarkMode : AppColors.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: primaryColor, size: 18),
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
    final taskProvider = context.read<TaskProvider>();

    if (tasks.isEmpty) {
      return Card(child: CardEmptyState.tasksDone());
    }

    return Column(
      children: tasks.asMap().entries.map((entry) {
        final index = entry.key;
        final task = entry.value;

        return OrganicTaskCard(
          key: ValueKey(task.id),
          task: task,
          index: index,
          taskProvider: taskProvider,
        );
      }).toList(),
    );
  }

  Widget _buildUpcomingTasks(List<Task> tasks) {
    final taskProvider = context.read<TaskProvider>();

    if (tasks.isEmpty) {
      return Card(child: CardEmptyState.noUpcoming());
    }

    final previewTasks = tasks.take(3).toList();
    final hasMore = tasks.length > 3;
    final displayTasks = _upcomingExpanded ? tasks : previewTasks;

    return Column(
      children: [
        // Show tasks using OrganicTaskCard
        ...displayTasks.asMap().entries.map((entry) {
          final index = entry.key;
          final task = entry.value;

          return OrganicTaskCard(
            key: ValueKey(task.id),
            task: task,
            index: index,
            taskProvider: taskProvider,
          );
        }),

        // Expandable section toggle
        if (hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: InkWell(
              onTap: () => setState(() => _upcomingExpanded = !_upcomingExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
          ),
      ],
    );
  }

  Widget _buildStreaksCard(DashboardProvider provider, List members) {
    final streaks = provider.streaksSorted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (streaks.isEmpty) {
      return Card(child: CardEmptyState.noStreaks());
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
                      MemberAvatar(
                        displayName: streak.displayName,
                        radius: 20,
                        backgroundColor: isTopStreak
                            ? Colors.orange.withValues(alpha: 0.15)
                            : null,
                        foregroundColor: isTopStreak ? Colors.orange[700] : null,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (pendingTasks.isEmpty) {
      return _buildEmptyWorkloadCard(isDark);
    }

    // Calculate workload distribution
    final workload = <String, int>{};
    int unassigned = 0;
    for (final task in pendingTasks) {
      if (task.assignedTo != null) {
        workload[task.assignedTo!] = (workload[task.assignedTo!] ?? 0) + 1;
      } else {
        unassigned++;
      }
    }

    // Build segments for the bar chart
    final segments = _buildWorkloadSegments(members, workload, unassigned);
    final totalTasks = pendingTasks.length;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$totalTasks pending task${totalTasks != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
            SizedBox(height: AppSpacing.md),
            StackedBarChart(
              segments: segments,
              height: 32,
              showLegend: true,
              showValues: true,
            ),
            if (unassigned > 0)
              _buildUnassignedTasksBanner(unassigned, provider, members),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWorkloadCard(bool isDark) {
    return Card(
      child: CardEmptyState(
        icon: Icons.celebration,
        message: 'All caught up! No pending tasks.',
        color: AppColors.success,
      ),
    );
  }

  List<BarSegment> _buildWorkloadSegments(
    List members,
    Map<String, int> workload,
    int unassigned,
  ) {
    final memberIds = members.map((m) => m.userId as String).toList();
    final segments = <BarSegment>[];

    for (final member in members) {
      final count = workload[member.userId] ?? 0;
      if (count > 0) {
        segments.add(BarSegment(
          id: member.userId,
          label: member.displayName ?? 'Unknown',
          value: count,
          color: MemberColors.getColorForId(member.userId, memberIds),
        ));
      }
    }

    if (unassigned > 0) {
      segments.add(BarSegment(
        id: 'unassigned',
        label: 'Unassigned',
        value: unassigned,
        color: Colors.grey[400]!,
      ));
    }

    return segments;
  }

  Widget _buildUnassignedTasksBanner(
    int unassigned,
    TaskProvider provider,
    List members,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.md),
      child: InkWell(
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
                  'Tap to assign $unassigned task${unassigned > 1 ? 's' : ''}',
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
    );
  }

  Widget _buildWeeklySummary(DashboardProvider provider, List members) {
    final taskCounts = provider.taskCounts;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (taskCounts.isEmpty || taskCounts.values.every((v) => v == 0)) {
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

    // Build segments for each member
    final memberIds = members.map((m) => m.userId as String).toList();
    final segments = <BarSegment>[];

    for (final member in members) {
      final count = taskCounts[member.userId] ?? 0;
      if (count > 0) {
        segments.add(BarSegment(
          id: member.userId,
          label: member.displayName ?? 'Unknown',
          value: count,
          color: MemberColors.getColorForId(member.userId, memberIds),
        ));
      }
    }

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
                    '$totalCompleted task${totalCompleted != 1 ? 's' : ''} completed this week',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            StackedBarChart(
              segments: segments,
              height: 32,
              showLegend: true,
              showValues: true,
            ),
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

}
