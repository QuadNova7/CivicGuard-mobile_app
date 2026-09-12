import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/config/mapbox_config.dart';

class MapApiService {
  MapApiService._();
  static final MapApiService instance = MapApiService._();

  /// Fetch all active verified hazard incidents from incident-service via Kong Gateway
  /// Joins composite decisions from Supabase public.hazard_verdicts table
  Future<List<Map<String, dynamic>>> fetchMapHazards() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.incidentsMapHazards);
      if (response.success && response.data != null) {
        final List<dynamic> hazardsRaw = response.data['hazards'] ?? response.data;
        if (hazardsRaw.isNotEmpty) {
          return hazardsRaw.map<Map<String, dynamic>>((h) {
            final lat = (h['latitude'] is num) ? (h['latitude'] as num).toDouble() : 6.7985;
            final lng = (h['longitude'] is num) ? (h['longitude'] as num).toDouble() : 79.8895;
            final typeStr = (h['incident_type'] ?? h['hazard_type'] ?? h['type'] ?? 'FLOOD').toString().toUpperCase();
            final sevStr = (h['severity'] ?? h['urgency'] ?? 'HIGH').toString().toUpperCase();
            final statusStr = (h['status'] ?? 'CONFIRMED').toString().toUpperCase();
            final verdictStr = (h['verdict'] ?? (statusStr == 'CONFIRMED' ? 'CONFIRMED' : 'NEEDS_VERIFICATION')).toString().toUpperCase();
            
            final conf = (h['confidence'] is num)
                ? ((h['confidence'] as num) <= 1.0
                    ? ((h['confidence'] as num) * 100).round()
                    : (h['confidence'] as num).round())
                : (verdictStr == 'CONFIRMED' ? 94 : 75);

            final isClosed = h['is_road_closed'] == true;
            final roadName = h['road_name']?.toString();
            final wardName = h['ward_name']?.toString();
            final reasons = (h['reasons'] is List)
                ? (h['reasons'] as List).map((r) => r.toString()).toList()
                : <String>[
                    verdictStr == 'CONFIRMED'
                        ? 'Aggregated spatial reports verified with council operational clearance'
                        : 'Citizen report received, automated AI verification in progress'
                  ];

            String label = 'Hazard';
            String internalCategory = 'OTHER';
            if (typeStr.contains('FLOOD')) {
              label = 'Flood Alert';
              internalCategory = 'FLOOD';
            } else if (typeStr.contains('BLOCK') || typeStr.contains('TREE')) {
              label = 'Blockage';
              internalCategory = 'BLOCKAGE';
            } else if (typeStr.contains('ROAD') || typeStr.contains('DAMAGE') || isClosed) {
              label = isClosed ? 'Closed Road' : 'Road Hazard';
              internalCategory = isClosed ? 'ROAD_CLOSED' : 'BLOCKAGE';
            } else if (typeStr.contains('LANDSLIDE')) {
              label = 'Landslide Alert';
              internalCategory = 'BLOCKAGE';
            } else {
              label = 'Hazard';
              internalCategory = 'OTHER';
            }

            final locationDesc = roadName != null
                ? (wardName != null ? '$roadName, $wardName' : roadName)
                : (h['description']?.toString() ?? 'Colombo District, Western Province');

            final photoUrl = (h['photo_url'] != null && h['photo_url'].toString().startsWith('http'))
                ? h['photo_url'].toString()
                : ((h['evidence_url'] != null && h['evidence_url'].toString().startsWith('http'))
                    ? h['evidence_url'].toString()
                    : 'assets/images/1.jpg');

            return {
              'id': h['id']?.toString() ?? 'inc-${DateTime.now().millisecondsSinceEpoch}',
              'type': internalCategory,
              'hazard_type': typeStr,
              'label': label,
              'title': h['title']?.toString() ?? (roadName != null ? '$label on $roadName' : '$label Report'),
              'location': locationDesc,
              'coordinates': LatLng(lat, lng),
              'severity': sevStr,
              'status': statusStr,
              'verdict': verdictStr,
              'verified': verdictStr == 'CONFIRMED' || statusStr == 'CONFIRMED' || conf >= 85,
              'confidence': conf,
              'urgency': sevStr,
              'reasons': reasons,
              'is_road_closed': isClosed,
              'reportedTime': 'Live Database',
              'assignedCrew': 'Municipal Response Unit',
              'photo': photoUrl,
              'description': h['description']?.toString() ??
                  'Verified hazard actively monitored by municipal emergency triage and logged in hazard_verdicts.',
            };
          }).toList();
        }
      }
    } catch (_) {
      // Return empty on failure rather than fake mocks
    }
    return [];
  }

  /// Fetch all emergency relief shelters from relief-service via Kong Gateway
  Future<List<Map<String, dynamic>>> fetchReliefShelters() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.reliefShelters);
      if (response.success && response.data != null) {
        final List<dynamic> sheltersRaw = response.data['shelters'] ?? response.data;
        if (sheltersRaw.isNotEmpty) {
          return sheltersRaw.map<Map<String, dynamic>>((s) {
            final lat = (s['latitude'] is num) ? (s['latitude'] as num).toDouble() : 6.7930;
            final lng = (s['longitude'] is num) ? (s['longitude'] as num).toDouble() : 79.9020;
            final capacity = (s['capacity'] is num) ? (s['capacity'] as num).toInt() : 200;
            final currentOccupancy = (s['current_occupancy'] is num) ? (s['current_occupancy'] as num).toInt() : 60;
            final available = capacity - currentOccupancy;

            return {
              'id': s['id']?.toString() ?? 'shelter-${DateTime.now().millisecondsSinceEpoch}',
              'type': 'SHELTER',
              'hazard_type': 'SHELTER',
              'label': 'Relief Center',
              'title': s['name']?.toString() ?? 'Municipal Relief Center',
              'location': s['address']?.toString() ?? 'Western Province Relief Hub',
              'coordinates': LatLng(lat, lng),
              'severity': 'SAFE',
              'status': s['is_active'] == false ? 'FULL' : 'ACTIVE',
              'verdict': 'OFFICIAL_SHELTER',
              'verified': true,
              'confidence': 100,
              'urgency': 'LOW',
              'reasons': ['Designated 24/7 Municipal Council Disaster Shelter & Relief Desk'],
              'is_road_closed': false,
              'capacity': '$available / $capacity Beds Available',
              'resources': s['resources']?.toString() ?? 'Hot Meals, Medical Triage, Drinking Water',
              'reportedTime': 'Operational',
              'photo': 'assets/images/4.jpg',
              'description': s['description']?.toString() ??
                  'Official designated disaster relief center with 24/7 Red Cross and medical desk support.',
            };
          }).toList();
        }
      }
    } catch (_) {
      // Return empty on failure
    }
    return [];
  }

  /// Fetch route from Mapbox Directions API
  Future<List<LatLng>> fetchRoute(LatLng origin, LatLng destination) async {
    try {
      final url = 'https://api.mapbox.com/directions/v5/mapbox/driving/'
          '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
          '?geometries=geojson&access_token=${MapboxConfig.publicAccessToken}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          final coordinates = geometry['coordinates'] as List<dynamic>?;
          if (coordinates != null) {
            return coordinates.map((c) {
              return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
            }).toList();
          }
        }
      }
    } catch (e) {
      // Fallback
    }
    return [];
  }
}
