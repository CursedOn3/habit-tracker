import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/constants.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<Position?> getCurrentPosition() async {
    if (!await hasPermission()) {
      final granted = await requestPermission();
      if (!granted) return null;
    }

    if (!await isLocationServiceEnabled()) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if user is within [radius] meters of [targetLat, targetLng]
  bool isNearLocation({
    required double userLat,
    required double userLng,
    required double targetLat,
    required double targetLng,
    double radius = AppConstants.geofenceRadius,
  }) {
    final distance = Geolocator.distanceBetween(
      userLat,
      userLng,
      targetLat,
      targetLng,
    );
    return distance <= radius;
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 50, // Update every 50 meters
      ),
    );
  }
}
