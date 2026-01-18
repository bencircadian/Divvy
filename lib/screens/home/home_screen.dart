import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/task.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/tasks/organic_task_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/task_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _activeTab = 'today';
  late AnimationController _blobController;
  String? _lastLoadedHouseholdId;
  final _searchController = TextEditingController();
  bool _showSearch = false;
  final Set<String> _selectedTaskIds = {};
  String? _selectedCategory;
  _TaskSortOrder _sortOrder = _TaskSortOrder.dueDate;
  bool _showQuickAdd = false;
  final _quickAddController = TextEditingController();

  bool get _isSelectionMode => _selectedTaskIds.isNotEmpty;

  void _toggleSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedTaskIds.clear());
  }

  Future<void> _completeSelectedTasks(TaskProvider taskProvider) async {
    final tasks = taskProvider.tasks.where((t) => _selectedTaskIds.contains(t.id) && !t.isCompleted).toList();
    for (final task in tasks) {
      await taskProvider.toggleTaskComplete(task);
    }
    _clearSelection();
  }

  Future<void> _deleteSelectedTasks(TaskProvider taskProvider) async {
    for (final taskId in _selectedTaskIds.toList()) {
      await taskProvider.deleteTask(taskId);
    }
    _clearSelection();
  }

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  void dispose() {
    _blobController.dispose();
    _searchController.dispose();
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _createQuickTask(TaskProvider taskProvider, String householdId) async {
    final title = _quickAddController.text.trim();
    if (title.isEmpty) return;

    await taskProvider.createTask(
      householdId: householdId,
      title: title,
      dueDate: DateTime.now(), // Default to today
    );

    _quickAddController.clear();
    setState(() => _showQuickAdd = false);
  }

  List<Task> _getFilteredTasks(TaskProvider taskProvider) {
    List<Task> tasks;
    switch (_activeTab) {
      case 'today':
        // Include tasks due today AND tasks without due dates (anytime tasks)
        final todayTasks = taskProvider.incompleteTodayTasks;
        final anytimeTasks = taskProvider.pendingTasks
            .where((t) => t.dueDate == null)
            .toList();
        tasks = [...todayTasks, ...anytimeTasks];
        break;
      case 'upcoming':
        tasks = taskProvider.upcomingUniqueTasks;
        break;
      case 'done':
        tasks = taskProvider.completedTasksSortedByRecent;
        break;
      default:
        tasks = taskProvider.pendingTasks;
    }

    // Apply category filter if selected
    if (_selectedCategory != null) {
      tasks = tasks.where((t) {
        final category = t.category?.toLowerCase() ?? '';
        return category == _selectedCategory!.toLowerCase();
      }).toList();
    }

    // Apply search filter if search is active
    final query = taskProvider.searchQuery;
    if (query.isNotEmpty) {
      tasks = tasks.where((t) {
        final titleMatch = t.title.toLowerCase().contains(query);
        final categoryMatch = t.category?.toLowerCase().contains(query) ?? false;
        final assigneeMatch = t.assignedToName?.toLowerCase().contains(query) ?? false;
        return titleMatch || categoryMatch || assigneeMatch;
      }).toList();
    }

    // Apply sorting
    // For "done" tab, always sort by completion date (most recent first)
    if (_activeTab == 'done') {
      tasks.sort((a, b) {
        final aCompleted = a.completedAt ?? a.createdAt;
        final bCompleted = b.completedAt ?? b.createdAt;
        return bCompleted.compareTo(aCompleted);
      });
    } else {
      tasks.sort((a, b) {
        switch (_sortOrder) {
          case _TaskSortOrder.dueDate:
            if (a.dueDate == null && b.dueDate == null) return 0;
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
          case _TaskSortOrder.priority:
            return b.priority.index.compareTo(a.priority.index);
          case _TaskSortOrder.createdAt:
            return b.createdAt.compareTo(a.createdAt);
          case _TaskSortOrder.alphabetical:
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        }
      });
    }

    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final householdProvider = context.watch<HouseholdProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final household = householdProvider.currentHousehold;

    if (household == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Load tasks and dashboard data when household becomes available or changes
    if (_lastLoadedHouseholdId != household.id) {
      _lastLoadedHouseholdId = household.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        taskProvider.loadTasks(household.id);
        dashboardProvider.loadDashboardData(household.id);
      });
    }

    final filteredTasks = _getFilteredTasks(taskProvider);
    final pendingCount = taskProvider.pendingTasks.length;
    final completedCount = taskProvider.completedTasks.length;

    // Weekly completed tasks count
    final weeklyCompletedTotal = dashboardProvider.taskCounts.values.fold(0, (a, b) => a + b);
    final weeklyGoal = 20; // Could make this configurable

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : null,
      body: Stack(
        children: [
          // Floating organic background blobs (dark mode only)
          if (isDark) ...[
            _buildFloatingBlob(
              top: -80,
              right: -120,
              size: 400,
              color: AppColors.primary.withValues(alpha: 0.15),
              controller: _blobController,
            ),
            _buildFloatingBlob(
              bottom: 200,
              left: -100,
              size: 300,
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              controller: _blobController,
              reverse: true,
            ),
          ],

          // Main content
          RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await householdProvider.loadUserHousehold();
              await taskProvider.loadTasks(household.id);
              await dashboardProvider.loadDashboardData(household.id);
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Tasks refreshed'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Header
                _buildHeader(context, authProvider, isDark),

                // Progress blob with weekly stats
                _buildProgressBlob(
                  context,
                  weeklyCompletedTotal,
                  weeklyGoal,
                  isDark,
                  dashboardProvider,
                  householdProvider.members,
                ),

                // Tab pills with search toggle
                _buildTabPills(isDark, pendingCount, completedCount, taskProvider),

                // Search bar (when visible)
                _buildSearchBar(isDark, taskProvider),

                // Category filter chips
                _buildCategoryChips(isDark),

                // Quick add input
                _buildQuickAddInput(isDark, taskProvider, household.id),

                // Bulk action bar (when in selection mode)
                if (_isSelectionMode)
                  _buildBulkActionBar(isDark, taskProvider),

                // Task list (with skeleton loading)
                if (taskProvider.isLoading)
                  const TaskListSkeleton(count: 5)
                else if (filteredTasks.isEmpty)
                  _buildEmptyState(isDark)
                else
                  ...filteredTasks.asMap().entries.map((entry) =>
                      OrganicTaskCard(
                        task: entry.value,
                        index: entry.key,
                        taskProvider: taskProvider,
                        isSelected: _selectedTaskIds.contains(entry.value.id),
                        isSelectionMode: _isSelectionMode,
                        onLongPress: () => _toggleSelection(entry.value.id),
                        onSelectionTap: () => _toggleSelection(entry.value.id),
                      )),

                // Space for bottom nav and FAB
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBlob({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
    required AnimationController controller,
    bool reverse = false,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = reverse
            ? 1 - controller.value
            : controller.value;
        final offset = math.sin(value * 2 * math.pi) * 20;

        return Positioned(
          top: top != null ? top + offset : null,
          bottom: bottom != null ? bottom - offset : null,
          left: left != null ? left + offset * 0.5 : null,
          right: right != null ? right - offset * 0.5 : null,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [color, color.withValues(alpha: 0)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(size * 0.6),
                topRight: Radius.circular(size * 0.4),
                bottomLeft: Radius.circular(size * 0.3),
                bottomRight: Radius.circular(size * 0.7),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider authProvider, bool isDark) {
    final profile = authProvider.profile;
    final displayName = profile?.displayName ?? 'there';
    final firstName = displayName.split(' ').first;
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMM d');

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(now),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ).createShader(bounds),
                    child: Text(
                      'Hey, $firstName',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/home?tab=2'),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: profile?.avatarUrl == null
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  image: profile?.avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(profile!.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profile?.avatarUrl == null
                    ? Center(
                        child: Text(
                          firstName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF102219) : Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBlob(
    BuildContext context,
    int completed,
    int goal,
    bool isDark,
    DashboardProvider dashboardProvider,
    List members,
  ) {
    final progress = goal > 0 ? (completed / goal).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(8),
          ),
          border: Border.all(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Circular progress
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CustomPaint(
                    painter: _CircularProgressPainter(
                      progress: progress,
                      progressColor: AppColors.primary,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF162E22) : Colors.white,
                        ),
                        child: Center(
                          child: Text(
                            '$completed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimary : Colors.grey[800],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "This week's progress",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$completed tasks completed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimary : Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Per-person breakdown
            if (dashboardProvider.taskCounts.isNotEmpty) ...[
              SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: members.map((member) {
                  final count = dashboardProvider.taskCounts[member.userId] ?? 0;
                  final name = member.displayName ?? 'Unknown';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$name: $count',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textPrimary : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabPills(bool isDark, int pendingCount, int completedCount, TaskProvider taskProvider) {
    final tabs = ['today', 'upcoming', 'done'];
    final hasActiveSearch = taskProvider.searchQuery.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          // Tab pills - wrap in Flexible to prevent overflow
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: tabs.map((tab) {
                  final isActive = _activeTab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isActive
                              ? const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryDark],
                                )
                              : null,
                          color: isActive
                              ? null
                              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tab[0].toUpperCase() + tab.substring(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive
                                ? (isDark ? const Color(0xFF102219) : Colors.white)
                                : (isDark ? AppColors.textSecondary : Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sort dropdown button (hidden on "done" tab - always sorted by recent)
          if (_activeTab != 'done')
            PopupMenuButton<_TaskSortOrder>(
              initialValue: _sortOrder,
              onSelected: (order) => setState(() => _sortOrder = order),
              tooltip: 'Sort by',
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sort,
                      size: 20,
                      color: isDark ? AppColors.textSecondary : Colors.grey[600],
                    ),
                  ],
                ),
              ),
              itemBuilder: (context) => _TaskSortOrder.values.map((order) {
                return PopupMenuItem(
                  value: order,
                  child: Row(
                    children: [
                      if (_sortOrder == order)
                        Icon(Icons.check, size: 18, color: AppColors.primary)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(order.label),
                    ],
                  ),
                );
              }).toList(),
            ),
          if (_activeTab != 'done')
            const SizedBox(width: 8),
          // Search toggle button
          GestureDetector(
            onTap: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  taskProvider.clearSearch();
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (_showSearch || hasActiveSearch)
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _showSearch ? Icons.close : Icons.search,
                size: 20,
                color: (_showSearch || hasActiveSearch)
                    ? AppColors.primary
                    : (isDark ? AppColors.textSecondary : Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddInput(bool isDark, TaskProvider taskProvider, String householdId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: AnimatedCrossFade(
        firstChild: GestureDetector(
          onTap: () => setState(() => _showQuickAdd = true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: isDark ? AppColors.textSecondary : Colors.grey[500],
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick add task...',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondary : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
        secondChild: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quickAddController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _createQuickTask(taskProvider, householdId),
                  decoration: InputDecoration(
                    hintText: 'Task name',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.textSecondary : Colors.grey[500],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : Colors.grey[900],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  _quickAddController.clear();
                  setState(() => _showQuickAdd = false);
                },
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: isDark ? AppColors.textSecondary : Colors.grey[500],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () => _createQuickTask(taskProvider, householdId),
                  icon: const Icon(Icons.send_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        crossFadeState: _showQuickAdd ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    final categories = [
      ('Kitchen', AppColors.kitchen),
      ('Bathroom', AppColors.bathroom),
      ('Living', AppColors.living),
      ('Outdoor', AppColors.outdoor),
      ('Pet', AppColors.pet),
      ('Laundry', AppColors.laundry),
      ('Grocery', AppColors.grocery),
      ('Maintenance', AppColors.maintenance),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: _selectedCategory == null,
              onSelected: (_) => setState(() => _selectedCategory = null),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: _selectedCategory == null
                    ? AppColors.primary
                    : (isDark ? AppColors.textSecondary : Colors.grey[600]),
                fontWeight: _selectedCategory == null ? FontWeight.w600 : FontWeight.normal,
              ),
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
              side: BorderSide.none,
            ),
          ),
          // Category chips
          ...categories.map((cat) {
            final name = cat.$1;
            final color = cat.$2;
            final isSelected = _selectedCategory?.toLowerCase() == name.toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(name),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _selectedCategory = isSelected ? null : name;
                }),
                selectedColor: color.withValues(alpha: 0.2),
                checkmarkColor: color,
                labelStyle: TextStyle(
                  color: isSelected ? color : (isDark ? AppColors.textSecondary : Colors.grey[600]),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
                side: BorderSide.none,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, TaskProvider taskProvider) {
    if (!_showSearch) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (value) => taskProvider.setSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          hintStyle: TextStyle(
            color: isDark ? AppColors.textSecondary : Colors.grey[500],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? AppColors.textSecondary : Colors.grey[500],
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? AppColors.textSecondary : Colors.grey[500],
                  ),
                  onPressed: () {
                    _searchController.clear();
                    taskProvider.clearSearch();
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(
          color: isDark ? AppColors.textPrimary : Colors.grey[900],
        ),
      ),
    );
  }

  Widget _buildBulkActionBar(bool isDark, TaskProvider taskProvider) {
    final selectedCount = _selectedTaskIds.length;
    final incompleteCount = taskProvider.tasks
        .where((t) => _selectedTaskIds.contains(t.id) && !t.isCompleted)
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Selection count
          Expanded(
            child: Text(
              '$selectedCount selected',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : Colors.grey[900],
              ),
            ),
          ),
          // Complete button
          if (incompleteCount > 0)
            TextButton.icon(
              onPressed: () => _completeSelectedTasks(taskProvider),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Complete'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          // Delete button
          TextButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Tasks'),
                  content: Text('Delete $selectedCount task${selectedCount > 1 ? 's' : ''}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await _deleteSelectedTasks(taskProvider);
              }
            },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          // Clear selection button
          IconButton(
            onPressed: _clearSelection,
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Clear selection',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    String message;
    String subtitle;
    String? actionLabel;

    switch (_activeTab) {
      case 'today':
        message = 'Nothing due today';
        subtitle = 'Enjoy your free time or add a new task';
        actionLabel = 'Add Task';
        break;
      case 'upcoming':
        message = 'No upcoming tasks';
        subtitle = 'Add tasks to plan ahead';
        actionLabel = 'Add Task';
        break;
      case 'done':
        message = 'No completed tasks';
        subtitle = 'Complete tasks to see them here';
        actionLabel = null; // No action for done tab
        break;
      default:
        message = 'No tasks';
        subtitle = 'Tap + to create one';
        actionLabel = 'Add Task';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: EmptyState(
        icon: Icons.check_circle_outline,
        title: message,
        subtitle: subtitle,
        iconColor: isDark ? AppColors.textSecondary : Colors.grey[400],
        actionLabel: actionLabel,
        onAction: actionLabel != null ? () => context.push('/create-task') : null,
      ),
    );
  }
}

// Custom painter for circular progress
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 6.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2, // Start from top
      2 * math.pi * progress, // Sweep angle
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

enum _TaskSortOrder {
  dueDate('Due Date'),
  priority('Priority'),
  createdAt('Newest'),
  alphabetical('A-Z');

  const _TaskSortOrder(this.label);
  final String label;
}
