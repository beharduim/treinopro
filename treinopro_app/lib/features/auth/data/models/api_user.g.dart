// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiUser _$ApiUserFromJson(Map<String, dynamic> json) => ApiUser(
  id: json['id'] as String,
  email: json['email'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  userType: json['userType'] as String,
  isVerified: json['isVerified'] as bool,
  profileImageUrl: json['profileImageUrl'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
  totalRatings: (json['totalRatings'] as num?)?.toInt(),
  approvalStatus: json['approvalStatus'] as String?,
  createdAt: json['createdAt'] as String?,
);

Map<String, dynamic> _$ApiUserToJson(ApiUser instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'userType': instance.userType,
  'isVerified': instance.isVerified,
  'profileImageUrl': instance.profileImageUrl,
  'rating': instance.rating,
  'totalRatings': instance.totalRatings,
  'approvalStatus': instance.approvalStatus,
  'createdAt': instance.createdAt,
};
