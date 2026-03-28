import 'package:geolocator/geolocator.dart';

/// A lightweight service that wraps [Geolocator] to:
/// - request location permission on first use
/// - return the device [Position] or null if unavailable/denied
/// - expose a [calculateDistance] helper using the built-in Haversine formula
class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  bool _permanentlyDenied = false;

  /// Whether the user permanently denied location permission.
  bool get permissionDeniedPermanently => _permanentlyDenied;

  /// Requests permission if needed and returns the current [Position],
  /// or `null` if location is unavailable or the user denied access.
  Future<Position?> getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) {
      _permanentlyDenied = true;
      return null;
    }

    _permanentlyDenied = false;
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 6),
      ),
    );
  }

  /// Returns the straight-line distance in **meters** between two coordinates.
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
