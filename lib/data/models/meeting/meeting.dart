import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/quill_utils.dart';

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

  /// Extract plain text from notes for list preview.
  /// Handles HTML (Ionic + Flutter), Quill Delta JSON (legacy Flutter), and plain text.
  String? get plainTextPreview {
    if (notes == null || notes!.isEmpty) return null;
    final trimmed = notes!.trim();
    // Quill Delta JSON (legacy Flutter saves)
    try {
      final decoded = jsonDecode(trimmed);
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
    // HTML (Ionic app + new Flutter saves)
    if (trimmed.startsWith('<')) {
      final text = QuillUtils.stripHtml(trimmed);
      return text.isEmpty ? null : text;
    }
    // Plain text fallback
    return trimmed;
  }
}
