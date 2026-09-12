import 'package:flutter/foundation.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'CITIZEN', 'COMMUNITY_VOLUNTEER', 'FIELD_CREW'
  final String district;
  final String? crewId;
  final String? crewName;
  final String? specialty; // 'WATER_RESCUE', '4X4_DEBRIS', 'MEDICAL_TRIAGE', 'DRONE_RECON', 'HAM_RADIO'
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
  bool get isVolunteer => role == 'COMMUNITY_VOLUNTEER' || role == 'CITIZEN';
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Predefined Demo Personas for Fast Testing & Verification
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

  static const UserModel volunteerKasun = UserModel(
    id: '88888888-8888-8888-8888-888888888888',
    name: 'Kasun Mendis',
    email: 'kasun.volunteer@gmail.com',
    phone: '+94771234567',
    role: 'COMMUNITY_VOLUNTEER',
    district: 'Colombo',
    equipment: [],
  );

  void loginAs(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void loginWithCredentials(String email, String password, {String role = 'COMMUNITY_VOLUNTEER', String district = 'Colombo'}) {
    if (email.toLowerCase().contains('water') || role == 'WATER_RESCUE') {
      _currentUser = waterRescueLead;
    } else if (email.toLowerCase().contains('4x4') || email.toLowerCase().contains('debris') || role == '4X4_DEBRIS') {
      _currentUser = debrisLead;
    } else if (email.toLowerCase().contains('medical') || role == 'MEDICAL_TRIAGE') {
      _currentUser = medicalLead;
    } else {
      _currentUser = UserModel(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first.toUpperCase(),
        email: email,
        phone: '+94771234567',
        role: role == 'FIELD_CREW' ? 'FIELD_CREW' : 'COMMUNITY_VOLUNTEER',
        district: district,
        crewName: role == 'FIELD_CREW' ? '$district Field Response Unit' : null,
        specialty: role == 'FIELD_CREW' ? 'WATER_RESCUE' : null,
        equipment: role == 'FIELD_CREW' ? ['Basic Emergency Gear', 'First Aid Kit'] : [],
      );
    }
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
