import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/household_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/main_shell.dart';
import '../screens/notifications/notification_settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/settings/link_account_screen.dart';
import '../screens/onboarding/create_household_screen.dart';
import '../screens/onboarding/join_household_screen.dart';
import '../screens/onboarding/quick_setup_screen.dart';
import '../screens/tasks/create_task_screen.dart';
import '../screens/tasks/task_detail_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider, HouseholdProvider householdProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: Listenable.merge([authProvider, householdProvider]),
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoadingHousehold = householdProvider.isLoading;
        final hasHousehold = householdProvider.hasHousehold;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup';
        final isHouseholdSetupRoute = state.matchedLocation == '/create-household' ||
            state.matchedLocation == '/join-household';
        final isQuickSetup = state.matchedLocation == '/quick-setup';

        // Not authenticated -> go to login
        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }

        // Wait for household data to load before redirecting
        if (isAuthenticated && isLoadingHousehold && !isAuthRoute) {
          return null; // Stay on current route while loading
        }

        // Authenticated but on auth route -> check household
        if (isAuthenticated && isAuthRoute) {
          if (isLoadingHousehold) {
            return null; // Wait for loading
          }
          return hasHousehold ? '/home' : '/create-household';
        }

        // Authenticated, no household, not on setup route -> go to setup
        if (isAuthenticated && !hasHousehold && !isHouseholdSetupRoute && !isQuickSetup) {
          return '/create-household';
        }

        // Authenticated, has household, on household setup route -> go to home
        // (user already has a household, no need to create/join another)
        if (isAuthenticated && hasHousehold && isHouseholdSetupRoute) {
          return '/home';
        }

        // Quick setup requires a household
        if (isAuthenticated && !hasHousehold && isQuickSetup) {
          return '/create-household';
        }

        // Allow staying on quick-setup if explicitly navigated (new household flow)
        // Router won't interfere with explicit navigation to quick-setup

        return null;
      },
      routes: [
        // Root route to handle OAuth callbacks (/?code=...)
        GoRoute(
          path: '/',
          redirect: (context, state) {
            // This handles OAuth redirects - Supabase will process the code
            // automatically, then we redirect based on auth state
            final isAuthenticated = authProvider.isAuthenticated;
            final hasHousehold = householdProvider.hasHousehold;

            if (!isAuthenticated) {
              return '/login';
            }
            return hasHousehold ? '/home' : '/create-household';
          },
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/create-household',
          name: 'create-household',
          builder: (context, state) => const CreateHouseholdScreen(),
        ),
        GoRoute(
          path: '/join-household',
          name: 'join-household',
          builder: (context, state) {
            final code = state.uri.queryParameters['code'];
            return JoinHouseholdScreen(initialCode: code);
          },
        ),
        GoRoute(
          path: '/join/:code',
          name: 'join-with-code',
          redirect: (context, state) {
            final code = state.pathParameters['code'];
            return '/join-household?code=$code';
          },
        ),
        GoRoute(
          path: '/quick-setup',
          name: 'quick-setup',
          builder: (context, state) => const QuickSetupScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const MainShell(),
        ),
        GoRoute(
          path: '/create-task',
          name: 'create-task',
          builder: (context, state) => const CreateTaskScreen(),
        ),
        GoRoute(
          path: '/task/:id',
          name: 'task-detail',
          builder: (context, state) => TaskDetailScreen(
            taskId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/notifications/settings',
          name: 'notification-settings',
          builder: (context, state) => const NotificationSettingsScreen(),
        ),
        GoRoute(
          path: '/settings/link-account',
          name: 'link-account',
          builder: (context, state) => const LinkAccountScreen(),
        ),
      ],
    );
  }
}
