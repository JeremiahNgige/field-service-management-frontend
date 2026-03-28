import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends Equatable {
  const UserModel({
    required this.userId,
    this.username,
    required this.email,
    required this.phoneNumber,
    required this.address,
    this.profilePicture,
    this.userType,
    this.dateJoined,
    this.lastLogin,
    this.fcmToken,
  });

  @JsonKey(name: 'user_id')
  final String userId;

  final String? username;
  final String? email;

  @JsonKey(name: 'phone_number')
  final String? phoneNumber;

  final String? address;

  @JsonKey(name: 'profile_picture')
  final String? profilePicture;

  @JsonKey(name: 'user_type')
  final String? userType;

  @JsonKey(name: 'date_joined')
  final String? dateJoined;

  @JsonKey(name: 'last_login')
  final String? lastLogin;

  @JsonKey(name: 'fcm_token')
  final String? fcmToken;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  @override
  List<Object?> get props => [
    userId,
    username,
    email,
    phoneNumber,
    address,
    profilePicture,
    userType,
    dateJoined,
    lastLogin,
    fcmToken,
  ];
}

@JsonSerializable()
class LoginRequest extends Equatable {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);

  @override
  List<Object?> get props => [email, password];
}

/// Registration request payload.
@JsonSerializable()
class RegisterRequest extends Equatable {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.password2,
    required this.phoneNumber,
    required this.address,
    this.username,
    this.userType = 'technician',
    this.profilePicture = '',
    this.fcmToken,
  });

  final String? email;
  final String? password;
  final String? password2;

  @JsonKey(name: 'phone_number')
  final String? phoneNumber;

  final String? address;
  final String? username;
  final String? fcmToken;

  @JsonKey(name: 'user_type')
  final String? userType;

  @JsonKey(name: 'profile_picture')
  final String? profilePicture;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);

  @override
  List<Object?> get props => [
    email,
    password,
    password2,
    phoneNumber,
    address,
    username,
    userType,
    profilePicture,
    fcmToken,
  ];
}

/// Auth tokens returned on login.
@JsonSerializable()
class AuthTokens extends Equatable {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);

  Map<String, dynamic> toJson() => _$AuthTokensToJson(this);

  @override
  List<Object?> get props => [access, refresh];
}
