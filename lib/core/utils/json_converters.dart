import 'package:freezed_annotation/freezed_annotation.dart';

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