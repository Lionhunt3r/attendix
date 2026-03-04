import 'dart:convert';

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
    @JsonKey(name: 'attendees') List<int>? attendeeIds,
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

  /// Extract plain text from Quill Delta JSON notes for list preview
  String? get plainTextPreview {
    if (notes == null || notes!.isEmpty) return null;
    try {
      final decoded = jsonDecode(notes!.trim());
      List? ops;
      if (decoded is List) {
        ops = decoded;
      } else if (decoded is Map) {
        ops = decoded['ops'] as List?;
      }
      if (ops != null) {
        final text = ops
            .map((op) => (op as Map)['insert']?.toString() ?? '')
            .join('')
            .trim();
        return text.isEmpty ? null : text;
      }
    } catch (_) {}
    return notes!.trim();
  }
}
