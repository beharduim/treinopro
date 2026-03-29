import 'package:json_annotation/json_annotation.dart';
import 'api_user.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse {
  final ApiUser user;
  final String accessToken;
  final String refreshToken;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
