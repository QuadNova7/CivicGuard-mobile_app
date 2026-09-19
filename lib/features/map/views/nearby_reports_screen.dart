import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/config/mapbox_config.dart';
import '../../../core/services/location_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../services/map_api_service.dart';

class NearbyReportsScreen extends StatefulWidget {
  final LatLng? targetDestination;
  
  const NearbyReportsScreen({super.key, this.targetDestination});

  @override
  State<NearbyReportsScreen> createState() => _NearbyReportsScreenState();
}

class _NearbyReportsScreenState extends State<NearbyReportsScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isMapView = true;
  String _activeFilter = 'ALL';
  String _currentStyle = MapboxConfig.styleStreets;
  LatLng? _userLocation;
  final bool _showLegend = true;
  bool _isLoadingLive = false;
  bool _isLocating = false;
  StreamSubscription<Position>? _positionStreamSub;

  // Pulse animation controller for user location beacon
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Selected incident for bottom sheet
  Map<String, dynamic>? _selectedIncident;

  // Real-world Sri Lanka Incidents & Relief Centers with road-snapped coordinates (Live Synced + Seed Baseline)
  List<Map<String, dynamic>> _incidents = [];

  // Active Closed Roads retrieved from backend database
  List<Map<String, dynamic>> _closedRoads = [];

  // Currently drawn route on map
  List<LatLng> _currentRoute = [];
  RouteInfo? _currentRouteInfo;

  void _clearRoute() {
    setState(() {
      _currentRoute = [];
      _currentRouteInfo = null;
    });
  }

  void _fitRouteBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = math.max(latDiff, lngDiff);

    double zoom = 14.0;
    if (maxDiff > 0.5) {
      zoom = 9.5;
    } else if (maxDiff > 0.2) {
      zoom = 11.0;
    } else if (maxDiff > 0.08) {
      zoom = 12.5;
    } else if (maxDiff > 0.03) {
      zoom = 13.8;
    } else {
      zoom = 14.8;
    }

    _mapController.move(LatLng(centerLat, centerLng), zoom);
  }

  Future<void> _drawRouteTo(LatLng destination) async {
    if (_userLocation == null) return;
    
    setState(() {
      _currentRoute = [];
      _currentRouteInfo = null;
    });

    final routeInfo = await MapApiService.instance.fetchRouteDetails(_userLocation!, destination);
    
    if (mounted && routeInfo.points.isNotEmpty) {
      setState(() {
        _currentRoute = routeInfo.points;
        _currentRouteInfo = routeInfo;
      });
      _fitRouteBounds(routeInfo.points);
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // Initial baseline closed roads so map displays them instantly
    _closedRoads = [
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

    _startLocationTracking();
    _loadLiveBackendData();
  }

  void _startLocationTracking() async {
    await _centerUserLocation(silent: true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        _positionStreamSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          ),
        ).listen((Position pos) {
          if (mounted) {
            setState(() {
              _userLocation = LatLng(pos.latitude, pos.longitude);
            });
          }
        });
      }
    } catch (_) {}
  }

  /// Live Telemetry Ingestion from Backend Services
  Future<void> _loadLiveBackendData() async {
    setState(() => _isLoadingLive = true);
    try {
      final liveHazards = await MapApiService.instance.fetchMapHazards();
      final liveShelters = await MapApiService.instance.fetchReliefShelters();
      final liveClosedRoads = await MapApiService.instance.fetchClosedRoads();

      if (mounted) {
        setState(() {
          _incidents = [...liveHazards, ...liveShelters];
          if (liveClosedRoads.isNotEmpty) {
            _closedRoads = liveClosedRoads;
          }
        });
      }
    } catch (_) {
      // Graceful offline fallback
    } finally {
      if (mounted) {
        setState(() => _isLoadingLive = false);
      }
    }
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredIncidents {
    if (_activeFilter == 'ALL') return _incidents;
    if (_activeFilter == 'FLOODS') {
      return _incidents.where((i) => i['type'] == 'FLOOD').toList();
    }
    if (_activeFilter == 'BLOCKAGES') {
      return _incidents.where((i) => i['type'] == 'BLOCKAGE').toList();
    }
    if (_activeFilter == 'ROAD_CLOSED') {
      return _incidents.where((i) => i['type'] == 'ROAD_CLOSED').toList();
    }
    if (_activeFilter == 'SHELTERS') {
      return _incidents.where((i) => i['type'] == 'SHELTER').toList();
    }
    return _incidents;
  }

  /// Computes visible polyline coordinates for a closed road
  List<LatLng> _getClosedRoadSegment(Map<String, dynamic> road) {
    final name = (road['name'] ?? '').toString().toLowerCase();
    final LatLng pos = (road['coordinates'] is LatLng)
        ? road['coordinates'] as LatLng
        : LatLng(
            (road['latitude'] as num).toDouble(),
            (road['longitude'] as num).toDouble(),
          );

    if (name.contains('havelock')) {
      return [
        const LatLng(6.8835, 79.8640),
        const LatLng(6.8810, 79.8648),
        const LatLng(6.8785, 79.8655),
        const LatLng(6.8755, 79.8665),
        const LatLng(6.8725, 79.8678),
      ];
    } else if (name.contains('baseline')) {
      return [
        const LatLng(6.9540, 79.8765),
        const LatLng(6.9510, 79.8772),
        const LatLng(6.9480, 79.8780),
        const LatLng(6.9450, 79.8788),
        const LatLng(6.9410, 79.8795),
      ];
    } else if (name.contains('katubedda')) {
      return [
        const LatLng(6.7980, 79.8935),
        const LatLng(6.7950, 79.8964),
        const LatLng(6.7915, 79.8995),
        const LatLng(6.7880, 79.9025),
      ];
    } else if (name.contains('moratuwa')) {
      return [
        const LatLng(6.8040, 79.8850),
        const LatLng(6.8010, 79.8875),
        const LatLng(6.7985, 79.8895),
        const LatLng(6.7955, 79.8920),
        const LatLng(6.7930, 79.8945),
      ];
    }

    // Default segment around coordinates
    return [
      LatLng(pos.latitude + 0.0035, pos.longitude - 0.0018),
      pos,
      LatLng(pos.latitude - 0.0035, pos.longitude + 0.0018),
    ];
  }

  Future<void> _centerUserLocation({bool silent = false}) async {
    if (_isLocating) return;
    if (mounted) setState(() => _isLocating = true);

    try {
      final loc = await LocationHelper.getCurrentLiveLocation();
      if (mounted) {
        setState(() {
          _userLocation = LatLng(loc.latitude, loc.longitude);
          _isLocating = false;
        });
        _mapController.move(_userLocation!, 15.0);
        if (!silent) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GPS Position: ${loc.formattedAddress}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0F2B48),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _userLocation ??= const LatLng(6.7920, 79.8850);
          _isLocating = false;
        });
        _mapController.move(_userLocation!, 14.5);
      }
    }

    // Automatically draw route to target destination if passed
    if (mounted && widget.targetDestination != null && _userLocation != null) {
      _drawRouteTo(widget.targetDestination!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Top Modern Pure White Header Card (Clean separation from map tiles)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2B48).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: const Border(
                  bottom: BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Controls Row
                  Row(
                    children: [
                      // Map / List Pill Switcher
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildViewTab(Icons.map_rounded, 'Map', true),
                            _buildViewTab(Icons.view_list_rounded, 'List', false),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Live Sync Indicator Button
                      GestureDetector(
                        onTap: _loadLiveBackendData,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isLoadingLive
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF0284C7),
                                      ),
                                    )
                                  : Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                              const SizedBox(width: 5),
                              Text(
                                'LIVE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F2B48),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Map Style Switcher Button (Streets, Satellite, Dark, Outdoors)
                      GestureDetector(
                        onTap: _showStylePicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.layers_rounded,
                                size: 15,
                                color: Color(0xFF0F2B48),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _getStyleLabel(_currentStyle),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F2B48),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Filter Horizontal Chips Matching Marker Color Coding
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', 'All Hazards', const Color(0xFF0F2B48), Icons.layers_outlined),
                        _buildFilterChip('FLOODS', '🌊 Floods', const Color(0xFF2563EB), Icons.water_drop_rounded),
                        _buildFilterChip('BLOCKAGES', '⚠️ Blockages', const Color(0xFFD97706), Icons.warning_amber_rounded),
                        _buildFilterChip('ROAD_CLOSED', '⛔ Closures', const Color(0xFFDC2626), Icons.block_rounded),
                        _buildFilterChip('SHELTERS', '🏠 Shelters', const Color(0xFF059669), Icons.home_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Map View / List View container in Expanded (Map height starts cleanly below top filters)
            Expanded(
              child: _isMapView
                  ? Stack(
                      children: [
                        _buildMap(),

                        // Active Route Navigation HUD (at top: 12 of the map container)
                        if (_currentRouteInfo != null && _currentRoute.isNotEmpty)
                          Positioned(
                            top: 12,
                            left: 16,
                            right: 16,
                            child: _buildActiveRouteHud(),
                          ),

                        // Floating Map Legend Overlay (Explaining Safe Detour & Closed Road Lines)
                        if (_showLegend)
                          Positioned(
                            left: 16,
                            bottom: _selectedIncident != null ? 180 : 90,
                            child: _buildMapLegendOverlay(),
                          ),

                        // Floating Re-Center GPS Button
                        Positioned(
                          right: 16,
                          bottom: _selectedIncident != null ? 180 : 90,
                          child: FloatingActionButton(
                            mini: true,
                            onPressed: () => _centerUserLocation(silent: false),
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2563EB),
                            elevation: 4,
                            child: _isLocating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF2563EB),
                                    ),
                                  )
                                : const Icon(Icons.my_location_rounded, size: 22),
                          ),
                        ),

                        // Bottom Selected Incident Card
                        if (_selectedIncident != null)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 80,
                            child: _buildIncidentBottomCard(_selectedIncident!),
                          ),
                      ],
                    )
                  : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  /// High-Precision Navigation HUD Banner with Distance, Duration, Safe Detour Telemetry & Clear Action
  Widget _buildActiveRouteHud() {
    if (_currentRouteInfo == null || _currentRoute.isEmpty) return const SizedBox.shrink();
    final info = _currentRouteInfo!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: info.isDetour ? const Color(0xFF10B981) : const Color(0xFF2563EB),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2B48).withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: info.isDetour ? const Color(0xFFECFDF5) : const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              info.isDetour ? Icons.alt_route_rounded : Icons.navigation_rounded,
              size: 20,
              color: info.isDetour ? const Color(0xFF059669) : const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '${info.distanceKm} km',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F2B48),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '~${info.durationMinutes} mins',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  info.isDetour
                      ? '🛡️ Safe Detour Active (${info.avoidedRoads.isNotEmpty ? info.avoidedRoads.first : "Closed roads avoided"})'
                      : '🧭 Turn-by-Turn Safe Driving Route',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: info.isDetour ? const Color(0xFF059669) : const Color(0xFF2563EB),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _clearRoute,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Interactive Collapsible Map Legend Box
  Widget _buildMapLegendOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2B48).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Safe Detour Route Item
              Container(
                width: 14,
                height: 3.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Safe Detour',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF065F46),
                ),
              ),
              const SizedBox(width: 10),
              // Impassable Closed Road Item
              Container(
                width: 14,
                height: 3.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Closed Road',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewTab(IconData icon, String label, bool isMapTab) {
    final isSelected = _isMapView == isMapTab;
    return GestureDetector(
      onTap: () => setState(() => _isMapView = isMapTab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F2B48) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, Color categoryColor, IconData icon) {
    final isSelected = _activeFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _activeFilter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? categoryColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? categoryColor : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? categoryColor.withValues(alpha: 0.25)
                    : const Color(0xFF0F2B48).withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(6.7920, 79.8850), // Centered on Galle Road A2 in Moratuwa/Rawathawatta
        initialZoom: 14.2,
        minZoom: 6.0,
        maxZoom: 18.0,
      ),
      children: [
        // 1. Watermark-Free Tile Layer
        TileLayer(
          urlTemplate: MapboxConfig.getTileUrl(style: _currentStyle),
          userAgentPackageName: 'com.civicguard.mobileapp',
          tileProvider: NetworkTileProvider(),
        ),

        // 2. Dynamic Flood Hazard Risk Perimeters (from live database flood coordinates)
        PolygonLayer(
          polygons: _incidents
              .where((i) => (i['type'] == 'FLOOD' || i['hazard_type'] == 'FLOOD') && i['coordinates'] is LatLng)
              .map((flood) {
                final center = flood['coordinates'] as LatLng;
                const double radius = 0.0018;
                final points = [
                  LatLng(center.latitude + radius, center.longitude),
                  LatLng(center.latitude + radius * 0.707, center.longitude + radius * 0.707),
                  LatLng(center.latitude, center.longitude + radius),
                  LatLng(center.latitude - radius * 0.707, center.longitude + radius * 0.707),
                  LatLng(center.latitude - radius, center.longitude),
                  LatLng(center.latitude - radius * 0.707, center.longitude - radius * 0.707),
                  LatLng(center.latitude, center.longitude - radius),
                  LatLng(center.latitude + radius * 0.707, center.longitude - radius * 0.707),
                ];
                return Polygon(
                  points: points,
                  color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                  borderColor: const Color(0xFF1D4ED8),
                  borderStrokeWidth: 1.8,
                );
              })
              .toList(),
        ),

        // 3. Dynamic Safe Routing & Closed Road Polyline Layer
        PolylineLayer(
          polylines: [
            // A. Closed Roads (Prominently rendered in High-Visibility Red Casing)
            for (final road in _closedRoads) ...[
              // Outer warning casing glow
              Polyline(
                points: _getClosedRoadSegment(road),
                color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                strokeWidth: 9.0,
              ),
              // Solid Red Alert Barrier
              Polyline(
                points: _getClosedRoadSegment(road),
                color: const Color(0xFFDC2626),
                strokeWidth: 5.0,
              ),
              // Inner crimson center line
              Polyline(
                points: _getClosedRoadSegment(road),
                color: const Color(0xFF991B1B),
                strokeWidth: 2.0,
              ),
            ],

            // B. Dynamic Active Route Polyline (Vibrant Electric Blue Highlight & Emerald Safe Detour)
            if (_currentRoute.isNotEmpty) ...[
              // Soft glow casing underlay
              Polyline(
                points: _currentRoute,
                color: (_currentRouteInfo?.isDetour == true
                        ? const Color(0xFF059669)
                        : const Color(0xFF0284C7))
                    .withValues(alpha: 0.40),
                strokeWidth: 10.0,
              ),
              // Crisp high-visibility core polyline
              Polyline(
                points: _currentRoute,
                color: _currentRouteInfo?.isDetour == true
                    ? const Color(0xFF10B981) // Emerald Green for Safe Detour
                    : const Color(0xFF2563EB), // Electric Royal Blue for Direct Route
                strokeWidth: 5.5,
              ),
              // Bright center highlight ribbon
              Polyline(
                points: _currentRoute,
                color: _currentRouteInfo?.isDetour == true
                    ? const Color(0xFF6EE7B7)
                    : const Color(0xFF60A5FA),
                strokeWidth: 2.0,
              ),
            ],
          ],
        ),

        // 4. Interactive Marker Layer (Hazards, Shelters, Closed Road Badges & Live User GPS Beacon)
        MarkerLayer(
          markers: [
            // Live User Location Pulsing GPS Beacon (On Galle Road Idama approach)
            if (_userLocation != null)
              Marker(
                point: _userLocation!,
                width: 80,
                height: 80,
                alignment: Alignment.center,
                child: _buildLiveUserBeacon(),
              ),

            // Closed Road Warning Badges
            ..._closedRoads.map((road) {
              final pos = (road['coordinates'] is LatLng)
                  ? road['coordinates'] as LatLng
                  : LatLng(
                      (road['latitude'] as num).toDouble(),
                      (road['longitude'] as num).toDouble(),
                    );
              return Marker(
                point: pos,
                width: 105,
                height: 32,
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.40),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.block_rounded, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Closed Road',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Incident Hazard & Shelter Teardrop Pins
            ..._filteredIncidents.map((incident) {
              final isSelected = _selectedIncident?['id'] == incident['id'];
              return Marker(
                point: incident['coordinates'] as LatLng,
                width: 90,
                height: 70,
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIncident = incident;
                    });
                    _mapController.move(
                      incident['coordinates'] as LatLng,
                      14.5,
                    );
                  },
                  child: _buildTeardropHazardPin(incident, isSelected),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  /// High-Visibility Pulsing Live GPS Beacon with "YOU" Badge
  Widget _buildLiveUserBeacon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final pulseValue = _pulseAnimation.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Translucent Radar Pulse Wave
            Container(
              width: 32 + (pulseValue * 36),
              height: 32 + (pulseValue * 36),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0284C7).withValues(alpha: (1.0 - pulseValue) * 0.45),
              ),
            ),
            // Middle Halo Ring
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
              ),
            ),
            // Inner Solid Deep Blue Core with White Border
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.60),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // "YOU" Mini Label Badge positioned above the dot
            Positioned(
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2B48),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF38BDF8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'YOU',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Custom Teardrop Hazard Pin with floating title banner
  Widget _buildTeardropHazardPin(Map<String, dynamic> incident, bool isSelected) {
    Color themeColor;
    IconData iconData;
    String miniBadge;

    if (incident['type'] == 'FLOOD') {
      themeColor = const Color(0xFF2563EB); // Vibrant Blue
      iconData = Icons.water_drop_rounded;
      miniBadge = '🌊 Flood';
    } else if (incident['type'] == 'BLOCKAGE') {
      themeColor = const Color(0xFFD97706); // Amber Warning
      iconData = Icons.warning_amber_rounded;
      miniBadge = '⚠️ Hazard';
    } else if (incident['type'] == 'ROAD_CLOSED') {
      themeColor = const Color(0xFFDC2626); // Crimson Red
      iconData = Icons.block_rounded;
      miniBadge = '⛔ Closed';
    } else if (incident['type'] == 'SHELTER') {
      themeColor = const Color(0xFF059669); // Emerald Green
      iconData = Icons.home_rounded;
      miniBadge = '🏠 Relief';
    } else {
      themeColor = const Color(0xFF0F2B48);
      iconData = Icons.location_on_rounded;
      miniBadge = '📍 Report';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating Mini Title Chip (Visible on Map)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: themeColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            miniBadge,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F2B48),
            ),
          ),
        ),

        const SizedBox(height: 2),

        // Teardrop Marker Body
        Stack(
          alignment: Alignment.center,
          children: [
            // Lower diamond point
            Positioned(
              bottom: 0,
              child: Transform.rotate(
                angle: 0.785398, // 45 degrees
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ),

            // Teardrop Circular Head
            Container(
              width: isSelected ? 36 : 30,
              height: isSelected ? 36 : 30,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: isSelected ? 2.8 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.45),
                    blurRadius: isSelected ? 12 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  iconData,
                  color: Colors.white,
                  size: isSelected ? 19 : 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIncidentBottomCard(Map<String, dynamic> incident) {
    final isShelter = incident['type'] == 'SHELTER';
    Color themeColor;
    if (incident['type'] == 'FLOOD') {
      themeColor = const Color(0xFF2563EB);
    } else if (incident['type'] == 'BLOCKAGE') {
      themeColor = const Color(0xFFD97706);
    } else if (incident['type'] == 'ROAD_CLOSED') {
      themeColor = const Color(0xFFDC2626);
    } else {
      themeColor = const Color(0xFF059669);
    }

    final isNetworkPhoto = incident['photo'] != null && incident['photo'].toString().startsWith('http');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2B48).withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showIncidentDetailModal(incident),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: isNetworkPhoto
                      ? Image.network(
                          incident['photo'] as String,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset('assets/images/1.jpg', width: 58, height: 58, fit: BoxFit.cover),
                        )
                      : Image.asset(
                          incident['photo'] as String,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 10),
                // Text Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isShelter
                                  ? const Color(0xFFDCFCE7)
                                  : (incident['type'] == 'FLOOD'
                                      ? const Color(0xFFDBEAFE)
                                      : (incident['type'] == 'BLOCKAGE'
                                          ? const Color(0xFFFEF3C7)
                                          : const Color(0xFFFEE2E2))),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isShelter
                                  ? 'RELIEF HUB'
                                  : incident['severity'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                color: themeColor,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            incident['reportedTime'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        incident['title'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F2B48),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        incident['location'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Active Incident Reports (${_filteredIncidents.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F2B48),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _loadLiveBackendData,
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded, size: 14, color: AppColors.primaryNavy),
                    const SizedBox(width: 4),
                    Text(
                      'Refresh',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadLiveBackendData,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _filteredIncidents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final inc = _filteredIncidents[index];
                return _buildIncidentListCard(inc);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentListCard(Map<String, dynamic> inc) {
    final isShelter = inc['type'] == 'SHELTER';
    Color themeColor;
    if (inc['type'] == 'FLOOD') {
      themeColor = const Color(0xFF2563EB);
    } else if (inc['type'] == 'BLOCKAGE') {
      themeColor = const Color(0xFFD97706);
    } else if (inc['type'] == 'ROAD_CLOSED') {
      themeColor = const Color(0xFFDC2626);
    } else {
      themeColor = const Color(0xFF059669);
    }

    final isNetworkPhoto = inc['photo'] != null && inc['photo'].toString().startsWith('http');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2B48).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showIncidentDetailModal(inc),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: isNetworkPhoto
                      ? Image.network(
                          inc['photo'] as String,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset('assets/images/1.jpg', width: 60, height: 60, fit: BoxFit.cover),
                        )
                      : Image.asset(
                          inc['photo'] as String,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isShelter ? 'SHELTER' : (inc['severity'] as String),
                              style: GoogleFonts.plusJakartaSans(
                                color: themeColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            inc['reportedTime'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        inc['title'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F2B48),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        inc['location'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStylePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Map Theme',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F2B48),
                  ),
                ),
                const SizedBox(height: 12),
                _buildStyleOption('Streets', MapboxConfig.styleStreets, Icons.map_rounded),
                _buildStyleOption('Satellite View', MapboxConfig.styleSatellite, Icons.satellite_alt_rounded),
                _buildStyleOption('Night / Dark Mode', MapboxConfig.styleDark, Icons.dark_mode_rounded),
                _buildStyleOption('Topographic / Outdoors', MapboxConfig.styleOutdoors, Icons.terrain_rounded),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStyleOption(String title, String styleId, IconData icon) {
    final isSelected = _currentStyle == styleId;
    return ListTile(
      onTap: () {
        setState(() => _currentStyle = styleId);
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F2B48) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF0F2B48), size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? const Color(0xFF0F2B48) : const Color(0xFF334155),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0F2B48), size: 20)
          : null,
    );
  }

  String _getStyleLabel(String style) {
    if (style == MapboxConfig.styleSatellite) return 'Satellite';
    if (style == MapboxConfig.styleDark) return 'Dark';
    if (style == MapboxConfig.styleOutdoors) return 'Terrain';
    return 'Streets';
  }

  void _showIncidentDetailModal(Map<String, dynamic> incident) {
    final isShelter = incident['type'] == 'SHELTER';
    final isConfirmed = incident['verified'] == true;
    final isRoadClosed = incident['is_road_closed'] == true;
    final reasonsList = incident['reasons'] as List<dynamic>? ?? [];

    Color themeColor;
    if (isShelter) {
      themeColor = const Color(0xFF059669);
    } else if (incident['type'] == 'FLOOD') {
      themeColor = const Color(0xFF2563EB);
    } else if (incident['type'] == 'BLOCKAGE') {
      themeColor = const Color(0xFFD97706);
    } else if (incident['type'] == 'ROAD_CLOSED' || isRoadClosed) {
      themeColor = const Color(0xFFDC2626);
    } else {
      themeColor = const Color(0xFF0F2B48);
    }

    final isNetworkPhoto = incident['photo'] != null && incident['photo'].toString().startsWith('http');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.68,
          maxChildSize: 0.92,
          minChildSize: 0.45,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Photo Preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: isNetworkPhoto
                        ? Image.network(
                            incident['photo'] as String,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset('assets/images/1.jpg', width: double.infinity, height: 160, fit: BoxFit.cover),
                          )
                        : Image.asset(
                            incident['photo'] as String,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                  ),

                  const SizedBox(height: 14),

                  // Decision Badges Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: isShelter
                              ? const Color(0xFFDCFCE7)
                              : (isConfirmed
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFFEF3C7)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isShelter
                              ? 'EMERGENCY SHELTER'
                              : (isConfirmed ? 'VERIFIED HAZARD' : 'UNDER AI ANALYSIS'),
                          style: GoogleFonts.plusJakartaSans(
                            color: themeColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          '${incident['confidence']}% AI Confidence',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F2B48),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Title & Location
                  Text(
                    incident['title'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F2B48),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          incident['location'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Road Closure Indicator
                  if (!isShelter)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isRoadClosed ? const Color(0xFFFEE2E2) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isRoadClosed ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isRoadClosed ? Icons.do_not_disturb_on_rounded : Icons.check_circle_rounded,
                            size: 16,
                            color: isRoadClosed ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isRoadClosed ? 'Road Closed to Public Traffic' : 'Road Open / Passable with Caution',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isRoadClosed ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Description
                  Text(
                    incident['description'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.4,
                      color: const Color(0xFF334155),
                    ),
                  ),

                  // Multi-Signal Evidence Reasoning Box (hazard_verdicts)
                  if (reasonsList.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.analytics_outlined, size: 14, color: Color(0xFF0F2B48)),
                              const SizedBox(width: 6),
                              Text(
                                'Multi-Signal Verification Log',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F2B48),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...reasonsList.map((reason) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(
                                      reason.toString(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: const Color(0xFF475569),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Navigation Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        if (incident['coordinates'] is LatLng) {
                          _drawRouteTo(incident['coordinates'] as LatLng);
                        }
                      },
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: Text(
                        isShelter ? 'Route to Evacuation Center' : 'Safe Detour Around Hazard',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2B48),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
