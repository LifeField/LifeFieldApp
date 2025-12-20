import 'package:freezed_annotation/freezed_annotation.dart';

import 'role.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    @RoleConverter() required Role role,
    String? fullName,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

class RoleConverter implements JsonConverter<Role, String> {
  const RoleConverter();

  @override
  Role fromJson(String json) => roleFromApi(json);

  @override
  String toJson(Role object) => object.apiValue;
}
