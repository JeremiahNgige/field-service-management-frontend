// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JobModel _$JobModelFromJson(Map<String, dynamic> json) => JobModel(
  jobId: json['job_id'] as String?,
  title: json['title'] as String?,
  description: json['description'] as String?,
  status: $enumDecodeNullable(_$JobStatusEnumMap, json['status']),
  priority: $enumDecodeNullable(_$JobPriorityEnumMap, json['priority']),
  requirements: json['requirements'] as Map<String, dynamic>?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  assignedTo: json['assigned_to'] as String?,
  customerName: json['customer_name'] as String?,
  phoneNumber: json['phone_number'] as String?,
  address: json['address'] == null
      ? null
      : Address.fromJson(json['address'] as Map<String, dynamic>),
  startTime: json['start_time'] as String?,
  endTime: json['end_time'] as String?,
  currency: json['currency'] as String?,
  price: _parsePrice(json['price']),
  signature: json['signature'] as String?,
  photos: (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList(),
  isOverdue: json['is_overdue'] as bool?,
);

Map<String, dynamic> _$JobModelToJson(JobModel instance) => <String, dynamic>{
  'job_id': instance.jobId,
  'title': instance.title,
  'description': instance.description,
  'status': _$JobStatusEnumMap[instance.status],
  'priority': _$JobPriorityEnumMap[instance.priority],
  'requirements': instance.requirements,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'assigned_to': instance.assignedTo,
  'customer_name': instance.customerName,
  'phone_number': instance.phoneNumber,
  'address': instance.address,
  'start_time': instance.startTime,
  'end_time': instance.endTime,
  'currency': instance.currency,
  'price': _priceToJson(instance.price),
  'signature': instance.signature,
  'photos': instance.photos,
  'is_overdue': instance.isOverdue,
};

const _$JobStatusEnumMap = {
  JobStatus.unassigned: 'unassigned',
  JobStatus.assigned: 'assigned',
  JobStatus.inProgress: 'in_progress',
  JobStatus.completed: 'completed',
  JobStatus.cancelled: 'cancelled',
};

const _$JobPriorityEnumMap = {
  JobPriority.low: 'low',
  JobPriority.medium: 'medium',
  JobPriority.high: 'high',
};

UploadUrlRequest _$UploadUrlRequestFromJson(Map<String, dynamic> json) =>
    UploadUrlRequest(
      imageCount: (json['image_count'] as num).toInt(),
      hasSignature: json['has_signature'] as bool,
    );

Map<String, dynamic> _$UploadUrlRequestToJson(UploadUrlRequest instance) =>
    <String, dynamic>{
      'image_count': instance.imageCount,
      'has_signature': instance.hasSignature,
    };

PresignedUrlEntry _$PresignedUrlEntryFromJson(Map<String, dynamic> json) =>
    PresignedUrlEntry(
      uploadUrl: json['upload_url'] as String,
      key: json['key'] as String,
    );

Map<String, dynamic> _$PresignedUrlEntryToJson(PresignedUrlEntry instance) =>
    <String, dynamic>{'upload_url': instance.uploadUrl, 'key': instance.key};

UploadUrlsResponse _$UploadUrlsResponseFromJson(Map<String, dynamic> json) =>
    UploadUrlsResponse(
      signature: json['signature'] == null
          ? null
          : PresignedUrlEntry.fromJson(
              json['signature'] as Map<String, dynamic>,
            ),
      images: (json['images'] as List<dynamic>)
          .map((e) => PresignedUrlEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UploadUrlsResponseToJson(UploadUrlsResponse instance) =>
    <String, dynamic>{
      'signature': instance.signature,
      'images': instance.images,
    };

Address _$AddressFromJson(Map<String, dynamic> json) => Address(
  street: json['street'] as String?,
  city: json['city'] as String?,
  state: json['state'] as String?,
  zip: json['zip'] as String?,
  latLong: json['LatLong'] == null
      ? null
      : LatLong.fromJson(json['LatLong'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
  'street': instance.street,
  'city': instance.city,
  'state': instance.state,
  'zip': instance.zip,
  'LatLong': instance.latLong,
};

LatLong _$LatLongFromJson(Map<String, dynamic> json) => LatLong(
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$LatLongToJson(LatLong instance) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
