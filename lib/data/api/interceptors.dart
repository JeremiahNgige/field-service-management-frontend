import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../utils/constants.dart';
import 'session_expired_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Secure Storage
// ─────────────────────────────────────────────────────────────────────────────

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

const _kAccessToken = AppConstants.accessTokenKey;
const _kRefreshToken = AppConstants.refreshTokenKey;

// ─────────────────────────────────────────────────────────────────────────────
// Public token API
// ─────────────────────────────────────────────────────────────────────────────

/// No-op: kept for API compatibility.
Future<void> initTokenBox() async {}

Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);
Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);

/// Checks if a JWT string is locally expired.
bool isJwtExpired(String? token) {
  if (token == null || token.isEmpty) return true;
  try {
    return JwtDecoder.isExpired(token);
  } catch (_) {
    return true; // Malformed tokens are treated as expired
  }
}

Future<void> saveTokens({
  required String access,
  required String refresh,
}) async {
  await Future.wait([
    _storage.write(key: _kAccessToken, value: access),
    _storage.write(key: _kRefreshToken, value: refresh),
  ]);
}

Future<void> clearTokens() async {
  await Future.wait([
    _storage.delete(key: _kAccessToken),
    _storage.delete(key: _kRefreshToken),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Concurrent-refresh lock
// ─────────────────────────────────────────────────────────────────────────────
//
// When multiple requests fire simultaneously and all receive 401, only the
// FIRST one should attempt to refresh.  The rest queue behind a Completer
// and receive the same result once the single refresh completes.

bool _isRefreshing = false;
Completer<bool>? _refreshCompleter;

// ─────────────────────────────────────────────────────────────────────────────
// AuthInterceptor
// ─────────────────────────────────────────────────────────────────────────────

/// Injects the Bearer token on every request and handles 401 with a
/// thread-safe token-refresh + retry.  When the refresh token has also
/// expired it clears local credentials and signals [SessionExpiredNotifier]
/// so the rest of the app can redirect to the login screen.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Whitelist public endpoints from token injection natively
    if (options.path.contains('/login/') || options.path.contains('/register/')) {
      return handler.next(options);
    }

    final token = await getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Whitelist public endpoints from 401 retry loops natively
    if (err.requestOptions.path.contains('/login/') || 
        err.requestOptions.path.contains('/register/')) {
      return handler.next(err);
    }

    if (err.response?.statusCode != 401) {
      // Not an auth error — pass through immediately.
      return handler.next(err);
    }

    // ── Concurrent-refresh guard ───────────────────────────────────────────
    if (_isRefreshing) {
      // Another request is already refreshing.  Wait for it to finish.
      final succeeded = await _refreshCompleter!.future;
      if (succeeded) {
        // Re-inject the freshly written token and retry.
        final newToken = await getAccessToken();
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        try {
          final retryResponse = await Dio().fetch(opts);
          return handler.resolve(retryResponse);
        } catch (e) {
          return handler.next(err);
        }
      } else {
        // Refresh had already failed — surface the 401.
        return handler.next(err);
      }
    }

    // ── First request gets to perform the refresh ──────────────────────────
    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    final refreshToken = await getRefreshToken();
    if (isJwtExpired(refreshToken)) {
      // Refresh token is completely expired, invalid, or missing — session is definitively over.
      await _handleExpiry();
      _refreshCompleter!.complete(false);
      _isRefreshing = false;
      _refreshCompleter = null;
      return handler.next(err);
    }

    String? newAccess;
    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      final response = await refreshDio.post(
        '/user/refresh/',
        data: {'refresh': refreshToken!},
      );

      newAccess = response.data['access'] as String;
      final newRefresh = response.data['refresh'] as String? ?? refreshToken;
      await saveTokens(access: newAccess, refresh: newRefresh);

      // Signal other waiters: refresh succeeded.
      _refreshCompleter!.complete(true);
      _isRefreshing = false;
      _refreshCompleter = null;
    } catch (_) {
      // Refresh failed — both tokens are invalid.
      await _handleExpiry();
      _refreshCompleter!.complete(false);
      _isRefreshing = false;
      _refreshCompleter = null;
      return handler.next(err);
    }

    // Now securely retry outside the Completer's try/catch block natively.
    // If THIS fetch times out or fails (due to momentary internet drop), it won't
    // inadvertently leap into the catch(_) block and crash the nullified _refreshCompleter!
    try {
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newAccess';
      final retryResponse = await Dio().fetch(opts);
      return handler.resolve(retryResponse);
    } catch (e) {
      return handler.next(err);
    }
  }

  /// Clears stored tokens and notifies the app that the session is over.
  Future<void> _handleExpiry() async {
    await clearTokens();
    SessionExpiredNotifier.instance.notify();
  }
}
