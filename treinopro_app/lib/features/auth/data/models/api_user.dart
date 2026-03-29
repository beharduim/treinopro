import 'package:json_annotation/json_annotation.dart';

part 'api_user.g.dart';

@JsonSerializable()
class ApiUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String userType;
  final bool isVerified;
  final String? profileImageUrl;
  final double? rating;
  final int? totalRatings;
  final String? approvalStatus;

  const ApiUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userType,
    required this.isVerified,
    this.profileImageUrl,
    this.rating,
    this.totalRatings,
    this.approvalStatus,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) => _$ApiUserFromJson(json);
  Map<String, dynamic> toJson() => _$ApiUserToJson(this);

  String get fullName => '$firstName $lastName';
  
  // Rating com fallback para 5.0 (valor inicial)
  double get userRating => rating ?? 5.0;
}
