import 'package:freezed_annotation/freezed_annotation.dart';

part 'church.freezed.dart';
part 'church.g.dart';

/// Church model - BFECG special feature (global, no tenantId)
/// Tabelle: churches
@freezed
class Church with _$Church {
  const factory Church({
    String? id, // Note: String, not int!
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'created_from') String? createdFrom,
    required String name,
  }) = _Church;

  factory Church.fromJson(Map<String, dynamic> json) => _$ChurchFromJson(json);
}

/// Extension for Church
extension ChurchExtension on Church {
  String get displayName => name;
}
