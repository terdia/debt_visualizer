import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/debt_profile.dart';
import '../debt_repository.dart';

class HiveDebtRepository implements DebtRepository {
  static const String _boxName = 'debt_profiles';
  late Box<Map> _box;
  final _profilesController = StreamController<List<DebtProfile>>.broadcast();

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map>(_boxName);
    _emitProfiles();
  }

  @override
  Future<void> dispose() async {
    await _profilesController.close();
    await _box.close();
  }

  @override
  Future<List<DebtProfile>> getAllProfiles() async {
    return _box.values
        .map((data) => DebtProfile.fromJson(data as Map<dynamic, dynamic>))
        .toList();
  }

  @override
  Future<DebtProfile?> getProfileById(String id) async {
    final data = _box.get(id);
    if (data == null) return null;
    return DebtProfile.fromJson(data as Map<dynamic, dynamic>);
  }

  @override
  Future<DebtProfile> createProfile(DebtProfile profile) async {
    await _box.put(profile.id, profile.toJson());
    _emitProfiles();
    return profile;
  }

  @override
  Future<DebtProfile> updateProfile(DebtProfile profile) async {
    await _box.put(profile.id, profile.toJson());
    _emitProfiles();
    return profile;
  }

  @override
  Future<void> deleteProfile(String id) async {
    await _box.delete(id);
    _emitProfiles();
  }

  @override
  Stream<List<DebtProfile>> watchProfiles() {
    return _profilesController.stream;
  }

  void _emitProfiles() {
    try {
      final profiles = _box.values
          .map((data) => DebtProfile.fromJson(data as Map<dynamic, dynamic>))
          .toList();
      _profilesController.add(profiles);
      print('Loaded ${profiles.length} profiles from storage');
    } catch (e) {
      print('Error loading profiles: $e');
      _profilesController.add([]);
    }
  }
}
