import 'package:attendix/core/config/supabase_config.dart';
import 'package:attendix/core/constants/enums.dart';
import 'package:attendix/core/providers/debug_providers.dart';
import 'package:attendix/core/providers/tenant_providers.dart';
import 'package:attendix/core/router/app_router.dart';
import 'package:attendix/core/theme/app_theme.dart';
import 'package:attendix/data/models/tenant/tenant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initialize the integration test binding.
///
/// Call this at the start of your integration test main() function.
IntegrationTestWidgetsFlutterBinding initIntegrationTestBinding() {
  return IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}

/// Launch the test app with a specific role and tenant.
///
/// [tester] - The WidgetTester from testWidgets
/// [role] - The role for the test user ('conductor', 'helper', 'player', 'parent')
/// [tenantId] - The tenant ID to use (default: 1)
/// [tenant] - Optional custom Tenant object
///
/// Example:
/// ```dart
/// testWidgets('Conductor sees People tab', (tester) async {
///   await launchTestApp(tester, role: 'conductor', tenantId: 1);
///   // ... test assertions
/// });
/// ```
Future<ProviderContainer> launchTestApp(
  WidgetTester tester, {
  required String role,
  int tenantId = 1,
  Tenant? tenant,
}) async {
  final effectiveTenant = tenant ?? _createTestTenant(tenantId);
  final effectiveRole = _roleFromString(role);
  final testUser = _createTestUser(role: role);
  final testSession = _createTestSession(user: testUser);

  final container = ProviderContainer(
    overrides: [
      // Override auth providers
      currentUserProvider.overrideWith((ref) => Stream.value(testUser)),
      currentSessionProvider.overrideWith((ref) => Stream.value(testSession)),
      authStateProvider.overrideWith((ref) {
        return Stream.value(AuthState(AuthChangeEvent.signedIn, testSession));
      }),

      // Override tenant
      currentTenantProvider.overrideWith(
        (ref) => _FakeCurrentTenantNotifier(effectiveTenant),
      ),

      // Override role for navigation
      currentTenantUserProvider.overrideWith((ref) async {
        return _createTenantUser(
          tenantId: effectiveTenant.id!,
          role: effectiveRole,
        );
      }),

      // Set debug role override for MainShell navigation
      debugRoleOverrideProvider.overrideWith((ref) => effectiveRole),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const _TestApp(),
    ),
  );

  // Pump and settle to let the app initialize and navigate
  await tester.pumpAndSettle();

  return container;
}

/// Launch the test app in unauthenticated state.
///
/// The app will show the login page.
///
/// Example:
/// ```dart
/// testWidgets('App shows login page when unauthenticated', (tester) async {
///   await launchUnauthenticatedApp(tester);
///   final loginPage = LoginPageObject(tester);
///   loginPage.expectPageVisible();
/// });
/// ```
Future<ProviderContainer> launchUnauthenticatedApp(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      // Override auth to be unauthenticated
      currentUserProvider.overrideWith((ref) => Stream.value(null)),
      currentSessionProvider.overrideWith((ref) => Stream.value(null)),
      authStateProvider.overrideWith((ref) {
        return Stream.value(const AuthState(AuthChangeEvent.signedOut, null));
      }),

      // No tenant selected
      currentTenantProvider.overrideWith(
        (ref) => _FakeCurrentTenantNotifier(null),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const _TestApp(),
    ),
  );

  await tester.pumpAndSettle();

  return container;
}

/// The test app widget that mirrors the main app structure.
class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Attendix Test',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

/// Fake CurrentTenantNotifier for testing.
///
/// Extends CurrentTenantNotifier with a fake Ref that provides mocked
/// dependencies so the constructor's `_initializeTenant()` doesn't crash.
class _FakeCurrentTenantNotifier extends CurrentTenantNotifier {
  _FakeCurrentTenantNotifier(Tenant? initialTenant) : super(_FakeRef()) {
    // Set state after constructor completes (overrides any initialization)
    state = initialTenant;
  }
}

/// Minimal fake Ref for CurrentTenantNotifier.
///
/// Provides mock implementations for the providers that CurrentTenantNotifier
/// needs during initialization.
class _FakeRef extends Fake implements Ref<Object?> {
  @override
  T read<T>(ProviderListenable<T> provider) {
    // Return mock for supabaseAuthProvider - needed by _initializeTenant
    if (identical(provider, supabaseAuthProvider)) {
      final mockAuth = _MockGoTrueClient();
      when(() => mockAuth.currentUser).thenReturn(null);
      return mockAuth as T;
    }
    if (identical(provider, supabaseClientProvider)) {
      return _MockSupabaseClient() as T;
    }
    // Return no-op for other providers during initialization
    throw UnimplementedError('Provider $provider not mocked in _FakeRef');
  }

  @override
  T watch<T>(ProviderListenable<T> provider) => read(provider);

  @override
  void invalidate(ProviderOrFamily provider) {}
}

/// Mock Supabase client for testing.
class _MockSupabaseClient extends Mock implements SupabaseClient {}

/// Mock GoTrueClient for auth.
class _MockGoTrueClient extends Mock implements GoTrueClient {}

// ========== Helper Functions ==========

/// Create a test tenant with the given ID.
Tenant _createTestTenant(int tenantId) {
  return Tenant(
    id: tenantId,
    shortName: 'Test$tenantId',
    longName: 'Test Orchestra $tenantId',
    maintainTeachers: false,
    showHolidays: false,
    type: 'orchestra',
    withExcuses: true,
    betaProgram: false,
    showMembersList: false,
  );
}

/// Convert a role string to Role enum.
Role _roleFromString(String role) {
  return switch (role.toLowerCase()) {
    'admin' => Role.admin,
    'conductor' => Role.admin, // 'conductor' maps to admin for convenience
    'helper' => Role.helper,
    'player' => Role.player,
    'viewer' => Role.viewer,
    'responsible' => Role.responsible,
    'parent' => Role.parent,
    'applicant' => Role.applicant,
    'voice_leader' || 'voiceleader' => Role.voiceLeader,
    _ => Role.none,
  };
}

/// Create a test user with the given role.
User _createTestUser({String role = 'conductor'}) {
  final userId = 'test-user-uuid-$role-1';
  return User(
    id: userId,
    appMetadata: {'role': role},
    userMetadata: {'email': '$role@test.local', 'name': 'Test $role'},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    email: '$role@test.local',
  );
}

/// Create a test session for the user.
Session _createTestSession({required User user}) {
  return Session(
    accessToken: 'test-access-token-${DateTime.now().millisecondsSinceEpoch}',
    tokenType: 'bearer',
    user: user,
    expiresIn: 3600,
    refreshToken: 'test-refresh-token',
  );
}

/// Create a TenantUser for testing.
TenantUser _createTenantUser({
  required int tenantId,
  required Role role,
}) {
  return TenantUser(
    id: 1,
    tenantId: tenantId,
    userId: 'test-user-uuid-${role.name}-1',
    role: role.value,
    email: '${role.name}@test.local',
    favorite: false,
  );
}
