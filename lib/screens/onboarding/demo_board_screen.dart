import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/task.dart';
import '../../providers/demo_provider.dart';
import '../../utils/category_utils.dart';

/// Interactive demo board that lets users experience the app before signing up.
class DemoBoardScreen extends StatefulWidget {
  const DemoBoardScreen({super.key});

  @override
  State<DemoBoardScreen> createState() => _DemoBoardScreenState();
}

class _DemoBoardScreenState extends State<DemoBoardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DemoProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final demoProvider = context.watch<DemoProvider>();
    final todayTasks = demoProvider.todayTasks;
    final otherPendingTasks = demoProvider.pendingTasks
        .where((t) => !todayTasks.contains(t))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey[100],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Demo Mode',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ).createShader(bounds),
                    child: const Text(
                      'Try it out!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap tasks to mark them complete. Swipe left for quick actions.',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? AppColors.textSecondary : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Task list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  if (todayTasks.isNotEmpty) ...[
                    _buildSectionHeader('Today', todayTasks.length, isDark),
                    ...todayTasks.asMap().entries.map((entry) =>
                        _DemoTaskCard(
                          task: entry.value,
                          index: entry.key,
                          onToggle: () => demoProvider.toggleTaskComplete(entry.value),
                        )),
                  ],
                  if (otherPendingTasks.isNotEmpty) ...[
                    _buildSectionHeader('Upcoming', otherPendingTasks.length, isDark),
                    ...otherPendingTasks.asMap().entries.map((entry) =>
                        _DemoTaskCard(
                          task: entry.value,
                          index: entry.key + todayTasks.length,
                          onToggle: () => demoProvider.toggleTaskComplete(entry.value),
                        )),
                  ],
                  if (demoProvider.completedTasks.isNotEmpty) ...[
                    _buildSectionHeader('Completed', demoProvider.completedTasks.length, isDark),
                    ...demoProvider.completedTasks.asMap().entries.map((entry) =>
                        _DemoTaskCard(
                          task: entry.value,
                          index: entry.key + todayTasks.length + otherPendingTasks.length,
                          onToggle: () => demoProvider.toggleTaskComplete(entry.value),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSignUpBar(context, isDark),
    );
  }

  Widget _buildSectionHeader(String title, int count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondary : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondary : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Like what you see?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : Colors.grey[900],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sign up to save your progress and invite your household.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondary : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Sign In'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => context.go('/signup'),
                    child: const Text('Create Account'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoTaskCard extends StatelessWidget {
  final Task task;
  final int index;
  final VoidCallback onToggle;

  const _DemoTaskCard({
    required this.task,
    required this.index,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = CategoryUtils.getCategoryColor(task);

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

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        onToggle();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        decoration: BoxDecoration(
          color: task.isCompleted ? Colors.orange : AppColors.success,
          borderRadius: borderRadius,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              task.isCompleted ? 'Undo' : 'Done',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              task.isCompleted ? Icons.replay : Icons.check,
              color: Colors.white,
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onToggle();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(AppSpacing.md),
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
                  Container(
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
                        if (task.description != null && task.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondary : Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        SizedBox(height: AppSpacing.sm),
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
                                CategoryUtils.getCategoryName(task),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: categoryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
