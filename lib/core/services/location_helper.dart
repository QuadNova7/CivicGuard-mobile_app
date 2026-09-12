import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final double accuracy;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.accuracy,
  });
}

class LocationHelper {
  /// Fetches live GPS coordinates and resolves to real Sri Lankan location address.
  /// Works reliably on all Android devices (including Huawei HMS without Google Play Services).
  static Future<LocationResult> getCurrentLiveLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await Geolocator.openLocationSettings();
      if (!serviceEnabled) {
        throw 'Location services (GPS) are turned off. Please enable GPS in device settings.';
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission was denied. Please allow location access.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw 'Location permission is permanently denied. Please enable in App Settings.';
    }

    Position? position;

    // 1. Try high-accuracy with native Android LocationManager (Huawei HMS compatible)
    try {
      final androidSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        forceLocationManager: true, // Bypass Google Play Services requirement
        intervalDuration: const Duration(seconds: 1),
        timeLimit: const Duration(seconds: 8),
      );

      position = await Geolocator.getCurrentPosition(
        locationSettings: defaultTargetPlatform == TargetPlatform.android
            ? androidSettings
            : const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 8),
              ),
      );
    } catch (_) {
      // 2. Try last known cached position
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }

    // 3. Fallback to balanced accuracy if GPS satellite lock takes too long indoors
    if (position == null) {
      try {
        final lowSettings = AndroidSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 0,
          forceLocationManager: true,
          timeLimit: const Duration(seconds: 6),
        );
        position = await Geolocator.getCurrentPosition(
          locationSettings: lowSettings,
        );
      } catch (_) {}
    }

    // 4. Fallback to general LocationSettings
    if (position == null) {
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 6),
          ),
        );
      } catch (_) {}
    }

    if (position == null) {
      throw 'Could not obtain GPS fix. Please ensure location is enabled and try again.';
    }

    final address = await reverseGeocode(position.latitude, position.longitude);

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      formattedAddress: address,
      accuracy: position.accuracy,
    );
  }

  /// Reverses coordinates to a human-readable Sri Lankan location address
  /// using OpenStreetMap Nominatim with fallback to District math.
  static Future<String> reverseGeocode(double lat, double lng) async {
    final latStr = lat.toStringAsFixed(4);
    final lngStr = lng.toStringAsFixed(4);

    // 1. OpenStreetMap Nominatim reverse HTTP lookup (Universal for all devices & Huawei HMS)
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=' + lat.toString() + '&lon=' + lng.toString() + '&zoom=18&addressdetails=1',
      );
      final request = await client.getUrl(url);
      request.headers.set('User-Agent', 'CivicGuard-MobileApp/1.0 (Disaster Response)');
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final road = address['road'] ?? address['suburb'] ?? address['neighbourhood'];
          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['county'] ?? address['state_district'];
          final state = address['state'] ?? 'Sri Lanka';
          if (road != null && city != null) {
            return '$road, $city, $state ($latStr N, $lngStr E)';
          } else if (city != null) {
            return '$city, $state ($latStr N, $lngStr E)';
          }
        }
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          final parts = displayName.split(',');
          final shortName = parts.take(3).join(', ').trim();
          return '$shortName ($latStr N, $lngStr E)';
        }
      }
    } catch (_) {
      // HTTP reverse geocoding timed out or offline
    }

    // 2. Mathematical Nearest Sri Lanka District calculation
    final nearestCity = _findNearestSriLankanCity(lat, lng);
    return '$nearestCity ($latStr N, $lngStr E)';
  }

  static String _findNearestSriLankanCity(double lat, double lng) {
    const sriLankanCities = [
      {'name': 'Colombo 07, Western Province', 'lat': 6.9044, 'lng': 79.8687},
      {'name': 'Colombo Central, Western Province', 'lat': 6.9271, 'lng': 79.8612},
      {'name': 'Moratuwa, Western Province', 'lat': 6.7730, 'lng': 79.8816},
      {'name': 'Panadura, Western Province', 'lat': 6.7132, 'lng': 79.9074},
      {'name': 'Peradeniya, Kandy, Central Province', 'lat': 7.2600, 'lng': 80.5975},
      {'name': 'Kandy City, Central Province', 'lat': 7.2906, 'lng': 80.6337},
      {'name': 'Nugegoda, Western Province', 'lat': 6.8724, 'lng': 79.8997},
      {'name': 'Dehiwala-Mount Lavinia, Western Province', 'lat': 6.8402, 'lng': 79.8712},
      {'name': 'Gampaha, Western Province', 'lat': 7.0840, 'lng': 79.9926},
      {'name': 'Negombo, Western Province', 'lat': 7.2008, 'lng': 79.8737},
      {'name': 'Galle Fort, Southern Province', 'lat': 6.0535, 'lng': 80.2210},
      {'name': 'Matara, Southern Province', 'lat': 5.9549, 'lng': 80.5550},
      {'name': 'Kurunegala, North Western', 'lat': 7.4863, 'lng': 80.3623},
      {'name': 'Ratnapura, Sabaragamuwa', 'lat': 6.7056, 'lng': 80.3847},
      {'name': 'Jaffna, Northern Province', 'lat': 9.6615, 'lng': 80.0255},
      {'name': 'Anuradhapura, North Central', 'lat': 8.3114, 'lng': 80.4037},
      {'name': 'Batticaloa, Eastern Province', 'lat': 7.7310, 'lng': 81.6747},
      {'name': 'Nuwara Eliya, Central Province', 'lat': 6.9497, 'lng': 80.7891},
      {'name': 'Kalutara, Western Province', 'lat': 6.5854, 'lng': 79.9607},
      {'name': 'Badulla, Uva Province', 'lat': 6.9934, 'lng': 81.0550},
    ];

    String nearestName = 'Sri Lanka';
    double minDistance = double.infinity;

    for (final city in sriLankanCities) {
      final cLat = city['lat'] as double;
      final cLng = city['lng'] as double;
      final dist = _calculateDistance(lat, lng, cLat, cLng);
      if (dist < minDistance) {
        minDistance = dist;
        nearestName = city['name'] as String;
      }
    }

    return nearestName;
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
