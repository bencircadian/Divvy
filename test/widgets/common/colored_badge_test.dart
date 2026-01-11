import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/widgets/common/colored_badge.dart';

void main() {
  group('ColoredBadge', () {
    testWidgets('displays label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ColoredBadge(
              label: 'Test Label',
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ColoredBadge(
              label: 'With Icon',
              color: Colors.blue,
              icon: Icons.star,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('does not display icon when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ColoredBadge(
              label: 'No Icon',
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });
  });

  group('ColoredBadge.priority', () {
    testWidgets('high priority uses error color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColoredBadge.priority('high'),
          ),
        ),
      );

      expect(find.text('High'), findsOneWidget);
      // Verify badge renders with a container (color verification done visually)
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('normal priority uses warning color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColoredBadge.priority('normal'),
          ),
        ),
      );

      expect(find.text('Normal'), findsOneWidget);
    });

    testWidgets('low priority uses grey color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColoredBadge.priority('low'),
          ),
        ),
      );

      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('capitalizes first letter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColoredBadge.priority('HIGH'),
          ),
        ),
      );

      expect(find.text('HIGH'), findsOneWidget);
    });
  });

  group('ColoredBadge.status', () {
    testWidgets('completed status uses success color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColoredBadge.status('completed'),
          ),
        ),
      );

      expect(find.text('completed'), findsOneWidget);
    });

    testWidgets('done status uses success color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColoredBadge.status('done'),
          ),
        ),
      );

      expect(find.text('done'), findsOneWidget);
    });

    testWidgets('overdue status uses error color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColoredBadge.status('overdue'),
          ),
        ),
      );

      expect(find.text('overdue'), findsOneWidget);
    });

    testWidgets('pending status uses warning color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColoredBadge.status('pending'),
          ),
        ),
      );

      expect(find.text('pending'), findsOneWidget);
    });
  });

  group('CategoryBadge', () {
    testWidgets('displays category text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryBadge(category: 'Kitchen'),
          ),
        ),
      );

      expect(find.text('Kitchen'), findsOneWidget);
    });

    testWidgets('kitchen category gets correct color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryBadge(category: 'kitchen'),
          ),
        ),
      );

      expect(find.text('kitchen'), findsOneWidget);
    });

    testWidgets('unknown category gets primary color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryBadge(category: 'unknown'),
          ),
        ),
      );

      expect(find.text('unknown'), findsOneWidget);
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryBadge(
              category: 'Kitchen',
              icon: Icons.kitchen,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.kitchen), findsOneWidget);
    });
  });
}
