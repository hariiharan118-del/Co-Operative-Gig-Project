import 'package:geolocator/geolocator.dart';

class DeviceLocation {
  const DeviceLocation({this.lat, this.lng, this.denied = false});

  final double? lat;
  final double? lng;
  final bool denied;

  bool get hasCoords => lat != null && lng != null;
}

/// Mirrors the Worker tracking screen: check services, request permission, then read a fix.
Future<DeviceLocation> resolveDeviceLocation() async {
  try {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) return const DeviceLocation(denied: true);

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return const DeviceLocation(denied: true);
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    );
    return DeviceLocation(lat: position.latitude, lng: position.longitude);
  } catch (_) {
    return const DeviceLocation(denied: true);
  }
}
