import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../data/models/tenant/tenant.dart';

/// Provider for loading a tenant by its register ID
final tenantByRegisterIdProvider = FutureProvider.family<Tenant?, String>((ref, registerId) async {
  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('tenants')
      .select('*')
      .eq('register_id', registerId)
      .maybeSingle();

  if (response == null) return null;
  return Tenant.fromJson(response);
});

/// Provider for loading groups for a tenant
final registrationGroupsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, tenantId) async {
  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('instruments')
      .select('id, name')
      .eq('tenantId', tenantId)
      .eq('maingroup', false)
      .order('name');

  return (response as List).map((g) => {
    'id': g['id'] as int,
    'name': g['name'] as String,
  }).toList();
});

/// Model for registration form data
class RegistrationFormData {
  String email;
  String password;
  String confirmPassword;
  String firstName;
  String lastName;
  int? groupId;
  String? phone;
  DateTime? birthDate;
  String? notes;
  Map<String, dynamic> additionalFields;

  RegistrationFormData({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.firstName = '',
    this.lastName = '',
    this.groupId,
    this.phone,
    this.birthDate,
    this.notes,
    Map<String, dynamic>? additionalFields,
  }) : additionalFields = additionalFields ?? {};
}

/// Registration service for handling the registration process
class RegistrationService {
  final SupabaseClient supabase;

  RegistrationService(this.supabase);

  /// Register a new user for a tenant
  Future<RegistrationResult> register({
    required Tenant tenant,
    required RegistrationFormData formData,
    bool isLoggedIn = false,
    String? existingUserId,
  }) async {
    try {
      String? userId = existingUserId;
      bool isNewAccount = false;

      // Create new auth user if not logged in
      if (!isLoggedIn) {
        final authResponse = await supabase.auth.signUp(
          email: formData.email,
          password: formData.password,
        );

        if (authResponse.user == null) {
          return RegistrationResult.error('Registrierung fehlgeschlagen.');
        }

        // Check if user already exists (no identities means existing user)
        if (authResponse.user!.identities?.isEmpty ?? true) {
          // Try to sign in
          final signInResponse = await supabase.auth.signInWithPassword(
            email: formData.email,
            password: formData.password,
          );
          if (signInResponse.user == null) {
            return RegistrationResult.error(
              'E-Mail-Adresse bereits vergeben. Bitte melde dich an.',
            );
          }
          userId = signInResponse.user!.id;
          isNewAccount = false;
        } else {
          userId = authResponse.user!.id;
          isNewAccount = true;
        }
      }

      if (userId == null) {
        return RegistrationResult.error('Benutzer-ID nicht verfügbar.');
      }

      // Check if user is already registered in this tenant
      final existingTenantUser = await supabase
          .from('tenantUsers')
          .select('id')
          .eq('userId', userId)
          .eq('tenantId', tenant.id!)
          .maybeSingle();

      if (existingTenantUser != null) {
        return RegistrationResult.error(
          'Du bist bereits in dieser Gruppe registriert.',
        );
      }

      // Create tenant user with applicant role (7)
      await supabase.from('tenantUsers').insert({
        'userId': userId,
        'tenantId': tenant.id!,
        'role': 7, // Role.applicant
        'email': formData.email.isNotEmpty ? formData.email : null,
      });

      // Create player record
      final playerData = {
        'appId': userId,
        'tenantId': tenant.id!,
        'firstName': formData.firstName,
        'lastName': formData.lastName,
        'email': formData.email.isNotEmpty ? formData.email : null,
        'phone': formData.phone,
        'birthday': formData.birthDate?.toIso8601String().split('T').first,
        'instrument': formData.groupId,
        'notes': formData.notes,
        'pending': !tenant.autoApproveRegistrations,
        'self_register': true,
        'additional_fields': formData.additionalFields.isNotEmpty
            ? formData.additionalFields
            : null,
      };

      await supabase.from('player').insert(playerData);

      return RegistrationResult.success(
        isNewAccount: isNewAccount,
        autoApproved: tenant.autoApproveRegistrations,
      );
    } catch (e) {
      return RegistrationResult.error(e.toString());
    }
  }
}

/// Result of registration attempt
class RegistrationResult {
  final bool success;
  final String? errorMessage;
  final bool isNewAccount;
  final bool autoApproved;

  const RegistrationResult._({
    required this.success,
    this.errorMessage,
    this.isNewAccount = false,
    this.autoApproved = false,
  });

  factory RegistrationResult.success({
    bool isNewAccount = false,
    bool autoApproved = false,
  }) {
    return RegistrationResult._(
      success: true,
      isNewAccount: isNewAccount,
      autoApproved: autoApproved,
    );
  }

  factory RegistrationResult.error(String message) {
    return RegistrationResult._(
      success: false,
      errorMessage: message,
    );
  }
}

/// Provider for registration service
final registrationServiceProvider = Provider<RegistrationService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return RegistrationService(supabase);
});
