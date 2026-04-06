/// {@category Core}
///
/// Utility class for device location and geocoding services.
/// 
/// This helper uses the `geolocator` and `geocoding` packages to retrieve 
/// physical coordinates and map them to readable address components.
library;

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Provides high-level utility methods for location-aware features.
abstract class LocationHelper {
  /// Attempts to determine the user's current ISO country code (e.g., 'SA', 'EG').
  /// 
  /// The workflow involves:
  /// 1. Verifying if device location services are enabled.
  /// 2. Checking and requesting necessary permissions from the user.
  /// 3. Fetching the current GPS coordinates (latitude/longitude).
  /// 4. Performing a reverse-geocoding lookup to find the country.
  /// 
  /// Returns the ISO country code (e.g., 'SA') or `null` if any stage of the 
  /// process fails or is denied by the user.
  static Future<String?> getCurrentCountryCode() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // 1. Verify location services are active at the OS level.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null; // Gracefully handle disabled GPS settings.
      }

      // 2. Manage runtime permission state.
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null; // User explicitly denied permissions for this request.
        }
      }

      // 3. Handle persistent denial (e.g., manually blocked in App Settings).
      if (permission == LocationPermission.deniedForever) {
        return null; 
      }

      // 4. Retrieve current high-precision position.
      Position position = await Geolocator.getCurrentPosition();

      // 5. Perform reverse-geocoding lookup using coordinates.
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // 6. Extract the country identifier from the highest-priority result.
      if (placemarks.isNotEmpty) {
        return placemarks.first.isoCountryCode; // Returns 'SA', 'EG', etc.
      }
      return null;
    } catch (e) {
      // Catch any unexpected exceptions during sensor or network access.
      return null;
    }
  }
}
