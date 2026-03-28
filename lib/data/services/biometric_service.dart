import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kBiometricEnabled = 'biometric_enabled';

// ─────────────────────────────────────────────────────────────────────────────
// BiometricService
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps [LocalAuthentication] and biometric preference persistence.
///
/// - Android: uses BiometricPrompt (fingerprint, face, iris — device-dependent).
/// - iOS:     uses LAContext (Touch ID / Face ID).
///
/// Biometric preference is stored in [FlutterSecureStorage] so it cannot
/// be tampered with via plain SharedPreferences.
@lazySingleton
class BiometricService {
  BiometricService()
      : _auth = LocalAuthentication(),
        _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;

  // ── Capability ─────────────────────────────────────────────────────────────

  /// Returns true if the device supports biometrics AND at least one
  /// biometric is enrolled (e.g. a fingerprint or Face ID scan is set up).
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isDeviceSupported) return false;

      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Preference ─────────────────────────────────────────────────────────────

  /// Returns true if the user has opted in to biometric unlock.
  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _kBiometricEnabled);
    return val == 'true';
  }

  /// Persists the user's biometric opt-in choice.
  Future<void> setBiometricEnabled({required bool enabled}) async {
    await _storage.write(
      key: _kBiometricEnabled,
      value: enabled.toString(),
    );
  }

  // ── Authentication ─────────────────────────────────────────────────────────

  /// Triggers the platform biometric prompt.
  ///
  /// Returns `true` on success, `false` on failure or cancellation.
  /// [reason] is shown beneath the biometric prompt on Android.
  Future<bool> authenticate({
    String reason = 'Confirm your identity to unlock FSM',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,        // keeps the prompt alive if app goes bg
          biometricOnly: true,    // do NOT fall back to device PIN/password
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
