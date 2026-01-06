import 'package:flutter/material.dart';

import '../../models/recurrence_rule.dart';

class RecurrencePicker extends StatefulWidget {
  final RecurrenceRule? initialValue;
  final ValueChanged<RecurrenceRule?> onChanged;

  const RecurrencePicker({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<RecurrencePicker> createState() => _RecurrencePickerState();
}

class _RecurrencePickerState extends State<RecurrencePicker> {
  RecurrenceRule? _rule;

  @override
  void initState() {
    super.initState();
    _rule = widget.initialValue;
  }

  void _showRecurrenceDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RecurrenceOptionsSheet(
        initialRule: _rule,
        onSave: (rule) {
          setState(() => _rule = rule);
          widget.onChanged(rule);
        },
      ),
    );
  }

  void _clearRecurrence() {
    setState(() => _rule = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    if (_rule == null) {
      return OutlinedButton.icon(
        onPressed: _showRecurrenceDialog,
        icon: const Icon(Icons.repeat),
        label: const Text('Add Recurrence'),
      );
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.repeat),
        title: Text(_rule!.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showRecurrenceDialog,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearRecurrence,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurrenceOptionsSheet extends StatefulWidget {
  final RecurrenceRule? initialRule;
  final ValueChanged<RecurrenceRule> onSave;

  const _RecurrenceOptionsSheet({
    this.initialRule,
    required this.onSave,
  });

  @override
  State<_RecurrenceOptionsSheet> createState() => _RecurrenceOptionsSheetState();
}

class _RecurrenceOptionsSheetState extends State<_RecurrenceOptionsSheet> {
  late RecurrenceFrequency _frequency;
  late int _interval;
  late Set<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    _frequency = widget.initialRule?.frequency ?? RecurrenceFrequency.daily;
    _interval = widget.initialRule?.interval ?? 1;
    _selectedDays = widget.initialRule?.days?.toSet() ?? {};
  }

  void _save() {
    List<int>? days;
    if (_frequency == RecurrenceFrequency.weekly && _selectedDays.isNotEmpty) {
      days = _selectedDays.toList()..sort();
    }

    final rule = RecurrenceRule(
      frequency: _frequency,
      interval: _interval,
      days: days,
    );
    widget.onSave(rule);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repeat',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          // Quick options
          Text(
            'Quick options',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickOption('Daily', RecurrenceFrequency.daily, 1),
              _buildQuickOption('Weekly', RecurrenceFrequency.weekly, 1),
              _buildQuickOption('Every 2 weeks', RecurrenceFrequency.weekly, 2),
              _buildQuickOption('Monthly', RecurrenceFrequency.monthly, 1),
            ],
          ),
          const SizedBox(height: 24),

          // Custom frequency
          Text(
            'Or customize',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Every '),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _interval,
                isDense: true,
                items: List.generate(12, (i) => i + 1)
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _interval = value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<RecurrenceFrequency>(
            segments: const [
              ButtonSegment(value: RecurrenceFrequency.daily, label: Text('Day')),
              ButtonSegment(value: RecurrenceFrequency.weekly, label: Text('Week')),
              ButtonSegment(value: RecurrenceFrequency.monthly, label: Text('Month')),
            ],
            selected: {_frequency},
            onSelectionChanged: (selected) {
              setState(() => _frequency = selected.first);
            },
          ),

          // Day selector for weekly
          if (_frequency == RecurrenceFrequency.weekly) ...[
            const SizedBox(height: 16),
            Text(
              'On these days',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                _buildDayChip(0, 'S'),
                _buildDayChip(1, 'M'),
                _buildDayChip(2, 'T'),
                _buildDayChip(3, 'W'),
                _buildDayChip(4, 'T'),
                _buildDayChip(5, 'F'),
                _buildDayChip(6, 'S'),
              ],
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOption(String label, RecurrenceFrequency freq, int interval) {
    final isSelected = _frequency == freq && _interval == interval;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _frequency = freq;
            _interval = interval;
          });
        }
      },
    );
  }

  Widget _buildDayChip(int day, String label) {
    final isSelected = _selectedDays.contains(day);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedDays.add(day);
          } else {
            _selectedDays.remove(day);
          }
        });
      },
    );
  }
}
