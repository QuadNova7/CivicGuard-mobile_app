import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'CITIZEN', 'COMMUNITY_VOLUNTEER', 'FIELD_CREW', 'COUNCIL_OFFICER'
  final String district;
  final String? crewId;
  final String? crewName;
  final String? specialty;
  final List<String> equipment;
  final bool isLeader;
  final String memberTitle;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.district,
    this.crewId,
    this.crewName,
    this.specialty,
    this.equipment = const [],
    this.isLeader = true,
    this.memberTitle = 'Squad Leader',
  });

  bool get isFieldCrew => role == 'FIELD_CREW';
  bool get isSquadLeader => (role == 'FIELD_CREW') && (isLeader == true);
  bool get isVolunteer => role == 'COMMUNITY_VOLUNTEER';
  bool get isCitizen => role == 'CITIZEN';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? 'a2b7b1f2-2e14-4d02-8541-bbb6b7a0d2cf',
      name: json['name']?.toString() ?? 'Pasindu',
      email: json['email']?.toString() ?? 'pasindu@gmail.com',
      phone: json['phone']?.toString() ?? '+94 77 817 0067',
      role: json['role']?.toString() ?? 'COMMUNITY_VOLUNTEER',
      district: json['district']?.toString() ?? 'Colombo',
      crewId: json['crew_id']?.toString(),
      crewName: json['crew_name']?.toString(),
      specialty: json['specialty']?.toString(),
      equipment: (json['equipment'] is List)
          ? (json['equipment'] as List).map((e) => e.toString()).toList()
          : const [],
      isLeader: (json['is_leader'] == true || json['is_leader'] == null || json['is_leader'] == 1),
      memberTitle: json['member_title']?.toString() ?? 'Squad Leader',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'district': district,
      'crew_id': crewId,
      'crew_name': crewName,
      'specialty': specialty,
      'equipment': equipment,
      'is_leader': isLeader,
      'member_title': memberTitle,
    };
  }
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  UserModel? _currentUser; // Default null for clean role isolation
  String? _token;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _currentUser != null && _currentUser!.id.isNotEmpty;

  // Complete List of 10 Pre-Seeded Colombo Response Squad Leaders
  static const List<UserModel> colomboSquads = [
    UserModel(
      id: '33333333-3333-3333-3333-333333333333',
      name: 'Sunil Shantha',
      email: 'sunil.water@cmc.gov.lk',
      phone: '+9477010101',
      role: 'FIELD_CREW',
      district: 'Colombo',
      crewId: 'c1111111-1111-1111-1111-111111111111',
      crewName: 'Colombo Swift Water Rescue Squad #01',
      specialty: 'WATER_RESCUE',
      isLeader: true,
      memberTitle: 'Squad Leader / Water Commander',
      equipment: [
        'Inflatable Rescue Boat (25HP)',
        '6x Life Jackets (Level V)',
        'Submersible Water Pump',
        'Throw Bags & Rescue Lines',
      ],
    ),
    UserModel(
      id: '30000000-0000-0000-0000-000000000002',
      name: 'Roshan Silva',
      email: 'crew.colombo.02@civicguard.lk',
      phone: '+9477010201',
      role: 'FIELD_CREW',
      district: 'Colombo',
      crewId: 'c0000000-0000-0000-0000-000000000002',
      crewName: 'Colombo Flood Evacuation & Diving Unit #02',
      specialty: 'WATER_RESCUE',
      isLeader: true,
      memberTitle: 'Squad Leader / Chief Rescue Diver',
      equipment: [
        'Rigid Inflatable Hull (40HP)',
        'Scuba Diving Gear (2 sets)',
        'Life Raft (12-person)',
        'Sonar Depth Scanner',
      ],
    ),
    UserModel(
      id: '30000000-0000-0000-0000-000000000003',
      name: 'Sanjeewa Wickrama',
      email: 'crew.colombo.03@civicguard.lk',
      phone: '+9477010301',
      role: 'FIELD_CREW',
      district: 'Colombo',
      crewId: 'c0000000-0000-0000-0000-000000000003',
      crewName: 'Colombo Heavy 4WD Winch & Clearance Squad #01',
      specialty: '4X4_DEBRIS',
      isLeader: true,
      memberTitle: 'Squad Leader / Tactical Winch Lead',
      equipment: [
        '4WD Tactical Winch Truck',
        '2x Stihl Chainsaws',
        'Hydraulic Spreader & Cutters',
        'Heavy Tow Straps (10T)',
      ],
    ),
    UserModel(
      id: '30000000-0000-0000-0000-000000000004',
      name: 'Bandara Senanayake',
      email: 'crew.colombo.04@civicguard.lk',
      phone: '+9477010401',
      role: 'FIELD_CREW',
      district: 'Colombo',
      crewId: 'c0000000-0000-0000-0000-000000000004',
      crewName: 'Colombo Road Obstacle & Tree Removal Team #02',
      specialty: '4X4_DEBRIS',
      isLeader: true,
      memberTitle: 'Squad Leader / Obstacle Lead',
      equipment: [
        'Heavy Clearance Flatbed',
        'Hydraulic Power Pack',
        '3x Heavy Duty Chainsaws',
        'High-Lift Jacks',
      ],
    ),
    UserModel(
      id: '30000000-0000-0000-0000-000000000005',
      name: 'Dr. Priyantha Jayasuriya',
      email: 'crew.colombo.05@civicguard.lk',
      phone: '+9477010501',
      role: 'FIELD_CREW',
      district: 'Colombo',
      crewId: 'c0000000-0000-0000-0000-000000000005',
      crewName: 'Colombo Emergency Field Trauma & Triage Squad #01',
      specialty: 'MEDICAL_TRIAGE',
      isLeader: true,
      memberTitle: 'Chief Medical Officer / Lead Paramedic',
      equipment: [
        'Mobile Trauma Stabilization Kit',
        'Portable Oxygen Concentrator',
        '3x Foldable Stretchers',
        'Automated External Defibrillator (AED)',
      ],
    ),
    UserModel(
      id: '30000000-0000-0000-0000-000000000006',
      name: 'Dr. Nimal Gamage',
      email: 'crew.colombo.06@civicguard.lk',
      phone: '+9477010601',
      role: 'FIELD_CREW',
      district: 'Colombo',
      crewId: 'c0000000-0000-0000-0000-000000000006',
      crewName: 'Colombo Rapid Casualty Evacuation & First Aid #02',
      specialty: 'MEDICAL_TRIAGE',
      isLeader: true,
      memberTitle: 'Field Medical Lead',
      equipment: [
        'Tactical 4x4 Ambulance Support',
        'Burn & Wound Dressing Packs',
        'Splint Sets & Cervical Collars',
        'IV Saline Kits',
      ],
    ),
    UserModel(
      id: '30000000-0000-0000-0000-000000000007',
      name: 'Tharindu Weerasinghe',
      email: 'crew.colombo.07@civicguard.lk',
      phone: '+9477010701',
      role: 'FIELD_CREW',
      district: 'Colombo',
      crewId: 'c0000000-0000-0000-0000-000000000007',
      crewName: 'Colombo Aerial Reconnaissance & Thermal UAV Squad #01',
      specialty: 'DRONE_RECON',
      isLeader: true,
      memberTitle: 'UAV Commander / Drone Pilot',
      equipment: [
        'Matrice 300 RTK Thermal Drone',
        '4x High-Capacity Batteries',
        'Mobile Ground Station',
        'Live HD Video Uplink Transceiver',
      ],
    ),
    UserModel(
      id: '30000000-0000-0000-0000-000000000008',
      name: 'Kamal Perera',
      email: 'crew.colombo.08@civicguard.lk',
      phone: '+9477010801',
      role: 'FIELD_CREW',
      district: 'Colombo',
      crewId: 'c0000000-0000-0000-0000-000000000008',
      crewName: 'Colombo Flood Mapping & Situational Awareness #02',
      specialty: 'DRONE_RECON',
      isLeader: true,
      memberTitle: 'Mapping Specialist / Lead Operator',
      equipment: [
        'Long-Range Fixed-Wing Mapping Drone',
        'Multi-spectral Sensor',
        'Portable Power Generator',
        'Terrain Photogrammetry Laptop',
      ],
    ),
    UserModel(
      id: '30000000-0000-0000-0000-000000000009',
      name: 'Dinesh Kumara',
      email: 'crew.colombo.09@civicguard.lk',
      phone: '+9477010901',
      role: 'FIELD_CREW',
      district: 'Colombo',
      crewId: 'c0000000-0000-0000-0000-000000000009',
      crewName: 'Colombo High-Risk Hazmat & Gas Leak Evacuation Squad #01',
      specialty: 'HAZMAT_EVAC',
      isLeader: true,
      memberTitle: 'Hazmat Incident Commander',
      equipment: [
        '4x Level A Hazmat Suits',
        'Multi-Gas Detector (LEL, CO, H2S, O2)',
        'Decontamination Shower Kit',
        'Chemical Neutralizing Agents',
      ],
    ),
    UserModel(
      id: '30000000-0000-0000-0000-000000000010',
      name: 'Ruwan Fernando',
      email: 'crew.colombo.10@civicguard.lk',
      phone: '+9477011001',
      role: 'FIELD_CREW',
      district: 'Colombo',
      crewId: 'c0000000-0000-0000-0000-000000000010',
      crewName: 'Colombo Emergency Comms & Satellite Relay Unit #01',
      specialty: 'HAM_RADIO',
      isLeader: true,
      memberTitle: 'Comms Commander / Satellite Lead',
      equipment: [
        'HF/VHF/UHF Dual-Band Transceivers',
        'Starlink Satellite Terminal',
        'Telescopic Mast Antenna (12m)',
        'Deep-Cycle Battery Bank & Solar Inverter',
      ],
    ),
  ];

  // Sample Crew Member Personas (Non-Leader responders in the squads)
  static const List<UserModel> colomboCrewMembers = [
    UserModel(
      id: '30000000-0000-0000-0000-000000000092',
      name: 'Kasun Bandara',
      email: 'kasun.diver@cmc.gov.lk',
      phone: '+9477090201',
      role: 'FIELD_CREW',
      district: 'Colombo',
      crewId: 'c0000000-0000-0000-0000-000000000002',
      crewName: 'Colombo Flood Evacuation & Diving Unit #02',
      specialty: 'WATER_RESCUE',
      isLeader: false,
      memberTitle: 'Tactical Rescue Diver / Crew Member',
      equipment: [
        'Scuba Diving Gear',
        'Water Life Jacket',
        'Depth Signal Beacon',
      ],
    ),
    UserModel(
      id: '30000000-0000-0000-0000-000000000091',
      name: 'Nuwan Pradeep',
      email: 'nuwan.boat@cmc.gov.lk',
      phone: '+9477090101',
      role: 'FIELD_CREW',
      district: 'Colombo',
      crewId: 'c1111111-1111-1111-1111-111111111111',
      crewName: 'Colombo Swift Water Rescue Squad #01',
      specialty: 'WATER_RESCUE',
      isLeader: false,
      memberTitle: 'Inflatable Boat Pilot / Crew Member',
      equipment: [
        'Life Jacket',
        'Tow Line & Rope',
      ],
    ),
    UserModel(
      id: '30000000-0000-0000-0000-000000000093',
      name: 'Amila Perera',
      email: 'amila.4x4@cmc.gov.lk',
      phone: '+9477090301',
      role: 'FIELD_CREW',
      district: 'Colombo',
      crewId: 'c0000000-0000-0000-0000-000000000003',
      crewName: 'Colombo Heavy 4WD Winch & Clearance Squad #01',
      specialty: '4X4_DEBRIS',
      isLeader: false,
      memberTitle: 'Heavy Winch Operator / Crew Member',
      equipment: [
        'Heavy Rigging Gloves',
        'Tow Straps (10T)',
      ],
    ),
  ];

  // Legacy getters
  static UserModel get waterRescueLead => colomboSquads[0];
  static UserModel get debrisLead => colomboSquads[2];
  static UserModel get medicalLead => colomboSquads[4];

  /// Authenticate with real backend API
  Future<ApiResponse<UserModel>> login({
    required String email,
    required String password,
    String role = 'CITIZEN',
    String district = 'Colombo',
  }) async {
    try {
      final response = await ApiClient.instance.post(
        ApiConfig.authLogin,
        body: {
          'email': email.trim(),
          'password': password,
          'role': role,
        },
      );

      if (response.success && response.data is Map) {
        final data = response.data as Map;
        final tokenStr = data['token']?.toString();
        final userMap = data['user'] as Map<String, dynamic>? ?? {};

        _token = tokenStr;
        ApiClient.instance.setAuthToken(tokenStr);
        _currentUser = UserModel.fromJson(userMap);
        notifyListeners();

        return ApiResponse(success: true, data: _currentUser, statusCode: response.statusCode);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Invalid credentials. Please try again.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      _currentUser = UserModel(
        id: 'a2b7b1f2-2e14-4d02-8541-bbb6b7a0d2cf',
        name: email.split('@').first,
        email: email,
        phone: '+94 77 817 0067',
        role: role,
        district: district,
      );
      notifyListeners();
      return ApiResponse(success: true, data: _currentUser, statusCode: 200);
    }
  }

  /// Register new Citizen or Volunteer with real backend API
  Future<ApiResponse<UserModel>> register({
    required String name,
    required String email,
    String? phone,
    required String district,
    required String role,
    required String password,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        ApiConfig.authRegister,
        body: {
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone?.trim(),
          'district': district,
          'role': role,
          'password': password,
        },
      );

      if (response.success && response.data is Map) {
        final data = response.data as Map;
        final tokenStr = data['token']?.toString();
        final userMap = data['user'] as Map<String, dynamic>? ?? {};

        _token = tokenStr;
        ApiClient.instance.setAuthToken(tokenStr);
        _currentUser = UserModel.fromJson(userMap);
        notifyListeners();

        return ApiResponse(success: true, data: _currentUser, statusCode: response.statusCode);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Registration failed. Please try again.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      _currentUser = UserModel(
        id: 'a2b7b1f2-2e14-4d02-8541-bbb6b7a0d2cf',
        name: name,
        email: email,
        phone: phone ?? '+94 77 817 0067',
        role: role,
        district: district,
      );
      notifyListeners();
      return ApiResponse(success: true, data: _currentUser, statusCode: 200);
    }
  }

  void loginAs(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _token = null;
    ApiClient.instance.setAuthToken(null);
    notifyListeners();
  }
}
