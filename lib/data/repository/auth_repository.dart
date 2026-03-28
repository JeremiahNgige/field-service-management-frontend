import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../utils/helpers.dart';
import '../api/api.dart';
import '../models/user/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ABSTRACT CONTRACT
// ─────────────────────────────────────────────────────────────────────────────

/// Auth repository: maps [ApiResponse] of [AuthTokens] / [UserModel] → domain models.
abstract class IAuthRepository {
  Future<Either<String, AuthTokens>> login(LoginRequest request);
  Future<Either<String, UserModel>> register(RegisterRequest request);
  Future<Either<String, void>> logout();
  Future<Either<String, UserModel>> updateProfile(Map<String, dynamic> data);
  Future<Either<String, UserModel>> fetchProfile();
  Future<void> updateFcmToken(String token);
}

// ─────────────────────────────────────────────────────────────────────────────
// IMPLEMENTATION
// ─────────────────────────────────────────────────────────────────────────────

@LazySingleton(as: IAuthRepository)
class AuthRepository implements IAuthRepository {
  AuthRepository(this._api);

  final IApiService _api;

  @override
  Future<Either<String, AuthTokens>> login(LoginRequest request) async {
    final result = await _api.login(request);
    return result.fold((error) => Left(AppHelpers.friendlyError(error)), (response) {
      if (response.data != null) {
        return Right(response.data!);
      }
      return const Left('Login failed: no token returned');
    });
  }

  @override
  Future<Either<String, UserModel>> register(RegisterRequest request) async {
    final result = await _api.register(request);
    return result.fold((error) => Left(AppHelpers.friendlyError(error)), (response) {
      if (response.data != null) {
        return Right(response.data!);
      }
      return const Left('Registration failed: no user returned');
    });
  }

  @override
  Future<Either<String, void>> logout() async {
    final result = await _api.logout();
    return result.fold(
      (error) => Left(AppHelpers.friendlyError(error)),
      (_) => const Right(null),
    );
  }

  @override
  Future<Either<String, UserModel>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    final result = await _api.updateProfile(data);
    return result.fold((error) => Left(AppHelpers.friendlyError(error)), (response) {
      if (response.data != null) {
        return Right(response.data!);
      }
      return const Left('Profile update failed');
    });
  }

  @override
  Future<Either<String, UserModel>> fetchProfile() async {
    final result = await _api.fetchProfile();
    return result.fold((error) => Left(AppHelpers.friendlyError(error)), (response) {
      if (response.data != null) {
        return Right(response.data!);
      }
      return const Left('Failed to fetch profile details');
    });
  }


  @override
  Future<void> updateFcmToken(String token) async {
    // Best-effort: silently ignore failures so login never blocks on this.
    await _api.updateFcmToken(token);
  }
}
