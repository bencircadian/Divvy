import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../providers/household_provider.dart';
import '../../services/onboarding_progress_service.dart';

/// A collapsible onboarding checklist widget (like Loom's onboarding).
///
/// Shows progress on key actions after initial setup.
class OnboardingChecklist extends StatefulWidget {
  /// Callback when user taps "invite member" item
  final VoidCallback? onInviteTap;

  /// Callback when user taps "complete profile" item
  final VoidCallback? onProfileTap;

  const OnboardingChecklist({
    super.key,
    this.onInviteTap,
    this.onProfileTap,
  });

  @override
  State<OnboardingChecklist> createState() => _OnboardingChecklistState();
}

class _OnboardingChecklistState extends State<OnboardingChecklist>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.value = _isExpanded ? 1.0 : 0.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _dismiss() async {
    await OnboardingProgressService.dismiss();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch household provider for member count changes
    final householdProvider = context.watch<HouseholdProvider>();
    final memberCount = householdProvider.members.length;

    // Auto-mark invite as complete if household has 2+ members
    final hasMultipleMembers = memberCount >= 2;
    if (hasMultipleMembers && !OnboardingProgressService.hasInvitedFirstMember) {
      // Schedule this for after the build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        OnboardingProgressService.markFirstMemberInvited();
        if (mounted) setState(() {});
      });
    }

    // Don't show if dismissed or complete
    if (!OnboardingProgressService.shouldShow) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate progress including auto-completed items
    final hasInvited = OnboardingProgressService.hasInvitedFirstMember || hasMultipleMembers;
    final completedCount = _getCompletedCount(hasInvited);
    final progress = completedCount / 3;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : Colors.grey[200]!,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Progress indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                        Center(
                          child: Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Getting started',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimary
                                : Colors.grey[900],
                          ),
                        ),
                        Text(
                          '$completedCount/3 completed',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondary
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand/collapse icon
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: isDark ? AppColors.textSecondary : Colors.grey[600],
                    ),
                  ),
                  // Dismiss button
                  IconButton(
                    onPressed: _dismiss,
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: isDark ? AppColors.textSecondary : Colors.grey[500],
                    ),
                    tooltip: 'Dismiss checklist',
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                const Divider(height: 1),
                _buildChecklistItem(
                  icon: Icons.check_circle_outline,
                  title: 'Complete your first task',
                  subtitle: 'Mark a task as done',
                  isCompleted: OnboardingProgressService.hasCompletedFirstTask,
                  onTap: () {
                    // Just stay on home - user can complete a task here
                  },
                ),
                _buildChecklistItem(
                  icon: Icons.person_add_outlined,
                  title: 'Invite a household member',
                  subtitle: hasMultipleMembers
                      ? 'You have $memberCount members'
                      : 'Share tasks with others',
                  isCompleted: hasInvited,
                  onTap: widget.onInviteTap ?? () {
                    // Default: show a snackbar with instructions
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Go to Settings tab to invite members'),
                      ),
                    );
                  },
                ),
                _buildChecklistItem(
                  icon: Icons.person_outline,
                  title: 'Complete your profile',
                  subtitle: 'Add your name and photo',
                  isCompleted: OnboardingProgressService.hasCompletedProfile,
                  onTap: widget.onProfileTap ?? () {
                    // Default: show a snackbar with instructions
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Go to Settings tab to edit your profile'),
                      ),
                    );
                  },
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getCompletedCount(bool hasInvited) {
    int count = 0;
    if (OnboardingProgressService.hasCompletedFirstTask) count++;
    if (hasInvited) count++;
    if (OnboardingProgressService.hasCompletedProfile) count++;
    return count;
  }

  Widget _buildChecklistItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: isCompleted ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: isLast
            ? null
            : BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.cardBorder : Colors.grey[200]!,
                  ),
                ),
              ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppColors.success : Colors.transparent,
                border: isCompleted
                    ? null
                    : Border.all(
                        color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                        width: 2,
                      ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isCompleted
                          ? (isDark ? AppColors.textSecondary : Colors.grey[500])
                          : (isDark ? AppColors.textPrimary : Colors.grey[900]),
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondary : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            if (!isCompleted)
              Icon(
                Icons.chevron_right,
                color: isDark ? AppColors.textSecondary : Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}
