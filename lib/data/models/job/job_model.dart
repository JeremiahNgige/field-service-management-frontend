import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'job_model.g.dart';

/// Status values matching Django backend choices.
enum JobStatus {
  @JsonValue('unassigned')
  unassigned,
  @JsonValue('assigned')
  assigned,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

/// Priority values matching Django backend choices.
enum JobPriority {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
}

/// Mirrors the Django Job model.
@JsonSerializable()
class JobModel extends Equatable {
  const JobModel({
    this.jobId,
    this.title,
    this.description,
    this.status,
    this.priority,
    this.requirements,
    this.createdAt,
    this.updatedAt,
    this.assignedTo,
    this.customerName,
    this.phoneNumber,
    this.address,
    this.startTime,
    this.endTime,
    this.currency,
    this.price,
    this.signature,
    this.photos,
    this.isOverdue,
  });

  @JsonKey(name: 'job_id')
  final String? jobId;

  final String? title;
  final String? description;
  final JobStatus? status;
  final JobPriority? priority;
  final Map<String, dynamic>? requirements;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  @JsonKey(name: 'assigned_to')
  final String? assignedTo;

  @JsonKey(name: 'customer_name')
  final String? customerName;

  @JsonKey(name: 'phone_number')
  final String? phoneNumber;

  final Address? address;

  @JsonKey(name: 'start_time')
  final String? startTime;

  @JsonKey(name: 'end_time')
  final String? endTime;

  final String? currency;

  @JsonKey(fromJson: _parsePrice, toJson: _priceToJson)
  final double? price;

  final String? signature;
  final List<String>? photos;

  @JsonKey(name: 'is_overdue')
  final bool? isOverdue;

  factory JobModel.fromJson(Map<String, dynamic> json) =>
      _$JobModelFromJson(json);

  Map<String, dynamic> toJson() => _$JobModelToJson(this);

  @override
  List<Object?> get props => [
    jobId,
    title,
    description,
    status,
    priority,
    requirements,
    createdAt,
    updatedAt,
    assignedTo,
    customerName,
    phoneNumber,
    address,
    startTime,
    endTime,
    currency,
    price,
    signature,
    photos,
    isOverdue,
  ];
}

/// Upload URL payload for pre-signed S3/MinIO URLs.
@JsonSerializable()
class UploadUrlRequest extends Equatable {
  const UploadUrlRequest({
    required this.imageCount,
    required this.hasSignature,
  });

  @JsonKey(name: 'image_count')
  final int imageCount;

  @JsonKey(name: 'has_signature')
  final bool hasSignature;

  factory UploadUrlRequest.fromJson(Map<String, dynamic> json) =>
      _$UploadUrlRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UploadUrlRequestToJson(this);

  @override
  List<Object?> get props => [imageCount, hasSignature];
}

/// A single presigned URL entry.
@JsonSerializable()
class PresignedUrlEntry extends Equatable {
  const PresignedUrlEntry({required this.uploadUrl, required this.key});

  @JsonKey(name: 'upload_url')
  final String uploadUrl;

  final String key;

  factory PresignedUrlEntry.fromJson(Map<String, dynamic> json) =>
      _$PresignedUrlEntryFromJson(json);

  Map<String, dynamic> toJson() => _$PresignedUrlEntryToJson(this);

  @override
  List<Object?> get props => [uploadUrl, key];
}

/// Response from the upload URL generation endpoint.
@JsonSerializable()
class UploadUrlsResponse extends Equatable {
  const UploadUrlsResponse({this.signature, required this.images});

  final PresignedUrlEntry? signature;
  final List<PresignedUrlEntry> images;

  factory UploadUrlsResponse.fromJson(Map<String, dynamic> json) =>
      _$UploadUrlsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UploadUrlsResponseToJson(this);

  @override
  List<Object?> get props => [signature, images];
}

@JsonSerializable()
class Address extends Equatable {
  const Address({this.street, this.city, this.state, this.zip, this.latLong});

  final String? street;
  final String? city;
  final String? state;
  final String? zip;

  @JsonKey(name: 'LatLong')
  final LatLong? latLong;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);

  @override
  List<Object?> get props => [street, city, state, zip, latLong];
}

@JsonSerializable()
class LatLong extends Equatable {
  const LatLong({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  factory LatLong.fromJson(Map<String, dynamic> json) =>
      _$LatLongFromJson(json);
  Map<String, dynamic> toJson() => _$LatLongToJson(this);

  @override
  List<Object?> get props => [latitude, longitude];
}

double? _parsePrice(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? _priceToJson(double? value) {
  if (value == null) return null;
  return value.toStringAsFixed(2);
}
