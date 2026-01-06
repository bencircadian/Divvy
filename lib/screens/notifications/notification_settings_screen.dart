import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final prefs = notificationProvider.preferences;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notification Settings'),
      ),
      body: prefs == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSection(
                  'General',
                  [
                    SwitchListTile(
                      title: const Text('Push notifications'),
                      subtitle: const Text('Receive push notifications on your device'),
                      value: prefs.pushEnabled,
                      onChanged: (value) => _updatePreference(
                        prefs.copyWith(pushEnabled: value),
                      ),
                    ),
                  ],
                ),
                _buildSection(
                  'Notification Types',
                  [
                    SwitchListTile(
                      title: const Text('Task assignments'),
                      subtitle: const Text('When a task is assigned to you'),
                      value: prefs.taskAssignedEnabled,
                      onChanged: (value) => _updatePreference(
                        prefs.copyWith(taskAssignedEnabled: value),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Task completions'),
                      subtitle: const Text('When someone completes a task'),
                      value: prefs.taskCompletedEnabled,
                      onChanged: (value) => _updatePreference(
                        prefs.copyWith(taskCompletedEnabled: value),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Mentions'),
                      subtitle: const Text('When someone @mentions you in a note'),
                      value: prefs.mentionsEnabled,
                      onChanged: (value) => _updatePreference(
                        prefs.copyWith(mentionsEnabled: value),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Due date reminders'),
                      subtitle: const Text('Reminders before tasks are due'),
                      value: prefs.dueRemindersEnabled,
                      onChanged: (value) => _updatePreference(
                        prefs.copyWith(dueRemindersEnabled: value),
                      ),
                    ),
                  ],
                ),
                if (prefs.dueRemindersEnabled)
                  _buildSection(
                    'Reminder Timing',
                    [
                      ListTile(
                        title: const Text('Remind me before'),
                        subtitle: Text(_formatMinutes(prefs.reminderBeforeMinutes)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showReminderTimingPicker(prefs),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...children,
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else if (minutes == 60) {
      return '1 hour';
    } else if (minutes < 1440) {
      return '${minutes ~/ 60} hours';
    } else {
      return '${minutes ~/ 1440} day${minutes >= 2880 ? 's' : ''}';
    }
  }

  void _updatePreference(dynamic prefs) {
    context.read<NotificationProvider>().savePreferences(prefs);
  }

  void _showReminderTimingPicker(dynamic currentPrefs) {
    final options = [
      (15, '15 minutes'),
      (30, '30 minutes'),
      (60, '1 hour'),
      (120, '2 hours'),
      (1440, '1 day'),
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remind me before'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return RadioListTile<int>(
              title: Text(option.$2),
              value: option.$1,
              groupValue: currentPrefs.reminderBeforeMinutes,
              onChanged: (value) {
                if (value != null) {
                  _updatePreference(
                    currentPrefs.copyWith(reminderBeforeMinutes: value),
                  );
                  Navigator.pop(ctx);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
