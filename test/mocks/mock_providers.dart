/// Mock providers for testing
library;

import 'package:flutter/foundation.dart';
import 'package:divvy/models/task.dart';
import 'package:divvy/models/user_profile.dart';
import 'package:divvy/models/household.dart';
import 'package:divvy/models/household_member.dart';
import 'package:divvy/models/app_notification.dart';
import 'package:divvy/models/task_bundle.dart';
import 'package:divvy/providers/auth_provider.dart';
import '../helpers/test_data.dart';

/// Mock AuthProvider for testing
class MockAuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unauthenticated;
  UserProfile? _profile;
  String? _errorMessage;
  bool _isLoading = false;
  List<String> _linkedProviders = ['email'];
  String _userId = TestData.testUserId;

  AuthStatus get status => _status;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String get userId => _userId;

  bool? get bundlesEnabled => _profile?.bundlesEnabled;
  bool get needsBundlePreferencePrompt =>
      _profile != null && _profile!.bundlesEnabled == null;

  List<String> get linkedProviders => List.from(_linkedProviders);
  bool hasProvider(String provider) => _linkedProviders.contains(provider);
  bool get hasEmailIdentity => hasProvider('email');
  bool get hasGoogleIdentity => hasProvider('google');
  bool get hasAppleIdentity => hasProvider('apple');

  /// Set authenticated state with profile
  void setAuthenticated({
    UserProfile? profile,
    List<String>? providers,
    String? userId,
  }) {
    _status = AuthStatus.authenticated;
    _profile = profile ?? TestData.createUserProfile();
    _linkedProviders = providers ?? ['email'];
    _userId = userId ?? TestData.testUserId;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set unauthenticated state
  void setUnauthenticated() {
    _status = AuthStatus.unauthenticated;
    _profile = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Mock sign up
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 10));

    _isLoading = false;
    _status = AuthStatus.authenticated;
    _profile = TestData.createUserProfile(displayName: displayName);
    notifyListeners();
    return true;
  }

  /// Mock sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 10));

    _isLoading = false;
    _status = AuthStatus.authenticated;
    _profile = TestData.createUserProfile();
    notifyListeners();
    return true;
  }

  /// Mock sign out
  Future<void> signOut() async {
    _status = AuthStatus.unauthenticated;
    _profile = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Mock Google sign in
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 10));

    _isLoading = false;
    _status = AuthStatus.authenticated;
    _profile = TestData.createUserProfile();
    _linkedProviders = ['google'];
    notifyListeners();
    return true;
  }

  /// Mock Apple sign in
  Future<bool> signInWithApple() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 10));

    _isLoading = false;
    _status = AuthStatus.authenticated;
    _profile = TestData.createUserProfile();
    _linkedProviders = ['apple'];
    notifyListeners();
    return true;
  }

  /// Mock update profile
  Future<bool> updateProfile({String? displayName, String? avatarUrl}) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(
        displayName: displayName ?? _profile!.displayName,
        avatarUrl: avatarUrl ?? _profile!.avatarUrl,
      );
      notifyListeners();
    }
    return true;
  }

  /// Mock link Google identity
  Future<bool> linkGoogleIdentity() async {
    if (!_linkedProviders.contains('google')) {
      _linkedProviders.add('google');
      notifyListeners();
    }
    return true;
  }

  /// Mock link Apple identity
  Future<bool> linkAppleIdentity() async {
    if (!_linkedProviders.contains('apple')) {
      _linkedProviders.add('apple');
      notifyListeners();
    }
    return true;
  }

  /// Mock unlink identity
  Future<bool> unlinkIdentity(String provider) async {
    if (_linkedProviders.length <= 1) {
      _errorMessage = 'Cannot unlink your only sign-in method';
      notifyListeners();
      return false;
    }

    _linkedProviders.remove(provider);
    notifyListeners();
    return true;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// Mock HouseholdProvider for testing
class MockHouseholdProvider extends ChangeNotifier {
  Household? _currentHousehold;
  List<HouseholdMember> _members = [];
  bool _isLoading = false;
  String? _errorMessage;

  Household? get currentHousehold => _currentHousehold;
  List<HouseholdMember> get members => List.unmodifiable(_members);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasHousehold => _currentHousehold != null;

  /// Set household with members
  void setHousehold({
    Household? household,
    List<HouseholdMember>? members,
  }) {
    _currentHousehold = household ?? TestData.createHousehold();
    _members = members ?? TestData.createMemberList();
    notifyListeners();
  }

  /// Clear household
  void clearHousehold() {
    _currentHousehold = null;
    _members = [];
    notifyListeners();
  }

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Mock load household
  Future<void> loadUserHousehold() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 10));

    _isLoading = false;
    notifyListeners();
  }

  /// Mock create household
  Future<bool> createHousehold(String name) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 10));

    _currentHousehold = TestData.createHousehold(name: name);
    _members = [TestData.createHouseholdMember(role: 'admin')];
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Mock join household
  Future<bool> joinHouseholdByCode(String code) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 10));

    // Simulate invalid code
    if (code.length < 6) {
      _errorMessage = 'Invalid invite code.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _currentHousehold = TestData.createHousehold(inviteCode: code);
    _members = TestData.createMemberList();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Mock leave household
  Future<bool> leaveHousehold() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 10));

    _currentHousehold = null;
    _members = [];
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// Mock TaskProvider for testing
class MockTaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentHouseholdId;

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get pendingTasks =>
      _tasks.where((t) => t.status == TaskStatus.pending).toList();
  List<Task> get completedTasks =>
      _tasks.where((t) => t.status == TaskStatus.completed).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentHouseholdId => _currentHouseholdId;

  List<Task> get tasksDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return dueDay.isAtSameMomentAs(today) ||
             (dueDay.isAfter(today) && dueDay.isBefore(tomorrow));
    }).toList();
  }

  List<Task> get tasksDueThisWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));

    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return dueDay.isAfter(today.subtract(const Duration(days: 1))) &&
             dueDay.isBefore(weekEnd);
    }).toList();
  }

  List<Task> get upcomingUniqueTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final futureTasks = _tasks.where((t) {
      if (t.isCompleted || t.dueDate == null) return false;
      final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return dueDay.isAfter(today) || dueDay.isAtSameMomentAs(tomorrow);
    }).toList();

    futureTasks.sort((a, b) =>
        (a.dueDate ?? DateTime.now()).compareTo(b.dueDate ?? DateTime.now()));

    final seenTitles = <String>{};
    final uniqueTasks = <Task>[];

    for (final task in futureTasks) {
      final key = task.isRecurring ? task.title : task.id;
      if (!seenTitles.contains(key)) {
        seenTitles.add(key);
        uniqueTasks.add(task);
      }
    }

    return uniqueTasks;
  }

  /// Set tasks list
  void setTasks(List<Task> tasks) {
    _tasks = List.from(tasks);
    notifyListeners();
  }

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Mock load tasks
  Future<void> loadTasks(String householdId) async {
    _currentHouseholdId = householdId;
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 10));

    _isLoading = false;
    notifyListeners();
  }

  /// Mock create task
  Future<bool> createTask({
    required String householdId,
    required String title,
    String? description,
    String? assignedTo,
    TaskPriority priority = TaskPriority.normal,
    DateTime? dueDate,
    DuePeriod? duePeriod,
    dynamic recurrenceRule,
    String? parentTaskId,
    String? category,
  }) async {
    final task = TestData.createTask(
      householdId: householdId,
      title: title,
      description: description,
      assignedTo: assignedTo,
      priority: priority,
      dueDate: dueDate,
      duePeriod: duePeriod,
    );

    _tasks.add(task);
    notifyListeners();
    return true;
  }

  /// Mock toggle task complete
  Future<bool> toggleTaskComplete(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      final newStatus = task.isCompleted ? TaskStatus.pending : TaskStatus.completed;
      final newCompletedAt = task.isCompleted ? null : DateTime.now();

      // Create new Task directly since copyWith doesn't allow setting null
      _tasks[index] = Task(
        id: task.id,
        householdId: task.householdId,
        title: task.title,
        description: task.description,
        createdBy: task.createdBy,
        assignedTo: task.assignedTo,
        status: newStatus,
        priority: task.priority,
        dueDate: task.dueDate,
        duePeriod: task.duePeriod,
        createdAt: task.createdAt,
        completedAt: newCompletedAt,
        completedBy: task.isCompleted ? null : task.completedBy,
        isRecurring: task.isRecurring,
        recurrenceRule: task.recurrenceRule,
        parentTaskId: task.parentTaskId,
        coverImageUrl: task.coverImageUrl,
        category: task.category,
        bundleId: task.bundleId,
        bundleOrder: task.bundleOrder,
        assignedToName: task.assignedToName,
        createdByName: task.createdByName,
        completedByName: task.isCompleted ? null : task.completedByName,
        contributors: task.contributors,
      );
      notifyListeners();
    }
    return true;
  }

  /// Mock delete task
  Future<bool> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    return true;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// Mock BundleProvider for testing
class MockBundleProvider extends ChangeNotifier {
  List<TaskBundle> _bundles = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TaskBundle> get bundles => List.unmodifiable(_bundles);
  List<TaskBundle> get activeBundles =>
      _bundles.where((b) => !b.isComplete).toList();
  List<TaskBundle> get completedBundles =>
      _bundles.where((b) => b.isComplete).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Set bundles list
  void setBundles(List<TaskBundle> bundles) {
    _bundles = List.from(bundles);
    notifyListeners();
  }

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Mock load bundles
  Future<void> loadBundles(String householdId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 10));

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// Mock NotificationProvider for testing
class MockNotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  /// Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set notifications
  void setNotifications(List<AppNotification> notifications) {
    _notifications = List.from(notifications);
    _unreadCount = notifications.where((n) => !n.read).length;
    notifyListeners();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0 && !_notifications[index].read) {
      _notifications[index] = AppNotification(
        id: _notifications[index].id,
        userId: _notifications[index].userId,
        type: _notifications[index].type,
        title: _notifications[index].title,
        body: _notifications[index].body,
        data: _notifications[index].data,
        read: true,
        createdAt: _notifications[index].createdAt,
      );
      _unreadCount--;
      notifyListeners();
    }
  }
}
