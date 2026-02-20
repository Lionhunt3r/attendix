import 'package:freezed_annotation/freezed_annotation.dart';

import '../constants/enums.dart';

/// Converter that handles both int and String values from JSON
/// and converts them to String
class FlexibleStringConverter implements JsonConverter<String?, dynamic> {
  const FlexibleStringConverter();

  @override
  String? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is String) return json;
    if (json is int) return json.toString();
    if (json is double) return json.toString();
    if (json is bool) return json.toString();
    return json.toString();
  }

  @override
  dynamic toJson(String? object) => object;
}

/// Converter that handles both String and int values from JSON
/// and converts them to int
class FlexibleIntConverter implements JsonConverter<int?, dynamic> {
  const FlexibleIntConverter();

  @override
  int? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is int) return json;
    if (json is String) return int.tryParse(json);
    if (json is double) return json.toInt();
    return null;
  }

  @override
  dynamic toJson(int? object) => object;
}

/// Converter that handles both String and bool values from JSON
/// and converts them to bool
class FlexibleBoolConverter implements JsonConverter<bool, dynamic> {
  const FlexibleBoolConverter();

  @override
  bool fromJson(dynamic json) {
    if (json == null) return false;
    if (json is bool) return json;
    if (json is int) return json != 0;
    if (json is String) {
      return json.toLowerCase() == 'true' || json == '1';
    }
    return false;
  }

  @override
  dynamic toJson(bool object) => object;
}

/// Converter that handles dynamic values that could be List or Map
class FlexibleListConverter implements JsonConverter<List<dynamic>?, dynamic> {
  const FlexibleListConverter();

  @override
  List<dynamic>? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is List) return json;
    return null;
  }

  @override
  dynamic toJson(List<dynamic>? object) => object;
}

/// Converter for Map with String keys
class FlexibleMapConverter implements JsonConverter<Map<String, dynamic>?, dynamic> {
  const FlexibleMapConverter();

  @override
  Map<String, dynamic>? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is Map) return Map<String, dynamic>.from(json);
    return null;
  }

  @override
  dynamic toJson(Map<String, dynamic>? object) => object;
}

/// Converter for AttendanceStatus that handles both int and String values
///
/// The database stores status as integer (0-5), but sometimes it comes as string.
/// This converter handles both cases and always outputs integer for database writes.
class FlexibleAttendanceStatusConverter implements JsonConverter<AttendanceStatus, dynamic> {
  const FlexibleAttendanceStatusConverter();

  @override
  AttendanceStatus fromJson(dynamic json) {
    if (json == null) return AttendanceStatus.neutral;

    // Handle integer values (as stored in database)
    if (json is int) {
      return AttendanceStatus.fromValue(json);
    }

    // Handle string values
    if (json is String) {
      // Try to parse as integer first
      final intValue = int.tryParse(json);
      if (intValue != null) {
        return AttendanceStatus.fromValue(intValue);
      }

      // Try to match enum name
      return AttendanceStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == json.toLowerCase(),
        orElse: () => AttendanceStatus.neutral,
      );
    }

    return AttendanceStatus.neutral;
  }

  @override
  dynamic toJson(AttendanceStatus status) => status.value;
}