import 'dart:async';

/// Singleton stream that the Dio interceptor layer uses to signal
/// an unrecoverable session expiry (refresh token also rejected) to the
/// rest of the app — without creating a circular dependency on AuthBloc.
///
/// Usage:
///   Publisher (interceptors.dart):  SessionExpiredNotifier.instance.notify();
///   Subscriber (auth_bloc.dart):    SessionExpiredNotifier.instance.stream
class SessionExpiredNotifier {
  SessionExpiredNotifier._();
  static final instance = SessionExpiredNotifier._();

  final _controller = StreamController<void>.broadcast();

  /// Listens for session-expiry events.
  Stream<void> get stream => _controller.stream;

  /// Broadcasts a session-expiry event.
  void notify() {
    if (!_controller.isClosed) _controller.add(null);
  }

  /// Call only when the app is shutting down.
  void dispose() => _controller.close();
}
