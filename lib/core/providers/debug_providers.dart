import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/enums.dart';
import 'tenant_providers.dart';

/// Debug role override - only active in debug mode
/// Set to null to use the real role from the tenant user
final debugRoleOverrideProvider = StateProvider<Role?>((ref) => null);

/// Effective role provider that respects debug override in debug mode
/// In release mode, this always returns the real role
final effectiveRoleProvider = Provider<Role>((ref) {
  // In release mode, always use real role (no overhead)
  if (kReleaseMode) {
    return ref.watch(currentRoleProvider);
  }

  // In debug mode, check for override
  final override = ref.watch(debugRoleOverrideProvider);
  if (override != null) {
    return override;
  }

  return ref.watch(currentRoleProvider);
});
