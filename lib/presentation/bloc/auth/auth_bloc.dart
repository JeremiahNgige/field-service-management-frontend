import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../data/api/interceptors.dart';
import '../../../data/api/session_expired_notifier.dart';
import '../../../data/models/user/user_model.dart';
import '../../../data/repository/auth_repository.dart';
import '../../../data/services/biometric_service.dart';
import '../../../data/services/fcm_service.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.tokens, this.user});
  final AuthTokens tokens;
  final UserModel? user;
  @override
  List<Object?> get props => [tokens, user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}


class AuthSessionExpired extends AuthState {
  const AuthSessionExpired();
}

class AuthFailure extends AuthState {
  const AuthFailure({required this.message});
  final String message;
  @override
  List<Object?> get props => [message];
}

class AuthBiometricStatus extends AuthState {
  const AuthBiometricStatus({
    required this.isAvailable,
    required this.isEnabled,
    required this.hasToken,
  });
  final bool isAvailable;
  final bool isEnabled;
  final bool hasToken;
  @override
  List<Object?> get props => [isAvailable, isEnabled, hasToken];
}

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.request});
  final LoginRequest request;
  @override
  List<Object?> get props => [request];
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({required this.request});
  final RegisterRequest request;
  @override
  List<Object?> get props => [request];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthUpdateProfileRequested extends AuthEvent {
  const AuthUpdateProfileRequested({required this.data});
  final Map<String, dynamic> data;
  @override
  List<Object?> get props => [data];
}

class AuthCheckBiometricStatus extends AuthEvent {
  const AuthCheckBiometricStatus();
}

class AuthFetchProfileRequested extends AuthEvent {
  const AuthFetchProfileRequested();
}

class AuthBiometricUnlockRequested extends AuthEvent {
  const AuthBiometricUnlockRequested();
}

class AuthSetBiometricEnabled extends AuthEvent {
  const AuthSetBiometricEnabled({required this.enabled});
  final bool enabled;
}

class _AuthSessionExpiredReceived extends AuthEvent {
  const _AuthSessionExpiredReceived();
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository, this._biometricService, this._fcmService)
    : super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthUpdateProfileRequested>(_onUpdateProfile);
    on<AuthCheckBiometricStatus>(_onCheckBiometricStatus);
    on<AuthBiometricUnlockRequested>(_onBiometricUnlock);
    on<AuthSetBiometricEnabled>(_onSetBiometricEnabled);
    on<AuthFetchProfileRequested>(_onFetchProfile);
    on<_AuthSessionExpiredReceived>(_onSessionExpired);

    // Subscribe to the global session-expiry signal from the interceptor.
    _sessionExpirySub = SessionExpiredNotifier.instance.stream.listen(
      (_) => add(const _AuthSessionExpiredReceived()),
    );

    // Subscribe to FCM token rotation — keeps the backend always current.
    _fcmTokenRefreshSub = _fcmService.onTokenRefresh.listen((newToken) {
      _authRepository.updateFcmToken(newToken);
    });
  }

  UserModel? _extractUserFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final payload = JwtDecoder.decode(token);
      return UserModel.fromJson(payload);
    } catch (e) {
      return null;
    }
  }

  Future<void> _registerFcmToken() async {
    final token = await _fcmService.getToken();
    if (token != null) {
      await _authRepository.updateFcmToken(token);
    }
  }

  final IAuthRepository _authRepository;
  final BiometricService _biometricService;
  final FcmService _fcmService;
  late final StreamSubscription<void> _sessionExpirySub;
  late final StreamSubscription<String> _fcmTokenRefreshSub;

  @override
  Future<void> close() {
    _sessionExpirySub.cancel();
    _fcmTokenRefreshSub.cancel();
    return super.close();
  }

  // ── Credential login ───────────────────────────────────────────────────────

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      emit(const AuthFailure(message: 'No internet connection.'));
      return;
    }

    final result = await _authRepository.login(event.request);
    result.fold(
      (error) => emit(AuthFailure(message: error)),
      (tokens) {
        final user = _extractUserFromToken(tokens.access);
        emit(AuthAuthenticated(tokens: tokens, user: user));
        // Fire-and-forget: register the FCM token with the backend.
        _registerFcmToken();
      },
    );
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      emit(const AuthFailure(message: 'No internet connection.'));
      return;
    }

    final result = await _authRepository.register(event.request);

    result.fold(
      (error) => emit(AuthFailure(message: error)),
      (user) => emit(const AuthUnauthenticated()),
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await _authRepository.logout();
    await _biometricService.setBiometricEnabled(enabled: false);
    emit(const AuthUnauthenticated());
  }

  // ── Profile update ─────────────────────────────────────────────────────────

  Future<void> _onUpdateProfile(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      emit(const AuthFailure(message: 'No internet connection.'));
      return;
    }

    final result = await _authRepository.updateProfile(event.data);
    result.fold((error) => emit(AuthFailure(message: error)), (user) {
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        emit(AuthAuthenticated(tokens: currentState.tokens, user: user));
      }
    });
  }

  // ── Fetch Profile ──────────────────────────────────────────────────────────

  Future<void> _onFetchProfile(
    AuthFetchProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return; // Silently abort if offline; cached profile remains active.
    }

    final result = await _authRepository.fetchProfile();
    result.fold(
      (error) {
        // Silently fail or log. We retain current user data in state.
      },
      (user) {
        emit(AuthAuthenticated(tokens: currentState.tokens, user: user));
      },
    );
  }

  // ── Session expired (from interceptor via stream) ──────────────────────────

  Future<void> _onSessionExpired(
    _AuthSessionExpiredReceived event,
    Emitter<AuthState> emit,
  ) async {
    // Tokens were already cleared by the interceptor before it notified.
    // Also clear the biometric preference so the user must fully re-login.
    await _biometricService.setBiometricEnabled(enabled: false);
    emit(const AuthSessionExpired());
  }

  // ── Biometric status check ─────────────────────────────────────────────────

  Future<void> _onCheckBiometricStatus(
    AuthCheckBiometricStatus event,
    Emitter<AuthState> emit,
  ) async {
    final token = await getAccessToken();
    final refreshToken = await getRefreshToken();


    if (isJwtExpired(refreshToken)) {
      await clearTokens(); // Hard wipe local tokens
      emit(
        const AuthBiometricStatus(
          isAvailable: false,
          isEnabled: false,
          hasToken: false,
        ),
      );
      // Wait a tick then force session expiry so the router resets heavily.
      add(const _AuthSessionExpiredReceived());
      return;
    }

    final hasToken = token != null && token.isNotEmpty;
    final isAvailable = await _biometricService.isAvailable();
    final isEnabled = await _biometricService.isBiometricEnabled();

    emit(
      AuthBiometricStatus(
        isAvailable: isAvailable,
        isEnabled: isEnabled,
        hasToken: hasToken,
      ),
    );
  }

  // ── Biometric unlock ───────────────────────────────────────────────────────

  Future<void> _onBiometricUnlock(
    AuthBiometricUnlockRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final didAuthenticate = await _biometricService.authenticate();
    if (!didAuthenticate) {
      emit(const AuthFailure(message: 'Biometric authentication failed'));
      return;
    }

    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    if (accessToken == null || accessToken.isEmpty) {
      emit(const AuthFailure(message: 'No session found. Please log in.'));
      return;
    }

    final user = _extractUserFromToken(accessToken);

    emit(
      AuthAuthenticated(
        tokens: AuthTokens(access: accessToken, refresh: refreshToken ?? ''),
        user: user,
      ),
    );

    // Fire-and-forget: register the FCM token with the backend.
    _registerFcmToken();
  }

  // ── Set biometric preference ───────────────────────────────────────────────

  Future<void> _onSetBiometricEnabled(
    AuthSetBiometricEnabled event,
    Emitter<AuthState> emit,
  ) async {
    await _biometricService.setBiometricEnabled(enabled: event.enabled);
    emit(state);
  }
}
