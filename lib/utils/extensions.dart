import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../data/models/job/job_model.dart';

extension StringExtension on String {
  /// Capitalize first letter.
  String get capitalize =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;

  /// Convert snake_case to Title Case.
  String get toTitleCase => split('_')
      .map((word) => word.capitalize)
      .join(' ');

  /// Check if a string is a valid email.
  bool get isValidEmail => RegExp(
        r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(this);
}

extension DateTimeExtension on DateTime {
  /// Returns a human-friendly relative time string (e.g., "3 minutes ago").
  String get timeAgo => timeago.format(this);

  /// Returns a formatted date string.
  String get formatted =>
      DateFormat('MMM dd, yyyy • hh:mm a').format(this);

  /// Returns a date-only string.
  String get dateOnly => DateFormat('MMM dd, yyyy').format(this);
}

extension JobStatusExtension on JobStatus {
  Color get color {
    switch (this) {
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

  IconData get icon {
    switch (this) {
      case JobStatus.unassigned:
        return Icons.hourglass_empty;
      case JobStatus.assigned:
        return Icons.person;
      case JobStatus.inProgress:
        return Icons.construction;
      case JobStatus.completed:
        return Icons.check_circle;
      case JobStatus.cancelled:
        return Icons.cancel;
    }
  }
}

extension JobPriorityExtension on JobPriority {
  Color get color {
    switch (this) {
      case JobPriority.low:
        return Colors.green;
      case JobPriority.medium:
        return Colors.orange;
      case JobPriority.high:
        return Colors.red;
    }
  }
}

extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // ── Snackbar helpers ────────────────────────────────────────────────────────

  /// Shows a slick success snackbar (green).
  void showSuccessSnackBar(String message, {Duration? duration}) =>
      AppSnackBar.success(this, message, duration: duration);

  /// Shows a slick error snackbar (red).
  void showErrorSnackBar(String message, {Duration? duration}) =>
      AppSnackBar.error(this, message, duration: duration);

  /// Shows a slick info snackbar (blue).
  void showInfoSnackBar(String message, {Duration? duration}) =>
      AppSnackBar.info(this, message, duration: duration);

  /// Shows a slick warning snackbar (amber).
  void showWarningSnackBar(String message, {Duration? duration}) =>
      AppSnackBar.warning(this, message, duration: duration);
}

// ─── AppSnackBar ──────────────────────────────────────────────────────────────
// Slick, icon-enhanced floating snackbars with semantic colours.
// Usage:
//   context.showSuccessSnackBar('Job saved!');
//   context.showErrorSnackBar(AppHelpers.friendlyError(e));
//   AppSnackBar.success(context, 'Done');
// ─────────────────────────────────────────────────────────────────────────────

class AppSnackBar {
  AppSnackBar._();

  // ── Semantic entry points ──────────────────────────────────────────────────

  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
  }) =>
      _show(
        context,
        message: message,
        icon: Icons.check_circle_rounded,
        background: const Color(0xFF1B873A),        // deep green
        duration: duration ?? const Duration(seconds: 3),
      );

  static void error(
    BuildContext context,
    String message, {
    Duration? duration,
  }) =>
      _show(
        context,
        message: message,
        icon: Icons.error_rounded,
        background: const Color(0xFFBF2600),        // deep red
        duration: duration ?? const Duration(seconds: 5),
      );

  static void info(
    BuildContext context,
    String message, {
    Duration? duration,
  }) =>
      _show(
        context,
        message: message,
        icon: Icons.info_rounded,
        background: const Color(0xFF0654C4),        // deep blue
        duration: duration ?? const Duration(seconds: 4),
      );

  static void warning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) =>
      _show(
        context,
        message: message,
        icon: Icons.warning_rounded,
        background: const Color(0xFF8A5700),        // deep amber
        duration: duration ?? const Duration(seconds: 4),
      );

  // ── Core renderer ──────────────────────────────────────────────────────────

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color background,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: EdgeInsets.zero,
          content: _SnackBarContent(
            message: message,
            icon: icon,
            background: background,
          ),
        ),
      );
  }
}

// ── Private widget ─────────────────────────────────────────────────────────────

class _SnackBarContent extends StatelessWidget {
  const _SnackBarContent({
    required this.message,
    required this.icon,
    required this.background,
  });

  final String message;
  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: background.withAlpha(120),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

