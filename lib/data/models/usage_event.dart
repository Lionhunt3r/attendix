import 'package:freezed_annotation/freezed_annotation.dart';

part 'usage_event.freezed.dart';
part 'usage_event.g.dart';

/// Insert payload for the `usage_events` table.
///
/// Schema source: `supabase/sql/usage_events.sql`. The columns
/// `id` and `created_at` have DB-side defaults and are NOT sent.
@freezed
class UsageEvent with _$UsageEvent {
  const factory UsageEvent({
    @JsonKey(name: 'event_name') required String eventName,
    @JsonKey(name: 'tenant_id') int? tenantId,
    @JsonKey(name: 'device_type') required String deviceType,
    @Default(<String, dynamic>{}) Map<String, dynamic> properties,
  }) = _UsageEvent;

  factory UsageEvent.fromJson(Map<String, dynamic> json) =>
      _$UsageEventFromJson(json);
}
