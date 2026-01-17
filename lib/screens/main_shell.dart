import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/household_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/bundles/bundle_preference_dialog.dart';
import 'dashboard/dashboard_screen.dart';
import 'home/home_screen.dart';
import 'onboarding/feature_tour_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _hasShownBundleDialog = false;
  bool _showOnboarding = false;
  bool _hasCheckedOnboarding = false;

  @override
  void initState() {
    super.initState();
    // Check for first launch and show onboarding
    _checkFirstLaunch();
    // Show bundle preference dialog after first frame if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBundlePreference();
    });
  }

  Future<void> _checkFirstLaunch() async {
    if (_hasCheckedOnboarding) return;
    _hasCheckedOnboarding = true;
    final isFirstLaunch = await FeatureTourScreen.isFirstLaunch();
    if (isFirstLaunch && mounted) {
      setState(() => _showOnboarding = true);
    }
  }

  void _checkBundlePreference() {
    if (_hasShownBundleDialog) return;

    final authProvider = context.read<AuthProvider>();
    if (authProvider.needsBundlePreferencePrompt) {
      _hasShownBundleDialog = true;
      BundlePreferenceDialog.show(context);
    }
  }

  final _screens = const [
    DashboardScreen(),
    HomeScreen(),
    SettingsScreen(),
  ];

  final _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Overview'),
    _NavItem(icon: Icons.checklist_rounded, label: 'My Tasks'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _showHouseholdSheet() {
    final householdProvider = context.read<HouseholdProvider>();
    _showHouseholdInfo(context, householdProvider.currentHousehold, householdProvider.members);
  }

  void _openNotifications() {
    context.push('/notifications');
  }

  void _addTask() {
    context.push('/create-task');
  }

  @override
  Widget build(BuildContext context) {
    // Show onboarding tour on first launch
    if (_showOnboarding) {
      return FeatureTourScreen(
        onComplete: () => setState(() => _showOnboarding = false),
      );
    }

    final householdProvider = context.watch<HouseholdProvider>();
    final authProvider = context.watch<AuthProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final household = householdProvider.currentHousehold;
    final unreadCount = notificationProvider.unreadCount;
    final userName = authProvider.profile?.displayName ?? 'User';

    return Scaffold(
      body: Column(
        children: [
          // Custom Header
          _buildCustomHeader(
            context,
            userName: userName,
            householdName: household?.name,
            unreadCount: unreadCount,
          ),
          // Main Content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildOrganicBottomNav(context),
      floatingActionButton: _buildOrganicFab(context),
    );
  }

  Widget _buildCustomHeader(
    BuildContext context, {
    required String userName,
    String? householdName,
    required int unreadCount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDarkMode : AppColors.primary;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          // User Avatar with online indicator
          GestureDetector(
            onTap: _showHouseholdSheet,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    userName[0].toUpperCase(),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Greeting text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back,',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                ),
                Text(
                  '$userName!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                ),
              ],
            ),
          ),
          // Notification button
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              backgroundColor: AppColors.error,
              label: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            onPressed: _openNotifications,
            tooltip: 'Notifications',
          ),
          // Household button
          IconButton(
            icon: Icon(
              Icons.group_outlined,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            onPressed: _showHouseholdSheet,
            tooltip: 'Household info',
          ),
        ],
      ),
    );
  }

  void _showHouseholdInfo(
    BuildContext context,
    dynamic household,
    List members,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.home_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  household?.name ?? 'Household',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            Divider(height: AppSpacing.lg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.vpn_key_outlined),
              title: const Text('Invite Code'),
              subtitle: Text(
                household?.inviteCode ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: household?.inviteCode ?? ''),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invite code copied!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Members (${members.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: AppSpacing.sm),
            ...members.map((member) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(
                      (member.displayName ?? 'U')[0].toUpperCase(),
                    ),
                  ),
                  title: Text(member.displayName ?? 'Unknown'),
                  trailing: member.isAdmin
                      ? Chip(
                          label: const Text('Admin'),
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                        )
                      : null,
                )),
            SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganicBottomNav(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDarkMode : AppColors.primary;
    final taskProvider = context.watch<TaskProvider>();
    final overdueCount = taskProvider.pendingTasks.where((t) => t.isOverdue).length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDarkAlt : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.cardBorder : Colors.grey[200]!,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _currentIndex == index;

              return GestureDetector(
                onTap: () => _onTabTapped(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppAnimations.fast,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10), // Square-ish rounded corners
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Show badge on Tasks tab (index 1) if there are overdue tasks
                      Badge(
                        isLabelVisible: index == 1 && overdueCount > 0,
                        backgroundColor: AppColors.error,
                        label: Text(
                          overdueCount > 9 ? '9+' : '$overdueCount',
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                        child: Icon(
                          item.icon,
                          size: 24,
                          color: isSelected
                              ? primaryColor
                              : (isDark ? Colors.grey[500] : Colors.grey[600]),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? primaryColor
                              : (isDark ? Colors.grey[500] : Colors.grey[600]),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildOrganicFab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDarkMode : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _addTask,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
