import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:commity_app1/Database/Database.dart';

/// LocationService - Handles real-time location permission and fetching
/// Requests permission on login and stores location in DB + locally
class LocationService {
  /// Request location permission and get current location
  /// Returns a map with latitude, longitude, and address
  /// Returns null if permission denied or location unavailable
  static Future<Map<String, dynamic>?> requestAndGetLocation() async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('📍 Location services are disabled');
        return null;
      }

      // 2. Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // 3. Request permission if not granted
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('📍 Location permission denied by user');
          return null;
        }
      }

      // 4. Check if permanently denied
      if (permission == LocationPermission.deniedForever) {
        print('📍 Location permission permanently denied');
        return null;
      }

      // 5. Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // 6. Reverse geocode to get address
      String address = '';
      String city = '';
      String state = '';
      String country = '';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.locality ?? '';
          state = place.administrativeArea ?? '';
          country = place.country ?? '';
          address = [
            place.street ?? '',
            place.subLocality ?? '',
            city,
            state,
            country,
          ].where((s) => s.isNotEmpty).join(', ');
        }
      } catch (e) {
        print('📍 Reverse geocoding error: $e');
        address = '${position.latitude}, ${position.longitude}';
      }

      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // 7. Save location locally
      await AuthService.saveUserLocation(
        position.latitude,
        position.longitude,
        address,
      );

      // 8. Send location to backend
      await _sendLocationToServer(locationData);

      print('📍 Location obtained: $address (${position.latitude}, ${position.longitude})');
      return locationData;
    } catch (e) {
      print('📍 Location error: $e');
      return null;
    }
  }

  /// Send location data to server
  static Future<void> _sendLocationToServer(Map<String, dynamic> locationData) async {
    try {
      final vendorId = await AuthService.getVendorIdString();
      final database = Database();
      
      final response = await database.getData({
        'action': 'update_location',
        'vendor_id': vendorId,
        'latitude': locationData['latitude'].toString(),
        'longitude': locationData['longitude'].toString(),
        'address': locationData['address'].toString(),
        'city': locationData['city'].toString(),
        'state': locationData['state'].toString(),
        'country': locationData['country'].toString(),
      });

      print('📍 Location sent to server: $response');
    } catch (e) {
      print('📍 Error sending location to server: $e');
    }
  }

  /// Check if location permission is already granted
  static Future<bool> isLocationPermissionGranted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Open app settings (for when permission is permanently denied)
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openAppSettings();
  }
}
