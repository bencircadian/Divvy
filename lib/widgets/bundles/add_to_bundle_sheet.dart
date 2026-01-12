import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/task_bundle.dart';
import '../../providers/bundle_provider.dart';
import '../../providers/household_provider.dart';
import 'create_bundle_sheet.dart';

/// Bottom sheet for adding a task to a bundle.
class AddToBundleSheet extends StatefulWidget {
  final String taskId;
  final String? currentBundleId;

  const AddToBundleSheet({
    super.key,
    required this.taskId,
    this.currentBundleId,
  });

  @override
  State<AddToBundleSheet> createState() => _AddToBundleSheetState();
}

class _AddToBundleSheetState extends State<AddToBundleSheet> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final householdId = context.read<HouseholdProvider>().currentHousehold?.id;
      if (householdId != null) {
        context.read<BundleProvider>().loadBundles(householdId);
      }
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

  Future<void> _addToBundle(TaskBundle bundle) async {
    setState(() => _isLoading = true);

    final success = await context.read<BundleProvider>().addTaskToBundle(
      taskId: widget.taskId,
      bundleId: bundle.id,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, bundle);
      }
    }
  }

  Future<void> _removeFromBundle() async {
    setState(() => _isLoading = true);

    final success = await context.read<BundleProvider>().removeTaskFromBundle(
      widget.taskId,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context, null);
      }
    }
  }

  Future<void> _createNewBundle() async {
    final bundle = await showModalBottomSheet<TaskBundle>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CreateBundleSheet(),
    );

    if (bundle != null && mounted) {
      await _addToBundle(bundle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bundleProvider = context.watch<BundleProvider>();
    final bundles = bundleProvider.bundles;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
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
                    'Add to Bundle',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (widget.currentBundleId != null)
                    TextButton(
                      onPressed: _isLoading ? null : _removeFromBundle,
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ),

            // Loading or content
            if (_isLoading || bundleProvider.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else if (bundles.isEmpty)
              Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'No bundles yet',
                      style: theme.textTheme.titleMedium,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Create a bundle to group related tasks',
                      style: theme.textTheme.bodySmall,
                    ),
                    SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: _createNewBundle,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Bundle'),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  children: [
                    // Create new bundle option
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.add,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: const Text('Create New Bundle'),
                        onTap: _createNewBundle,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),

                    // Existing bundles
                    ...bundles.map((bundle) {
                      final isSelected = bundle.id == widget.currentBundleId;
                      final color = _parseColor(bundle.color);

                      return Card(
                        color: isSelected ? color.withValues(alpha: 0.1) : null,
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getIconData(bundle.icon),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(bundle.name),
                          subtitle: Text('${bundle.totalTasks} tasks'),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: color)
                              : const Icon(Icons.chevron_right),
                          onTap: isSelected ? null : () => _addToBundle(bundle),
                        ),
                      );
                    }),
                    SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
