/// Mock Supabase infrastructure for testing
library;

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock Supabase client for testing
///
/// Provides configurable responses for database queries and auth operations.
class MockSupabaseClient {
  final MockSupabaseAuth auth = MockSupabaseAuth();
  final Map<String, List<Map<String, dynamic>>> _tables = {};
  final Map<String, MockRealtimeChannel> _channels = {};

  /// Configure mock data for a table
  void setTableData(String table, List<Map<String, dynamic>> data) {
    _tables[table] = List.from(data);
  }

  /// Get data from a mock table
  List<Map<String, dynamic>> getTableData(String table) {
    return _tables[table] ?? [];
  }

  /// Clear all mock data
  void clearAllData() {
    _tables.clear();
  }

  /// Simulate a database query builder
  MockQueryBuilder from(String table) {
    return MockQueryBuilder(this, table);
  }

  /// Create a mock realtime channel
  MockRealtimeChannel channel(String name) {
    _channels[name] ??= MockRealtimeChannel(name);
    return _channels[name]!;
  }
}

/// Mock query builder for database operations
class MockQueryBuilder {
  final MockSupabaseClient _client;
  final String _table;
  List<Map<String, dynamic>> _data = [];
  final List<_MockFilter> _filters = [];
  String? _orderColumn;
  bool _orderAscending = true;
  bool _orderNullsFirst = false;
  int? _rangeStart;
  int? _rangeEnd;

  MockQueryBuilder(this._client, this._table) {
    _data = List.from(_client.getTableData(_table));
  }

  MockQueryBuilder select([String columns = '*']) {
    // columns parameter is accepted for API compatibility but not used in mock
    return this;
  }

  MockQueryBuilder eq(String column, dynamic value) {
    _filters.add(_MockFilter(column, value, _FilterType.eq));
    return this;
  }

  MockQueryBuilder neq(String column, dynamic value) {
    _filters.add(_MockFilter(column, value, _FilterType.neq));
    return this;
  }

  MockQueryBuilder gt(String column, dynamic value) {
    _filters.add(_MockFilter(column, value, _FilterType.gt));
    return this;
  }

  MockQueryBuilder gte(String column, dynamic value) {
    _filters.add(_MockFilter(column, value, _FilterType.gte));
    return this;
  }

  MockQueryBuilder lt(String column, dynamic value) {
    _filters.add(_MockFilter(column, value, _FilterType.lt));
    return this;
  }

  MockQueryBuilder lte(String column, dynamic value) {
    _filters.add(_MockFilter(column, value, _FilterType.lte));
    return this;
  }

  MockQueryBuilder order(String column, {bool ascending = true, bool nullsFirst = false}) {
    _orderColumn = column;
    _orderAscending = ascending;
    _orderNullsFirst = nullsFirst;
    return this;
  }

  MockQueryBuilder range(int start, int end) {
    _rangeStart = start;
    _rangeEnd = end;
    return this;
  }

  MockQueryBuilder limit(int count) {
    _rangeEnd = (_rangeStart ?? 0) + count - 1;
    return this;
  }

  /// Execute and return all matching rows
  Future<List<Map<String, dynamic>>> execute() async {
    return _applyFiltersAndSort();
  }

  /// Return single row or null
  Future<Map<String, dynamic>?> maybeSingle() async {
    final results = _applyFiltersAndSort();
    return results.isEmpty ? null : results.first;
  }

  /// Return single row or throw
  Future<Map<String, dynamic>> single() async {
    final results = _applyFiltersAndSort();
    if (results.isEmpty) {
      throw PostgrestException(message: 'No rows found', code: 'PGRST116');
    }
    if (results.length > 1) {
      throw PostgrestException(message: 'Multiple rows found', code: 'PGRST116');
    }
    return results.first;
  }

  /// Insert data
  MockQueryBuilder insert(Map<String, dynamic> data) {
    final tableData = _client.getTableData(_table);
    final newData = Map<String, dynamic>.from(data);
    newData['id'] ??= 'mock-id-${tableData.length + 1}';
    tableData.add(newData);
    _client.setTableData(_table, tableData);
    _data = [newData];
    return this;
  }

  /// Update data
  MockQueryBuilder update(Map<String, dynamic> updates) {
    final tableData = _client.getTableData(_table);
    for (int i = 0; i < tableData.length; i++) {
      if (_matchesFilters(tableData[i])) {
        tableData[i] = {...tableData[i], ...updates};
      }
    }
    _client.setTableData(_table, tableData);
    return this;
  }

  /// Delete data
  MockQueryBuilder delete() {
    final tableData = _client.getTableData(_table);
    tableData.removeWhere((row) => _matchesFilters(row));
    _client.setTableData(_table, tableData);
    return this;
  }

  /// Upsert data
  MockQueryBuilder upsert(Map<String, dynamic> data) {
    final tableData = _client.getTableData(_table);
    final id = data['id'];
    final existingIndex = tableData.indexWhere((row) => row['id'] == id);

    if (existingIndex >= 0) {
      tableData[existingIndex] = {...tableData[existingIndex], ...data};
    } else {
      tableData.add(data);
    }
    _client.setTableData(_table, tableData);
    _data = [data];
    return this;
  }

  List<Map<String, dynamic>> _applyFiltersAndSort() {
    var results = _data.where((row) => _matchesFilters(row)).toList();

    if (_orderColumn != null) {
      results.sort((a, b) {
        final aVal = a[_orderColumn];
        final bVal = b[_orderColumn];

        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return _orderNullsFirst ? -1 : 1;
        if (bVal == null) return _orderNullsFirst ? 1 : -1;

        int comparison;
        if (aVal is Comparable) {
          comparison = aVal.compareTo(bVal);
        } else {
          comparison = aVal.toString().compareTo(bVal.toString());
        }

        return _orderAscending ? comparison : -comparison;
      });
    }

    if (_rangeStart != null && _rangeEnd != null) {
      final end = (_rangeEnd! + 1).clamp(0, results.length);
      final start = _rangeStart!.clamp(0, results.length);
      results = results.sublist(start, end);
    }

    return results;
  }

  bool _matchesFilters(Map<String, dynamic> row) {
    for (final filter in _filters) {
      final value = row[filter.column];

      switch (filter.type) {
        case _FilterType.eq:
          if (value != filter.value) return false;
          break;
        case _FilterType.neq:
          if (value == filter.value) return false;
          break;
        case _FilterType.gt:
          if (value is! Comparable || value.compareTo(filter.value) <= 0) return false;
          break;
        case _FilterType.gte:
          if (value is! Comparable || value.compareTo(filter.value) < 0) return false;
          break;
        case _FilterType.lt:
          if (value is! Comparable || value.compareTo(filter.value) >= 0) return false;
          break;
        case _FilterType.lte:
          if (value is! Comparable || value.compareTo(filter.value) > 0) return false;
          break;
      }
    }
    return true;
  }
}

class _MockFilter {
  final String column;
  final dynamic value;
  final _FilterType type;

  _MockFilter(this.column, this.value, this.type);
}

enum _FilterType { eq, neq, gt, gte, lt, lte }

/// Mock Supabase Auth
class MockSupabaseAuth {
  User? _currentUser;
  Session? _currentSession;
  final _authStateController = StreamController<AuthState>.broadcast();

  User? get currentUser => _currentUser;
  Session? get currentSession => _currentSession;
  Stream<AuthState> get onAuthStateChange => _authStateController.stream;

  /// Create a mock session for a user
  static Session _createMockSession(User user) {
    return Session(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      tokenType: 'bearer',
      user: user,
    );
  }

  /// Set the current user for testing
  void setCurrentUser(User? user) {
    _currentUser = user;
    if (user != null) {
      _currentSession = _createMockSession(user);
      _authStateController.add(AuthState(AuthChangeEvent.signedIn, _currentSession));
    } else {
      _currentSession = null;
      _authStateController.add(AuthState(AuthChangeEvent.signedOut, null));
    }
  }

  /// Create a mock user
  static User createMockUser({
    String id = 'test-user-id',
    String? email,
    Map<String, dynamic>? userMetadata,
    List<UserIdentity>? identities,
  }) {
    return User(
      id: id,
      appMetadata: {},
      userMetadata: userMetadata ?? {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
      identities: identities,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    final user = createMockUser(
      email: email,
      userMetadata: data,
    );
    _currentUser = user;
    _currentSession = _createMockSession(user);
    _authStateController.add(AuthState(AuthChangeEvent.signedIn, _currentSession));
    return AuthResponse(user: user, session: _currentSession);
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final user = createMockUser(email: email);
    _currentUser = user;
    _currentSession = _createMockSession(user);
    _authStateController.add(AuthState(AuthChangeEvent.signedIn, _currentSession));
    return AuthResponse(user: user, session: _currentSession);
  }

  Future<void> signOut() async {
    _currentUser = null;
    _currentSession = null;
    _authStateController.add(AuthState(AuthChangeEvent.signedOut, null));
  }

  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  }) async {
    final user = createMockUser(
      userMetadata: {'provider': provider.name},
    );
    _currentUser = user;
    _currentSession = _createMockSession(user);
    _authStateController.add(AuthState(AuthChangeEvent.signedIn, _currentSession));
    return AuthResponse(user: user, session: _currentSession);
  }

  Future<void> signInWithOAuth(
    OAuthProvider provider, {
    String? redirectTo,
  }) async {
    // OAuth redirect - in tests, simulate the callback
  }

  Future<void> linkIdentity(
    OAuthProvider provider, {
    String? redirectTo,
  }) async {
    // Identity linking redirect
  }

  Future<void> unlinkIdentity(UserIdentity identity) async {
    // Mock unlink - just updates the user
  }

  void dispose() {
    _authStateController.close();
  }
}


/// Mock Realtime Channel
class MockRealtimeChannel {
  final String name;
  final List<void Function(dynamic)> _callbacks = [];
  bool _isSubscribed = false;

  MockRealtimeChannel(this.name);

  bool get isSubscribed => _isSubscribed;

  MockRealtimeChannel onPostgresChanges({
    required PostgresChangeEvent event,
    required String schema,
    required String table,
    PostgresChangeFilter? filter,
    required void Function(PostgresChangePayload) callback,
  }) {
    _callbacks.add((payload) {
      if (payload is PostgresChangePayload) {
        callback(payload);
      }
    });
    return this;
  }

  RealtimeChannel subscribe([void Function(RealtimeSubscribeStatus, Object?)? callback]) {
    _isSubscribed = true;
    callback?.call(RealtimeSubscribeStatus.subscribed, null);
    // Return a mock RealtimeChannel - in real usage this would be the actual channel
    throw UnimplementedError('Mock does not return real RealtimeChannel');
  }

  Future<void> unsubscribe() async {
    _isSubscribed = false;
    _callbacks.clear();
  }

  /// Simulate a realtime event for testing
  void simulateEvent(PostgresChangePayload payload) {
    for (final callback in _callbacks) {
      callback(payload);
    }
  }
}

/// Create a mock PostgresChangePayload for testing
PostgresChangePayload createMockPayload({
  required PostgresChangeEvent eventType,
  Map<String, dynamic> newRecord = const {},
  Map<String, dynamic> oldRecord = const {},
  String schema = 'public',
  String table = 'tasks',
}) {
  return PostgresChangePayload(
    schema: schema,
    table: table,
    commitTimestamp: DateTime.now(),
    eventType: eventType,
    newRecord: newRecord,
    oldRecord: oldRecord,
    errors: null,
  );
}
