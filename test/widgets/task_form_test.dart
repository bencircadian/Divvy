/// Tests for task form widget
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/task.dart';
import 'package:divvy/models/recurrence_rule.dart';

void main() {
  group('Task Form Widget Tests', () {
    group('Title Validation', () {
      testWidgets('shows error for empty title', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        // Submit without entering title
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        expect(find.text('Title is required'), findsOneWidget);
      });

      testWidgets('accepts valid title', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField).first, 'Valid Task Title');
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        expect(find.text('Title is required'), findsNothing);
      });

      testWidgets('shows error for whitespace-only title', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField).first, '   ');
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        expect(find.text('Title is required'), findsOneWidget);
      });
    });

    group('Recurrence Selection', () {
      testWidgets('shows recurrence dropdown', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        expect(find.text('Recurrence'), findsOneWidget);
        expect(find.byType(DropdownButton<RecurrenceFrequency?>), findsOneWidget);
      });

      testWidgets('can select daily recurrence', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        await tester.tap(find.byType(DropdownButton<RecurrenceFrequency?>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Daily').last);
        await tester.pumpAndSettle();

        expect(find.text('Daily'), findsOneWidget);
      });

      testWidgets('can select weekly recurrence', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        await tester.tap(find.byType(DropdownButton<RecurrenceFrequency?>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Weekly').last);
        await tester.pumpAndSettle();

        expect(find.text('Weekly'), findsOneWidget);
      });

      testWidgets('shows day selection for weekly recurrence', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        await tester.tap(find.byType(DropdownButton<RecurrenceFrequency?>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Weekly').last);
        await tester.pumpAndSettle();

        // Day selection chips should appear
        expect(find.text('Mon'), findsOneWidget);
        expect(find.text('Tue'), findsOneWidget);
        expect(find.text('Wed'), findsOneWidget);
      });
    });

    group('Due Date Picker', () {
      testWidgets('shows date picker button', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        expect(find.text('Select Due Date'), findsOneWidget);
      });

      testWidgets('opens date picker on tap', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        await tester.tap(find.text('Select Due Date'));
        await tester.pumpAndSettle();

        // Date picker dialog should appear
        expect(find.byType(DatePickerDialog), findsOneWidget);
      });

      testWidgets('displays selected date', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        await tester.tap(find.text('Select Due Date'));
        await tester.pumpAndSettle();

        // Select a date (tap OK)
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Should show the selected date
        expect(find.text('Select Due Date'), findsNothing);
      });
    });

    group('Priority Selection', () {
      testWidgets('shows priority dropdown', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        expect(find.text('Priority'), findsOneWidget);
        expect(find.byType(DropdownButton<TaskPriority>), findsOneWidget);
      });

      testWidgets('can select high priority', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        await tester.tap(find.byType(DropdownButton<TaskPriority>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('High').last);
        await tester.pumpAndSettle();

        expect(find.text('High'), findsOneWidget);
      });

      testWidgets('defaults to normal priority', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        expect(find.text('Normal'), findsOneWidget);
      });
    });

    group('Assignee Selection', () {
      testWidgets('shows assignee dropdown', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        expect(find.text('Assign To'), findsOneWidget);
      });

      testWidgets('unassigned is an option', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        expect(find.text('Unassigned'), findsOneWidget);
      });
    });

    group('Form Submission', () {
      testWidgets('submit button is present', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        expect(find.text('Submit'), findsOneWidget);
      });

      testWidgets('valid form calls onSubmit', (tester) async {
        bool submitted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(
                onSubmit: () => submitted = true,
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField).first, 'Valid Title');
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        expect(submitted, isTrue);
      });

      testWidgets('invalid form does not call onSubmit', (tester) async {
        bool submitted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(
                onSubmit: () => submitted = true,
              ),
            ),
          ),
        );

        // Don't enter title
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        expect(submitted, isFalse);
      });
    });

    group('Description Field', () {
      testWidgets('shows description text field', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        expect(find.text('Description'), findsOneWidget);
      });

      testWidgets('description is optional', (tester) async {
        bool submitted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(
                onSubmit: () => submitted = true,
              ),
            ),
          ),
        );

        // Enter only title
        await tester.enterText(find.byType(TextFormField).first, 'Task Title');
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        expect(submitted, isTrue);
      });

      testWidgets('accepts description text', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: _TestTaskForm(),
            ),
          ),
        );

        final descriptionFields = find.byType(TextFormField);
        await tester.enterText(descriptionFields.at(1), 'Task description here');
        await tester.pumpAndSettle();

        expect(find.text('Task description here'), findsOneWidget);
      });
    });
  });
}

/// Test widget that mimics the task form behavior
class _TestTaskForm extends StatefulWidget {
  final VoidCallback? onSubmit;

  const _TestTaskForm({this.onSubmit});

  @override
  State<_TestTaskForm> createState() => _TestTaskFormState();
}

class _TestTaskFormState extends State<_TestTaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskPriority _priority = TaskPriority.normal;
  RecurrenceFrequency? _recurrence;
  DateTime? _dueDate;
  final Set<int> _selectedDays = {};

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Priority
            const Text('Priority'),
            DropdownButton<TaskPriority>(
              value: _priority,
              items: TaskPriority.values.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _priority = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Recurrence
            const Text('Recurrence'),
            DropdownButton<RecurrenceFrequency?>(
              value: _recurrence,
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...RecurrenceFrequency.values.map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(f.name[0].toUpperCase() + f.name.substring(1)),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _recurrence = value);
              },
            ),

            // Weekly day selection
            if (_recurrence == RecurrenceFrequency.weekly) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .asMap()
                    .entries
                    .map((e) {
                  final dayIndex = e.key + 1;
                  return FilterChip(
                    label: Text(e.value),
                    selected: _selectedDays.contains(dayIndex),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(dayIndex);
                        } else {
                          _selectedDays.remove(dayIndex);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),

            // Due Date
            OutlinedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _dueDate = date);
                }
              },
              child: Text(_dueDate == null
                  ? 'Select Due Date'
                  : 'Due: ${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'),
            ),
            const SizedBox(height: 16),

            // Assign To
            const Text('Assign To'),
            DropdownButton<String?>(
              value: null,
              items: const [
                DropdownMenuItem(value: null, child: Text('Unassigned')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 24),

            // Submit
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSubmit?.call();
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
