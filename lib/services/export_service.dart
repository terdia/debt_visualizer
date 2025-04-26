import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/debt_profile.dart';

class ExportService {
  /// Export debt profiles to JSON string
  String exportToJson(List<DebtProfile> profiles) {
    final List<Map<String, dynamic>> profileMaps = profiles
        .map((profile) => profile.toJson())
        .toList();

    return jsonEncode({
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'profiles': profileMaps,
    });
  }

  /// Import debt profiles from JSON string
  /// Returns a list of profiles and any validation errors
  Future<(List<DebtProfile>, List<String>)> importFromJson(String jsonStr) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final List<String> errors = [];
      
      // Validate version
      final version = data['version'] as String?;
      if (version == null) {
        errors.add('Invalid export file: missing version');
        final result = (<DebtProfile>[], errors);
        return result;
      }

      // Validate profiles array
      final profilesJson = data['profiles'];
      if (profilesJson is! List) {
        errors.add('Invalid export file: profiles must be an array');
        final result = (<DebtProfile>[], errors);
        return result;
      }

      // Parse profiles with error handling
      final List<DebtProfile> profiles = [];
      for (var i = 0; i < profilesJson.length; i++) {
        try {
          final profile = DebtProfile.fromJson(
            Map<String, dynamic>.from(profilesJson[i]),
          );
          profiles.add(profile);
        } catch (e) {
          errors.add('Error parsing profile #${i + 1}: ${e.toString()}');
        }
      }

      final result = (profiles as List<DebtProfile>, errors);      return result;
    } catch (e) {
      final result = (<DebtProfile>[], ['Invalid JSON format: ${e.toString()}']);
      return result;
    }
  }

  /// Validate imported profiles
  List<String> validateProfiles(List<DebtProfile> profiles) {
    final errors = <String>[];
    
    for (final profile in profiles) {
      if (profile.totalDebt < profile.amountPaid) {
        errors.add(
          '${profile.name}: Amount paid cannot be greater than total debt',
        );
      }
      if (profile.interestRate < 0) {
        errors.add('${profile.name}: Interest rate cannot be negative');
      }
      if (profile.monthlyPayment <= 0) {
        errors.add('${profile.name}: Monthly payment must be greater than 0');
      }
      if (profile.hourlyWage != null && profile.hourlyWage! <= 0) {
        errors.add('${profile.name}: Hourly wage must be greater than 0');
      }
    }

    return errors;
  }
}
