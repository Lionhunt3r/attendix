import 'package:freezed_annotation/freezed_annotation.dart';

part 'teacher.freezed.dart';
part 'teacher.g.dart';

/// Teacher model - represents a teacher/instructor (Ausbilder)
/// Based on TypeScript Teacher interface from Ionic project
@freezed
class Teacher with _$Teacher {
  const factory Teacher({
    int? id,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    required String name,
    @Default([]) List<int> instruments,
    @Default('') String notes,
    @Default('') String number,
    @JsonKey(name: 'private') @Default(false) bool isPrivate,
    int? tenantId,
    int? legacyId,
    // Computed fields (not in DB)
    @JsonKey(includeFromJson: false, includeToJson: false) String? insNames,
    @JsonKey(includeFromJson: false, includeToJson: false) int? playerCount,
  }) = _Teacher;

  factory Teacher.fromJson(Map<String, dynamic> json) => _$TeacherFromJson(json);
}

/// Extension for Teacher
extension TeacherExtension on Teacher {
  /// Display name
  String get displayName => name;

  /// Has phone number
  bool get hasNumber => number.isNotEmpty;
}
