import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'api_response.g.dart';

/// Generic API response wrapper that maps all server responses.
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> extends Equatable {
  const ApiResponse({
    this.message,
    this.data,
    this.next,
    this.previous,
    this.error,
  });

  final String? message;
  final T? data;
  final String? next;
  final String? previous;
  final String? error;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);

  @override
  List<Object?> get props => [message, data, next, previous, error];
}
