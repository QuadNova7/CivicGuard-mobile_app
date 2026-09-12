import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/config/mapbox_config.dart';
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

  // Pulse animation controller for user location beacon
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Selected incident for bottom sheet
  Map<String, dynamic>? _selectedIncident;

  // Real-world Sri Lanka Incidents & Relief Centers with road-snapped coordinates (Live Synced + Seed Baseline)
  List<Map<String, dynamic>> _incidents = [];

  // Currently drawn route on map
  List<LatLng> _currentRoute = [];

  Future<void> _drawRouteTo(LatLng destination) async {
    if (_userLocation == null) return;
    
    // Clear existing route to show loading state implicitly or just fetch new
    setState(() => _currentRoute = []);

    final routePoints = await MapApiService.instance.fetchRoute(_userLocation!, destination);
    
    if (mounted && routePoints.isNotEmpty) {
      setState(() {
        _currentRoute = routePoints;
      });
      // Optionally adjust map bounds to fit the route
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
    
    _centerUserLocation();
    _loadLiveBackendData();
  }
  /// Live Telemetry Ingestion from Backend Services
  Future<void> _loadLiveBackendData() async {
    setState(() => _isLoadingLive = true);
    try {
      final liveHazards = await MapApiService.instance.fetchMapHazards();
      final liveShelters = await MapApiService.instance.fetchReliefShelters();

      if (mounted) {
        setState(() {
          _incidents = [...liveHazards, ...liveShelters];
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

  Future<void> _centerUserLocation({bool silent = false}) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _userLocation = LatLng(position.latitude, position.longitude);
          });
          _mapController.move(_userLocation!, 14.5);
        }
      } else {
        // Fallback default location (Galle Road, Idama / Moratuwa)
        if (mounted) {
          setState(() {
            _userLocation = const LatLng(6.7795, 79.8835);
          });
          if (!silent) {
            _mapController.move(_userLocation!, 14.5);
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _userLocation = const LatLng(6.7795, 79.8835);
        });
        if (!silent) {
          _mapController.move(_userLocation!, 14.5);
        }
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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Map View or List View
          _isMapView ? _buildMap() : _buildListView(),

          // 2. Top Navigation & Filter Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Top Search / View Switcher Row
                    Row(
                      children: [
                        // Map / List Pill Toggle
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F2B48).withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
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
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F2B48).withValues(alpha: 0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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

                        // Map Style Switcher (Streets, Satellite, Dark, Outdoors)
                        GestureDetector(
                          onTap: _showStylePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F2B48).withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.layers_rounded,
                                  size: 16,
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

                    const SizedBox(height: 8),

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
            ),
          ),

          // 3. Floating Map Legend Overlay (Explaining Green Route & Red Dashed Line)
          if (_isMapView && _showLegend)
            Positioned(
              left: 16,
              bottom: _selectedIncident != null ? 180 : 90,
              child: _buildMapLegendOverlay(),
            ),

          // 4. Floating Re-Center GPS Button (Map View Only)
          if (_isMapView)
            Positioned(
              right: 16,
              bottom: _selectedIncident != null ? 180 : 90,
              child: FloatingActionButton(
                mini: true,
                onPressed: () => _centerUserLocation(silent: false),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2563EB),
                elevation: 4,
                child: const Icon(Icons.my_location_rounded, size: 22),
              ),
            ),

          // 5. Bottom Selected Incident Card (Map View Only)
          if (_isMapView && _selectedIncident != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 80,
              child: _buildIncidentBottomCard(_selectedIncident!),
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

        // 3. Dynamic Safe Routing Polyline Layer (Active calculated route only)
        PolylineLayer(
          polylines: [
            if (_currentRoute.isNotEmpty)
              Polyline(
                points: _currentRoute,
                color: const Color(0xFF2563EB),
                strokeWidth: 5.5,
              ),
          ],
        ),

        // 4. Interactive Marker Layer (Hazards, Shelters & Live User GPS Beacon)
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
            // "📍 YOU" Mini Label Badge positioned above the dot
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
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
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

  /// Custom Teardrop Pin with Floating Category Label Matching Filter Bar
  Widget _buildTeardropHazardPin(Map<String, dynamic> incident, bool isSelected) {
    Color themeColor;
    IconData iconData;
    String emojiTag;

    switch (incident['type']) {
      case 'FLOOD':
        themeColor = const Color(0xFF2563EB); // Vibrant Blue
        iconData = Icons.water_drop_rounded;
        emojiTag = '🌊';
        break;
      case 'BLOCKAGE':
        themeColor = const Color(0xFFD97706); // Warning Amber
        iconData = Icons.warning_amber_rounded;
        emojiTag = '⚠️';
        break;
      case 'ROAD_CLOSED':
        themeColor = const Color(0xFFDC2626); // Alert Red
        iconData = Icons.block_rounded;
        emojiTag = '⛔';
        break;
      case 'SHELTER':
      default:
        themeColor = const Color(0xFF059669); // Relief Emerald
        iconData = Icons.night_shelter_rounded;
        emojiTag = '🏠';
        break;
    }

    final labelText = incident['label'] as String? ?? incident['type'] as String;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Floating Mini Label Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? themeColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.white : themeColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: isSelected ? 0.40 : 0.20),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emojiTag,
                style: const TextStyle(fontSize: 8),
              ),
              const SizedBox(width: 2),
              Text(
                labelText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF0F2B48),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 2),

        // 2. Teardrop Map Pin Head & Needle
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Pointer Needle Tip (Rotated Diamond/Square)
            Positioned(
              bottom: -4,
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
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 95), // Spacing for top header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      ),
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
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2B48).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: isNetworkPhoto
              ? Image.network(
                  inc['photo'] as String,
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset('assets/images/1.jpg', width: 55, height: 55, fit: BoxFit.cover),
                )
              : Image.asset(
                  inc['photo'] as String,
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                ),
        ),
        title: Text(
          inc['title'] as String,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F2B48),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              inc['location'] as String,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isShelter
                        ? const Color(0xFFDCFCE7)
                        : (inc['type'] == 'FLOOD'
                            ? const Color(0xFFDBEAFE)
                            : (inc['type'] == 'BLOCKAGE'
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFFEE2E2))),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isShelter ? 'RELIEF HUB' : inc['severity'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      color: themeColor,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  inc['reportedTime'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Color(0xFF94A3B8),
        ),
        onTap: () => _showIncidentDetailModal(inc),
      ),
    );
  }

  void _showStylePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Basemap Styles (Watermark-Free)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F2B48),
                ),
              ),
              const SizedBox(height: 14),
              _buildStyleOption(
                'Streets HD (OpenStreetMap)',
                MapboxConfig.styleStreets,
                Icons.map_rounded,
              ),
              _buildStyleOption(
                'Satellite Imagery (Esri HD)',
                MapboxConfig.styleSatellite,
                Icons.satellite_alt_rounded,
              ),
              _buildStyleOption(
                'Dark Tactical (Esri Dark)',
                MapboxConfig.styleDark,
                Icons.dark_mode_rounded,
              ),
              _buildStyleOption(
                'Outdoors & Topo (OpenTopo)',
                MapboxConfig.styleOutdoors,
                Icons.terrain_rounded,
              ),
              _buildStyleOption(
                'Light Minimal (Esri Light)',
                MapboxConfig.styleLight,
                Icons.light_mode_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStyleOption(String title, String styleId, IconData icon) {
    final isSelected = _currentStyle == styleId;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF0F2B48) : const Color(0xFF64748B),
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
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
          : null,
      onTap: () {
        setState(() => _currentStyle = styleId);
        Navigator.pop(context);
      },
    );
  }

  String _getStyleLabel(String styleId) {
    switch (styleId) {
      case MapboxConfig.styleSatellite:
        return 'Satellite';
      case MapboxConfig.styleOutdoors:
        return 'Outdoors';
      case MapboxConfig.styleDark:
        return 'Dark';
      case MapboxConfig.styleLight:
        return 'Light';
      default:
        return 'Streets';
    }
  }

  void _showIncidentDetailModal(Map<String, dynamic> incident) {
    final isShelter = incident['type'] == 'SHELTER';
    final isConfirmed = incident['verdict'] == 'CONFIRMED' || incident['status'] == 'CONFIRMED';
    final isRoadClosed = incident['is_road_closed'] == true;
    final reasonsList = (incident['reasons'] is List) ? (incident['reasons'] as List) : <dynamic>[];

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
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Decision Reasoning (hazard_verdicts):',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...reasonsList.map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(color: Color(0xFF0F2B48), fontWeight: FontWeight.bold)),
                                    Expanded(
                                      child: Text(
                                        r.toString(),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          color: const Color(0xFF334155),
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Detour / Navigation CTA Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (incident['coordinates'] != null) {
                        _drawRouteTo(incident['coordinates'] as LatLng);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2B48),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isShelter ? 'Navigate to Shelter' : 'Calculate Turn-by-Turn Safe Detour',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
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
