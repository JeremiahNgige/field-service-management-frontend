part of 'image_capture_cubit.dart';

class ImageCaptureState extends Equatable {
  const ImageCaptureState({
    this.photosMap = const {},
    this.signaturesMap = const {},
  });

  final Map<String, List<LocalPhoto>> photosMap;
  final Map<String, List<Map<String, dynamic>>> signaturesMap;

  ImageCaptureState copyWith({
    Map<String, List<LocalPhoto>>? photosMap,
    Map<String, List<Map<String, dynamic>>>? signaturesMap,
  }) {
    return ImageCaptureState(
      photosMap: photosMap ?? this.photosMap,
      signaturesMap: signaturesMap ?? this.signaturesMap,
    );
  }

  factory ImageCaptureState.fromJson(Map<String, dynamic> json) {
    final photosMapRaw = json['photosMap'] as Map<String, dynamic>? ?? {};
    final parsedPhotosMap = <String, List<LocalPhoto>>{};
    for (final entry in photosMapRaw.entries) {
      final list = entry.value as List<dynamic>? ?? [];
      parsedPhotosMap[entry.key] = list
          .map((e) => LocalPhoto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    final signaturesMapRaw = json['signaturesMap'] as Map<String, dynamic>? ?? {};
    final parsedSigMap = <String, List<Map<String, dynamic>>>{};
    for (final entry in signaturesMapRaw.entries) {
      final list = entry.value as List<dynamic>? ?? [];
      parsedSigMap[entry.key] = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return ImageCaptureState(
      photosMap: parsedPhotosMap,
      signaturesMap: parsedSigMap,
    );
  }

  Map<String, dynamic> toJson() {
    final photosJson = <String, dynamic>{};
    for (final entry in photosMap.entries) {
      photosJson[entry.key] = entry.value.map((e) => e.toJson()).toList();
    }

    return {
      'photosMap': photosJson,
      'signaturesMap': signaturesMap,
    };
  }

  @override
  List<Object> get props => [photosMap, signaturesMap];
}
