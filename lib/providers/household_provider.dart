import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/household.dart';
import '../models/household_member.dart';
import '../services/supabase_service.dart';

class HouseholdProvider extends ChangeNotifier {
  Household? _currentHousehold;
  List<HouseholdMember> _members = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authSubscription;

  Household? get currentHousehold => _currentHousehold;
  List<HouseholdMember> get members => List.unmodifiable(_members);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasHousehold => _currentHousehold != null;

  final _uuid = const Uuid();

  HouseholdProvider() {
    _init();
  }

  void _init() {
    // Load household if user is already logged in
    if (SupabaseService.currentUser != null) {
      loadUserHousehold();
    }

    // Listen for auth state changes
    _authSubscription = SupabaseService.authStateChanges.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        loadUserHousehold();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentHousehold = null;
        _members = [];
        notifyListeners();
      }
    });
  }

  Future<void> loadUserHousehold() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Get user's household membership
      final membershipResponse = await SupabaseService.client
          .from('household_members')
          .select('household_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (membershipResponse != null) {
        final householdId = membershipResponse['household_id'] as String;

        // Load household details
        final householdResponse = await SupabaseService.client
            .from('households')
            .select()
            .eq('id', householdId)
            .single();

        _currentHousehold = Household.fromJson(householdResponse);
        await _loadMembers();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading household: $e');
      _errorMessage = 'Failed to load household: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMembers() async {
    if (_currentHousehold == null) return;

    try {
      final response = await SupabaseService.client
          .from('household_members')
          .select('*, profiles(display_name, avatar_url)')
          .eq('household_id', _currentHousehold!.id);

      _members = (response as List)
          .map((json) => HouseholdMember.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading members: $e');
    }
  }

  Future<bool> createHousehold(String name) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final householdId = _uuid.v4();
      final inviteCode = _generateInviteCode();

      // Create household
      await SupabaseService.client.from('households').insert({
        'id': householdId,
        'name': name,
        'invite_code': inviteCode,
        'created_by': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Add creator as admin member
      await SupabaseService.client.from('household_members').insert({
        'household_id': householdId,
        'user_id': userId,
        'role': 'admin',
        'joined_at': DateTime.now().toIso8601String(),
      });

      await loadUserHousehold();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create household.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinHouseholdByCode(String code) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Find household by invite code
      final householdResponse = await SupabaseService.client
          .from('households')
          .select()
          .eq('invite_code', code.toUpperCase())
          .maybeSingle();

      if (householdResponse == null) {
        _errorMessage = 'Invalid invite code.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final householdId = householdResponse['id'] as String;

      // Check if already a member
      final existingMembership = await SupabaseService.client
          .from('household_members')
          .select()
          .eq('household_id', householdId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMembership != null) {
        _errorMessage = 'You are already a member of this household.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Join household
      await SupabaseService.client.from('household_members').insert({
        'household_id': householdId,
        'user_id': userId,
        'role': 'member',
        'joined_at': DateTime.now().toIso8601String(),
      });

      await loadUserHousehold();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to join household.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> leaveHousehold() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null || _currentHousehold == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.client
          .from('household_members')
          .delete()
          .eq('household_id', _currentHousehold!.id)
          .eq('user_id', userId);

      _currentHousehold = null;
      _members = [];

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to leave household.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
