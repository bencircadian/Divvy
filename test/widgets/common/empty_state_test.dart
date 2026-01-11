import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/widgets/common/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('displays icon and title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No items',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No items',
              subtitle: 'Add some items to get started',
            ),
          ),
        ),
      );

      expect(find.text('Add some items to get started'), findsOneWidget);
    });

    testWidgets('does not display subtitle when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No items',
            ),
          ),
        ),
      );

      // Only title should be present
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('displays action button when callback provided', (tester) async {
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No items',
              actionLabel: 'Add item',
              onAction: () => buttonPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Add item'), findsOneWidget);
      await tester.tap(find.text('Add item'));
      expect(buttonPressed, isTrue);
    });

    testWidgets('does not display button without callback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No items',
              actionLabel: 'Add item',
              // No onAction callback
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('uses custom icon color when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No items',
              iconColor: Colors.red,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, Colors.red);
    });

    testWidgets('uses custom icon size when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No items',
              iconSize: 100,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 100);
    });
  });

  group('EmptyStateCompact', () {
    testWidgets('displays icon and message in a row', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateCompact(
              icon: Icons.info,
              message: 'Nothing here',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('uses custom color when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateCompact(
              icon: Icons.info,
              message: 'Nothing here',
              color: Colors.blue,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, Colors.blue);
    });
  });
}
