/// Tests for BundleProvider
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/task_bundle.dart';
import 'package:divvy/models/task.dart';

import '../helpers/test_data.dart';
import '../mocks/mock_providers.dart';

void main() {
  group('BundleProvider Tests', () {
    late MockBundleProvider bundleProvider;

    setUp(() {
      bundleProvider = MockBundleProvider();
    });

    group('Bundle CRUD Operations', () {
      test('bundles list starts empty', () {
        expect(bundleProvider.bundles, isEmpty);
      });

      test('setBundles populates list', () {
        final bundles = [
          _createTestBundle('1', 'Morning Routine'),
          _createTestBundle('2', 'Cleaning Routine'),
        ];

        bundleProvider.setBundles(bundles);

        expect(bundleProvider.bundles.length, equals(2));
      });

      test('bundles list is unmodifiable', () {
        bundleProvider.setBundles([_createTestBundle('1', 'Test')]);

        expect(
          () => bundleProvider.bundles.add(_createTestBundle('2', 'Another')),
          throwsUnsupportedError,
        );
      });
    });

    group('Task Reordering in Bundle', () {
      test('bundle with tasks maintains order', () {
        final tasks = [
          TestData.createTask(id: 't1', title: 'Task 1'),
          TestData.createTask(id: 't2', title: 'Task 2'),
          TestData.createTask(id: 't3', title: 'Task 3'),
        ];

        final bundle = _createTestBundle('1', 'Ordered Bundle', tasks: tasks);
        bundleProvider.setBundles([bundle]);

        final loadedBundle = bundleProvider.bundles.first;
        expect(loadedBundle.tasks?.length, equals(3));
        expect(loadedBundle.tasks?.first.id, equals('t1'));
      });
    });

    group('Bundle Progress Calculation', () {
      test('empty bundle has 0% progress', () {
        final bundle = _createTestBundle('1', 'Empty', tasks: []);

        expect(bundle.progress, equals(0.0));
        expect(bundle.progressPercent, equals(0));
      });

      test('bundle with no completed tasks has 0% progress', () {
        final tasks = [
          TestData.createTask(id: 't1', status: TaskStatus.pending),
          TestData.createTask(id: 't2', status: TaskStatus.pending),
        ];

        final bundle = _createTestBundle('1', 'Pending', tasks: tasks);

        expect(bundle.progress, equals(0.0));
        expect(bundle.completedTasks, equals(0));
        expect(bundle.pendingTasks, equals(2));
      });

      test('bundle with all completed tasks has 100% progress', () {
        final tasks = [
          TestData.createTask(id: 't1', status: TaskStatus.completed),
          TestData.createTask(id: 't2', status: TaskStatus.completed),
        ];

        final bundle = _createTestBundle('1', 'Complete', tasks: tasks);

        expect(bundle.progress, equals(1.0));
        expect(bundle.progressPercent, equals(100));
        expect(bundle.isComplete, isTrue);
      });

      test('bundle with mixed tasks has correct progress', () {
        final tasks = [
          TestData.createTask(id: 't1', status: TaskStatus.completed),
          TestData.createTask(id: 't2', status: TaskStatus.pending),
          TestData.createTask(id: 't3', status: TaskStatus.pending),
          TestData.createTask(id: 't4', status: TaskStatus.completed),
        ];

        final bundle = _createTestBundle('1', 'Mixed', tasks: tasks);

        expect(bundle.progress, equals(0.5)); // 2/4
        expect(bundle.progressPercent, equals(50));
        expect(bundle.completedTasks, equals(2));
        expect(bundle.pendingTasks, equals(2));
      });

      test('progress rounds correctly', () {
        final tasks = [
          TestData.createTask(id: 't1', status: TaskStatus.completed),
          TestData.createTask(id: 't2', status: TaskStatus.pending),
          TestData.createTask(id: 't3', status: TaskStatus.pending),
        ];

        final bundle = _createTestBundle('1', 'ThirdDone', tasks: tasks);

        // 1/3 = 0.333...
        expect(bundle.progress, closeTo(0.333, 0.01));
        expect(bundle.progressPercent, equals(33));
      });
    });

    group('Active/Completed Filtering', () {
      test('activeBundles filters correctly', () {
        bundleProvider.setBundles([
          _createTestBundleWithStatus('1', 'Active 1', 'active'),
          _createTestBundleWithStatus('2', 'Completed 1', 'completed'),
          _createTestBundleWithStatus('3', 'Active 2', 'active'),
        ]);

        expect(bundleProvider.activeBundles.length, equals(2));
      });

      test('completedBundles filters correctly', () {
        bundleProvider.setBundles([
          _createTestBundleWithStatus('1', 'Active 1', 'active'),
          _createTestBundleWithStatus('2', 'Completed 1', 'completed'),
          _createTestBundleWithStatus('3', 'Completed 2', 'completed'),
        ]);

        expect(bundleProvider.completedBundles.length, equals(2));
      });
    });

    group('Loading State', () {
      test('loading state defaults to false', () {
        expect(bundleProvider.isLoading, isFalse);
      });

      test('loading state can be toggled', () {
        bundleProvider.setLoading(true);
        expect(bundleProvider.isLoading, isTrue);

        bundleProvider.setLoading(false);
        expect(bundleProvider.isLoading, isFalse);
      });
    });

    group('Error State', () {
      test('error message defaults to null', () {
        expect(bundleProvider.errorMessage, isNull);
      });

      test('error can be set and cleared', () {
        bundleProvider.setError('Load failed');
        expect(bundleProvider.errorMessage, equals('Load failed'));

        bundleProvider.clearError();
        expect(bundleProvider.errorMessage, isNull);
      });
    });

    group('Bundle Properties', () {
      test('bundle has id, name, and description', () {
        final bundle = _createTestBundle(
          'bundle-123',
          'Test Bundle',
          description: 'A test description',
        );

        expect(bundle.id, equals('bundle-123'));
        expect(bundle.name, equals('Test Bundle'));
        expect(bundle.description, equals('A test description'));
      });

      test('bundle has icon and color', () {
        final bundle = TaskBundle(
          id: 'b1',
          householdId: TestData.testHouseholdId,
          name: 'Styled Bundle',
          icon: 'cleaning_services',
          color: '#F67280',
          createdBy: TestData.testUserId,
          createdAt: DateTime.now(),
        );

        expect(bundle.icon, equals('cleaning_services'));
        expect(bundle.color, equals('#F67280'));
      });

      test('bundle has total tasks count', () {
        final tasks = [
          TestData.createTask(id: 't1'),
          TestData.createTask(id: 't2'),
          TestData.createTask(id: 't3'),
        ];

        final bundle = _createTestBundle('1', 'With Tasks', tasks: tasks);

        expect(bundle.totalTasks, equals(3));
      });

      test('empty bundle returns isEmpty true', () {
        final bundle = _createTestBundle('1', 'Empty', tasks: []);
        expect(bundle.isEmpty, isTrue);
      });

      test('bundle with null tasks returns isEmpty true', () {
        final bundle = TaskBundle(
          id: 'b1',
          householdId: TestData.testHouseholdId,
          name: 'No Tasks',
          createdBy: TestData.testUserId,
          createdAt: DateTime.now(),
          tasks: null,
        );

        expect(bundle.isEmpty, isTrue);
        expect(bundle.totalTasks, equals(0));
      });
    });

    group('Bundle Load', () {
      test('loadBundles updates loading state', () async {
        final future = bundleProvider.loadBundles(TestData.testHouseholdId);
        await future;

        expect(bundleProvider.isLoading, isFalse);
      });
    });

    group('Available Icons and Colors', () {
      test('TaskBundle has available icons list', () {
        expect(TaskBundle.availableIcons, isNotEmpty);
        expect(TaskBundle.availableIcons, contains('list'));
        expect(TaskBundle.availableIcons, contains('home'));
        expect(TaskBundle.availableIcons, contains('cleaning_services'));
      });

      test('TaskBundle has available colors list', () {
        expect(TaskBundle.availableColors, isNotEmpty);
        expect(TaskBundle.availableColors, contains('#009688'));
        expect(TaskBundle.availableColors.length, greaterThanOrEqualTo(5));
      });
    });

    group('Bundle JSON Serialization', () {
      test('bundle can be converted to JSON', () {
        final bundle = TaskBundle(
          id: 'b1',
          householdId: TestData.testHouseholdId,
          name: 'Test Bundle',
          description: 'Description',
          icon: 'home',
          color: '#009688',
          createdBy: TestData.testUserId,
          createdAt: DateTime(2026, 1, 15),
        );

        final json = bundle.toJson();

        expect(json['id'], equals('b1'));
        expect(json['name'], equals('Test Bundle'));
        expect(json['description'], equals('Description'));
        expect(json['icon'], equals('home'));
        expect(json['color'], equals('#009688'));
      });

      test('bundle can be created from JSON', () {
        final json = {
          'id': 'b1',
          'household_id': TestData.testHouseholdId,
          'name': 'From JSON',
          'description': 'Created from JSON',
          'icon': 'kitchen',
          'color': '#4CAF50',
          'created_by': TestData.testUserId,
          'created_at': '2026-01-15T12:00:00.000',
        };

        final bundle = TaskBundle.fromJson(json);

        expect(bundle.id, equals('b1'));
        expect(bundle.name, equals('From JSON'));
        expect(bundle.description, equals('Created from JSON'));
        expect(bundle.icon, equals('kitchen'));
        expect(bundle.color, equals('#4CAF50'));
      });
    });

    group('Bundle CopyWith', () {
      test('copyWith creates modified copy', () {
        final original = _createTestBundle('1', 'Original');

        final modified = original.copyWith(name: 'Modified');

        expect(modified.id, equals(original.id));
        expect(modified.name, equals('Modified'));
        expect(original.name, equals('Original'));
      });

      test('copyWith preserves unmodified fields', () {
        final original = TaskBundle(
          id: 'b1',
          householdId: TestData.testHouseholdId,
          name: 'Original',
          description: 'Original Description',
          icon: 'home',
          color: '#009688',
          createdBy: TestData.testUserId,
          createdAt: DateTime(2026, 1, 15),
        );

        final modified = original.copyWith(name: 'New Name');

        expect(modified.description, equals('Original Description'));
        expect(modified.icon, equals('home'));
        expect(modified.color, equals('#009688'));
      });
    });
  });
}

TaskBundle _createTestBundle(
  String id,
  String name, {
  String? description,
  List<Task>? tasks,
}) {
  return TaskBundle(
    id: id,
    householdId: TestData.testHouseholdId,
    name: name,
    description: description,
    createdBy: TestData.testUserId,
    createdAt: DateTime.now(),
    tasks: tasks,
  );
}

/// Creates a bundle with status for filtering tests
/// Note: The actual TaskBundle model might not have a status field,
/// this is for testing the mock provider's filtering behavior
TaskBundle _createTestBundleWithStatus(String id, String name, String status) {
  // For the mock, we use the bundle's completion status
  // 'completed' status means all tasks are done
  final tasks = status == 'completed'
      ? [TestData.createTask(status: TaskStatus.completed)]
      : [TestData.createTask(status: TaskStatus.pending)];

  return TaskBundle(
    id: id,
    householdId: TestData.testHouseholdId,
    name: name,
    createdBy: TestData.testUserId,
    createdAt: DateTime.now(),
    tasks: tasks,
  );
}
