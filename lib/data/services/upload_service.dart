import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../utils/constants.dart';
import '../models/job/job_model.dart';

/// Handles direct PUT uploads to MinIO using presigned URLs generated
/// by the Django backend (`/jobs/upload-urls/`).
///
/// Upload flow:
///   1. Call [ApiService.generateUploadUrls] with [UploadUrlRequest] to get
///      an [UploadUrlsResponse] containing [PresignedUrlEntry] items.
///   2. For each file, call [MinioUploadService.put] using
///      [PresignedUrlEntry.uploadUrl] + raw bytes.
///   3. Store the [PresignedUrlEntry.key] values on the job record.
///   4. Use [AppConstants.minioObjectUrl(key)] to build public display URLs.
class MinioUploadService {
  MinioUploadService._();

  // A bare Dio instance configured to talk directly to MinIO.
  // No Auth interceptor — presigned URLs carry their own auth via query params.
  static Dio get _dio => Dio(
    BaseOptions(
      baseUrl: AppConstants.minioEndpoint,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      validateStatus: (status) => status != null && status < 400,
    ),
  );

  /// Uploads [fileBytes] to MinIO using the [presignedUrl] from
  /// [PresignedUrlEntry.uploadUrl].
  ///
  /// Returns [Right(key)] on success or [Left(DioException)] on failure.
  static Future<Either<DioException, String>> put({
    required String presignedUrl,
    required String key,
    required List<int> fileBytes,
    String contentType = 'application/octet-stream',
  }) async {
    try {
      // INTERCEPT DOCKER DNS:
      // Django's boto3 client often generates presigned URLs using internal docker routing identifiers. 
      // The mobile device physically cannot resolve 'minio:9000', it must map to the LAN IP.
      String finalUrl = presignedUrl;
      if (finalUrl.contains('://minio:9000')) {
        finalUrl = finalUrl.replaceFirst(RegExp(r'https?://minio:9000'), AppConstants.minioEndpoint);
      } else if (finalUrl.contains('://localhost:9000')) {
        finalUrl = finalUrl.replaceFirst(RegExp(r'https?://localhost:9000'), AppConstants.minioEndpoint);
      }

      await _dio.put<void>(
        finalUrl, 
        // CHUNK FIX: Instead of mapping each byte into its own Array (2 million arrays), 
        // passing the raw payload array once solves Dart parallel thread hanging natively.
        data: Stream.fromIterable([fileBytes]),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': fileBytes.length,
          },
        ),
      );
      return Right(key);
    } on DioException catch (e) {
      return Left(e);
    }
  }

  /// Uploads a photo [PresignedUrlEntry] directly.
  ///
  /// Convenience wrapper over [put] that reads the URL and key from the entry.
  static Future<Either<DioException, String>> putFromEntry({
    required PresignedUrlEntry entry,
    required List<int> fileBytes,
    String contentType = 'image/jpeg',
  }) => put(
    presignedUrl: entry.uploadUrl,
    key: entry.key,
    fileBytes: fileBytes,
    contentType: contentType,
  );

  /// Uploads multiple images in parallel from [UploadUrlsResponse.images].
  ///
  /// Returns:
  /// - [uploaded]: map of `index → object key` for successes.
  /// - [errors]: list of human-readable error strings for failures.
  static Future<({Map<int, String> uploaded, List<String> errors})> putImages({
    required List<PresignedUrlEntry> entries,
    required List<List<int>> bytesPerImage,
    String contentType = 'image/jpeg',
  }) async {
    assert(
      entries.length == bytesPerImage.length,
      'entries and bytesPerImage must have the same length',
    );

    final results = await Future.wait(
      List.generate(
        entries.length,
        (i) => putFromEntry(
          entry: entries[i],
          fileBytes: bytesPerImage[i],
          contentType: contentType,
        ),
      ),
    );

    final uploaded = <int, String>{};
    final errors = <String>[];

    for (var i = 0; i < results.length; i++) {
      results[i].fold(
        (err) => errors.add('Image $i: ${err.message}'),
        (key) => uploaded[i] = key,
      );
    }

    return (uploaded: uploaded, errors: errors);
  }

  /// Uploads the optional signature [PresignedUrlEntry] if present.
  static Future<Either<DioException, String>?> putSignature({
    required PresignedUrlEntry? entry,
    required List<int>? signatureBytes,
    String contentType = 'image/png',
  }) {
    if (entry == null || signatureBytes == null) return Future.value(null);
    return putFromEntry(
      entry: entry,
      fileBytes: signatureBytes,
      contentType: contentType,
    );
  }
}
