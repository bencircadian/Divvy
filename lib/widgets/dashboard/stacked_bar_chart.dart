import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

/// A segment of the stacked bar chart.
class BarSegment {
  final String id;
  final String label;
  final int value;
  final Color color;

  const BarSegment({
    required this.id,
    required this.label,
    required this.value,
    required this.color,
  });
}

/// A horizontal stacked bar chart showing distribution across segments.
class StackedBarChart extends StatelessWidget {
  final List<BarSegment> segments;
  final double height;
  final double borderRadius;
  final bool showLegend;
  final bool showValues;
  final VoidCallback? onTap;

  const StackedBarChart({
    super.key,
    required this.segments,
    this.height = 28,
    this.borderRadius = 8,
    this.showLegend = true,
    this.showValues = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = segments.fold(0, (sum, s) => sum + s.value);

    if (total == 0) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.grey[200],
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stacked bar
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Row(
                children: segments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final segment = entry.value;
                  final flex = segment.value;
                  final isFirst = index == 0;
                  final isLast = index == segments.length - 1;

                  return Expanded(
                    flex: flex,
                    child: Container(
                      decoration: BoxDecoration(
                        color: segment.color,
                        borderRadius: BorderRadius.horizontal(
                          left: isFirst ? Radius.circular(borderRadius) : Radius.zero,
                          right: isLast ? Radius.circular(borderRadius) : Radius.zero,
                        ),
                      ),
                      child: showValues && segment.value > 0
                          ? Center(
                              child: Text(
                                '${segment.value}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // Legend
        if (showLegend) ...[
          SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: segments.where((s) => s.value > 0).map((segment) {
              final percentage = ((segment.value / total) * 100).round();
              return _LegendItem(
                color: segment.color,
                label: segment.label,
                value: segment.value,
                percentage: percentage,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  final int percentage;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($value)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

/// A list of member colors for consistent coloring across the app.
class MemberColors {
  static const List<Color> colors = [
    Color(0xFF4DB6AC), // Teal
    Color(0xFFE07A5F), // Copper
    Color(0xFFF67280), // Rose
    Color(0xFF9575CD), // Purple
    Color(0xFF64B5F6), // Blue
    Color(0xFFFFB74D), // Orange
    Color(0xFF81C784), // Green
    Color(0xFFBA68C8), // Pink
  ];

  static Color getColor(int index) {
    return colors[index % colors.length];
  }

  static Color getColorForId(String id, List<String> allIds) {
    final index = allIds.indexOf(id);
    return getColor(index >= 0 ? index : 0);
  }
}
