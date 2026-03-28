import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../utils/helpers.dart';
import '../api/api.dart';
import '../models/api_response/api_response.dart';
import '../models/job/job_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ABSTRACT CONTRACT
// ─────────────────────────────────────────────────────────────────────────────

abstract class IJobRepository {
  Future<Either<String, ApiResponse<List<JobModel>>>> listJobs({String? cursor});
  Future<Either<String, ApiResponse<List<JobModel>>>> fetchAssignedJobs({String? cursor});
  Future<Either<String, JobModel>> getJobDetail(String jobId);
  Future<Either<String, JobModel>> updateJob(
    String jobId,
    Map<String, dynamic> data,
  );
  Future<Either<String, void>> deleteJob(String jobId);
  Future<Either<String, JobModel>> assignJob(String jobId, String userId);
  Future<Either<String, UploadUrlsResponse>> generateUploadUrls(
    UploadUrlRequest request,
  );
  Future<Either<String, Map<String, String>>> getDownloadUrls(
    List<String> keys,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// IMPLEMENTATION
// ─────────────────────────────────────────────────────────────────────────────

@LazySingleton(as: IJobRepository)
class JobRepository implements IJobRepository {
  JobRepository(this._api);

  final IApiService _api;

  @override
  Future<Either<String, ApiResponse<List<JobModel>>>> listJobs({String? cursor}) async {
    final result = await _api.listJobs(cursor: cursor);
    return result.fold(
      (e) => Left(AppHelpers.friendlyError(e)),
      (r) => Right(r),
    );
  }

  @override
  Future<Either<String, ApiResponse<List<JobModel>>>> fetchAssignedJobs({
    String? cursor,
  }) async {
    final result = await _api.fetchAssignedJobs(cursor: cursor);
    return result.fold(
      (e) => Left(AppHelpers.friendlyError(e)),
      (r) => Right(r),
    );
  }

  @override
  Future<Either<String, JobModel>> getJobDetail(String jobId) async {
    final result = await _api.getJobDetail(jobId);
    return result.fold(
      (e) => Left(AppHelpers.friendlyError(e)),
      (r) => r.data != null ? Right(r.data!) : const Left('Job not found'),
    );
  }

  @override
  Future<Either<String, JobModel>> updateJob(
    String jobId,
    Map<String, dynamic> data,
  ) async {
    final result = await _api.updateJob(jobId, data);
    return result.fold(
      (e) => Left(AppHelpers.friendlyError(e)),
      (r) => r.data != null ? Right(r.data!) : const Left('Job update failed'),
    );
  }

  @override
  Future<Either<String, void>> deleteJob(String jobId) async {
    final result = await _api.deleteJob(jobId);
    return result.fold((e) => Left(AppHelpers.friendlyError(e)), (_) => const Right(null));
  }

  @override
  Future<Either<String, JobModel>> assignJob(
    String jobId,
    String userId,
  ) async {
    final result = await _api.assignJob(jobId, userId);
    return result.fold(
      (e) => Left(AppHelpers.friendlyError(e)),
      (r) => r.data != null ? Right(r.data!) : const Left('Job assign failed'),
    );
  }

  @override
  Future<Either<String, UploadUrlsResponse>> generateUploadUrls(
    UploadUrlRequest request,
  ) async {
    final result = await _api.generateUploadUrls(request);
    return result.fold((e) => Left(AppHelpers.friendlyError(e)), Right.new);
  }

  @override
  Future<Either<String, Map<String, String>>> getDownloadUrls(
    List<String> keys,
  ) async {
    final result = await _api.getDownloadUrls(keys);
    return result.fold((e) => Left(AppHelpers.friendlyError(e)), Right.new);
  }

}
