import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/app_logo.dart';

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
              backgroundImage: authProvider.profile?.avatarUrl != null
                  ? NetworkImage(authProvider.profile!.avatarUrl!)
                  : null,
              child: authProvider.profile?.avatarUrl == null
                  ? Text(
                      (authProvider.profile?.displayName ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            title: Text(authProvider.profile?.displayName ?? 'Unknown'),
            subtitle: Text(authProvider.user?.email ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Edit profile
            },
          ),
          const Divider(),

          // Linked Accounts section
          _buildSectionHeader(context, 'Linked Accounts'),
          ...authProvider.linkedProviders.map((provider) => ListTile(
            leading: Icon(_getProviderIcon(provider)),
            title: Text(_getProviderDisplayName(provider)),
            subtitle: Text(authProvider.getIdentityEmail(provider) ?? ''),
            trailing: authProvider.linkedProviders.length > 1
                ? TextButton(
                    onPressed: () => _confirmUnlink(context, authProvider, provider),
                    child: const Text('Unlink'),
                  )
                : Chip(
                    label: const Text('Primary'),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  ),
          )),
          // Link existing email account (if signed in with OAuth only)
          if (!authProvider.hasEmailIdentity)
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Link Existing Account'),
              subtitle: const Text('Connect to your email account'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/link-account'),
            ),
          // Link Google (if signed in with email only)
          if (!authProvider.hasGoogleIdentity)
            ListTile(
              leading: const Icon(Icons.g_mobiledata),
              title: const Text('Link Google Account'),
              subtitle: const Text('Sign in faster with Google'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => authProvider.linkGoogleIdentity(),
            ),
          // Link Apple (if signed in with email only and not on Android)
          if (!authProvider.hasAppleIdentity)
            ListTile(
              leading: const Icon(Icons.apple),
              title: const Text('Link Apple Account'),
              subtitle: const Text('Sign in with Apple'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => authProvider.linkAppleIdentity(),
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

          // Display section
          _buildSectionHeader(context, 'Display'),
          SwitchListTile(
            secondary: const Icon(Icons.folder_outlined),
            title: const Text('Task Bundles'),
            subtitle: Text(
              authProvider.bundlesEnabled == true
                  ? 'Group related tasks together'
                  : 'Show all tasks individually',
            ),
            value: authProvider.bundlesEnabled ?? true,
            onChanged: (value) => authProvider.setBundlesPreference(value),
          ),
          const Divider(),

          // Notifications section
          _buildSectionHeader(context, 'Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notification settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notifications/settings'),
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
                applicationName: AppStrings.appName,
                applicationVersion: '1.0.0',
                applicationIcon: const AppLogoIcon(size: 48),
                children: [
                  Text(
                    AppStrings.tagline,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(AppStrings.appDescription),
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
            RadioGroup<ThemeModeOption>(
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ThemeModeOption>(
                    value: ThemeModeOption.system,
                    title: const Text('System default'),
                    secondary: const Icon(Icons.settings_suggest),
                  ),
                  RadioListTile<ThemeModeOption>(
                    value: ThemeModeOption.light,
                    title: const Text('Light'),
                    secondary: const Icon(Icons.light_mode),
                  ),
                  RadioListTile<ThemeModeOption>(
                    value: ThemeModeOption.dark,
                    title: const Text('Dark'),
                    secondary: const Icon(Icons.dark_mode),
                  ),
                ],
              ),
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

  IconData _getProviderIcon(String provider) {
    switch (provider) {
      case 'email':
        return Icons.email;
      case 'google':
        return Icons.g_mobiledata;
      case 'apple':
        return Icons.apple;
      default:
        return Icons.account_circle;
    }
  }

  String _getProviderDisplayName(String provider) {
    switch (provider) {
      case 'email':
        return 'Email & Password';
      case 'google':
        return 'Google';
      case 'apple':
        return 'Apple';
      default:
        return provider;
    }
  }

  void _confirmUnlink(BuildContext context, AuthProvider authProvider, String provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unlink ${_getProviderDisplayName(provider)}?'),
        content: Text('You will no longer be able to sign in with ${_getProviderDisplayName(provider)}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await authProvider.unlinkIdentity(provider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '${_getProviderDisplayName(provider)} unlinked'
                        : authProvider.errorMessage ?? 'Failed to unlink'),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[700],
            ),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
  }
}
