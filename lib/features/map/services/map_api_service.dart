import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

class RouteInfo {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final bool isDetour;
  final List<String> avoidedRoads;
  final List<String> steps;

  const RouteInfo({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    this.isDetour = false,
    this.avoidedRoads = const [],
    this.steps = const [],
  });
}

class MapApiService {
  MapApiService._();
  static final MapApiService instance = MapApiService._();

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
      // Return empty on failure
    }
    return [];
  }

  /// Fetch all active closed roads from backend or high-fidelity baseline
  Future<List<Map<String, dynamic>>> fetchClosedRoads() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.incidentsMapHazards);
      if (response.success && response.data != null) {
        final List<dynamic> roadsRaw = response.data['closed_roads'] ?? [];
        if (roadsRaw.isNotEmpty) {
          return roadsRaw.map<Map<String, dynamic>>((r) {
            final lat = (r['latitude'] is num) ? (r['latitude'] as num).toDouble() : 6.7985;
            final lng = (r['longitude'] is num) ? (r['longitude'] as num).toDouble() : 79.8895;
            final name = r['name']?.toString() ?? 'Closed Road Corridor';
            final id = r['id']?.toString() ?? 'cr-${DateTime.now().millisecondsSinceEpoch}';

            return {
              'id': id,
              'name': name,
              'latitude': lat,
              'longitude': lng,
              'coordinates': LatLng(lat, lng),
              'road_type': r['road_type']?.toString() ?? 'PRIMARY',
              'is_closed': true,
            };
          }).toList();
        }
      }
    } catch (_) {}

    // Fallback seed closed roads
    return [
      {
        'id': 'b1111111-1111-1111-1111-111111111111',
        'name': 'Havelock Road (Near Canal Bridge)',
        'latitude': 6.8785,
        'longitude': 79.8655,
        'coordinates': const LatLng(6.8785, 79.8655),
        'road_type': 'PRIMARY',
        'is_closed': true,
      },
      {
        'id': 'b5555555-5555-5555-5555-555555555555',
        'name': 'Baseline Road (Kelani Bridge Flyover Sector)',
        'latitude': 6.9480,
        'longitude': 79.8780,
        'coordinates': const LatLng(6.9480, 79.8780),
        'road_type': 'HIGHWAY',
        'is_closed': true,
      },
      {
        'id': '21db25c9-0e31-424d-81e5-a49cf9ab2d82',
        'name': 'Moratuwa Galle Road',
        'latitude': 6.7985,
        'longitude': 79.8895,
        'coordinates': const LatLng(6.7985, 79.8895),
        'road_type': 'PRIMARY',
        'is_closed': true,
      },
      {
        'id': 'a77531bf-54f0-40be-8f6b-39a54bc5822b',
        'name': 'Galle Road (Moratuwa / Katubedda)',
        'latitude': 6.7950,
        'longitude': 79.8964,
        'coordinates': const LatLng(6.7950, 79.8964),
        'road_type': 'PRIMARY',
        'is_closed': true,
      },
    ];
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

  /// Calculates distance from point C to line segment AB in kilometers
  double _distanceToSegment(LatLng c, LatLng a, LatLng b) {
    const distanceCalc = Distance();
    final double dx = b.longitude - a.longitude;
    final double dy = b.latitude - a.latitude;
    final double lenSq = dx * dx + dy * dy;

    if (lenSq == 0) {
      return distanceCalc.as(LengthUnit.Kilometer, c, a);
    }

    double u = ((c.longitude - a.longitude) * dx + (c.latitude - a.latitude) * dy) / lenSq;
    u = math.max(0.0, math.min(1.0, u));

    final double projLat = a.latitude + u * dy;
    final double projLng = a.longitude + u * dx;

    return distanceCalc.as(LengthUnit.Kilometer, c, LatLng(projLat, projLng));
  }

  /// High-Precision Turn-by-Turn Safe Routing Engine (OSRM + CivicGuard Safe Detours)
  /// 100% Free, Zero Billing, Zero API Key required
  Future<RouteInfo> fetchRouteDetails(LatLng origin, LatLng destination) async {
    bool isDetour = false;
    List<String> avoidedRoads = [];
    List<LatLng> waypoints = [origin, destination];

    // 1. Check CivicGuard Backend Safe-Path API for active road closure detours
    try {
      final safeRes = await ApiClient.instance.post(
        ApiConfig.incidentsSafePath,
        body: {
          'origin': {'latitude': origin.latitude, 'longitude': origin.longitude},
          'destination': {'latitude': destination.latitude, 'longitude': destination.longitude},
        },
      );

      if (safeRes.success && safeRes.data != null) {
        final data = safeRes.data;
        final rawAvoided = data['avoidedClosedRoads'] as List<dynamic>?;
        if (rawAvoided != null && rawAvoided.isNotEmpty) {
          isDetour = true;
          avoidedRoads = rawAvoided.map((r) => r['name']?.toString() ?? 'Closed Road').toList();
          final pathRaw = data['path'] as List<dynamic>?;
          if (pathRaw != null && pathRaw.length > 2) {
            waypoints = pathRaw
                .map((p) => LatLng(
                      (p['latitude'] as num).toDouble(),
                      (p['longitude'] as num).toDouble(),
                    ))
                .toList();
          }
        }
      }
    } catch (_) {
      // Backend detour check failed, continue with local corridor analysis
    }

    // 2. Client-Side Corridor Safety Guard: If no backend detour was returned, check local closed roads list
    if (!isDetour) {
      final closedRoads = await fetchClosedRoads();
      final List<Map<String, dynamic>> intersected = [];

      for (final cr in closedRoads) {
        final pos = cr['coordinates'] as LatLng;
        final distToCorridor = _distanceToSegment(pos, origin, destination);
        if (distToCorridor < 0.65) {
          intersected.add(cr);
        }
      }

      if (intersected.isNotEmpty) {
        isDetour = true;
        avoidedRoads = intersected.map((r) => r['name']?.toString() ?? 'Closed Road').toList();
        waypoints = [origin];

        for (final cr in intersected) {
          final name = (cr['name'] ?? '').toString().toLowerCase();
          final pos = cr['coordinates'] as LatLng;

          if (name.contains('katubedda') || (pos.latitude - 6.7950).abs() < 0.01) {
            // Detour via Telawala Road / Borupana corridor
            waypoints.add(const LatLng(6.8040, 79.8995));
            waypoints.add(const LatLng(6.8190, 79.8890));
          } else if (name.contains('moratuwa') || (pos.latitude - 6.7985).abs() < 0.01) {
            // Detour via Lunawa - Angulana station road
            waypoints.add(const LatLng(6.8010, 79.8830));
          } else if (name.contains('havelock') || (pos.latitude - 6.8785).abs() < 0.01) {
            // Detour via High Level Road
            waypoints.add(const LatLng(6.8740, 79.8730));
            waypoints.add(const LatLng(6.8850, 79.8690));
          } else if (name.contains('baseline') || (pos.latitude - 6.9480).abs() < 0.01) {
            // Detour via Aluthmawatha
            waypoints.add(const LatLng(6.9450, 79.8680));
          } else {
            // Dynamic perpendicular bypass waypoint
            final dLat = destination.latitude - origin.latitude;
            final dLon = destination.longitude - origin.longitude;
            final len = math.sqrt(dLat * dLat + dLon * dLon);
            if (len > 0) {
              final perpLat = -dLon / len;
              final perpLon = dLat / len;
              waypoints.add(LatLng(pos.latitude + perpLat * 0.0075, pos.longitude + perpLon * 0.0075));
            }
          }
        }
        waypoints.add(destination);
      }
    }

    // 3. Fetch high-precision road curves from OpenStreetMap OSRM Engine
    try {
      String coordsParam;
      if (waypoints.length > 2) {
        coordsParam = waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
      } else {
        coordsParam = '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
      }

      final osrmUrl = 'https://router.project-osrm.org/route/v1/driving/$coordsParam?overview=full&geometries=geojson&steps=true';
      final response = await http.get(Uri.parse(osrmUrl)).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final primaryRoute = routes[0];
          final geometry = primaryRoute['geometry'];
          final rawCoords = geometry['coordinates'] as List<dynamic>?;
          final distMeters = (primaryRoute['distance'] as num?)?.toDouble() ?? 0.0;
          final durationSecs = (primaryRoute['duration'] as num?)?.toDouble() ?? 0.0;

          List<String> stepInstructions = [];
          final legs = primaryRoute['legs'] as List<dynamic>?;
          if (legs != null) {
            for (final leg in legs) {
              final steps = leg['steps'] as List<dynamic>?;
              if (steps != null) {
                for (final step in steps) {
                  final name = step['name']?.toString();
                  if (name != null && name.isNotEmpty && !stepInstructions.contains(name)) {
                    stepInstructions.add(name);
                  }
                }
              }
            }
          }

          if (rawCoords != null && rawCoords.isNotEmpty) {
            final points = rawCoords.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
            return RouteInfo(
              points: points,
              distanceKm: double.parse((distMeters / 1000).toStringAsFixed(2)),
              durationMinutes: math.max(1, (durationSecs / 60).round()),
              isDetour: isDetour,
              avoidedRoads: avoidedRoads,
              steps: stepInstructions,
            );
          }
        }
      }
    } catch (_) {
      // OSRM network timeout or fallback
    }

    // 4. Mathematical Fallback
    const distanceCalc = Distance();
    double totalDist = 0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      totalDist += distanceCalc.as(LengthUnit.Kilometer, waypoints[i], waypoints[i + 1]);
    }

    return RouteInfo(
      points: waypoints,
      distanceKm: double.parse(totalDist.toStringAsFixed(2)),
      durationMinutes: math.max(1, (totalDist / 0.5).round()), // ~30 km/h
      isDetour: isDetour,
      avoidedRoads: avoidedRoads,
    );
  }

  /// Backward-compatible fetchRoute
  Future<List<LatLng>> fetchRoute(LatLng origin, LatLng destination) async {
    final info = await fetchRouteDetails(origin, destination);
    return info.points;
  }
}
