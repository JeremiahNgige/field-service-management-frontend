import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../utils/constants.dart';
import '../models/api_response/api_response.dart';
import '../models/job/job_model.dart';
import '../models/user/user_model.dart';
import 'interceptors.dart';
import '../services/upload_service.dart';

abstract class IApiService {
  Future<Either<DioException, ApiResponse<AuthTokens>>> login(
    LoginRequest request,
  );

  Future<Either<DioException, ApiResponse<UserModel>>> register(
    RegisterRequest request,
  );

  Future<Either<DioException, ApiResponse<String>>> logout();

  Future<Either<DioException, ApiResponse<UserModel>>> updateProfile(
    Map<String, dynamic> data,
  );

  Future<Either<DioException, ApiResponse<UserModel>>> fetchProfile();

  Future<Either<DioException, ApiResponse<List<JobModel>>>> listJobs({
    String? cursor,
  });

  Future<Either<DioException, ApiResponse<List<JobModel>>>> fetchAssignedJobs({
    String? cursor,
  });

  Future<Either<DioException, ApiResponse<JobModel>>> getJobDetail(
    String jobId,
  );

  Future<Either<DioException, ApiResponse<JobModel>>> updateJob(
    String jobId,
    Map<String, dynamic> data,
  );

  Future<Either<DioException, ApiResponse<String>>> deleteJob(String jobId);

  Future<Either<DioException, ApiResponse<JobModel>>> assignJob(
    String jobId,
    String userId,
  );

  Future<Either<DioException, UploadUrlsResponse>> generateUploadUrls(
    UploadUrlRequest request,
  );

  Future<Either<DioException, Map<String, String>>> getDownloadUrls(
    List<String> keys,
  );

  /// Registers or updates the device FCM token on the backend.
  Future<Either<DioException, void>> updateFcmToken(String token);
}

@LazySingleton(as: IApiService)
class ApiService implements IApiService {
  ApiService(this._dio);

  final Dio _dio;

  @override
  Future<Either<DioException, ApiResponse<AuthTokens>>> login(
    LoginRequest request,
  ) async {
    try {
      final response = await _dio.post('/user/login/', data: request.toJson());
      final tokens = AuthTokens.fromJson(response.data as Map<String, dynamic>);
      await saveTokens(access: tokens.access, refresh: tokens.refresh);
      return Right(ApiResponse(message: 'Login successful', data: tokens));
    } on DioException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<DioException, ApiResponse<UserModel>>> register(
    RegisterRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/user/register/',
        data: request.toJson(),
      );
      final json = response.data as Map<String, dynamic>;
      if (json['user'] == null) {
        return Left(
          DioException(
            requestOptions: RequestOptions(path: '/user/register/'),
            message: 'User not found',
          ),
        );
      }
      final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);

      return Right(
        ApiResponse(
          message: json['message'] as String? ?? 'Registration successful',
          data: user,
        ),
      );
    } on DioException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<DioException, ApiResponse<String>>> logout() async {
    try {
      await _dio.post('/user/logout/');
      await clearTokens();
      return const Right(ApiResponse(message: 'Logged out'));
    } on DioException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<DioException, ApiResponse<UserModel>>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/user/update/', data: data);
      final json = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
      return Right(
        ApiResponse(message: json['message'] as String?, data: user),
      );
    } on DioException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<DioException, ApiResponse<UserModel>>> fetchProfile() async {
    try {
      final response = await _dio.get('/user/profile/');
      final json = response.data as Map<String, dynamic>;
      final user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
      return Right(
        ApiResponse(message: json['message'] as String?, data: user),
      );
    } on DioException catch (e) {
      return Left(e);
    }
  }

  // ── Jobs ──────────────────────────────────────────────────────────────────

  @override
  Future<Either<DioException, ApiResponse<List<JobModel>>>> listJobs({
    String? cursor,
  }) async {
    try {
      final response = await _dio.get(
        '/jobs/list/',
        queryParameters: cursor != null ? {'cursor': cursor} : null,
      );
      final json = response.data as Map<String, dynamic>;
      final jobs = (json['jobs'] as List)
          .map((j) => JobModel.fromJson(j as Map<String, dynamic>))
          .toList();
      return Right(
        ApiResponse(
          message: json['message'] as String?,
          data: jobs,
          next: _extractCursor(json['next'] as String?),
          previous: _extractCursor(json['previous'] as String?),
        ),
      );
    } on DioException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<DioException, ApiResponse<List<JobModel>>>> fetchAssignedJobs({
    String? cursor,
  }) async {
    try {
      final response = await _dio.get(
        '/user/fetch-assigned-jobs/',
        queryParameters: cursor != null ? {'cursor': cursor} : null,
      );
      final json = response.data as Map<String, dynamic>;
      final jobs = (json['jobs'] as List)
          .map((j) => JobModel.fromJson(j as Map<String, dynamic>))
          .toList();
      return Right(
        ApiResponse(
          message: json['message'] as String?,
          data: jobs,
          next: _extractCursor(json['next'] as String?),
          previous: _extractCursor(json['previous'] as String?),
        ),
      );
    } on DioException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<DioException, ApiResponse<JobModel>>> getJobDetail(
    String jobId,
  ) async {
    try {
      final response = await _dio.get('/jobs/detail/$jobId/');
      final json = response.data as Map<String, dynamic>;
      final job = JobModel.fromJson(json['job'] as Map<String, dynamic>);
      return Right(ApiResponse(message: json['message'] as String?, data: job));
    } on DioException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<DioException, ApiResponse<JobModel>>> updateJob(
    String jobId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/jobs/update/$jobId/', data: data);
      final json = response.data as Map<String, dynamic>;
      final job = JobModel.fromJson(json['job'] as Map<String, dynamic>);
      return Right(ApiResponse(message: json['message'] as String?, data: job));
    } on DioException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<DioException, ApiResponse<String>>> deleteJob(
    String jobId,
  ) async {
    try {
      final response = await _dio.delete('/jobs/delete/$jobId/');
      final json = response.data as Map<String, dynamic>;
      return Right(ApiResponse(message: json['message'] as String?));
    } on DioException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<DioException, ApiResponse<JobModel>>> assignJob(
    String jobId,
    String userId,
  ) async {
    try {
      final response = await _dio.put(
        '/jobs/update/$jobId/',
        data: {'assigned_to': userId},
      );
      final json = response.data as Map<String, dynamic>;
      final job = JobModel.fromJson(json['job'] as Map<String, dynamic>);
      return Right(ApiResponse(message: json['message'] as String?, data: job));
    } on DioException catch (e) {
      return Left(e);
    }
  }

  // ── File Storage ──────────────────────────────────────────────────────────

  @override
  Future<Either<DioException, UploadUrlsResponse>> generateUploadUrls(
    UploadUrlRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/jobs/upload-urls/',
        data: request.toJson(),
      );
      return Right(
        UploadUrlsResponse.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<DioException, Map<String, String>>> getDownloadUrls(
    List<String> keys,
  ) async {
    try {
      final response = await _dio.post(
        '/jobs/download-urls/',
        data: {'keys': keys},
      );
      final urls = Map<String, String>.from(response.data['urls'] as Map);
      return Right(urls);
    } on DioException catch (e) {
      return Left(e);
    }
  }

  // ── Direct MinIO upload ───────────────────────────────────────────────────
  Future<Either<DioException, String>> uploadToMinio({
    required String presignedUrl,
    required String key,
    required List<int> fileBytes,
    String contentType = 'application/octet-stream',
  }) async {
    return MinioUploadService.put(
      presignedUrl: presignedUrl,
      key: key,
      fileBytes: fileBytes,
      contentType: contentType,
    );
  }

  String resolveMinioUrl(String key) => AppConstants.minioObjectUrl(key);

  @override
  Future<Either<DioException, void>> updateFcmToken(String token) async {
    try {
      await _dio.patch('/user/update-fcm-token/', data: {'fcm_token': token});
      return const Right(null);
    } on DioException catch (e) {
      return Left(e);
    }
  }

  String? _extractCursor(String? urlString) {
    if (urlString == null || urlString.isEmpty) return null;
    try {
      final uri = Uri.parse(urlString);
      return uri.queryParameters['cursor'];
    } catch (_) {
      return null;
    }
  }
}
