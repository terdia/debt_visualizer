import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/debt_profile.dart';
import '../debt_repository.dart';
import '../../services/auth_service.dart';

class SupabaseDebtRepository implements DebtRepository {
  final SupabaseClient _supabase;
  final AuthService _authService;
  final _profilesStream = StreamController<List<DebtProfile>>.broadcast();

  SupabaseDebtRepository(this._supabase, this._authService) {
    _initializeRealtimeSubscription();
  }

  void _initializeRealtimeSubscription() {
    _supabase
        .from('debt_profiles')
        .stream(primaryKey: ['id'])
        .eq('user_id', _authService.currentUser?.id)
        .listen((data) {
      final profiles = data
          .map((json) => DebtProfile.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      _profilesStream.add(profiles);
    });
  }

  @override
  Future<List<DebtProfile>> getProfiles() async {
    final response = await _supabase
        .from('debt_profiles')
        .select()
        .eq('user_id', _authService.currentUser?.id)
        .order('created_at');

    return response
        .map((json) => DebtProfile.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  @override
  Future<DebtProfile> createProfile(DebtProfile profile) async {
    if (!await _authService.hasActiveSubscription()) {
      throw Exception('Active subscription required');
    }

    final response = await _supabase.from('debt_profiles').insert({
      ...profile.toJson(),
      'user_id': _authService.currentUser?.id,
    }).select().single();

    return DebtProfile.fromJson(Map<String, dynamic>.from(response));
  }

  @override
  Future<DebtProfile> updateProfile(DebtProfile profile) async {
    if (!await _authService.hasActiveSubscription()) {
      throw Exception('Active subscription required');
    }

    final response = await _supabase
        .from('debt_profiles')
        .update(profile.toJson())
        .eq('id', profile.id)
        .eq('user_id', _authService.currentUser?.id)
        .select()
        .single();

    return DebtProfile.fromJson(Map<String, dynamic>.from(response));
  }

  @override
  Future<void> deleteProfile(String id) async {
    if (!await _authService.hasActiveSubscription()) {
      throw Exception('Active subscription required');
    }

    await _supabase
        .from('debt_profiles')
        .delete()
        .eq('id', id)
        .eq('user_id', _authService.currentUser?.id);
  }

  @override
  Stream<List<DebtProfile>> watchProfiles() {
    return _profilesStream.stream;
  }

  @override
  Future<void> syncProfiles(List<DebtProfile> profiles) async {
    if (!await _authService.hasActiveSubscription()) {
      throw Exception('Active subscription required');
    }

    // Delete all existing profiles
    await _supabase
        .from('debt_profiles')
        .delete()
        .eq('user_id', _authService.currentUser?.id);

    // Insert new profiles
    if (profiles.isNotEmpty) {
      await _supabase.from('debt_profiles').insert(
            profiles
                .map((p) => {
                      ...p.toJson(),
                      'user_id': _authService.currentUser?.id,
                    })
                .toList(),
          );
    }
  }

  @override
  void dispose() {
    _profilesStream.close();
  }
}
