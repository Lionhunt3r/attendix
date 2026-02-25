import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/constants/enums.dart';
import '../models/person/person.dart';

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthService(supabase);
});

/// Service for authentication-related operations
class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  /// Generate a random password
  String _generatePassword({int length = 12}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Create an account for a person
  ///
  /// This creates a new user in Supabase Auth and links them to the person.
  /// The user will receive an email to set their password.
  ///
  /// Returns the new user's ID (appId) on success.
  Future<String> createAccountForPerson({
    required Person person,
    required Role role,
    required int tenantId,
  }) async {
    if (person.email == null || person.email!.isEmpty) {
      throw AuthException('Person hat keine E-Mail-Adresse');
    }

    if (person.id == null) {
      throw AuthException('Person hat keine ID');
    }

    // Generate a temporary password (user will reset via email)
    final tempPassword = _generatePassword();

    try {
      // 1. Create user in Supabase Auth via admin API
      // Note: This requires admin privileges or a server-side function
      // For now, we'll use signUp with the temporary password
      final authResponse = await _supabase.auth.signUp(
        email: person.email!,
        password: tempPassword,
        emailRedirectTo: null, // Use default redirect
        data: {
          'firstName': person.firstName,
          'lastName': person.lastName,
        },
      );

      if (authResponse.user == null) {
        throw AuthException('Benutzer konnte nicht erstellt werden');
      }

      final userId = authResponse.user!.id;

      // 2. Update the player with the appId
      await _supabase
          .from('player')
          .update({'appId': userId})
          .eq('id', person.id!)
          .eq('tenantId', tenantId);

      // 3. Create tenant_users entry
      await _supabase.from('tenant_users').insert({
        'user_id': userId,
        'tenant_id': tenantId,
        'role': role.value,
      });

      // 4. Send password reset email so user can set their own password
      await _supabase.auth.resetPasswordForEmail(person.email!);

      return userId;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Fehler beim Erstellen des Accounts: $e');
    }
  }

  /// Update a user's role in a tenant
  Future<void> updateUserRole({
    required String userId,
    required int tenantId,
    required Role newRole,
  }) async {
    try {
      await _supabase
          .from('tenant_users')
          .update({'role': newRole.value})
          .eq('user_id', userId)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw AuthException('Fehler beim Ändern der Rolle: $e');
    }
  }

  /// Get a user's role in a tenant
  Future<Role?> getUserRole({
    required String userId,
    required int tenantId,
  }) async {
    try {
      final response = await _supabase
          .from('tenant_users')
          .select('role')
          .eq('user_id', userId)
          .eq('tenant_id', tenantId)
          .maybeSingle();

      if (response == null) return null;
      return Role.fromValue(response['role'] as int);
    } catch (e) {
      return null;
    }
  }

  /// Remove a user's account connection from a person
  Future<void> unlinkAccount({
    required int personId,
    required int tenantId,
    required String userId,
  }) async {
    try {
      // Remove appId from player
      await _supabase
          .from('player')
          .update({'appId': null})
          .eq('id', personId)
          .eq('tenantId', tenantId);

      // Remove tenant_users entry
      await _supabase
          .from('tenant_users')
          .delete()
          .eq('user_id', userId)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw AuthException('Fehler beim Entfernen der Account-Verknüpfung: $e');
    }
  }
}

/// Exception for auth-related errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
