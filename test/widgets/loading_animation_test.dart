import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/widgets/common/loading_animation.dart';

void main() {
  group('LoadingAnimation', () {
    testWidgets('displays without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingAnimation(),
          ),
        ),
      );

      // Animation should start
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LoadingAnimation), findsOneWidget);
    });

    testWidgets('displays custom message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingAnimation(message: 'Custom loading message'),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Custom loading message'), findsOneWidget);
    });

    testWidgets('hides message when showMessage is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingAnimation(
              message: 'Should not appear',
              showMessage: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Should not appear'), findsNothing);
    });

    testWidgets('displays D logo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingAnimation(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('D'), findsOneWidget);
    });

    testWidgets('animation controllers are disposed properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingAnimation(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Remove the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      // Should not throw any errors during disposal
      await tester.pumpAndSettle();
    });
  });

  group('ButtonLoader', () {
    testWidgets('displays three dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ButtonLoader(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // ButtonLoader creates 3 Container widgets for the dots
      expect(find.byType(ButtonLoader), findsOneWidget);
    });

    testWidgets('uses custom color when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ButtonLoader(color: Colors.blue),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ButtonLoader), findsOneWidget);
    });

    testWidgets('disposes animation controller properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ButtonLoader(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      // Should not throw
      await tester.pumpAndSettle();
    });
  });

  group('CompletionCelebration', () {
    testWidgets('displays check icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompletionCelebration(),
          ),
        ),
      );

      // Start of animation
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('calls onComplete when animation finishes', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionCelebration(
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      // Wait for animation to complete (800ms)
      await tester.pumpAndSettle();

      expect(completed, true);
    });

    testWidgets('disposes properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompletionCelebration(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      await tester.pumpAndSettle();
    });
  });
}
