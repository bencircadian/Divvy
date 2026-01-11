import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// A reusable drag handle for bottom sheets.
///
/// Provides consistent styling across all bottom sheets.
class BottomSheetHandle extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsets margin;

  const BottomSheetHandle({
    super.key,
    this.width = 40,
    this.height = 4,
    this.margin = const EdgeInsets.only(top: 12, bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// A bottom sheet header with handle, title, and optional close button.
class BottomSheetHeader extends StatelessWidget {
  final String title;
  final bool showHandle;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final Widget? trailing;

  const BottomSheetHeader({
    super.key,
    required this.title,
    this.showHandle = true,
    this.showCloseButton = false,
    this.onClose,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHandle) const BottomSheetHandle(),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              if (showCloseButton)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose ?? () => Navigator.pop(context),
                ),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge,
                  textAlign: showCloseButton ? TextAlign.start : TextAlign.center,
                ),
              ),
              if (trailing != null)
                trailing!
              else if (showCloseButton)
                const SizedBox(width: 48), // Balance for close button
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
