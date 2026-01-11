import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/household_provider.dart';
import '../providers/notification_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'home/home_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    HomeScreen(),
    SettingsScreen(),
  ];

  final _navItems = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.checklist_rounded, label: 'Tasks'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _showHouseholdSheet() {
    final householdProvider = context.read<HouseholdProvider>();
    _showHouseholdInfo(context, householdProvider.currentHousehold, householdProvider.members);
  }

  void _signOut() {
    context.read<AuthProvider>().signOut();
  }

  void _openNotifications() {
    context.push('/notifications');
  }

  void _addTask() {
    context.push('/create-task');
  }

  @override
  Widget build(BuildContext context) {
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
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    userName[0].toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary,
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
                      color: AppColors.primary,
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
        padding: const EdgeInsets.all(24),
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
                const SizedBox(width: 8),
                Text(
                  household?.name ?? 'Household',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
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
            const SizedBox(height: 8),
            Text(
              'Members (${members.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganicBottomNav(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 24,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.grey[500] : Colors.grey[600]),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
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

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _addTask,
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: isDark ? AppColors.backgroundDarkDeep : Colors.white,
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
