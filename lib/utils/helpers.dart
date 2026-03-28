import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/job/job_model.dart';

class AppHelpers {
  AppHelpers._();

  static String formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Unknown';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat.yMMMMEEEEd().add_jm().format(dt);
    } catch (_) {
      return 'Invalid Date';
    }
  }

  static String formatDateTime(DateTime dt) {
    return DateFormat('hh:mm a\ndd MMM yyyy').format(dt);
  }

  static Future<void> launchNavigation(double lat, double lng) async {
    final iOsUrl = Uri.parse('maps://?q=$lat,$lng');
    final androidUrl = Uri.parse('google.navigation:q=$lat,$lng');

    if (Platform.isIOS) {
      if (await canLaunchUrl(iOsUrl)) {
        await launchUrl(iOsUrl);
      } else {
        await launchUrl(Uri.parse('https://maps.apple.com/?q=$lat,$lng'));
      }
    } else {
      if (await canLaunchUrl(androidUrl)) {
        await launchUrl(androidUrl);
      } else {
        await launchUrl(
          Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
          ),
        );
      }
    }
  }

  static Color statusColor(JobStatus? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case JobStatus.unassigned:
        return Colors.orange;
      case JobStatus.assigned:
        return Colors.teal;
      case JobStatus.inProgress:
        return Colors.blue;
      case JobStatus.completed:
        return Colors.green;
      case JobStatus.cancelled:
        return Colors.red;
    }
  }

  static Color priorityColor(JobPriority? priority) {
    if (priority == null) return Colors.grey;
    switch (priority) {
      case JobPriority.low:
        return Colors.green;
      case JobPriority.medium:
        return Colors.orange;
      case JobPriority.high:
        return Colors.red;
    }
  }

  /// Converts raw [meters] into a human-readable distance string.
  /// Shows in meters below 1 km, kilometres above.
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  // ─── API Error Translation ─────────────────────────────────────────────────

  /// Converts a raw [DioException] (or any error object) into a clear,
  /// user-friendly message that can be shown directly in the UI.
  ///
  /// Priority order:
  ///   1. HTTP status code → curated message
  ///   2. Server-provided  `error` / `message` / `detail` field in JSON body
  ///   3. DioException connection type (timeout, no internet, etc.)
  ///   4. Generic fallback
  static String friendlyError(dynamic error) {
    // ── Try to extract from HTTP response body first ───────────────────────
    try {
      final statusCode = error.response?.statusCode as int?;
      final data = error.response?.data;

      // Server-supplied message takes priority when status is not a hard-coded one.
      String? serverMessage;
      if (data is Map) {
        serverMessage = (data['error'] ??
                data['message'] ??
                data['detail'] ??
                data['non_field_errors']?.toString())
            ?.toString()
            .trim();
        // Strip surrounding brackets from DRF list-style errors, e.g. ["..."]
        if (serverMessage != null &&
            serverMessage.startsWith('[') &&
            serverMessage.endsWith(']')) {
          serverMessage = serverMessage.substring(1, serverMessage.length - 1)
              .replaceAll('"', '')
              .trim();
        }
      }

      switch (statusCode) {
        case 400:
          // Prefer the server's own validation message; fallback to generic.
          return serverMessage?.isNotEmpty == true
              ? serverMessage!
              : 'Some information you entered is invalid. Please review and try again.';
        case 401:
          return 'Your session has expired. Please sign in again to continue.';
        case 403:
          return 'You don\'t have permission to perform this action.';
        case 404:
          return 'The requested information could not be found. It may have been moved or deleted.';
        case 409:
          return serverMessage?.isNotEmpty == true
              ? serverMessage!
              : 'A conflict occurred — this record may already exist.';
        case 422:
          return serverMessage?.isNotEmpty == true
              ? serverMessage!
              : 'The data you submitted could not be processed. Please check the form and try again.';
        case 429:
          return 'Too many requests. Please wait a moment before trying again.';
        case 500:
        case 502:
        case 503:
        case 504:
          return 'Our servers are experiencing issues right now. Please try again in a few minutes.';
        default:
          if (statusCode != null && serverMessage?.isNotEmpty == true) {
            return serverMessage!;
          }
      }
    } catch (_) {}

    // ── DioException connection type ───────────────────────────────────────
    try {
      final type = error.type;
      // DioExceptionType enum values
      switch (type.toString()) {
        case 'DioExceptionType.connectionTimeout':
        case 'DioExceptionType.sendTimeout':
        case 'DioExceptionType.receiveTimeout':
          return 'The request timed out. Please check your connection and try again.';
        case 'DioExceptionType.connectionError':
          return 'Unable to reach the server. Please check your internet connection.';
        case 'DioExceptionType.cancel':
          return 'The request was cancelled.';
        default:
          break;
      }
    } catch (_) {}

    // ── Last-resort: raw message, cleaned up ──────────────────────────────
    final raw = error?.message?.toString() ?? '';
    if (raw.isEmpty || raw.toLowerCase().contains('dioexception')) {
      return 'Something went wrong. Please try again.';
    }
    return raw;
  }
}
