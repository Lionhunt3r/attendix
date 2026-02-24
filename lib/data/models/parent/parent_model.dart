import 'package:freezed_annotation/freezed_annotation.dart';

part 'parent_model.freezed.dart';
part 'parent_model.g.dart';

/// ParentModel - parents of players (named ParentModel to avoid Dart reserved word)
/// Tabelle: parents
@freezed
class ParentModel with _$ParentModel {
  const factory ParentModel({
    int? id,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    required String appId,
    required String email,
    required String firstName,
    required String lastName,
    int? tenantId,
  }) = _ParentModel;

  factory ParentModel.fromJson(Map<String, dynamic> json) =>
      _$ParentModelFromJson(json);
}

/// Extension for ParentModel
extension ParentModelExtension on ParentModel {
  String get fullName => '$firstName $lastName';
  String get displayName => '$lastName, $firstName';

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }
}
