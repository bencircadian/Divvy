import 'package:flutter/foundation.dart';

import '../models/task_bundle.dart';
import '../services/bundle_service.dart';
import '../services/supabase_service.dart';

/// Provider for managing task bundles/routines.
class BundleProvider extends ChangeNotifier {
  final BundleService _service;

  List<TaskBundle> _bundles = [];
  TaskBundle? _selectedBundle;
  bool _isLoading = false;
  String? _error;

  BundleProvider() : _service = BundleService(SupabaseService.client);

  List<TaskBundle> get bundles => _bundles;
  TaskBundle? get selectedBundle => _selectedBundle;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get bundles sorted by name.
  List<TaskBundle> get bundlesSortedByName {
    final sorted = List<TaskBundle>.from(_bundles);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  /// Get bundles with incomplete tasks.
  List<TaskBundle> get activeBundles {
    return _bundles.where((b) => !b.isComplete && b.totalTasks > 0).toList();
  }

  /// Get completed bundles.
  List<TaskBundle> get completedBundles {
    return _bundles.where((b) => b.isComplete).toList();
  }

  /// Load all bundles for a household.
  Future<void> loadBundles(String householdId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bundles = await _service.getBundlesWithTasks(householdId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading bundles: $e');
    }
  }

  /// Load a specific bundle with its tasks.
  Future<void> loadBundle(String bundleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedBundle = await _service.getBundleWithTasks(bundleId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading bundle: $e');
    }
  }

  /// Create a new bundle.
  Future<TaskBundle?> createBundle({
    required String householdId,
    required String name,
    String? description,
    String icon = 'list',
    String color = '#009688',
    required String createdBy,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final bundle = await _service.createBundle(
        householdId: householdId,
        name: name,
        description: description,
        icon: icon,
        color: color,
        createdBy: createdBy,
      );

      if (bundle != null) {
        _bundles.insert(0, bundle);
        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();
      return bundle;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error creating bundle: $e');
      return null;
    }
  }

  /// Update an existing bundle.
  Future<TaskBundle?> updateBundle({
    required String bundleId,
    String? name,
    String? description,
    String? icon,
    String? color,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.updateBundle(
        bundleId: bundleId,
        name: name,
        description: description,
        icon: icon,
        color: color,
      );

      if (updated != null) {
        final index = _bundles.indexWhere((b) => b.id == bundleId);
        if (index != -1) {
          _bundles[index] = updated.copyWith(tasks: _bundles[index].tasks);
        }
        if (_selectedBundle?.id == bundleId) {
          _selectedBundle = updated.copyWith(tasks: _selectedBundle?.tasks);
        }
        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating bundle: $e');
      return null;
    }
  }

  /// Delete a bundle.
  Future<bool> deleteBundle(String bundleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.deleteBundle(bundleId);

      if (success) {
        _bundles.removeWhere((b) => b.id == bundleId);
        if (_selectedBundle?.id == bundleId) {
          _selectedBundle = null;
        }
        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error deleting bundle: $e');
      return false;
    }
  }

  /// Add a task to a bundle.
  Future<bool> addTaskToBundle({
    required String taskId,
    required String bundleId,
    int? order,
  }) async {
    try {
      final success = await _service.addTaskToBundle(
        taskId: taskId,
        bundleId: bundleId,
        order: order,
      );

      if (success) {
        // Reload the bundle to get updated tasks
        await loadBundle(bundleId);
      }

      return success;
    } catch (e) {
      debugPrint('Error adding task to bundle: $e');
      return false;
    }
  }

  /// Remove a task from a bundle.
  Future<bool> removeTaskFromBundle(String taskId) async {
    try {
      final success = await _service.removeTaskFromBundle(taskId);

      if (success && _selectedBundle != null) {
        // Reload the bundle to get updated tasks
        await loadBundle(_selectedBundle!.id);
      }

      return success;
    } catch (e) {
      debugPrint('Error removing task from bundle: $e');
      return false;
    }
  }

  /// Reorder tasks in the selected bundle.
  Future<bool> reorderTasks(List<String> taskIds) async {
    if (_selectedBundle == null) return false;

    try {
      final success = await _service.reorderBundleTasks(
        bundleId: _selectedBundle!.id,
        taskIds: taskIds,
      );

      if (success) {
        await loadBundle(_selectedBundle!.id);
      }

      return success;
    } catch (e) {
      debugPrint('Error reordering tasks: $e');
      return false;
    }
  }

  /// Clear selected bundle.
  void clearSelectedBundle() {
    _selectedBundle = null;
    notifyListeners();
  }

  /// Clear all data.
  void clear() {
    _bundles = [];
    _selectedBundle = null;
    _error = null;
    notifyListeners();
  }
}
