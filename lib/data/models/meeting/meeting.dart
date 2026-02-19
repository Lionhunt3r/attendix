import 'package:freezed_annotation/freezed_annotation.dart';

part 'meeting.freezed.dart';
part 'meeting.g.dart';

/// Meeting model - represents a leadership/board meeting
@freezed
class Meeting with _$Meeting {
  const factory Meeting({
    int? id,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    required int tenantId,
    required String date,
    String? notes,
    @JsonKey(name: 'attendee_ids') List<int>? attendeeIds,
  }) = _Meeting;

  factory Meeting.fromJson(Map<String, dynamic> json) => _$MeetingFromJson(json);
}

/// Extension for Meeting
extension MeetingExtension on Meeting {
  /// Get formatted date
  String get formattedDate {
    final d = DateTime.tryParse(date);
    if (d == null) return date;
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  /// Get weekday name (German)
  String get weekdayName {
    final d = DateTime.tryParse(date);
    if (d == null) return '';
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return weekdays[d.weekday - 1];
  }
}
