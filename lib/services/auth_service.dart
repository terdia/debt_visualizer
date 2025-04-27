import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _subscriptionKey = 'has_subscription';
  final _storage = const FlutterSecureStorage();
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  /// Get the current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is logged in
  bool get isAuthenticated => currentUser != null;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _storage.delete(key: _subscriptionKey);
  }

  /// Check if user has an active subscription
  Future<bool> hasActiveSubscription() async {
    if (!isAuthenticated) return false;

    try {
      // Check local cache first
      final cachedValue = await _storage.read(key: _subscriptionKey);
      if (cachedValue != null) {
        return cachedValue == 'true';
      }

      // Query Supabase for subscription status
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('user_id', currentUser!.id)
          .eq('status', 'active')
          .maybeSingle();

      final hasSubscription = response != null;
      await _storage.write(
        key: _subscriptionKey,
        value: hasSubscription.toString(),
      );
      
      return hasSubscription;
    } catch (e) {
      return false;
    }
  }

  /// Create a new subscription
  Future<void> createSubscription({
    required String paymentMethodId,
  }) async {
    if (!isAuthenticated) {
      throw Exception('User must be authenticated');
    }

    // Create subscription in Stripe through Supabase Edge Function
    await _supabase.functions.invoke(
      'create-subscription',
      body: {'paymentMethodId': paymentMethodId},
    );

    // Update local cache
    await _storage.write(key: _subscriptionKey, value: 'true');
  }

  /// Cancel subscription
  Future<void> cancelSubscription() async {
    if (!isAuthenticated) {
      throw Exception('User must be authenticated');
    }

    // Cancel subscription through Supabase Edge Function
    await _supabase.functions.invoke('cancel-subscription');
    await _storage.write(key: _subscriptionKey, value: 'false');
  }

  /// Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
