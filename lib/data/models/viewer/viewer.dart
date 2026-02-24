import 'package:freezed_annotation/freezed_annotation.dart';

part 'viewer.freezed.dart';
part 'viewer.g.dart';

/// Viewer model - external observers without player role
/// Tabelle: viewers
@freezed
class Viewer with _$Viewer {
  const factory Viewer({
    int? id,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    required String appId,
    required String email,
    required String firstName,
    required String lastName,
    int? tenantId,
  }) = _Viewer;

  factory Viewer.fromJson(Map<String, dynamic> json) => _$ViewerFromJson(json);
}

/// Extension for Viewer
extension ViewerExtension on Viewer {
  String get fullName => '$firstName $lastName';
  String get displayName => '$lastName, $firstName';

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }
}
