import 'package:flutter/foundation.dart';
import '../models/debt_profile.dart';

/// Abstract repository interface for debt profiles
abstract class DebtRepository {
  /// Get all debt profiles
  Future<List<DebtProfile>> getAllProfiles();
  
  /// Get a specific debt profile by ID
  Future<DebtProfile?> getProfileById(String id);
  
  /// Create a new debt profile
  Future<DebtProfile> createProfile(DebtProfile profile);
  
  /// Update an existing debt profile
  Future<DebtProfile> updateProfile(DebtProfile profile);
  
  /// Delete a debt profile
  Future<void> deleteProfile(String id);
  
  /// Stream of debt profiles for real-time updates
  Stream<List<DebtProfile>> watchProfiles();
  
  /// Initialize the repository
  Future<void> initialize();
  
  /// Dispose of any resources
  Future<void> dispose();
}
