import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration
class SupabaseConfig {
  SupabaseConfig._();

  /// Get Supabase URL from environment
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  /// Get Supabase anon key from environment
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Initialize Supabase
  /// SEC-021: Validates that essential credentials are present
  static Future<void> initialize() async {
    // SEC-021: Validate essential credentials
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'Supabase configuration missing. '
        'Ensure SUPABASE_URL and SUPABASE_ANON_KEY are set in .env file.',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }
}

/// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Supabase auth provider
final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return ref.watch(supabaseClientProvider).auth;
});

/// Current user provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(supabaseAuthProvider);
  return auth.onAuthStateChange.map((event) => event.session?.user);
});

/// Current session provider
final currentSessionProvider = StreamProvider<Session?>((ref) {
  final auth = ref.watch(supabaseAuthProvider);
  return auth.onAuthStateChange.map((event) => event.session);
});

/// Auth state provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  final auth = ref.watch(supabaseAuthProvider);
  return auth.onAuthStateChange;
});

/// Extension methods for Supabase client
extension SupabaseClientExtension on SupabaseClient {
  /// Get the current user ID or throw if not authenticated
  String get currentUserId {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.id;
  }

  /// Check if user is authenticated
  bool get isAuthenticated => auth.currentUser != null;

  /// Get current user (nullable)
  User? get currentUser => auth.currentUser;
}