import 'package:attendix/core/config/supabase_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Test authentication helpers for integration tests.
///
/// Provides mock users, sessions, and provider overrides for testing
/// without a real Supabase auth backend.
class TestAuth {
  TestAuth._();

  // Test User IDs (consistent with seed.sql)
  static const conductorUserId = 'test-user-uuid-conductor-1';
  static const helperUserId = 'test-user-uuid-helper-1';
  static const playerUserId = 'test-user-uuid-player-1';
  static const conductor2UserId = 'test-user-uuid-conductor-2';

  /// Creates a mock User for testing.
  ///
  /// [id] - User UUID (default: conductorUserId)
  /// [email] - User email
  /// [role] - User role ('conductor', 'helper', 'player')
  static User createTestUser({
    String id = conductorUserId,
    String email = 'conductor@test.local',
    String role = 'conductor',
  }) {
    return User(
      id: id,
      appMetadata: {
        'role': role,
      },
      userMetadata: {
        'email': email,
        'name': 'Test User',
      },
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
  }

  /// Creates a mock Session for testing.
  ///
  /// [user] - Optional user to include in session
  /// [expiresIn] - Session expiry in seconds (default: 3600)
  static Session createTestSession({
    User? user,
    int expiresIn = 3600,
  }) {
    final effectiveUser = user ?? createTestUser();

    return Session(
      accessToken: 'test-access-token-${DateTime.now().millisecondsSinceEpoch}',
      tokenType: 'bearer',
      user: effectiveUser,
      expiresIn: expiresIn,
      refreshToken: 'test-refresh-token',
    );
  }

  /// Creates a conductor user (role=2, full access).
  static User createConductorUser({int tenantId = 1}) {
    return createTestUser(
      id: conductorUserId,
      email: 'conductor@test.local',
      role: 'conductor',
    );
  }

  /// Creates a helper user (role=1, limited access).
  static User createHelperUser({int tenantId = 1}) {
    return createTestUser(
      id: helperUserId,
      email: 'helper@test.local',
      role: 'helper',
    );
  }

  /// Creates a player user (role=0, minimal access).
  static User createPlayerUser({int tenantId = 1}) {
    return createTestUser(
      id: playerUserId,
      email: 'player@test.local',
      role: 'player',
    );
  }

  /// Creates an AuthState for testing.
  static AuthState createAuthState({
    AuthChangeEvent event = AuthChangeEvent.signedIn,
    Session? session,
  }) {
    return AuthState(
      event,
      session ?? createTestSession(),
    );
  }
}

/// Provider overrides for test authentication.
///
/// Use these overrides to bypass real Supabase auth in tests.
///
/// Example:
/// ```dart
/// final container = ProviderContainer(
///   overrides: [
///     ...testAuthOverrides(),
///   ],
/// );
/// ```
List<Override> testAuthOverrides({
  User? user,
  Session? session,
}) {
  final effectiveUser = user ?? TestAuth.createTestUser();
  final effectiveSession =
      session ?? TestAuth.createTestSession(user: effectiveUser);

  return [
    // Override user stream
    currentUserProvider.overrideWith((ref) {
      return Stream.value(effectiveUser);
    }),

    // Override session stream
    currentSessionProvider.overrideWith((ref) {
      return Stream.value(effectiveSession);
    }),

    // Override auth state stream
    authStateProvider.overrideWith((ref) {
      return Stream.value(
        TestAuth.createAuthState(session: effectiveSession),
      );
    }),
  ];
}

/// Creates provider overrides for a specific user role.
///
/// [role] - 'conductor', 'helper', or 'player'
List<Override> testAuthOverridesForRole(String role) {
  late User user;
  switch (role) {
    case 'conductor':
      user = TestAuth.createConductorUser();
      break;
    case 'helper':
      user = TestAuth.createHelperUser();
      break;
    case 'player':
      user = TestAuth.createPlayerUser();
      break;
    default:
      user = TestAuth.createTestUser();
  }
  return testAuthOverrides(user: user);
}

/// Creates provider overrides for unauthenticated state.
List<Override> testUnauthenticatedOverrides() {
  return [
    currentUserProvider.overrideWith((ref) => Stream.value(null)),
    currentSessionProvider.overrideWith((ref) => Stream.value(null)),
    authStateProvider.overrideWith((ref) {
      return Stream.value(
        const AuthState(AuthChangeEvent.signedOut, null),
      );
    }),
  ];
}
