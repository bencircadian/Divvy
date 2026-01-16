/// Tests for router/navigation
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../mocks/mock_providers.dart';

void main() {
  group('Router Tests', () {
    late MockAuthProvider authProvider;
    late MockHouseholdProvider householdProvider;

    setUp(() {
      authProvider = MockAuthProvider();
      householdProvider = MockHouseholdProvider();
    });

    group('Unauthenticated Redirects', () {
      testWidgets('unauthenticated redirects to login', (tester) async {
        // Not authenticated
        authProvider.setUnauthenticated();

        final router = _createTestRouter(
          authProvider: authProvider,
          householdProvider: householdProvider,
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Text appears in AppBar and body - verify it exists
        expect(find.text('Login Screen'), findsAtLeast(1));
      });

      testWidgets('trying to access dashboard redirects to login', (tester) async {
        authProvider.setUnauthenticated();

        final router = _createTestRouter(
          authProvider: authProvider,
          householdProvider: householdProvider,
          initialLocation: '/dashboard',
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Text appears in AppBar and body - verify it exists
        expect(find.text('Login Screen'), findsAtLeast(1));
        expect(find.text('Dashboard'), findsNothing);
      });
    });

    group('Authenticated Access', () {
      testWidgets('authenticated user accesses dashboard', (tester) async {
        authProvider.setAuthenticated();
        householdProvider.setHousehold();

        final router = _createTestRouter(
          authProvider: authProvider,
          householdProvider: householdProvider,
          initialLocation: '/dashboard',
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Dashboard'), findsAtLeast(1));
      });

      testWidgets('authenticated user without household goes to setup', (tester) async {
        authProvider.setAuthenticated();
        householdProvider.clearHousehold();

        final router = _createTestRouter(
          authProvider: authProvider,
          householdProvider: householdProvider,
          initialLocation: '/dashboard',
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Household Setup'), findsAtLeast(1));
      });
    });

    group('Deep Link Routing', () {
      testWidgets('join household deep link works', (tester) async {
        authProvider.setAuthenticated();

        final router = _createTestRouter(
          authProvider: authProvider,
          householdProvider: householdProvider,
          initialLocation: '/join-household?code=ABC123',
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Join Household'), findsAtLeast(1));
        expect(find.text('Code: ABC123'), findsOneWidget);
      });

      testWidgets('task deep link works', (tester) async {
        authProvider.setAuthenticated();
        householdProvider.setHousehold();

        final router = _createTestRouter(
          authProvider: authProvider,
          householdProvider: householdProvider,
          initialLocation: '/task/task-123',
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Task Detail'), findsAtLeast(1));
        expect(find.text('Task ID: task-123'), findsOneWidget);
      });
    });

    group('Back Navigation', () {
      testWidgets('back navigation works correctly', (tester) async {
        authProvider.setAuthenticated();
        householdProvider.setHousehold();

        final router = _createTestRouter(
          authProvider: authProvider,
          householdProvider: householdProvider,
          initialLocation: '/dashboard',
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to settings
        await tester.tap(find.text('Go to Settings'));
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsAtLeast(1));

        // Go back
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        expect(find.text('Dashboard'), findsAtLeast(1));
      });
    });

    group('Route Guards', () {
      testWidgets('protected routes redirect when session expires', (tester) async {
        authProvider.setAuthenticated();
        householdProvider.setHousehold();

        final router = _createTestRouter(
          authProvider: authProvider,
          householdProvider: householdProvider,
          initialLocation: '/dashboard',
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Dashboard'), findsAtLeast(1));

        // Simulate session expiry
        authProvider.setUnauthenticated();

        // Trigger router refresh
        router.refresh();
        await tester.pumpAndSettle();

        expect(find.text('Login Screen'), findsAtLeast(1));
      });
    });

    group('Error Handling', () {
      testWidgets('unknown route shows 404', (tester) async {
        authProvider.setAuthenticated();
        householdProvider.setHousehold();

        final router = _createTestRouter(
          authProvider: authProvider,
          householdProvider: householdProvider,
          initialLocation: '/unknown-route',
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Page Not Found'), findsAtLeast(1));
      });
    });
  });
}

/// Create a test router configuration
GoRouter _createTestRouter({
  required MockAuthProvider authProvider,
  required MockHouseholdProvider householdProvider,
  String initialLocation = '/',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isJoining = state.matchedLocation.startsWith('/join-household');

      if (!isLoggedIn && !isLoggingIn && !isJoining) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }

      // Check for household
      if (isLoggedIn && !householdProvider.hasHousehold) {
        if (!state.matchedLocation.startsWith('/setup') &&
            !state.matchedLocation.startsWith('/join-household')) {
          return '/setup';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/dashboard',
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const _TestScreen(title: 'Login Screen'),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const _DashboardScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const _TestScreen(
          title: 'Settings',
          hasBackButton: true,
        ),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const _TestScreen(title: 'Household Setup'),
      ),
      GoRoute(
        path: '/join-household',
        builder: (context, state) {
          final code = state.uri.queryParameters['code'] ?? '';
          return _JoinHouseholdScreen(code: code);
        },
      ),
      GoRoute(
        path: '/task/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _TaskDetailScreen(taskId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => const _TestScreen(title: 'Page Not Found'),
  );
}

class _TestScreen extends StatelessWidget {
  final String title;
  final bool hasBackButton;

  const _TestScreen({
    required this.title,
    this.hasBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: hasBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(title),
      ),
      body: Center(child: Text(title)),
    );
  }
}

class _DashboardScreen extends StatelessWidget {
  const _DashboardScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Dashboard'),
            ElevatedButton(
              onPressed: () => context.push('/settings'),
              child: const Text('Go to Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinHouseholdScreen extends StatelessWidget {
  final String code;

  const _JoinHouseholdScreen({required this.code});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Household')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Join Household'),
            Text('Code: $code'),
          ],
        ),
      ),
    );
  }
}

class _TaskDetailScreen extends StatelessWidget {
  final String taskId;

  const _TaskDetailScreen({required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Detail')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Task Detail'),
            Text('Task ID: $taskId'),
          ],
        ),
      ),
    );
  }
}
