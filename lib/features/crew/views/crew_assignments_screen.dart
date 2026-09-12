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
      'Take Baseline Road towards Kelani bridge junction (2.8 km)',
      'Exit right onto River Bank Bypass Road (600 m)',
      'Report to Forward Incident Command Post tent (150 m)',
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
      // Graceful fallback if GPS is disabled indoors
    }
  }

  double _calculateDistanceKm(double lat, double lng) {
    if (_currentLat == null || _currentLng == null) return 12.4;
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
    
    // Do NOT overwrite existing user session; use preview squad if not logged in as crew
    if (!AuthService.instance.isLoggedIn || !AuthService.instance.currentUser!.isFieldCrew) {
      setState(() => _isLoading = false);
    } else {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await CrewApiService.instance.fetchMyCrewTasks();
      final tasksList = data['tasks'] as List? ?? [];
      
      final List<CrewAssignment> parsedTasks = tasksList.map((t) {
        final incident = t['incidents'] ?? {};
        final requiredGearStr = incident['required_specialty']?.toString() ?? 'Basic Gear';
        
        return CrewAssignment(
          id: t['id']?.toString() ?? '',
          title: incident['title']?.toString() ?? 'Emergency Dispatch',
          priority: t['priority']?.toString() ?? 'HIGH',
          priorityColor: _getPriorityColor(t['priority']?.toString() ?? 'HIGH'),
          priorityBg: _getPriorityBg(t['priority']?.toString() ?? 'HIGH'),
          location: '${incident['wards']?['name'] ?? 'Local'}, ${incident['roads']?['name'] ?? 'Road'}',
          district: AuthService.instance.currentUser?.district ?? 'Colombo',
          assignedBy: 'Command Center',
          status: _getFrontendStatus(t['status']?.toString() ?? 'ASSIGNED'),
          statusBg: _getStatusBg(t['status']?.toString() ?? 'ASSIGNED'),
          statusColor: _getStatusColor(t['status']?.toString() ?? 'ASSIGNED'),
          imagePath: _getPlaceholderImage(incident['required_specialty']?.toString() ?? 'WATER_RESCUE'),
          description: incident['description']?.toString() ?? 'No description provided.',
          latitude: incident['latitude'] != null ? double.parse(incident['latitude'].toString()) : 6.9,
          longitude: incident['longitude'] != null ? double.parse(incident['longitude'].toString()) : 79.8,
          requiredSpecialty: incident['required_specialty']?.toString() ?? 'General Rescue',
          opsHotline: '+94 11 267 0000',
          requiredGear: [requiredGearStr],
          routeSteps: const ['Follow live GPS routing to the incident location.', 'Maintain communication with command.'],
        );
      }).toList();

      setState(() {
        _activeDispatches = parsedTasks.where((t) => t.status != 'Completed').toList();
        _resolvedDispatches = parsedTasks.where((t) => t.status == 'Completed').toList();
      });
    } catch (e) {
      // Failed to load
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
    if (status == 'RESOLVED') return 'Completed';
    if (status == 'IN_PROGRESS') return 'On Scene';
    return 'Assigned';
  }

  Color _getStatusBg(String status) {
    if (status == 'RESOLVED') return const Color(0xFFDCFCE7);
    if (status == 'IN_PROGRESS') return const Color(0xFFFEF3C7);
    return const Color(0xFFDBEAFE);
  }

  Color _getStatusColor(String status) {
    if (status == 'RESOLVED') return const Color(0xFF16A34A);
    if (status == 'IN_PROGRESS') return const Color(0xFF92400E);
    return const Color(0xFF1E40AF);
  }
  
  String _getPlaceholderImage(String spec) {
    if (spec.contains('WATER')) return 'assets/images/1.jpg';
    if (spec.contains('4X4') || spec.contains('DEBRIS')) return 'assets/images/3.jpg';
    return 'assets/images/2.jpg';
  }

  void _showSwitchSquadModal(BuildContext context) {
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Switch Response Squad',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              Text(
                'Select a specialized crew track to test dynamic task dispatching:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Option 1: Water Rescue
              _buildSquadSwitchTile(
                icon: Icons.sailing_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBg: const Color(0xFFE0F2FE),
                name: 'Sunil Shantha',
                squad: 'Colombo Swift Water Rescue Unit #01',
                district: 'Colombo District',
                specialty: 'WATER RESCUE',
                isSelected: AuthService.instance.currentUser?.specialty == 'WATER_RESCUE',
                onTap: () {
                  AuthService.instance.loginAs(AuthService.waterRescueLead);
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),

              // Option 2: 4x4 Debris
              _buildSquadSwitchTile(
                icon: Icons.airport_shuttle_rounded,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
                name: 'Bandara Senanayake',
                squad: 'Ratnapura 4WD Winch & Chainsaw Unit #02',
                district: 'Ratnapura District',
                specialty: '4X4 DEBRIS CLEARANCE',
                isSelected: AuthService.instance.currentUser?.specialty == '4X4_DEBRIS',
                onTap: () {
                  AuthService.instance.loginAs(AuthService.debrisLead);
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),

              // Option 3: Medical Triage
              _buildSquadSwitchTile(
                icon: Icons.medical_services_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBg: const Color(0xFFFEE2E2),
                name: 'Dr. Nimal Gamage',
                squad: 'Kandy Emergency Medical & Triage Unit #01',
                district: 'Kandy District',
                specialty: 'MEDICAL TRIAGE',
                isSelected: AuthService.instance.currentUser?.specialty == 'MEDICAL_TRIAGE',
                onTap: () {
                  AuthService.instance.loginAs(AuthService.medicalLead);
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSquadSwitchTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String name,
    required String squad,
    required String district,
    required String specialty,
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
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 18),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              squad,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            Text(
              district,
              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textLight),
            ),
          ],
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
        final bool isOfficialCrew = currentUser != null && currentUser.isFieldCrew;

        // STRICT ACCESS CONTROL: Non-crews are completely blocked
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
                      'This console is restricted to Municipal Council-assigned Response Crews. Community Volunteers and Citizens cannot access tactical dispatches.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/login?tab=0&role=FIELD_CREW&redirect=' + Uri.encodeComponent('/crew-assignments')),
                      icon: const Icon(Icons.badge_rounded, size: 18),
                      label: Text(
                        'Sign In with Crew Account',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/community-volunteer'),
                      child: Text(
                        'Return to Community Volunteer Hub',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF16A34A),
                        ),
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
              onPressed: () => context.pop(),
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
                  'Switch',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 0. Preview Mode Notice Banner
                if (!isOfficialCrew)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, color: Color(0xFF1D4ED8), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Squad Preview Console (${user.name})',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E40AF),
                                ),
                              ),
                              Text(
                                'Official squad credentials are pre-assigned by Council Officers.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.push('/login?tab=0&role=FIELD_CREW&redirect=' + Uri.encodeComponent('/crew-assignments')),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Crew Sign In',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 1. Tactical Readiness Banner
                _buildReadinessBanner(user),

                // 2. Declared Equipment Card
                _buildEquipmentManagerCard(user),

                // 3. Tab Bar (Active Dispatches vs Resolved Log)
                _buildTabSwitcher(_activeDispatches.length),

                // 4. Dispatches List
                _selectedTab == 0
                    ? _buildActiveDispatchesList(_activeDispatches)
                    : _buildResolvedLogList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadinessBanner(UserModel user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                      color: _isOnDuty ? const Color(0xFF22C55E) : Colors.grey,
                      shape: BoxShape.circle,
                      boxShadow: _isOnDuty
                          ? [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                activeColor: const Color(0xFF22C55E),
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
              color: Colors.white.withOpacity(0.7),
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
                  'Resolved Log (1)',
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
    if (dispatches.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryGreen, size: 48),
            const SizedBox(height: 12),
            Text(
              'No Pending Dispatches',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'All targeted missions for your specialty squad are complete. Standing by for officer orders.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
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
                color: Colors.black.withOpacity(0.03),
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
                        '${item.district} • ${item.location}',
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

                // Specialty requirement banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Color(0xFF0284C7), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Requires: ${item.requiredSpecialty}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
                  'Kelani River Bund Sandbag Reinforcement',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Completed with 4 Photo Evidence shots & 14 Civilians assisted. Road successfully reopened.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
