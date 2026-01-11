import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task_bundle.dart';

/// Service for managing task bundles/routines.
class BundleService {
  final SupabaseClient _supabase;

  BundleService(this._supabase);

  /// Create a new bundle.
  Future<TaskBundle?> createBundle({
    required String householdId,
    required String name,
    String? description,
    String icon = 'list',
    String color = '#009688',
    required String createdBy,
  }) async {
    try {
      final response = await _supabase.from('task_bundles').insert({
        'household_id': householdId,
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
        'created_by': createdBy,
      }).select().single();

      return TaskBundle.fromJson(response);
    } catch (e) {
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
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (icon != null) updates['icon'] = icon;
      if (color != null) updates['color'] = color;

      if (updates.isEmpty) return null;

      final response = await _supabase
          .from('task_bundles')
          .update(updates)
          .eq('id', bundleId)
          .select()
          .single();

      return TaskBundle.fromJson(response);
    } catch (e) {
      debugPrint('Error updating bundle: $e');
      return null;
    }
  }

  /// Delete a bundle.
  Future<bool> deleteBundle(String bundleId) async {
    try {
      // First, remove bundle_id from all tasks
      await _supabase
          .from('tasks')
          .update({'bundle_id': null, 'bundle_order': null})
          .eq('bundle_id', bundleId);

      // Then delete the bundle
      await _supabase.from('task_bundles').delete().eq('id', bundleId);
      return true;
    } catch (e) {
      debugPrint('Error deleting bundle: $e');
      return false;
    }
  }

  /// Get all bundles for a household.
  Future<List<TaskBundle>> getBundles(String householdId) async {
    try {
      final response = await _supabase
          .from('task_bundles')
          .select()
          .eq('household_id', householdId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TaskBundle.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting bundles: $e');
      return [];
    }
  }

  /// Get a bundle with its tasks.
  Future<TaskBundle?> getBundleWithTasks(String bundleId) async {
    try {
      final bundleResponse = await _supabase
          .from('task_bundles')
          .select()
          .eq('id', bundleId)
          .single();

      final tasksResponse = await _supabase
          .from('tasks')
          .select('''
            *,
            assigned_profile:profiles!tasks_assigned_to_fkey(display_name),
            created_profile:profiles!tasks_created_by_fkey(display_name),
            completed_profile:profiles!tasks_completed_by_fkey(display_name)
          ''')
          .eq('bundle_id', bundleId)
          .order('bundle_order', ascending: true);

      return TaskBundle.fromJson({
        ...bundleResponse,
        'tasks': tasksResponse,
      });
    } catch (e) {
      debugPrint('Error getting bundle with tasks: $e');
      return null;
    }
  }

  /// Get bundles with tasks for a household.
  Future<List<TaskBundle>> getBundlesWithTasks(String householdId) async {
    try {
      final bundlesResponse = await _supabase
          .from('task_bundles')
          .select()
          .eq('household_id', householdId)
          .order('created_at', ascending: false);

      final bundles = <TaskBundle>[];
      for (final bundleJson in bundlesResponse as List) {
        final bundleId = bundleJson['id'] as String;

        final tasksResponse = await _supabase
            .from('tasks')
            .select('''
              *,
              assigned_profile:profiles!tasks_assigned_to_fkey(display_name),
              created_profile:profiles!tasks_created_by_fkey(display_name),
              completed_profile:profiles!tasks_completed_by_fkey(display_name)
            ''')
            .eq('bundle_id', bundleId)
            .order('bundle_order', ascending: true);

        bundles.add(TaskBundle.fromJson({
          ...bundleJson,
          'tasks': tasksResponse,
        }));
      }

      return bundles;
    } catch (e) {
      debugPrint('Error getting bundles with tasks: $e');
      return [];
    }
  }

  /// Add a task to a bundle.
  Future<bool> addTaskToBundle({
    required String taskId,
    required String bundleId,
    int? order,
  }) async {
    try {
      // If no order specified, add at the end
      int bundleOrder = order ?? 999;
      if (order == null) {
        final existingTasks = await _supabase
            .from('tasks')
            .select('bundle_order')
            .eq('bundle_id', bundleId)
            .order('bundle_order', ascending: false)
            .limit(1);

        if ((existingTasks as List).isNotEmpty) {
          bundleOrder = (existingTasks.first['bundle_order'] as int? ?? 0) + 1;
        } else {
          bundleOrder = 0;
        }
      }

      await _supabase
          .from('tasks')
          .update({'bundle_id': bundleId, 'bundle_order': bundleOrder})
          .eq('id', taskId);

      return true;
    } catch (e) {
      debugPrint('Error adding task to bundle: $e');
      return false;
    }
  }

  /// Remove a task from a bundle.
  Future<bool> removeTaskFromBundle(String taskId) async {
    try {
      await _supabase
          .from('tasks')
          .update({'bundle_id': null, 'bundle_order': null})
          .eq('id', taskId);
      return true;
    } catch (e) {
      debugPrint('Error removing task from bundle: $e');
      return false;
    }
  }

  /// Reorder tasks in a bundle.
  Future<bool> reorderBundleTasks({
    required String bundleId,
    required List<String> taskIds,
  }) async {
    try {
      for (int i = 0; i < taskIds.length; i++) {
        await _supabase
            .from('tasks')
            .update({'bundle_order': i})
            .eq('id', taskIds[i]);
      }
      return true;
    } catch (e) {
      debugPrint('Error reordering bundle tasks: $e');
      return false;
    }
  }
}
