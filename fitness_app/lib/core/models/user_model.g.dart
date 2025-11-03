// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      userType: $enumDecode(_$UserTypeEnumMap, json['user_type']),
      phone: json['phone'] as String?,
      profileImage: json['profile_image'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'user_type': _$UserTypeEnumMap[instance.userType]!,
      'phone': instance.phone,
      'profile_image': instance.profileImage,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$UserTypeEnumMap = {
  UserType.trainer: 'trainer',
  UserType.athlete: 'athlete',
  UserType.nutritionist: 'nutritionist',
};

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'user': instance.user,
      'token': instance.token,
    };
