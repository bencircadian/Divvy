import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

/// A card showing weekly overview with two stats side by side.
/// Example: "TOTAL TIME: 12h" and "RANK: #1 in Household"
class WeeklyOverviewCard extends StatelessWidget {
  final String totalTimeLabel;
  final String totalTimeValue;
  final String rankLabel;
  final String rankValue;
  final String? rankSubtitle;

  const WeeklyOverviewCard({
    super.key,
    this.totalTimeLabel = 'TOTAL TIME',
    required this.totalTimeValue,
    this.rankLabel = 'RANK',
    required this.rankValue,
    this.rankSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDarkMode : AppColors.primary;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
        boxShadow: isDark ? null : AppShadows.cardShadow(isDark),
      ),
      child: Row(
        children: [
          // Total Time
          Expanded(
            child: _buildStatColumn(
              context,
              icon: Icons.timer_outlined,
              label: totalTimeLabel,
              value: totalTimeValue,
              color: primaryColor,
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 60,
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          // Rank
          Expanded(
            child: _buildStatColumn(
              context,
              icon: Icons.emoji_events_outlined,
              label: rankLabel,
              value: rankValue,
              subtitle: rankSubtitle,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[900],
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}
