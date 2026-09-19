import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/location_helper.dart';
import '../../auth/services/auth_service.dart';
import '../services/crew_api_service.dart';

class CrewAssignment {
  final String id;
  final String title;
  final String priority;
  final Color priorityColor;
  final Color priorityBg;
  final String location;
  final String district;
  final String assignedBy;
  final String status;
  final Color statusBg;
  final Color statusColor;
  final String imagePath;
  final String description;
  final double latitude;
  final double longitude;
  final String requiredSpecialty;
  final String opsHotline;
  final List<String> requiredGear;
  final List<String> routeSteps;

  const CrewAssignment({
    required this.id,
    required this.title,
    required this.priority,
    required this.priorityColor,
    required this.priorityBg,
    required this.location,
    this.district = 'Colombo',
    required this.assignedBy,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.imagePath,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.requiredSpecialty = 'Water Rescue & Evacuation',
    this.opsHotline = '+94 11 267 0002',
    this.requiredGear = const [
      'Inflatable Rescue Boat',
      'Life Vests (Class III)',
      'Medical Trauma Kit',
    ],
    this.routeSteps = const [
      'Take primary road toward incident coordinates',
      'Deploy tactical perimeter and engage emergency intervention',
      'Capture resolution photograph to reopen the road',
    ],
  });

  CrewAssignment copyWith({
    String? id,
    String? title,
    String? priority,
    Color? priorityColor,
    Color? priorityBg,
    String? location,
    String? district,
    String? assignedBy,
    String? status,
    Color? statusBg,
    Color? statusColor,
    String? imagePath,
    String? description,
    double? latitude,
    double? longitude,
    String? requiredSpecialty,
    String? opsHotline,
    List<String>? requiredGear,
    List<String>? routeSteps,
  }) {
    return CrewAssignment(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      priorityColor: priorityColor ?? this.priorityColor,
      priorityBg: priorityBg ?? this.priorityBg,
      location: location ?? this.location,
      district: district ?? this.district,
      assignedBy: assignedBy ?? this.assignedBy,
      status: status ?? this.status,
      statusBg: statusBg ?? this.statusBg,
      statusColor: statusColor ?? this.statusColor,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      requiredSpecialty: requiredSpecialty ?? this.requiredSpecialty,
      opsHotline: opsHotline ?? this.opsHotline,
      requiredGear: requiredGear ?? this.requiredGear,
      routeSteps: routeSteps ?? this.routeSteps,
    );
  }
}

class CrewAssignmentsScreen extends StatefulWidget {
  const CrewAssignmentsScreen({super.key});

  @override
  State<CrewAssignmentsScreen> createState() => _CrewAssignmentsScreenState();
}

class _CrewAssignmentsScreenState extends State<CrewAssignmentsScreen> {
  int _selectedTab = 0;
  bool _isOnDuty = true;
  double? _currentLat;
  double? _currentLng;
  bool _isLoading = true;
  List<CrewAssignment> _activeDispatches = [];
  List<CrewAssignment> _resolvedDispatches = [];

  Future<void> _fetchCurrentLocation() async {
    try {
      final loc = await LocationHelper.getCurrentLiveLocation();
      if (mounted) {
        setState(() {
          _currentLat = loc.latitude;
          _currentLng = loc.longitude;
        });
      }
    } catch (_) {
      // Graceful fallback
    }
  }

  double _calculateDistanceKm(double lat, double lng) {
    if (_currentLat == null || _currentLng == null) return 3.2;
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat - _currentLat!) * p) / 2 +
        cos(_currentLat! * p) * cos(lat * p) * (1 - cos((lng - _currentLng!) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    
    // Strictly verify Field Crew authentication
    if (AuthService.instance.currentUser == null || !AuthService.instance.currentUser!.isFieldCrew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/volunteer-type');
      });
      return;
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final activeCrewId = AuthService.instance.currentUser?.crewId;
      final data = await CrewApiService.instance.fetchMyCrewTasks(activeCrewId);
      final rawTasks = data['tasks'];
      final List tasksList = (rawTasks is List) ? rawTasks : [];
      
      final List<CrewAssignment> parsedTasks = [];

      for (final t in tasksList) {
        if (t is! Map) continue;
        final incident = (t['incidents'] is Map) ? Map<String, dynamic>.from(t['incidents'] as Map) : <String, dynamic>{};
        final roads = (incident['roads'] is Map) ? Map<String, dynamic>.from(incident['roads'] as Map) : <String, dynamic>{};
        final wards = (incident['wards'] is Map) ? Map<String, dynamic>.from(incident['wards'] as Map) : <String, dynamic>{};
        
        final roadName = roads['name']?.toString() ?? 'Assigned Road Location';
        final wardName = wards['name']?.toString() ?? '';
        final locationStr = wardName.isNotEmpty ? '$wardName • $roadName' : roadName;

        final incidentType = incident['incident_type']?.toString() ?? 'EMERGENCY';
        final displayTitle = (incident['title'] != null && incident['title'].toString().isNotEmpty)
            ? incident['title'].toString()
            : '${incidentType.replaceAll('_', ' ')} Response: $roadName';

        final priorityStr = (t['priority']?.toString() ?? incident['severity']?.toString() ?? 'HIGH').toUpperCase();
        final statusStr = t['status']?.toString() ?? 'ASSIGNED';

        // Evidence photo extraction
        String photoUrl = '';
        if (incident['incident_evidence'] is List && (incident['incident_evidence'] as List).isNotEmpty) {
          final firstEv = (incident['incident_evidence'] as List).first;
          if (firstEv is Map) {
            photoUrl = firstEv['file_url']?.toString() ?? '';
          }
        }

        final imagePath = photoUrl.isNotEmpty ? photoUrl : _getPlaceholderImage(incidentType);

        final desc = (t['description'] != null && t['description'].toString().isNotEmpty)
            ? t['description'].toString()
            : (incident['description']?.toString() ?? 'Dispatched emergency task requiring on-scene response.');

        final latVal = incident['latitude'] ?? t['latitude'];
        final lngVal = incident['longitude'] ?? t['longitude'];
        final double lat = latVal != null ? (double.tryParse(latVal.toString()) ?? 6.912) : 6.912;
        final double lng = lngVal != null ? (double.tryParse(lngVal.toString()) ?? 79.872) : 79.872;

        final reqSpec = incident['required_specialty']?.toString() ??
            t['required_specialty']?.toString() ??
            (incidentType == 'FLOOD' ? 'Water Rescue & Evacuation' : '4x4 Clearance & Debris Removal');

        parsedTasks.add(
          CrewAssignment(
            id: t['id']?.toString() ?? '',
            title: displayTitle,
            priority: priorityStr,
            priorityColor: _getPriorityColor(priorityStr),
            priorityBg: _getPriorityBg(priorityStr),
            location: locationStr,
            district: AuthService.instance.currentUser?.district ?? 'Colombo',
            assignedBy: 'Municipal Command Center',
            status: _getFrontendStatus(statusStr),
            statusBg: _getStatusBg(statusStr),
            statusColor: _getStatusColor(statusStr),
            imagePath: imagePath,
            description: desc,
            latitude: lat,
            longitude: lng,
            requiredSpecialty: reqSpec,
            opsHotline: '+94 11 267 0000',
            requiredGear: [reqSpec, 'VHF Radios', 'Field Rescue Kit'],
            routeSteps: [
              'Deploy unit from staging base toward $roadName',
              'Perform live tactical mitigation on site',
              'Upload SitRep report and resolution photo',
            ],
          ),
        );
      }

      if (mounted) {
        setState(() {
          _activeDispatches = parsedTasks.where((t) => t.status != 'Completed').toList();
          _resolvedDispatches = parsedTasks.where((t) => t.status == 'Completed').toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeDispatches = [];
          _resolvedDispatches = [];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getPriorityColor(String p) {
    if (p == 'URGENT' || p == 'CRITICAL') return const Color(0xFFEF4444);
    if (p == 'HIGH') return const Color(0xFFF59E0B);
    return const Color(0xFF3B82F6);
  }

  Color _getPriorityBg(String p) {
    if (p == 'URGENT' || p == 'CRITICAL') return const Color(0xFFFEE2E2);
    if (p == 'HIGH') return const Color(0xFFFEF3C7);
    return const Color(0xFFDBEAFE);
  }

  String _getFrontendStatus(String status) {
    if (status == 'RESOLVED' || status == 'COMPLETED') return 'Completed';
    if (status == 'IN_PROGRESS' || status == 'ACCEPTED') return 'On Scene';
    return 'Assigned';
  }

  Color _getStatusBg(String status) {
    if (status == 'RESOLVED' || status == 'COMPLETED') return const Color(0xFFDCFCE7);
    if (status == 'IN_PROGRESS' || status == 'ACCEPTED') return const Color(0xFFFEF3C7);
    return const Color(0xFFDBEAFE);
  }

  Color _getStatusColor(String status) {
    if (status == 'RESOLVED' || status == 'COMPLETED') return const Color(0xFF16A34A);
    if (status == 'IN_PROGRESS' || status == 'ACCEPTED') return const Color(0xFF92400E);
    return const Color(0xFF1E40AF);
  }
  
  String _getPlaceholderImage(String spec) {
    final s = spec.toUpperCase();
    if (s.contains('WATER') || s.contains('FLOOD')) return 'assets/images/1.jpg';
    if (s.contains('4X4') || s.contains('DEBRIS') || s.contains('TREE')) return 'assets/images/3.jpg';
    return 'assets/images/2.jpg';
  }

  IconData _getSquadIcon(String specialty) {
    final s = specialty.toUpperCase();
    if (s.contains('WATER')) return Icons.sailing_rounded;
    if (s.contains('4X4') || s.contains('DEBRIS')) return Icons.airport_shuttle_rounded;
    if (s.contains('MEDICAL') || s.contains('TRIAGE')) return Icons.medical_services_rounded;
    if (s.contains('DRONE') || s.contains('RECON')) return Icons.flight_takeoff_rounded;
    if (s.contains('HAZMAT')) return Icons.warning_amber_rounded;
    if (s.contains('RADIO') || s.contains('COMMS') || s.contains('HAM')) return Icons.settings_input_antenna_rounded;
    return Icons.shield_rounded;
  }

  Color _getSquadColor(String specialty) {
    final s = specialty.toUpperCase();
    if (s.contains('WATER')) return const Color(0xFF0284C7);
    if (s.contains('4X4') || s.contains('DEBRIS')) return const Color(0xFFD97706);
    if (s.contains('MEDICAL') || s.contains('TRIAGE')) return const Color(0xFFDC2626);
    if (s.contains('DRONE') || s.contains('RECON')) return const Color(0xFF7C3AED);
    if (s.contains('HAZMAT')) return const Color(0xFFEA580C);
    if (s.contains('RADIO') || s.contains('COMMS') || s.contains('HAM')) return const Color(0xFF059669);
    return const Color(0xFF1E293B);
  }

  Color _getSquadBg(String specialty) {
    final s = specialty.toUpperCase();
    if (s.contains('WATER')) return const Color(0xFFE0F2FE);
    if (s.contains('4X4') || s.contains('DEBRIS')) return const Color(0xFFFEF3C7);
    if (s.contains('MEDICAL') || s.contains('TRIAGE')) return const Color(0xFFFEE2E2);
    if (s.contains('DRONE') || s.contains('RECON')) return const Color(0xFFEDE9FE);
    if (s.contains('HAZMAT')) return const Color(0xFFFFEDD5);
    if (s.contains('RADIO') || s.contains('COMMS') || s.contains('HAM')) return const Color(0xFFD1FAE5);
    return const Color(0xFFF1F5F9);
  }

  void _showSwitchSquadModal(BuildContext context) {
    String searchFilter = '';
    String selectedRoleFilter = 'ALL'; // 'ALL', 'LEADERS', 'MEMBERS'
    String selectedCategory = 'ALL';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final allSquads = [...AuthService.colomboSquads, ...AuthService.colomboCrewMembers];
            final filteredSquads = allSquads.where((s) {
              final searchTrim = searchFilter.trim().toLowerCase();
              final sName = s.name.toLowerCase();
              final sCrew = (s.crewName ?? '').toLowerCase();
              final sSpec = (s.specialty ?? '').toLowerCase();
              final sTitle = s.memberTitle.toLowerCase();

              final bool matchesSearch = searchTrim.isEmpty ||
                  sName.contains(searchTrim) ||
                  sCrew.contains(searchTrim) ||
                  sSpec.contains(searchTrim) ||
                  sTitle.contains(searchTrim) ||
                  s.equipment.any((e) => e.toLowerCase().contains(searchTrim));

              final bool matchesRole = selectedRoleFilter == 'ALL' ||
                  (selectedRoleFilter == 'LEADERS' && s.isLeader) ||
                  (selectedRoleFilter == 'MEMBERS' && !s.isLeader);

              final bool matchesCategory = selectedCategory == 'ALL' ||
                  sSpec.toUpperCase().contains(selectedCategory.toUpperCase());

              return (matchesSearch == true) && (matchesRole == true) && (matchesCategory == true);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Switch Response Persona',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '10 Squad Leaders + 3 Tactical Crew Members',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 1. Role Segmented Toggle (All / Leaders / Members)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildRoleSegmentTab(
                            title: 'All (${allSquads.length})',
                            isSelected: selectedRoleFilter == 'ALL',
                            onTap: () => setModalState(() => selectedRoleFilter = 'ALL'),
                          ),
                        ),
                        Expanded(
                          child: _buildRoleSegmentTab(
                            title: '👑 Leaders (${AuthService.colomboSquads.length})',
                            isSelected: selectedRoleFilter == 'LEADERS',
                            onTap: () => setModalState(() => selectedRoleFilter = 'LEADERS'),
                          ),
                        ),
                        Expanded(
                          child: _buildRoleSegmentTab(
                            title: '👥 Members (${AuthService.colomboCrewMembers.length})',
                            isSelected: selectedRoleFilter == 'MEMBERS',
                            onTap: () => setModalState(() => selectedRoleFilter = 'MEMBERS'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2. Search Bar
                  TextField(
                    onChanged: (val) {
                      setModalState(() {
                        searchFilter = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name (e.g. Kasun, Sunil), squad, or gear...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textLight),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('ALL', 'All Units', selectedCategory, (cat) {
                          setModalState(() => selectedCategory = cat);
                        }),
                        const SizedBox(width: 6),
                        _buildFilterChip('WATER', 'Water Rescue', selectedCategory, (cat) {
                          setModalState(() => selectedCategory = cat);
                        }),
                        const SizedBox(width: 6),
                        _buildFilterChip('4X4', '4x4 Debris', selectedCategory, (cat) {
                          setModalState(() => selectedCategory = cat);
                        }),
                        const SizedBox(width: 6),
                        _buildFilterChip('MEDICAL', 'Medical Triage', selectedCategory, (cat) {
                          setModalState(() => selectedCategory = cat);
                        }),
                        const SizedBox(width: 6),
                        _buildFilterChip('DRONE', 'Drone Recon', selectedCategory, (cat) {
                          setModalState(() => selectedCategory = cat);
                        }),
                        const SizedBox(width: 6),
                        _buildFilterChip('HAZMAT', 'Hazmat', selectedCategory, (cat) {
                          setModalState(() => selectedCategory = cat);
                        }),
                        const SizedBox(width: 6),
                        _buildFilterChip('RADIO', 'Comms', selectedCategory, (cat) {
                          setModalState(() => selectedCategory = cat);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Persona List
                  Expanded(
                    child: filteredSquads.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'No matching response personas found',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredSquads.length,
                            itemBuilder: (context, index) {
                              final squad = filteredSquads[index];
                              final isSelected = AuthService.instance.currentUser?.id == squad.id;
                              final specialty = squad.specialty ?? 'WATER_RESCUE';
                              final icon = _getSquadIcon(specialty);
                              final iconColor = _getSquadColor(specialty);
                              final iconBg = _getSquadBg(specialty);

                              return _buildSquadSwitchTile(
                                icon: icon,
                                iconColor: iconColor,
                                iconBg: iconBg,
                                name: squad.name,
                                isLeader: squad.isLeader,
                                memberTitle: squad.memberTitle,
                                squad: squad.crewName ?? 'Colombo Response Squad',
                                district: '${squad.district} • ${squad.phone}',
                                specialty: specialty.replaceAll('_', ' '),
                                equipment: squad.equipment,
                                isSelected: isSelected,
                                onTap: () {
                                  AuthService.instance.loginAs(squad);
                                  Navigator.pop(ctx);
                                  _fetchData();
                                },
                              );
                            },
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

  Widget _buildRoleSegmentTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, String selectedKey, Function(String) onSelect) {
    final isSelected = key == selectedKey;
    return InkWell(
      onTap: () => onSelect(key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildSquadSwitchTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String name,
    required bool isLeader,
    required String memberTitle,
    required String squad,
    required String district,
    required String specialty,
    required List<String> equipment,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primaryGreen : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            // Role Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLeader ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isLeader ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                                ),
                              ),
                              child: Text(
                                isLeader ? '👑 Leader' : '🔒 Member',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: isLeader ? const Color(0xFF166534) : const Color(0xFF92400E),
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 18),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          memberTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isLeader ? const Color(0xFF0284C7) : const Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          squad,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          district,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (equipment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: equipment.take(3).map((eq) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        eq,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRouteStepsModal(BuildContext context, CrewAssignment assignment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.navigation_rounded, color: Color(0xFF0284C7), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tactical Route Navigation',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          assignment.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...assignment.routeSteps.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final step = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primaryNavy,
                        child: Text(
                          '$idx',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text('Acknowledge Route', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        final currentUser = AuthService.instance.currentUser;
        final bool isOfficialCrew = currentUser != null && (currentUser.isFieldCrew == true);

        if (!isOfficialCrew) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.primaryNavy,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                onPressed: () => context.go('/volunteer-type'),
              ),
              title: Text(
                'Access Restricted',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded, color: Color(0xFFDC2626), size: 52),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Official Response Crew Access Only',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This console is restricted to Municipal Council-assigned Response Crews. Select a crew profile to proceed.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showSwitchSquadModal(context),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: Text(
                        'Select Active Squad Persona',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final user = currentUser;

        if (_isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryNavy)),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primaryNavy,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  context.pop();
                } else {
                  context.go('/volunteer-type');
                }
              },
            ),
            title: Text(
              'Response Command',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => _showSwitchSquadModal(context),
                icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Switch Squad',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _fetchData,
            color: AppColors.primaryNavy,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSquadHeader(user),
                  _buildEquipmentManagerCard(user),
                  _buildTabSwitcher(_activeDispatches.length),
                  if (_selectedTab == 0)
                    _buildActiveDispatchesList(_activeDispatches)
                  else
                    _buildResolvedLogList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSquadHeader(UserModel user) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryNavy,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isOnDuty ? const Color(0xFF22C55E) : Colors.grey[500],
                      boxShadow: _isOnDuty
                          ? [BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.6), blurRadius: 6)]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isOnDuty ? 'ACTIVE ON-DUTY' : 'STANDBY (OFF-DUTY)',
                    style: GoogleFonts.plusJakartaSans(
                      color: _isOnDuty ? const Color(0xFF4ADE80) : Colors.grey[400],
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isOnDuty,
                onChanged: (val) {
                  setState(() => _isOnDuty = val);
                },
                activeThumbColor: const Color(0xFF22C55E),
                activeTrackColor: const Color(0xFF166534),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Squad Lead: ${user.name} • ${user.district} District',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            user.crewName ?? 'Official Response Squad',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentManagerCard(UserModel user) {
    final gear = user.equipment.isNotEmpty ? user.equipment : ['Basic Emergency Equipment'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech_rounded, color: Color(0xFF0284C7), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  user.crewName ?? 'Specialized Response Unit',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showSwitchSquadModal(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_horiz_rounded, size: 13, color: Color(0xFF0284C7)),
                      const SizedBox(width: 3),
                      Text(
                        'Switch',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: gear.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  item,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher(int activeCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? AppColors.primaryNavy : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Active Dispatches ($activeCount)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? AppColors.primaryNavy : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Resolved Log (${_resolvedDispatches.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDispatchesList(List<CrewAssignment> dispatches) {
    final currentSquadName = AuthService.instance.currentUser?.crewName ?? 'Selected Squad';

    if (dispatches.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDF4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryGreen, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              'No Active Missions Assigned',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'There are no emergency tickets currently dispatched to $currentSquadName. When a Municipal Officer dispatches a task to this squad, it will appear here automatically.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Refresh Tasks',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryNavy,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: dispatches.length,
      itemBuilder: (context, index) {
        final item = dispatches[index];
        final distance = _calculateDistanceKm(item.latitude, item.longitude);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tags
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.priorityBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.priority,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: item.priorityColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.status,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: item.statusColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.near_me_rounded, color: Color(0xFF0284C7), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${distance.toStringAsFixed(1)} km away',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  item.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),

                // Location & Assigned By
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                if (item.description.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      item.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Specialty requirement banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDCFCE7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Requires: ${item.requiredSpecialty}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () => _showRouteStepsModal(context, item),
                        icon: const Icon(Icons.navigation_rounded, size: 14),
                        label: Text(
                          'Route',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                          foregroundColor: const Color(0xFF0284C7),
                          side: const BorderSide(color: Color(0xFFBAE6FD)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push('/crew-assignment-details', extra: item);
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                        label: Text(
                          'Open SitRep & Respond',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                          backgroundColor: AppColors.primaryNavy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResolvedLogList() {
    if (_resolvedDispatches.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.history_rounded, color: Color(0xFF94A3B8), size: 36),
            const SizedBox(height: 10),
            Text(
              'No Resolved Tasks Logged',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Completed missions with SitReps and photo proof will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: _resolvedDispatches.length,
      itemBuilder: (context, index) {
        final item = _resolvedDispatches[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Completed • Road verified reopened.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
