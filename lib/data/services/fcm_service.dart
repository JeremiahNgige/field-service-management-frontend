import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Top-level background message handler (required by FCM)
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('[FCM] Background message received: ${message.messageId}');
}

// ─────────────────────────────────────────────────────────────────────────────
// FcmService
// ─────────────────────────────────────────────────────────────────────────────

@lazySingleton
class FcmService {
  FcmService(this._messaging, this._localNotifications);

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  // ── Foreground notification channel (Android) ──────────────────────────────
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'fsm_high_importance',
    'FSM Notifications',
    description: 'Notifications for Field Service Management job updates.',
    importance: Importance.high,
  );

  /// Call once after Firebase.initializeApp().
  Future<void> initialize() async {
    // Register the background handler.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions (iOS prompts; Android 13+ also needs this).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );


    // Create the high-importance channel for Android foreground notifications.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Show heads-up notifications while the app is in the foreground.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      final jobId = message.data['job_id']?.toString() ?? '';
      final userId = message.data['user_id']?.toString() ?? '';
      final payload = jsonEncode({'job_id': jobId, 'user_id': userId});

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: payload,
      );
    });

    log('[FCM] Initialized successfully.');
  }

  /// Sets up callbacks for when a notification is tapped.
  /// Handles foreground, background, and terminated states.
  Future<void> setupInteractions(void Function(String jobId, String targetUserId) onJobTapped) async {
    // 1. Terminated state
    final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
    _handleMessage(initialMsg, onJobTapped);

    // 2. Background state
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(message, onJobTapped);
    });

    // 3. Foreground state (Local Notifications)
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!);
            final jId = data['job_id']?.toString();
            final uId = data['user_id']?.toString();
            if (jId != null && jId.isNotEmpty) {
              onJobTapped(jId, uId ?? '');
            }
          } catch (e) {
            // Fallback for old missing payloads dynamically
            onJobTapped(response.payload!, '');
          }
        }
      },
    );
  }

  void _handleMessage(RemoteMessage? message, void Function(String, String) onJobTapped) {
    if (message == null) return;
    
    // Extract job_id and user_id from Django data payload natively
    final jobId = message.data['job_id']?.toString();
    final userId = message.data['user_id']?.toString() ?? '';
    
    if (jobId != null && jobId.isNotEmpty) {
      onJobTapped(jobId, userId);
    }
  }

  /// Returns the current FCM registration token, or null if unavailable.
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      log('[FCM] Token: $token');
      return token;
    } catch (e) {
      log('[FCM] Failed to get token: $e');
      return null;
    }
  }

  /// Emits a new token whenever FCM rotates or invalidates the old one.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
