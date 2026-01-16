/// Integration tests for authentication flow
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import '../test/helpers/test_data.dart';
import '../test/mocks/mock_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    late MockAuthProvider authProvider;
    late MockHouseholdProvider householdProvider;

    setUp(() {
      authProvider = MockAuthProvider();
      householdProvider = MockHouseholdProvider();
    });

    testWidgets('Sign up -> household creation -> dashboard', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final auth = context.watch<MockAuthProvider>();
                final household = context.watch<MockHouseholdProvider>();

                // Step 1: Not authenticated -> show sign up
                if (!auth.isAuthenticated) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Sign Up Screen'),
                          ElevatedButton(
                            onPressed: () async {
                              await auth.signUp(
                                email: 'test@example.com',
                                password: 'password123',
                                displayName: 'Test User',
                              );
                            },
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Step 2: Authenticated but no household -> create household
                if (!household.hasHousehold) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Create Household Screen'),
                          ElevatedButton(
                            onPressed: () async {
                              await household.createHousehold('My Home');
                            },
                            child: const Text('Create Household'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Step 3: Has household -> dashboard
                return const Scaffold(
                  body: Center(
                    child: Text('Dashboard'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Step 1: Start at sign up
      expect(find.text('Sign Up Screen'), findsOneWidget);

      // Sign up
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Step 2: At household creation
      expect(find.text('Create Household Screen'), findsOneWidget);

      // Create household
      await tester.tap(find.text('Create Household'));
      await tester.pumpAndSettle();

      // Step 3: At dashboard
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('Sign in -> existing household -> dashboard', (tester) async {
      // Pre-configure existing household
      householdProvider.setHousehold(
        household: TestData.createHousehold(name: 'Existing Home'),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final auth = context.watch<MockAuthProvider>();
                final household = context.watch<MockHouseholdProvider>();

                if (!auth.isAuthenticated) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Sign In Screen'),
                          ElevatedButton(
                            onPressed: () async {
                              await auth.signIn(
                                email: 'existing@example.com',
                                password: 'password',
                              );
                            },
                            child: const Text('Sign In'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (household.hasHousehold) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        children: [
                          const Text('Dashboard'),
                          Text('Household: ${household.currentHousehold?.name}'),
                        ],
                      ),
                    ),
                  );
                }

                return const Scaffold(
                  body: Center(child: Text('No Household')),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Start at sign in
      expect(find.text('Sign In Screen'), findsOneWidget);

      // Sign in
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Go directly to dashboard with existing household
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Household: Existing Home'), findsOneWidget);
    });

    testWidgets('Sign out -> returns to login', (tester) async {
      authProvider.setAuthenticated();
      householdProvider.setHousehold();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProvider),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final auth = context.watch<MockAuthProvider>();

                if (!auth.isAuthenticated) {
                  return const Scaffold(
                    body: Center(child: Text('Login Screen')),
                  );
                }

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Dashboard'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await auth.signOut();
                        },
                      ),
                    ],
                  ),
                  body: const Center(child: Text('Dashboard Content')),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Start at dashboard
      expect(find.text('Dashboard'), findsOneWidget);

      // Sign out
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Back to login
      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('Auth state persists across navigation', (tester) async {
      authProvider.setAuthenticated(
        profile: TestData.createUserProfile(displayName: 'John Doe'),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
          ],
          child: MaterialApp(
            initialRoute: '/',
            routes: {
              '/': (context) => Scaffold(
                appBar: AppBar(title: const Text('Home')),
                body: Consumer<MockAuthProvider>(
                  builder: (context, auth, _) {
                    return Column(
                      children: [
                        Text('User: ${auth.profile?.displayName ?? "Not logged in"}'),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/settings'),
                          child: const Text('Go to Settings'),
                        ),
                      ],
                    );
                  },
                ),
              ),
              '/settings': (context) => Scaffold(
                appBar: AppBar(title: const Text('Settings')),
                body: Consumer<MockAuthProvider>(
                  builder: (context, auth, _) {
                    return Text('Logged in as: ${auth.profile?.displayName}');
                  },
                ),
              ),
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // On home, see user
      expect(find.text('User: John Doe'), findsOneWidget);

      // Navigate to settings
      await tester.tap(find.text('Go to Settings'));
      await tester.pumpAndSettle();

      // User still available
      expect(find.text('Logged in as: John Doe'), findsOneWidget);
    });

    testWidgets('Loading state shown during authentication', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockAuthProvider>.value(value: authProvider),
          ],
          child: MaterialApp(
            home: Consumer<MockAuthProvider>(
              builder: (context, auth, _) {
                if (auth.isLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (auth.isAuthenticated) {
                  return const Scaffold(body: Center(child: Text('Logged In')));
                }

                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        auth.setLoading(true);
                        await Future.delayed(const Duration(milliseconds: 100));
                        await auth.signIn(email: 'test@test.com', password: 'pw');
                        auth.setLoading(false);
                      },
                      child: const Text('Login'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Start with login button
      expect(find.text('Login'), findsOneWidget);

      // Tap login and see loading
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for completion
      await tester.pumpAndSettle();

      // Now logged in
      expect(find.text('Logged In'), findsOneWidget);
    });
  });
}
