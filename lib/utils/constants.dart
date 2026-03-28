/// Global app constants for the FSM frontend.
class AppConstants {
  AppConstants._();

  /// Base URL of the Django backend served by Docker (gunicorn on port 8000).
  ///
  /// Pick the line that matches your run target and comment the others out:
  // static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator → host Docker
  // static const String baseUrl =
  //     'http://localhost:8000/api'; // iOS simulator → host Docker
  static const String baseUrl =
      'http://192.168.0.7:8000/api'; // Physical device → host LAN IP (update IP)

  // ── MinIO / S3 ────────────────────────────────────────────────────────────
  //
  // MinIO is exposed on host port 9000 via Docker (docker-compose.yml).
  // Use the same host-alias strategy as baseUrl above.
  //
  // Pick the line that matches your run target and comment the others out:
  // static const String minioEndpoint = 'http://10.0.2.2:9000'; // Android emulator → host Docker
  // static const String minioEndpoint =
  //     'http://localhost:9000'; // iOS simulator → host Docker
  static const String minioEndpoint =
      'http://192.168.0.7:9000'; // Physical device → host LAN IP (update IP)

  /// S3 bucket name (AWS_STORAGE_BUCKET_NAME in backend .env).
  static const String minioBucket = 'fsm-bucket';

  /// MinIO credentials (match AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY in .env).
  /// ⚠️  Rotate these before going to production.
  static const String minioAccessKey = 'minioadmin';
  static const String minioSecretKey = 'minioadmin';

  /// Whether to use TLS when talking to MinIO (AWS_S3_USE_SSL in .env).
  static const bool minioUseSsl = false;

  static String minioObjectUrl(String key) =>
      '$minioEndpoint/$minioBucket/$key';

  /// JWT token keys stored in Hive.
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  /// Pagination
  static const int pageSize = 25;

  /// S3 presigned URL expiry hint (mirrors Django default: 1800 s = 30 min)
  static const int urlExpirySeconds = 1800;

  /// App name
  static const String appName = 'FSM Field Service';

  /// Map Tile Provider
  static const String mapUrlTemplate = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
  static const List<String> mapSubdomains = ['a', 'b', 'c', 'd'];
}
