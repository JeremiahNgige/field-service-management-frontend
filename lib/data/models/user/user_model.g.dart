// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  userId: json['user_id'] as String,
  username: json['username'] as String?,
  email: json['email'] as String?,
  phoneNumber: json['phone_number'] as String?,
  address: json['address'] as String?,
  profilePicture: json['profile_picture'] as String?,
  userType: json['user_type'] as String?,
  dateJoined: json['date_joined'] as String?,
  lastLogin: json['last_login'] as String?,
  fcmToken: json['fcm_token'] as String?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'user_id': instance.userId,
  'username': instance.username,
  'email': instance.email,
  'phone_number': instance.phoneNumber,
  'address': instance.address,
  'profile_picture': instance.profilePicture,
  'user_type': instance.userType,
  'date_joined': instance.dateJoined,
  'last_login': instance.lastLogin,
  'fcm_token': instance.fcmToken,
};

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      email: json['email'] as String?,
      password: json['password'] as String?,
      password2: json['password2'] as String?,
      phoneNumber: json['phone_number'] as String?,
      address: json['address'] as String?,
      username: json['username'] as String?,
      userType: json['user_type'] as String? ?? 'technician',
      profilePicture: json['profile_picture'] as String? ?? '',
      fcmToken: json['fcmToken'] as String?,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'password2': instance.password2,
      'phone_number': instance.phoneNumber,
      'address': instance.address,
      'username': instance.username,
      'fcmToken': instance.fcmToken,
      'user_type': instance.userType,
      'profile_picture': instance.profilePicture,
    };

AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) => AuthTokens(
  access: json['access'] as String,
  refresh: json['refresh'] as String,
);

Map<String, dynamic> _$AuthTokensToJson(AuthTokens instance) =>
    <String, dynamic>{'access': instance.access, 'refresh': instance.refresh};
