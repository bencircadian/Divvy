import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final householdProvider = context.watch<HouseholdProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile section
          _buildSectionHeader(context, 'Profile'),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                (authProvider.profile?.displayName ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            title: Text(authProvider.profile?.displayName ?? 'Unknown'),
            subtitle: Text(authProvider.user?.email ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Edit profile
            },
          ),
          const Divider(),

          // Household section
          _buildSectionHeader(context, 'Household'),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(householdProvider.currentHousehold?.name ?? 'No household'),
            subtitle: Text('${householdProvider.members.length} members'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Household settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Invite members'),
            subtitle: Text('Code: ${householdProvider.currentHousehold?.inviteCode ?? ''}'),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                // TODO: Copy invite code
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite code copied!')),
                );
              },
            ),
          ),
          const Divider(),

          // Appearance section
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Theme'),
            subtitle: Text(_getThemeModeLabel(themeProvider.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context, themeProvider),
          ),
          const Divider(),

          // Notifications section
          _buildSectionHeader(context, 'Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notification settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notification-settings'),
          ),
          const Divider(),

          // About section
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About Divvy'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Divvy',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.home_work_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                children: [
                  const Text('A household task management app for families and roommates.'),
                ],
              );
            },
          ),
          const Divider(),

          // Sign out
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[700]),
            title: Text('Sign out', style: TextStyle(color: Colors.red[700])),
            onTap: () => _confirmSignOut(context, authProvider),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  String _getThemeModeLabel(ThemeModeOption mode) {
    switch (mode) {
      case ThemeModeOption.system:
        return 'System default';
      case ThemeModeOption.light:
        return 'Light';
      case ThemeModeOption.dark:
        return 'Dark';
    }
  }

  void _showThemePicker(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose theme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            RadioListTile<ThemeModeOption>(
              value: ThemeModeOption.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
              title: const Text('System default'),
              secondary: const Icon(Icons.settings_suggest),
            ),
            RadioListTile<ThemeModeOption>(
              value: ThemeModeOption.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
              title: const Text('Light'),
              secondary: const Icon(Icons.light_mode),
            ),
            RadioListTile<ThemeModeOption>(
              value: ThemeModeOption.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setThemeMode(value!);
                Navigator.pop(context);
              },
              title: const Text('Dark'),
              secondary: const Icon(Icons.dark_mode),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.signOut();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[700],
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
