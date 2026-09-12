import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/location_helper.dart';

class VolunteerOpportunity {
  final String id;
  final String title;
  final String category;
  final String district;
  final String status;
  final Color statusBg;
  final Color statusColor;
  final String location;
  final double latitude;
  final double longitude;
  final String date;
  final String volunteersNeeded;
  final int currentJoined;
  final int totalNeeded;
  final String imagePath;
  final String description;
  final List<String> requirements;
  final String coordinatorName;
  final String coordinatorPhone;
  final String assemblyPoint;
  final List<String> announcements;
  final List<String> routeSteps;

  const VolunteerOpportunity({
    required this.id,
    required this.title,
    this.category = 'Food & Water',
    this.district = 'Colombo',
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.location,
    this.latitude = 6.8340,
    this.longitude = 79.8650,
    required this.date,
    required this.volunteersNeeded,
    this.currentJoined = 18,
    this.totalNeeded = 25,
    required this.imagePath,
    required this.description,
    required this.requirements,
    this.coordinatorName = 'Squad Leader Kamalanatha',
    this.coordinatorPhone = '+94 77 345 8920',
    this.assemblyPoint = 'Gate 2 Community Hall, Ground Floor Registration Desk',
    this.announcements = const [
      'Relief packing boxes arrived at Hall B. Please check in at Gate 2.',
      'Volunteer parking arranged at Temple grounds opposite center.',
    ],
    this.routeSteps = const [
      'Head north on Galle Road toward Mount Lavinia junction (1.2 km)',
      'Turn left at Station Road toward St. Thomas Relief Center (450 m)',
      'Enter via Gate 2 to reach Volunteer Assembly Desk (100 m)',
    ],
  });
}

class JoinedActivity {
  final VolunteerOpportunity opportunity;
  final String joinedAt;
  final String volunteerRole;
  final String checkInStatus; // 'Not Checked In', 'On-Site Verified', 'Completed'
  final int hoursLogged;

  JoinedActivity({
    required this.opportunity,
    required this.joinedAt,
    this.volunteerRole = 'General Volunteer',
    this.checkInStatus = 'Not Checked In',
    this.hoursLogged = 0,
  });

  JoinedActivity copyWith({
    VolunteerOpportunity? opportunity,
    String? joinedAt,
    String? volunteerRole,
    String? checkInStatus,
    int? hoursLogged,
  }) {
    return JoinedActivity(
      opportunity: opportunity ?? this.opportunity,
      joinedAt: joinedAt ?? this.joinedAt,
      volunteerRole: volunteerRole ?? this.volunteerRole,
      checkInStatus: checkInStatus ?? this.checkInStatus,
      hoursLogged: hoursLogged ?? this.hoursLogged,
    );
  }
}

class CommunityVolunteerScreen extends StatefulWidget {
  final int initialTabIndex;

  const CommunityVolunteerScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<CommunityVolunteerScreen> createState() =>
      _CommunityVolunteerScreenState();
}

class _CommunityVolunteerScreenState extends State<CommunityVolunteerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter States
  String _selectedCategory = 'All Activities';
  String _selectedDistance = 'Any Distance';
  String _selectedDistrict = 'All Districts';

  double? _userLat;
  double? _userLng;
  String _userLocationName = '';
  bool _isLocating = false;

  // 1. Activity Categories Dropdown List
  final List<String> _categories = const [
    'All Activities',
    'Food & Water',
    'Donation Sorting',
    'Street Cleanup',
    'Shelter Support',
    'First Aid Camp',
  ];

  // 2. Distance Options Dropdown List
  final List<String> _distanceOptions = const [
    'Any Distance',
    'Within 3 km',
    'Within 5 km',
    'Within 10 km',
    'Within 25 km',
    'Within 50 km',
  ];

  // 3. All 25 Districts of Sri Lanka Dropdown List
  final List<String> _districts = const [
    'All Districts',
    'Ampara',
    'Anuradhapura',
    'Badulla',
    'Batticaloa',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Jaffna',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kilinochchi',
    'Kurunegala',
    'Mannar',
    'Matale',
    'Matara',
    'Monaragala',
    'Mullaitivu',
    'Nuwara Eliya',
    'Polonnaruwa',
    'Puttalam',
    'Ratnapura',
    'Trincomalee',
    'Vavuniya',
  ];

  final List<VolunteerOpportunity> _opportunities = const [
    VolunteerOpportunity(
      id: 'vol-1',
      title: 'Food Ration Packing Drive',
      category: 'Food & Water',
      district: 'Colombo',
      status: 'Urgent Today',
      statusBg: Color(0xFFFEE2E2),
      statusColor: Color(0xFFDC2626),
      location: 'St. Thomas Relief Center, Mount Lavinia',
      latitude: 6.8340,
      longitude: 79.8650,
      date: 'Today, 2:00 PM - 6:00 PM',
      volunteersNeeded: '18/25 Volunteers',
      currentJoined: 18,
      totalNeeded: 25,
      imagePath: 'assets/images/1.jpg',
      description:
          'Help sort, pack, and seal 500 dry ration packs containing rice, dhal, and canned goods for displaced families across Colombo South.',
      requirements: [
        'Wear comfortable footwear and clothes',
        'Bring a reusable water bottle',
        'Basic physical lifting capability (up to 10kg)',
      ],
      coordinatorName: 'Squad Leader Kamalanatha',
      coordinatorPhone: '+94 77 345 8920',
      assemblyPoint: 'Gate 2 Community Hall, Ground Floor Registration Desk',
      announcements: [
        'Relief packing boxes arrived at Hall B. Please check in at Gate 2.',
        'Volunteer parking arranged at Temple grounds opposite center.',
      ],
      routeSteps: [
        'Head north on Galle Road toward Mount Lavinia junction (1.2 km)',
        'Turn left at Station Road toward St. Thomas Relief Center (450 m)',
        'Enter via Gate 2 to reach Volunteer Assembly Desk (100 m)',
      ],
    ),
    VolunteerOpportunity(
      id: 'vol-2',
      title: 'Emergency Medical Camp Setup',
      category: 'First Aid Camp',
      district: 'Kalutara',
      status: 'High Priority',
      statusBg: Color(0xFFFEF3C7),
      statusColor: Color(0xFFD97706),
      location: 'Wadduwa Central Dispensary Grounds',
      latitude: 6.6667,
      longitude: 79.9333,
      date: 'Tomorrow, 8:00 AM - 1:00 PM',
      volunteersNeeded: '12/15 Volunteers',
      currentJoined: 12,
      totalNeeded: 15,
      imagePath: 'assets/images/2.jpg',
      description:
          'Assist doctors and certified nurses with patient intake registration, guiding elderly residents, and distributing first aid medical kits.',
      requirements: [
        'Patience and compassionate communication',
        'Fluent in Sinhala or Tamil (English is a bonus)',
        'Prior first-aid certificate preferred but not mandatory',
      ],
      coordinatorName: 'Dr. Priyantha Silva',
      coordinatorPhone: '+94 71 889 2341',
      assemblyPoint: 'Wadduwa Central Dispensary Main Lobby Registration',
      announcements: [
        'Mobile clinic van arriving at 07:30 AM.',
        'Sanitizer and medical masks provided at the check-in desk.',
      ],
      routeSteps: [
        'Drive south along Galle Road into Wadduwa town (8.4 km)',
        'Turn right at Dispensary Lane opposite the Clock Tower (200 m)',
        'Park at Front Lawn and report to Triage Tent (50 m)',
      ],
    ),
    VolunteerOpportunity(
      id: 'vol-3',
      title: 'Flood Debris & Canal Clearance',
      category: 'Street Cleanup',
      district: 'Colombo',
      status: 'Open',
      statusBg: Color(0xFFDCFCE7),
      statusColor: Color(0xFF16A34A),
      location: 'Wellawatte Canal Bank & Marine Drive',
      latitude: 6.8780,
      longitude: 79.8590,
      date: 'Sunday, 7:00 AM - 11:30 AM',
      volunteersNeeded: '34/50 Volunteers',
      currentJoined: 34,
      totalNeeded: 50,
      imagePath: 'assets/images/3.jpg',
      description:
          'Community-led environmental effort to clear fallen branches, plastic waste, and flood debris from canal runoff gates to prevent urban flooding.',
      requirements: [
        'Heavy-duty rubber boots or covered work shoes',
        'Work gloves (spare pairs will be provided)',
        'Safety vest (provided on site)',
      ],
      coordinatorName: 'Nadeeka Wickramasinghe',
      coordinatorPhone: '+94 76 554 1120',
      assemblyPoint: 'Marine Drive Canal Gate bridge checkpoint',
      announcements: [
        'Municipal tractor arrived to collect full garbage bags.',
        'Breakfast tea and buns will be served at 9:00 AM.',
      ],
      routeSteps: [
        'Proceed along Marine Drive toward Wellawatte bridge (3.1 km)',
        'Turn into Canal Side Walkway at the Municipal depot (150 m)',
        'Sign in with Coordinator Nadeeka at the yellow gazebo tent.',
      ],
    ),
    VolunteerOpportunity(
      id: 'vol-4',
      title: 'Relief Donation Sorting & QC',
      category: 'Donation Sorting',
      district: 'Gampaha',
      status: 'Urgent Today',
      statusBg: Color(0xFFFEE2E2),
      statusColor: Color(0xFFDC2626),
      location: 'Kelaniya Raja Maha Vihara Youth Center',
      latitude: 6.9553,
      longitude: 79.9197,
      date: 'Today, 4:00 PM - 8:30 PM',
      volunteersNeeded: '9/20 Volunteers',
      currentJoined: 9,
      totalNeeded: 20,
      imagePath: 'assets/images/4.jpg',
      description:
          'Sort clothing donations by size, verify baby formula expiry dates, and box essential hygiene packages for Kelani Valley flood relief camps.',
      requirements: [
        'Attention to detail for quality checking dates',
        'Friendly team player spirit',
        'Ability to stand for 2-3 hours with breaks',
      ],
      coordinatorName: 'Asela Fernando',
      coordinatorPhone: '+94 77 901 4455',
      assemblyPoint: 'Youth Center Warehouse Main Door #3',
      announcements: [
        'New shipment of 200 baby care kits arriving at 5:00 PM.',
      ],
      routeSteps: [
        'Follow Kandy Road toward Kelaniya bridge (5.8 km)',
        'Turn into Temple Road and follow signs for Youth Center (700 m)',
        'Check in at Warehouse Door #3 with Asela.',
      ],
    ),
    VolunteerOpportunity(
      id: 'vol-5',
      title: 'Displaced Family Shelter Support',
      category: 'Shelter Support',
      district: 'Ratnapura',
      status: 'High Priority',
      statusBg: Color(0xFFFEF3C7),
      statusColor: Color(0xFFD97706),
      location: 'Ratnapura Town Hall Temporary Shelter',
      latitude: 6.6828,
      longitude: 80.4034,
      date: 'Tomorrow, 9:00 AM - 5:00 PM',
      volunteersNeeded: '15/30 Volunteers',
      currentJoined: 15,
      totalNeeded: 30,
      imagePath: 'assets/images/1.jpg',
      description:
          'Provide care, distribute clean drinking water, manage meal service, and support children recreational activities at the flood shelter.',
      requirements: [
        'Empathetic and positive attitude',
        'Child-friendly and supportive demeanor',
        'Able to assist with meal distribution queues',
      ],
      coordinatorName: 'Chandana Perera',
      coordinatorPhone: '+94 72 443 1290',
      assemblyPoint: 'Town Hall Front Entrance Information Booth',
      announcements: [
        'Clean water bowser stationed at east entrance.',
      ],
      routeSteps: [
        'Take High Level Road (A4) directly to Ratnapura town center',
        'Turn left at Main Street Clock Tower to Town Hall',
        'Report to Chandana Perera at Entrance Booth.',
      ],
    ),
    VolunteerOpportunity(
      id: 'vol-6',
      title: 'Hill Country Landslide Relief Camp',
      category: 'Food & Water',
      district: 'Kandy',
      status: 'Urgent Today',
      statusBg: Color(0xFFFEE2E2),
      statusColor: Color(0xFFDC2626),
      location: 'Gatambe Community Ground, Peradeniya',
      latitude: 7.2721,
      longitude: 80.5980,
      date: 'Today, 1:00 PM - 7:00 PM',
      volunteersNeeded: '20/40 Volunteers',
      currentJoined: 20,
      totalNeeded: 40,
      imagePath: 'assets/images/2.jpg',
      description:
          'Prepare hot meals and organize dry ration logistics for displaced tea plantation worker families affected by heavy hill country rains.',
      requirements: [
        'Kitchen prep or food packaging experience is a plus',
        'Warm clothing recommended for evening shifts',
      ],
      coordinatorName: 'Ruwan Jayasuriya',
      coordinatorPhone: '+94 77 112 3344',
      assemblyPoint: 'Gatambe Ground Central Relief Pavillion',
      announcements: [
        'Fresh vegetables delivery arrived from Nuwara Eliya growers.',
      ],
      routeSteps: [
        'Drive on Colombo-Kandy Road (A1) toward Peradeniya junction',
        'Turn into Gatambe Ground entrance near Mahaweli river bank',
        'Check in at Pavilion desk.',
      ],
    ),
  ];

  // Active Joined Opportunities for the current user
  final List<JoinedActivity> _myActivities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );

    // Initial joined activity for demonstration
    _myActivities.add(
      JoinedActivity(
        opportunity: _opportunities[0],
        joinedAt: 'Today, 10:15 AM',
        volunteerRole: 'Ration Pack Assembler',
        checkInStatus: 'On-Site Verified',
        hoursLogged: 3,
      ),
    );

    _fetchUserLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserLocation() async {
    setState(() => _isLocating = true);
    try {
      final loc = await LocationHelper.getCurrentLiveLocation();
      if (mounted) {
        setState(() {
          _userLat = loc.latitude;
          _userLng = loc.longitude;
          _userLocationName = loc.formattedAddress;
          _isLocating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _userLat = 6.7958;
          _userLng = 79.8960;
          _userLocationName = 'Katubedda, Moratuwa';
          _isLocating = false;
        });
      }
    }
  }

  // Calculate Distance in Kilometers using Haversine Formula
  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R * asin...
  }

  String _getDistanceString(double destLat, double destLng) {
    if (_userLat == null || _userLng == null) return '~2.4 km';
    final double dist = _calculateDistanceKm(
      _userLat!,
      _userLng!,
      destLat,
      destLng,
    );
    if (dist < 1.0) {
      return '${(dist * 1000).round()} m away';
    }
    return '${dist.toStringAsFixed(1)} km away';
  }

  double? _getMaxDistanceKm(String distanceFilter) {
    switch (distanceFilter) {
      case 'Within 3 km':
        return 3.0;
      case 'Within 5 km':
        return 5.0;
      case 'Within 10 km':
        return 10.0;
      case 'Within 25 km':
        return 25.0;
      case 'Within 50 km':
        return 50.0;
      default:
        return null;
    }
  }

  List<VolunteerOpportunity> _getFilteredOpportunities() {
    return _opportunities.where((op) {
      // 1. Activity Type Filter
      if (_selectedCategory != 'All Activities' &&
          op.category != _selectedCategory) {
        return false;
      }

      // 2. District Filter
      if (_selectedDistrict != 'All Districts' &&
          op.district != _selectedDistrict) {
        return false;
      }

      // 3. Distance / Proximity Filter
      final maxDist = _getMaxDistanceKm(_selectedDistance);
      if (maxDist != null) {
        final userLat = _userLat ?? 6.7958;
        final userLng = _userLng ?? 79.8960;
        final dist = _calculateDistanceKm(
          userLat,
          userLng,
          op.latitude,
          op.longitude,
        );
        if (dist > maxDist) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _selectedCategory != 'All Activities' ||
      _selectedDistance != 'Any Distance' ||
      _selectedDistrict != 'All Districts';

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'All Activities';
      _selectedDistance = 'Any Distance';
      _selectedDistrict = 'All Districts';
    });
  }

  void _showJoinModal(VolunteerOpportunity opp) {
    final alreadyJoined = _myActivities.any((a) => a.opportunity.id == opp.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Expanded Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Responsive Header Badges (Using Wrap to avoid overflow)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: opp.statusBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                opp.status,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: opp.statusColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${opp.district} District',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.near_me_rounded,
                                    size: 12,
                                    color: Color(0xFF0284C7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getDistanceString(
                                      opp.latitude,
                                      opp.longitude,
                                    ),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Title
                        Text(
                          opp.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Location & Date Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 17,
                                    color: Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      opp.location,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16, thickness: 1, color: Color(0xFFEEF2F6)),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    size: 17,
                                    color: Color(0xFF0284C7),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      opp.date,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          'Mission Overview',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          opp.description,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: const Color(0xFF64748B),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // What you will need / Requirements
                        Text(
                          'Requirements & Preparation',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...opp.requirements.map(
                          (req) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 3),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    req,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Coordinator Info Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Color(0xFF3B82F6),
                                child: Icon(
                                  Icons.person_pin_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opp.coordinatorName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                    Text(
                                      'Coordinator Hotline: ${opp.coordinatorPhone}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: const Color(0xFF2563EB),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Button with FittedBox to prevent overflow
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (!alreadyJoined) {
                          setState(() {
                            _myActivities.add(
                              JoinedActivity(
                                opportunity: opp,
                                joinedAt: 'Just Now',
                                volunteerRole: 'Active Volunteer',
                                checkInStatus: 'Not Checked In',
                              ),
                            );
                          });
                          _showJoinSuccessDialog(opp);
                        } else {
                          // Switch to My Activities tab
                          _tabController.animateTo(1);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alreadyJoined
                            ? const Color(0xFF16A34A)
                            : AppColors.primaryNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              alreadyJoined
                                  ? Icons.task_alt_rounded
                                  : Icons.volunteer_activism_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              alreadyJoined
                                  ? 'Already Joined • View in Activities'
                                  : 'Confirm & Join This Mission',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showJoinSuccessDialog(VolunteerOpportunity opp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
            const SizedBox(width: 8),
            Text(
              'Mission Confirmed!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have been enrolled as a community volunteer for:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              opp.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Check the "My Activities" tab for navigation directions, coordinator hotline, and on-site check-in.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Stay Here',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _tabController.animateTo(1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              'Go to My Activities',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRouteNavigationModal(VolunteerOpportunity opp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    child: const Icon(Icons.directions_rounded, color: Color(0xFF0284C7), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Route & Travel Directions',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        Text(
                          opp.location,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
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
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ETA Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.navigation_rounded, color: Color(0xFF0284C7), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Travel: ~12 Mins (${_getDistanceString(opp.latitude, opp.longitude)})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0369A1),
                                  ),
                                ),
                                Text(
                                  'From: ${_userLocationName.isEmpty ? "Your current GPS" : _userLocationName}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: const Color(0xFF0284C7),
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
                    const SizedBox(height: 18),

                    // Turn by turn instructions
                    Text(
                      'Turn-by-Turn Road Route',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...opp.routeSteps.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final step = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.primaryNavy,
                              child: Text(
                                '$idx',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF334155),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 10),
                    // Assembly Point Details
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
                              const Icon(Icons.meeting_room_rounded, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                'On-Site Assembly Point',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            opp.assemblyPoint,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening live map route to ${opp.location}...'),
                        backgroundColor: const Color(0xFF0284C7),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, color: Colors.white, size: 18),
                  label: Text(
                    'Open in Google Maps / GPS App',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCoordinatorContactModal(VolunteerOpportunity opp) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opp.coordinatorName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      Text(
                        'On-Site Ground Coordinator',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    opp.coordinatorPhone,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Dialing ${opp.coordinatorPhone}...'),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                        },
                        icon: const Icon(Icons.call, color: Color(0xFF16A34A)),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opening WhatsApp chat with ${opp.coordinatorName}...'),
                              backgroundColor: const Color(0xFF0284C7),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF0284C7)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Call this number if you get lost on the way or need immediate access clearance at the venue security gates.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkInVolunteer(int index) {
    final activity = _myActivities[index];
    final isAlreadyCheckedIn = activity.checkInStatus == 'On-Site Verified';

    setState(() {
      _myActivities[index] = activity.copyWith(
        checkInStatus: isAlreadyCheckedIn ? 'Completed' : 'On-Site Verified',
        hoursLogged: isAlreadyCheckedIn ? activity.hoursLogged + 2 : 1,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              isAlreadyCheckedIn
                  ? 'Volunteer mission marked Completed (+2 hrs logged)!'
                  : 'On-site Check-in Verified at ${activity.opportunity.location}!',
            ),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Reusable Smart Dropdown Card Builder
  Widget _buildDropdownCard({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final bool isFiltered = value != items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFiltered ? const Color(0xFFF0F9FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFiltered ? const Color(0xFF38BDF8) : const Color(0xFFE2E8F0),
          width: isFiltered ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isFiltered ? const Color(0xFF0284C7) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isFiltered ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: isFiltered ? FontWeight.w700 : FontWeight.w600,
                  color: isFiltered ? const Color(0xFF0369A1) : const Color(0xFF334155),
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: 4,
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: item == value ? FontWeight.w700 : FontWeight.w500,
                        color: item == value ? const Color(0xFF0284C7) : const Color(0xFF334155),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryNavy,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Community Volunteers',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primaryNavy,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.my_location_rounded,
              color: Color(0xFF0284C7),
              size: 22,
            ),
            tooltip: 'Refresh My Location',
            onPressed: _fetchUserLocation,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                const Tab(text: 'Opportunities'),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('My Activities'),
                      if (_myActivities.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_myActivities.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOpportunitiesTab(),
          _buildMyActivitiesTab(),
        ],
      ),
    );
  }

  Widget _buildOpportunitiesTab() {
    final filteredList = _getFilteredOpportunities();

    return RefreshIndicator(
      onRefresh: _fetchUserLocation,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // GPS Location Status Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.near_me_rounded, size: 16, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isLocating
                        ? 'Acquiring GPS coordinates...'
                        : 'Sorting by live GPS: ${_userLocationName.isEmpty ? "Katubedda, Moratuwa" : _userLocationName}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0369A1),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isLocating)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                  ),
              ],
            ),
          ),

          // 3 Smart Dropdown Filters Header Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Section Header with Results Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryNavy),
                        const SizedBox(width: 6),
                        Text(
                          'Filter Opportunities',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Showing ${filteredList.length} of ${_opportunities.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Row 1: Activity Type Dropdown & Distance Dropdown
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildDropdownCard(
                        icon: Icons.volunteer_activism_rounded,
                        label: 'Activity',
                        value: _selectedCategory,
                        items: _categories,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildDropdownCard(
                        icon: Icons.radar_rounded,
                        label: 'Distance',
                        value: _selectedDistance,
                        items: _distanceOptions,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDistance = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Row 2: 25 Districts Dropdown & Optional Reset Button
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownCard(
                        icon: Icons.location_city_rounded,
                        label: 'District',
                        value: _selectedDistrict,
                        items: _districts,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDistrict = val);
                        },
                      ),
                    ),
                    if (_hasActiveFilters) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _resetFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.refresh_rounded, size: 15, color: Color(0xFFDC2626)),
                              const SizedBox(width: 4),
                              Text(
                                'Reset',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // List of Opportunities or Empty State
          if (filteredList.isEmpty)
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  Text(
                    'No opportunities match your filters',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try changing the activity type, expanding the distance radius, or selecting "All Districts".',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Reset All Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            )
          else
            ...filteredList.map((opp) => _buildOpportunityCard(opp)),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard(VolunteerOpportunity opp) {
    final isJoined = _myActivities.any((a) => a.opportunity.id == opp.id);
    final distanceText = _getDistanceString(opp.latitude, opp.longitude);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showJoinModal(opp),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Responsive Top Badges (Wrap to prevent right overflow on all phone widths)
              Wrap(
                spacing: 6,
                runSpacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: opp.statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      opp.status,
                      style: GoogleFonts.plusJakartaSans(
                        color: opp.statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      opp.category,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF475569),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded, size: 11, color: Color(0xFF0284C7)),
                        const SizedBox(width: 3),
                        Text(
                          distanceText,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF0284C7),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title & District
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opp.title,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.primaryNavy,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${opp.district} District • ${opp.location}',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Date & Time
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      opp.date,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Volunteers Needed',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF64748B),
                          fontSize: 11.5,
                        ),
                      ),
                      Text(
                        '${opp.currentJoined}/${opp.totalNeeded}',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primaryNavy,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: opp.currentJoined / opp.totalNeeded,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        opp.currentJoined / opp.totalNeeded >= 0.8
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom Button Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRouteNavigationModal(opp),
                      icon: const Icon(Icons.directions_rounded, size: 16, color: Color(0xFF0284C7)),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'View Route',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBAE6FD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showJoinModal(opp),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isJoined ? const Color(0xFF16A34A) : AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isJoined ? 'Joined ✓' : 'Join Mission',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyActivitiesTab() {
    if (_myActivities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.volunteer_activism_outlined, size: 54, color: Color(0xFF94A3B8)),
              const SizedBox(height: 14),
              Text(
                'No Joined Activities Yet',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Browse available community relief opportunities and tap "Join Mission" to participate.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _tabController.animateTo(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Browse Opportunities'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: _myActivities.length,
      itemBuilder: (context, index) {
        final activity = _myActivities[index];
        final opp = activity.opportunity;
        final isVerified = activity.checkInStatus == 'On-Site Verified';
        final isCompleted = activity.checkInStatus == 'Completed';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isVerified ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFFF1F5F9)
                            : isVerified
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.verified_rounded
                                : isVerified
                                    ? Icons.location_pin
                                    : Icons.pending_rounded,
                            size: 13,
                            color: isCompleted
                                ? const Color(0xFF475569)
                                : isVerified
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            activity.checkInStatus,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isCompleted
                                  ? const Color(0xFF475569)
                                  : isVerified
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Joined: ${activity.joinedAt}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  opp.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${opp.district} • ${opp.location}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),

                // Assembly Point Pill
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEEF2F6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          opp.assemblyPoint,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action Buttons Row: Route, Contact, Check-in
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRouteNavigationModal(opp),
                        icon: const Icon(Icons.navigation_rounded, size: 14, color: Color(0xFF0284C7)),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Route',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBAE6FD)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCoordinatorContactModal(opp),
                        icon: const Icon(Icons.phone_rounded, size: 14, color: Color(0xFF3B82F6)),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Hotline',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isCompleted ? null : () => _checkInVolunteer(index),
                        icon: Icon(
                          isCompleted
                              ? Icons.check_circle_rounded
                              : isVerified
                                  ? Icons.done_all_rounded
                                  : Icons.qr_code_scanner_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isCompleted
                                ? 'Done'
                                : isVerified
                                    ? 'Complete'
                                    : 'Check In',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCompleted
                              ? const Color(0xFF94A3B8)
                              : isVerified
                                  ? const Color(0xFF16A34A)
                                  : AppColors.primaryNavy,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 6),
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
}
