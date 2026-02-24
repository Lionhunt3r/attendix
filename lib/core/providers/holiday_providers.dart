import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/holiday_service.dart';
import 'tenant_providers.dart';

/// Provider for the HolidayService instance
final holidayServiceProvider = Provider<HolidayService>((ref) {
  return HolidayService();
});

/// Provider for fetching holidays based on current tenant's region
/// Returns empty HolidayData if tenant has no region or showHolidays is false
final holidaysProvider = FutureProvider<HolidayData>((ref) async {
  final tenant = ref.watch(currentTenantProvider);

  // Check if holidays should be shown
  if (tenant == null || !tenant.showHolidays || tenant.region == null) {
    return const HolidayData();
  }

  final service = ref.watch(holidayServiceProvider);
  return service.getHolidays(tenant.region!);
});

/// Provider for public holidays only
final publicHolidaysProvider = FutureProvider<List<Holiday>>((ref) async {
  final data = await ref.watch(holidaysProvider.future);
  return data.publicHolidays;
});

/// Provider for school holidays only
final schoolHolidaysProvider = FutureProvider<List<Holiday>>((ref) async {
  final data = await ref.watch(holidaysProvider.future);
  return data.schoolHolidays;
});

/// Provider for upcoming public holidays (not past)
final upcomingPublicHolidaysProvider = FutureProvider<List<Holiday>>((ref) async {
  final holidays = await ref.watch(publicHolidaysProvider.future);
  return holidays.where((h) => !h.isPast).toList();
});

/// Provider for upcoming school holidays (not past)
final upcomingSchoolHolidaysProvider = FutureProvider<List<Holiday>>((ref) async {
  final holidays = await ref.watch(schoolHolidaysProvider.future);
  return holidays.where((h) => !h.isPast).toList();
});
