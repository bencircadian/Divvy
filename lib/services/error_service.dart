import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Centralized error handling service using Sentry.
///
/// Provides structured logging, user context, and breadcrumbs for debugging.
class ErrorService {
  static bool _initialized = false;

  /// Initialize Sentry error monitoring.
  /// Call this before runApp() in main.dart.
  static Future<void> initialize({
    required String dsn,
    required Function() appRunner,
  }) async {
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = kDebugMode ? 'development' : 'production';
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;
        options.enableAutoSessionTracking = true;
        options.attachScreenshot = true;
        options.attachViewHierarchy = true;
        // Don't send PII by default
        options.sendDefaultPii = false;
        // Debug mode - more verbose logging
        options.debug = kDebugMode;
      },
      appRunner: appRunner,
    );
    _initialized = true;
  }

  /// Set the current user context for error tracking.
  static void setUser({
    required String userId,
    String? email,
    String? displayName,
    String? householdId,
  }) {
    if (!_initialized) return;

    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: userId,
        email: email,
        name: displayName,
      ));
      if (householdId != null) {
        scope.setTag('household_id', householdId);
      }
    });
  }

  /// Clear user context (e.g., on logout).
  static void clearUser() {
    if (!_initialized) return;

    Sentry.configureScope((scope) {
      scope.setUser(null);
      scope.removeTag('household_id');
    });
  }

  /// Add a breadcrumb for navigation tracking.
  static void addNavigationBreadcrumb({
    required String from,
    required String to,
  }) {
    if (!_initialized) return;

    Sentry.addBreadcrumb(Breadcrumb(
      category: 'navigation',
      message: '$from -> $to',
      level: SentryLevel.info,
    ));
  }

  /// Add a breadcrumb for user actions.
  static void addActionBreadcrumb({
    required String action,
    Map<String, dynamic>? data,
  }) {
    if (!_initialized) return;

    Sentry.addBreadcrumb(Breadcrumb(
      category: 'user.action',
      message: action,
      data: data,
      level: SentryLevel.info,
    ));
  }

  /// Add a breadcrumb for API calls.
  static void addApiBreadcrumb({
    required String method,
    required String endpoint,
    int? statusCode,
    Map<String, dynamic>? data,
  }) {
    if (!_initialized) return;

    Sentry.addBreadcrumb(Breadcrumb(
      category: 'api',
      message: '$method $endpoint',
      data: {
        if (statusCode != null) 'status_code': statusCode,
        ...?data,
      },
      level: statusCode != null && statusCode >= 400
          ? SentryLevel.error
          : SentryLevel.info,
    ));
  }

  /// Log an error to Sentry.
  static Future<void> logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? extras,
    SentryLevel level = SentryLevel.error,
  }) async {
    if (!_initialized) {
      debugPrint('ErrorService: $message - $error');
      return;
    }

    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (message != null) {
          scope.setTag('error_message', message);
        }
        if (extras != null) {
          for (final entry in extras.entries) {
            scope.setContexts(entry.key, {'value': entry.value});
          }
        }
        scope.level = level;
      },
    );
  }

  /// Log a message to Sentry (for non-exception events).
  static Future<void> logMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extras,
  }) async {
    if (!_initialized) {
      debugPrint('ErrorService: $message');
      return;
    }

    await Sentry.captureMessage(
      message,
      level: level,
      withScope: extras != null
          ? (scope) {
              for (final entry in extras.entries) {
                scope.setContexts(entry.key, {'value': entry.value});
              }
            }
          : null,
    );
  }

  /// Start a performance transaction.
  static ISentrySpan? startTransaction({
    required String name,
    required String operation,
  }) {
    if (!_initialized) return null;

    return Sentry.startTransaction(
      name,
      operation,
      bindToScope: true,
    );
  }

  /// Measure the duration of an async operation.
  static Future<T> measureAsync<T>({
    required String name,
    required String operation,
    required Future<T> Function() task,
  }) async {
    final transaction = startTransaction(name: name, operation: operation);
    try {
      final result = await task();
      transaction?.status = const SpanStatus.ok();
      return result;
    } catch (e) {
      transaction?.status = const SpanStatus.internalError();
      rethrow;
    } finally {
      await transaction?.finish();
    }
  }
}
