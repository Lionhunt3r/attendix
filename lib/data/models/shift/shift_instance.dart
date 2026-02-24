import 'package:freezed_annotation/freezed_annotation.dart';

part 'shift_instance.freezed.dart';
part 'shift_instance.g.dart';

/// A specific named shift instance (e.g., "Frühdienst", "Spätdienst")
/// Used when a shift plan has fixed named shifts
@freezed
class ShiftInstance with _$ShiftInstance {
  const factory ShiftInstance({
    required String date,
    required String name,
  }) = _ShiftInstance;

  factory ShiftInstance.fromJson(Map<String, dynamic> json) =>
      _$ShiftInstanceFromJson(json);
}

/// Extension methods for ShiftInstance
extension ShiftInstanceExtension on ShiftInstance {
  /// Parse date string to DateTime
  DateTime? get dateTime => DateTime.tryParse(date);
}
