/// Extended test helpers for Divvy app tests
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:divvy/models/task.dart';
import 'package:divvy/models/household.dart';

import '../mocks/mock_providers.dart';
import '../mocks/mock_services.dart';
import '../mocks/mock_supabase.dart';
import 'test_data.dart';

/// Pump a widget wrapped with all required providers
Future<void> pumpProviderWidget(
  WidgetTester tester,
  Widget child, {
  MockAuthProvider? authProvider,
  MockHouseholdProvider? householdProvider,
  MockTaskProvider? taskProvider,
  MockBundleProvider? bundleProvider,
  MockNotificationProvider? notificationProvider,
  bool authenticated = true,
  Household? household,
  List<Task>? tasks,
}) async {
  final auth = authProvider ?? MockAuthProvider();
  final householdProv = householdProvider ?? MockHouseholdProvider();
  final taskProv = taskProvider ?? MockTaskProvider();
  final bundleProv = bundleProvider ?? MockBundleProvider();
  final notifProv = notificationProvider ?? MockNotificationProvider();

  // Configure default states
  if (authenticated) {
    auth.setAuthenticated();
  }

  if (household != null) {
    householdProv.setHousehold(household: household);
  }

  if (tasks != null) {
    taskProv.setTasks(tasks);
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MockAuthProvider>.value(value: auth),
        ChangeNotifierProvider<MockHouseholdProvider>.value(value: householdProv),
        ChangeNotifierProvider<MockTaskProvider>.value(value: taskProv),
        ChangeNotifierProvider<MockBundleProvider>.value(value: bundleProv),
        ChangeNotifierProvider<MockNotificationProvider>.value(value: notifProv),
      ],
      child: MaterialApp(
        home: child,
      ),
    ),
  );
}

/// Create a configured mock Supabase client
MockSupabaseClient createMockSupabase({
  List<Map<String, dynamic>>? tasks,
  List<Map<String, dynamic>>? profiles,
  List<Map<String, dynamic>>? households,
  List<Map<String, dynamic>>? householdMembers,
  bool authenticated = true,
  String? userId,
}) {
  final client = MockSupabaseClient();

  // Set up table data
  if (tasks != null) {
    client.setTableData('tasks', tasks);
  }
  if (profiles != null) {
    client.setTableData('profiles', profiles);
  }
  if (households != null) {
    client.setTableData('households', households);
  }
  if (householdMembers != null) {
    client.setTableData('household_members', householdMembers);
  }

  // Configure auth
  if (authenticated) {
    client.auth.setCurrentUser(
      MockSupabaseAuth.createMockUser(id: userId ?? TestData.testUserId),
    );
  }

  return client;
}

/// Simulate going offline
void simulateOffline() {
  MockCacheService.setOnlineStatus(false);
  MockConnectivity.setConnected(false);
  MockSyncManager.instance.setOnlineStatus(false);
}

/// Simulate coming back online
void simulateOnline() {
  MockCacheService.setOnlineStatus(true);
  MockConnectivity.setConnected(true);
  MockSyncManager.instance.setOnlineStatus(true);
}

/// Reset all mock states
void resetAllMocks() {
  MockCacheService.reset();
  MockSyncManager.reset();
  MockSecureStorage.reset();
  MockConnectivity.reset();
}

/// Create test task list with various states
List<Task> createTestTaskList({int count = 10}) {
  final tasks = <Task>[];
  final now = DateTime.now();

  for (int i = 0; i < count; i++) {
    tasks.add(TestData.createTask(
      id: 'task-$i',
      title: 'Task $i',
      status: i % 3 == 0 ? TaskStatus.completed : TaskStatus.pending,
      dueDate: now.add(Duration(days: i - count ~/ 2)),
      priority: TaskPriority.values[i % 3],
    ));
  }

  return tasks;
}

/// Measure widget render time
Future<Duration> measureRenderTime(
  WidgetTester tester,
  Widget widget,
) async {
  final stopwatch = Stopwatch()..start();
  await tester.pumpWidget(MaterialApp(home: widget));
  await tester.pumpAndSettle();
  stopwatch.stop();
  return stopwatch.elapsed;
}

/// Wait for all animations to complete
Future<void> waitForAnimations(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

/// Find widget by type and get its state
T? findState<T extends State>(WidgetTester tester) {
  final element = tester.element(find.byType(T.runtimeType.toString() as Type));
  return element is StatefulElement ? element.state as T : null;
}

/// Verify no widget rebuilds occurred
class RebuildTracker extends StatefulWidget {
  final Widget child;
  final void Function(int) onBuild;

  const RebuildTracker({
    super.key,
    required this.child,
    required this.onBuild,
  });

  @override
  State<RebuildTracker> createState() => _RebuildTrackerState();
}

class _RebuildTrackerState extends State<RebuildTracker> {
  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    widget.onBuild(_buildCount);
    return widget.child;
  }
}

/// Security test helpers

/// Generate directory traversal attack payloads
List<String> getDirectoryTraversalPayloads() {
  return [
    '../../../etc/passwd',
    '..\\..\\..\\windows\\system32',
    '../../../..',
    '....//....//etc/passwd',
    '..%2F..%2F..%2Fetc%2Fpasswd',
    '..%252f..%252f..%252fetc%252fpasswd',
    '..%c0%af..%c0%af..%c0%afetc/passwd',
    '/etc/passwd%00.jpg',
  ];
}

/// Generate XSS attack payloads
List<String> getXssPayloads() {
  return [
    '<script>alert("XSS")</script>',
    '"><script>alert("XSS")</script>',
    "javascript:alert('XSS')",
    '<img src=x onerror=alert("XSS")>',
    '<svg onload=alert("XSS")>',
    '"><img src=x onerror=alert("XSS")>',
    "';alert('XSS');//",
    '<body onload=alert("XSS")>',
  ];
}

/// Generate SQL injection payloads
List<String> getSqlInjectionPayloads() {
  return [
    "'; DROP TABLE users; --",
    "1' OR '1'='1",
    "1; SELECT * FROM users",
    "admin'--",
    "1' UNION SELECT * FROM passwords--",
    "'; INSERT INTO users VALUES('hacked');--",
    "1'; UPDATE users SET password='hacked';--",
  ];
}

/// Generate malformed URI payloads
List<String> getMalformedUriPayloads() {
  return [
    'divvy://join/%00malicious',
    'divvy://join/code?redirect=evil.com',
    'divvy://join/../../../etc',
    'divvy://join/${'A' * 1000}',
    'divvy://join/code#<script>',
    'javascript:alert(1)',
    'data:text/html,<script>alert(1)</script>',
  ];
}

/// Verify a string is safe (no XSS, SQL injection, etc.)
bool isStringSafe(String input) {
  final dangerousPatterns = [
    RegExp(r'<script', caseSensitive: false),
    RegExp(r'javascript:', caseSensitive: false),
    RegExp(r'on\w+\s*=', caseSensitive: false),
    RegExp(r"'\s*(OR|AND|UNION|DROP|INSERT|UPDATE|DELETE|SELECT)", caseSensitive: false),
    RegExp(r'--\s*$'),
    RegExp(r';\s*(DROP|INSERT|UPDATE|DELETE|SELECT)', caseSensitive: false),
    // XSS test patterns - detect alert(), eval(), etc in suspicious contexts
    RegExp(r"';\s*alert\s*\(", caseSensitive: false),
    RegExp(r"';\s*eval\s*\(", caseSensitive: false),
  ];

  return !dangerousPatterns.any((pattern) => pattern.hasMatch(input));
}

/// Validate email format
bool isValidEmail(String email) {
  // RFC 5322 simplified regex
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );
  return emailRegex.hasMatch(email);
}

/// Validate invite code format (alphanumeric only)
bool isValidInviteCode(String code) {
  final codeRegex = RegExp(r'^[A-Za-z0-9]{6,12}$');
  return codeRegex.hasMatch(code);
}

/// Validate URL is safe (not javascript:, data:, etc.)
bool isUrlSafe(String url) {
  // Empty URL is not safe
  if (url.isEmpty) return false;

  final uri = Uri.tryParse(url);
  if (uri == null) return false;

  final unsafeSchemes = ['javascript', 'data', 'vbscript', 'file'];

  // If there's a scheme, check if it's safe
  if (uri.scheme.isNotEmpty) {
    return !unsafeSchemes.contains(uri.scheme.toLowerCase());
  }

  // For relative URLs, check if they're valid paths (start with /)
  if (url.startsWith('/')) {
    return true;
  }

  // Other URLs without schemes are not safe (like 'not a valid url' or '://missing-scheme')
  return false;
}

/// Performance test helpers

/// Generate large task list for performance testing
List<Task> generateLargeTskList(int count) {
  return List.generate(count, (i) => TestData.createTask(
    id: 'perf-task-$i',
    title: 'Performance Test Task $i',
    dueDate: DateTime.now().add(Duration(days: i % 30)),
    priority: TaskPriority.values[i % 3],
    status: i % 5 == 0 ? TaskStatus.completed : TaskStatus.pending,
  ));
}

/// Measure operation performance
Future<Duration> measureOperation(Future<void> Function() operation) async {
  final stopwatch = Stopwatch()..start();
  await operation();
  stopwatch.stop();
  return stopwatch.elapsed;
}

/// Assert operation completes within time limit
Future<void> assertCompletesWithin(
  Future<void> Function() operation,
  Duration limit, {
  String? reason,
}) async {
  final duration = await measureOperation(operation);
  expect(
    duration,
    lessThan(limit),
    reason: reason ?? 'Operation took ${duration.inMilliseconds}ms, expected less than ${limit.inMilliseconds}ms',
  );
}
