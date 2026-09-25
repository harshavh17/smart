import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';

class LocationResult {
  final bool isSuccess;
  final Position? position;
  final String? errorMessage;
  final bool isPermissionDeniedForever;

  LocationResult({
    required this.isSuccess,
    this.position,
    this.errorMessage,
    this.isPermissionDeniedForever = false,
  });
}

class LocationHelper {
  /// Checks and requests location permission, returns user's current Position
  static Future<LocationResult> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          isSuccess: false,
          errorMessage: 'Location services are disabled. Please enable GPS in device settings.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            isSuccess: false,
            errorMessage: 'Location permission was denied. Location is required for attendance.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          isSuccess: false,
          errorMessage: 'Location permissions are permanently denied. Please enable them in app settings.',
          isPermissionDeniedForever: true,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return LocationResult(
        isSuccess: true,
        position: position,
      );
    } catch (e) {
      return LocationResult(
        isSuccess: false,
        errorMessage: 'Failed to retrieve location: $e',
      );
    }
  }

  /// Calculates distance in meters between user position and target coordinates
  static double calculateDistanceInMeters({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
  }) {
    return Geolocator.distanceBetween(userLat, userLng, targetLat, targetLng);
  }

  /// Validates whether user is inside geofence boundary
  static bool isWithinGeofence({
    required double userLat,
    required double userLng,
    double? targetLat,
    double? targetLng,
    double? allowedRadiusMeters,
  }) {
    final tLat = targetLat ?? AppConstants.defaultCampusLat;
    final tLng = targetLng ?? AppConstants.defaultCampusLng;
    final radius = allowedRadiusMeters ?? AppConstants.defaultGeofenceRadiusMeters;

    final distance = calculateDistanceInMeters(
      userLat: userLat,
      userLng: userLng,
      targetLat: tLat,
      targetLng: tLng,
    );

    return distance <= radius;
  }

  /// Formats distance into human-readable string
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(1)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }
}
