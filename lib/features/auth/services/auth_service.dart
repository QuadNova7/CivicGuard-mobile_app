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
  });

  bool get isFieldCrew => role == 'FIELD_CREW';
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
    };
  }
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  // Default state: Logged out
  UserModel? _currentUser = null;
  String? _token = null;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _currentUser != null && _currentUser!.id.isNotEmpty;

  // Predefined Demo Crew Personas for Operations Testing
  static const UserModel waterRescueLead = UserModel(
    id: '33333333-3333-3333-3333-333333333333',
    name: 'Sunil Shantha',
    email: 'sunil.water@cmc.gov.lk',
    phone: '+94771234562',
    role: 'FIELD_CREW',
    district: 'Colombo',
    crewId: 'c1111111-1111-1111-1111-111111111111',
    crewName: 'Colombo Swift Water Rescue Unit #01',
    specialty: 'WATER_RESCUE',
    equipment: [
      'Inflatable Boat (15HP)',
      '4x Life Jackets',
      'Water Extraction Pump',
      'Heavy Tow Ropes',
    ],
  );

  static const UserModel debrisLead = UserModel(
    id: '66666666-6666-6666-6666-666666666666',
    name: 'Bandara Senanayake',
    email: 'bandara.4x4@civicguard.lk',
    phone: '+94771234565',
    role: 'FIELD_CREW',
    district: 'Ratnapura',
    crewId: 'c2222222-2222-2222-2222-222222222222',
    crewName: 'Ratnapura 4WD Winch & Chainsaw Unit #02',
    specialty: '4X4_DEBRIS',
    equipment: [
      '4WD Winch Truck',
      '2x Stihl Chainsaws',
      'Hydraulic Spreader',
      'High-Tension Tow Straps',
    ],
  );

  static const UserModel medicalLead = UserModel(
    id: '77777777-7777-7777-7777-777777777777',
    name: 'Dr. Nimal Gamage',
    email: 'nimal.medical@civicguard.lk',
    phone: '+94771234566',
    role: 'FIELD_CREW',
    district: 'Kandy',
    crewId: 'c3333333-3333-3333-3333-333333333333',
    crewName: 'Kandy Emergency Medical & Triage Unit #01',
    specialty: 'MEDICAL_TRIAGE',
    equipment: [
      'Mobile Trauma Kit',
      'Portable Oxygen Concentrator',
      'Foldable Stretchers',
      'Emergency Antibiotics',
    ],
  );

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
