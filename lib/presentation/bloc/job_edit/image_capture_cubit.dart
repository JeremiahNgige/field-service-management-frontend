import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:signature/signature.dart';

import '../../../data/models/job/local_photo.dart';

part 'image_capture_state.dart';

@injectable
class ImageCaptureCubit extends HydratedCubit<ImageCaptureState> {
  ImageCaptureCubit() : super(const ImageCaptureState());

  void addPhoto(String jobId, LocalPhoto photo) {
    final currentList = state.photosMap[jobId] ?? <LocalPhoto>[];
    final updatedMap = Map<String, List<LocalPhoto>>.from(state.photosMap);
    updatedMap[jobId] = List.of(currentList)..add(photo);
    emit(state.copyWith(photosMap: updatedMap));
  }

  void removePhoto(String jobId, LocalPhoto photo) {
    final currentList = state.photosMap[jobId] ?? <LocalPhoto>[];
    final updatedMap = Map<String, List<LocalPhoto>>.from(state.photosMap);
    updatedMap[jobId] = List.of(currentList)..remove(photo);
    emit(state.copyWith(photosMap: updatedMap));
  }

  void updateSignature(String jobId, List<Point> points) {
    final updatedMap = Map<String, List<Map<String, dynamic>>>.from(state.signaturesMap);
    updatedMap[jobId] = points
        .map((p) => {
              'dx': p.offset.dx,
              'dy': p.offset.dy,
              'type': p.type.index,
              'pressure': p.pressure,
            })
        .toList();
    emit(state.copyWith(signaturesMap: updatedMap));
  }

  void clearPhotos(String jobId) {
    final updatedMap = Map<String, List<LocalPhoto>>.from(state.photosMap);
    updatedMap.remove(jobId);
    emit(state.copyWith(photosMap: updatedMap));
  }

  void clearSignature(String jobId) {
    final updatedMap = Map<String, List<Map<String, dynamic>>>.from(state.signaturesMap);
    updatedMap.remove(jobId);
    emit(state.copyWith(signaturesMap: updatedMap));
  }

  void clearCache(String jobId) {
    final updatedPhotos = Map<String, List<LocalPhoto>>.from(state.photosMap)..remove(jobId);
    final updatedSigs = Map<String, List<Map<String, dynamic>>>.from(state.signaturesMap)..remove(jobId);
    emit(state.copyWith(photosMap: updatedPhotos, signaturesMap: updatedSigs));
  }

  @override
  ImageCaptureState? fromJson(Map<String, dynamic> json) {
    try {
      return ImageCaptureState.fromJson(json);
    } catch (_) {
      return const ImageCaptureState();
    }
  }

  @override
  Map<String, dynamic>? toJson(ImageCaptureState state) => state.toJson();
}
