import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/tasks/note_input.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _activeTab = 'today';
  late AnimationController _blobController;
  String? _lastLoadedHouseholdId;

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
    super.dispose();
  }

  List<Task> _getFilteredTasks(TaskProvider taskProvider) {
    switch (_activeTab) {
      case 'today':
        // Include tasks due today AND tasks without due dates (anytime tasks)
        final todayTasks = taskProvider.incompleteTodayTasks;
        final anytimeTasks = taskProvider.pendingTasks
            .where((t) => t.dueDate == null)
            .toList();
        return [...todayTasks, ...anytimeTasks];
      case 'upcoming':
        return taskProvider.upcomingUniqueTasks;
      case 'done':
        return taskProvider.completedTasksSortedByRecent;
      default:
        return taskProvider.pendingTasks;
    }
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
              await householdProvider.loadUserHousehold();
              if (household != null) {
                await taskProvider.loadTasks(household.id);
                await dashboardProvider.loadDashboardData(household.id);
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

                // Tab pills
                _buildTabPills(isDark, pendingCount, completedCount),

                // Task list
                if (filteredTasks.isEmpty)
                  _buildEmptyState(isDark)
                else
                  ...filteredTasks.asMap().entries.map((entry) =>
                      _buildOrganicTaskCard(entry.value, entry.key, taskProvider, isDark)),

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
              onTap: () {
                // Navigate to settings/profile
              },
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
              const SizedBox(height: 16),
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

  Widget _buildTabPills(bool isDark, int pendingCount, int completedCount) {
    final tabs = ['today', 'upcoming', 'done'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: tabs.map((tab) {
          final isActive = _activeTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
    );
  }

  Widget _buildOrganicTaskCard(Task task, int index, TaskProvider taskProvider, bool isDark) {
    final currentUserId = SupabaseService.currentUser?.id;
    final isOwnedByMe = task.assignedTo == currentUserId;
    final categoryColor = _getCategoryColor(task.title);

    // Alternate border radius for organic feel
    final isEven = index % 2 == 0;
    final borderRadius = isEven
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: GestureDetector(
        onTap: () => context.push('/task/${task.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: task.isCompleted
                ? (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[100])
                : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
            borderRadius: borderRadius,
            border: Border.all(
              color: task.isCompleted
                  ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!)
                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]!),
            ),
          ),
          child: Opacity(
            opacity: task.isCompleted ? 0.6 : 1.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => taskProvider.toggleTaskComplete(task),
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted ? AppColors.primary : Colors.transparent,
                      border: task.isCompleted
                          ? null
                          : Border.all(color: categoryColor, width: 2),
                    ),
                    child: task.isCompleted
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: isDark ? const Color(0xFF102219) : Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),

                // Task content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted
                              ? (isDark ? AppColors.textSecondary : Colors.grey[500])
                              : (isDark ? AppColors.textPrimary : Colors.grey[900]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Category tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _getCategoryName(task.title),
                              style: TextStyle(
                                fontSize: 12,
                                color: categoryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Due date
                          if (task.dueDate != null)
                            Text(
                              _formatDueDate(task.dueDate!),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondary : Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Assignee avatar
                if (task.assignedToName != null)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey[200],
                    ),
                    child: Center(
                      child: Text(
                        task.assignedToName![0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimary : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('kitchen') || lowerTitle.contains('dish') || lowerTitle.contains('cook')) {
      return AppColors.kitchen;
    } else if (lowerTitle.contains('bathroom') || lowerTitle.contains('toilet') || lowerTitle.contains('shower')) {
      return AppColors.bathroom;
    } else if (lowerTitle.contains('living') || lowerTitle.contains('vacuum') || lowerTitle.contains('dust')) {
      return AppColors.living;
    } else if (lowerTitle.contains('outdoor') || lowerTitle.contains('garden') || lowerTitle.contains('yard')) {
      return AppColors.outdoor;
    } else if (lowerTitle.contains('pet') || lowerTitle.contains('dog') || lowerTitle.contains('cat') || lowerTitle.contains('feed')) {
      return AppColors.pet;
    } else if (lowerTitle.contains('laundry') || lowerTitle.contains('wash') || lowerTitle.contains('clothes')) {
      return AppColors.laundry;
    } else if (lowerTitle.contains('grocery') || lowerTitle.contains('shop') || lowerTitle.contains('buy')) {
      return AppColors.grocery;
    } else if (lowerTitle.contains('fix') || lowerTitle.contains('repair') || lowerTitle.contains('maintenance')) {
      return AppColors.maintenance;
    }
    return AppColors.primary;
  }

  String _getCategoryName(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('kitchen') || lowerTitle.contains('dish') || lowerTitle.contains('cook')) {
      return 'Kitchen';
    } else if (lowerTitle.contains('bathroom') || lowerTitle.contains('toilet') || lowerTitle.contains('shower')) {
      return 'Bathroom';
    } else if (lowerTitle.contains('living') || lowerTitle.contains('vacuum') || lowerTitle.contains('dust')) {
      return 'Living';
    } else if (lowerTitle.contains('outdoor') || lowerTitle.contains('garden') || lowerTitle.contains('yard')) {
      return 'Outdoor';
    } else if (lowerTitle.contains('pet') || lowerTitle.contains('dog') || lowerTitle.contains('cat') || lowerTitle.contains('feed')) {
      return 'Pet';
    } else if (lowerTitle.contains('laundry') || lowerTitle.contains('wash') || lowerTitle.contains('clothes')) {
      return 'Laundry';
    } else if (lowerTitle.contains('grocery') || lowerTitle.contains('shop') || lowerTitle.contains('buy')) {
      return 'Grocery';
    } else if (lowerTitle.contains('fix') || lowerTitle.contains('repair') || lowerTitle.contains('maintenance')) {
      return 'Maintenance';
    }
    return 'Task';
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow';
    } else if (taskDate.isBefore(today.add(const Duration(days: 7)))) {
      return DateFormat('EEE').format(dueDate);
    } else {
      return DateFormat('MMM d').format(dueDate);
    }
  }

  Widget _buildEmptyState(bool isDark) {
    String message;
    String subtitle;

    switch (_activeTab) {
      case 'today':
        message = 'Nothing due today';
        subtitle = 'Enjoy your free time!';
        break;
      case 'upcoming':
        message = 'No upcoming tasks';
        subtitle = 'Add tasks to plan ahead';
        break;
      case 'done':
        message = 'No completed tasks';
        subtitle = 'Complete tasks to see them here';
        break;
      default:
        message = 'No tasks';
        subtitle = 'Tap + to create one';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: isDark ? AppColors.textSecondary : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimary : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondary : Colors.grey[500],
            ),
          ),
        ],
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
