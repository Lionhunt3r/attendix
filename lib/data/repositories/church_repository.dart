import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/church/church.dart';
import 'base_repository.dart';

/// Provider for ChurchRepository
final churchRepositoryProvider = Provider<ChurchRepository>((ref) {
  return ChurchRepository(ref);
});

/// Repository for church operations (BFECG special feature)
/// NOTE: This repository does NOT use TenantAwareRepository as churches are global
class ChurchRepository extends BaseRepository {
  ChurchRepository(super.ref);

  /// Get all churches (global, no tenant filter)
  Future<List<Church>> getChurches() async {
    try {
      final response = await supabase
          .from('churches')
          .select('*')
          .order('name');

      return (response as List)
          .map((e) => Church.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getChurches');
      rethrow;
    }
  }

  /// Create a new church
  Future<String> createChurch(String name, {String? userId}) async {
    try {
      final response = await supabase
          .from('churches')
          .insert({
            'name': name,
            'created_from': userId,
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e, stack) {
      handleError(e, stack, 'createChurch');
      rethrow;
    }
  }
}
