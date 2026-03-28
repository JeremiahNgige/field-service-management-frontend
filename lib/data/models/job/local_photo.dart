import 'dart:io';

class LocalPhoto {
  const LocalPhoto({
    required this.file,
    required this.capturedAt,
  });

  final File file;
  final DateTime capturedAt;

  factory LocalPhoto.fromJson(Map<String, dynamic> json) {
    return LocalPhoto(
      file: File(json['path'] as String),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': file.path,
      'capturedAt': capturedAt.toIso8601String(),
    };
  }
}
