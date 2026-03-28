import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../data/services/upload_service.dart';
import '../../../data/models/job/job_model.dart';
import '../../../data/models/job/local_photo.dart';
import '../../../data/repository/job_repository.dart';
import '../../../utils/constants.dart';

part 'upload_batch_state.dart';

@injectable
class UploadBatchCubit extends Cubit<UploadBatchState> {
  UploadBatchCubit(this._jobRepository) : super(const UploadBatchInitial());

  final IJobRepository _jobRepository;

  Future<void> executeBatchUpload({
    required String jobId,
    required List<LocalPhoto> photos,
    required Uint8List? signatureBytes,
  }) async {
    if (photos.isEmpty && signatureBytes == null) {
      emit(
        const UploadBatchFailure(
          error: 'Please add a photo or signature first.',
        ),
      );
      return;
    }

    emit(const UploadBatchInProgress());

    try {
      final req = UploadUrlRequest(
        imageCount: photos.length,
        hasSignature: signatureBytes != null,
      );

      final urlRes = await _jobRepository.generateUploadUrls(req);

      await urlRes.fold(
        (err) async {
          emit(UploadBatchFailure(error: err));
        },
        (urls) async {
          // 1. Upload Sig
          String? finalSigKey;
          if (signatureBytes != null && urls.signature != null) {
            final sigUpload = await MinioUploadService.putSignature(
              entry: urls.signature,
              signatureBytes: signatureBytes.toList(),
            );
            if (sigUpload != null) {
              finalSigKey = sigUpload.fold((l) => null, (r) => r);
            }
          }

          // 2. Upload Photos
          final validPhotoKeys = <String>[];
          if (photos.isNotEmpty) {
            final bytesList = await Future.wait(
              photos.map((p) => p.file.readAsBytes()),
            );
            final List<List<int>> intList = bytesList
                .map((b) => b.toList())
                .toList();
            final result = await MinioUploadService.putImages(
              entries: urls.images,
              bytesPerImage: intList,
            );
            for (var idx in result.uploaded.keys) {
              validPhotoKeys.add(result.uploaded[idx]!);
            }
          }

          // 3. Update Job State via API
          final updateData = <String, dynamic>{};
          if (finalSigKey != null) {
            updateData['signature'] = AppConstants.minioObjectUrl(finalSigKey);
          }
          if (validPhotoKeys.isNotEmpty) {
            updateData['photos'] = validPhotoKeys.map((k) => AppConstants.minioObjectUrl(k)).toList();
          }
          updateData['status'] = 'completed';

          if (updateData.isNotEmpty) {
            final finalRes = await _jobRepository.updateJob(jobId, updateData);
            finalRes.fold(
              (error) => emit(UploadBatchFailure(error: error)),
              (_) => emit(const UploadBatchSuccess()),
            );
          } else {
            // Nothing updated physically successful
            emit(const UploadBatchSuccess());
          }
        },
      );
    } catch (e) {
      emit(UploadBatchFailure(error: e.toString()));
    }
  }
}
