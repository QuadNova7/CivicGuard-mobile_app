import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  LocalCacheService._();
  static final LocalCacheService instance = LocalCacheService._();

  static const String _keySubmittedReports = 'civicguard_user_submitted_reports';
  static const String _keyDonations = 'civicguard_cached_donations';
  static const String _keyVolunteerActivities = 'civicguard_cached_volunteer_activities';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _getPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ===================== USER SUBMITTED INCIDENT REPORTS =====================

  Future<void> saveSubmittedReports(List<Map<String, dynamic>> reports) async {
    try {
      final p = await _getPrefs;
      final raw = jsonEncode(reports);
      await p.setString(_keySubmittedReports, raw);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getSubmittedReports() async {
    try {
      final p = await _getPrefs;
      final raw = p.getString(_keySubmittedReports);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> addSubmittedReport(Map<String, dynamic> report) async {
    try {
      final current = await getSubmittedReports();
      current.removeWhere((e) => e['id'] == report['id'] || (e['ticket_id'] != null && e['ticket_id'] == report['ticket_id']));
      current.insert(0, report);
      await saveSubmittedReports(current);
    } catch (_) {}
  }

  // Legacy compatibility aliases
  Future<void> saveReports(List<Map<String, dynamic>> reports) async {
    await saveSubmittedReports(reports);
  }

  Future<List<Map<String, dynamic>>> getCachedReports() async {
    return getSubmittedReports();
  }

  Future<void> addReport(Map<String, dynamic> report) async {
    await addSubmittedReport(report);
  }

  // ===================== DONATION RESOURCES =====================

  Future<void> saveDonations(List<Map<String, dynamic>> donations) async {
    try {
      final p = await _getPrefs;
      final raw = jsonEncode(donations);
      await p.setString(_keyDonations, raw);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getCachedDonations() async {
    try {
      final p = await _getPrefs;
      final raw = p.getString(_keyDonations);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> addDonation(Map<String, dynamic> donation) async {
    try {
      final current = await getCachedDonations();
      current.insert(0, donation);
      await saveDonations(current);
    } catch (_) {}
  }

  // ===================== VOLUNTEER ACTIVITIES =====================

  Future<void> saveJoinedActivities(List<Map<String, dynamic>> activities) async {
    try {
      final p = await _getPrefs;
      final raw = jsonEncode(activities);
      await p.setString(_keyVolunteerActivities, raw);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getCachedJoinedActivities() async {
    try {
      final p = await _getPrefs;
      final raw = p.getString(_keyVolunteerActivities);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> addJoinedActivity(Map<String, dynamic> activity) async {
    try {
      final current = await getCachedJoinedActivities();
      current.removeWhere((e) => e['id'] == activity['id']);
      current.insert(0, activity);
      await saveJoinedActivities(current);
    } catch (_) {}
  }

  // ===================== DEV SETTINGS =====================
  static const String _keyBaseIp = 'civicguard_base_ip';

  Future<void> saveBaseIp(String ip) async {
    try {
      final p = await _getPrefs;
      await p.setString(_keyBaseIp, ip);
    } catch (_) {}
  }

  Future<String?> getBaseIp() async {
    try {
      final p = await _getPrefs;
      return p.getString(_keyBaseIp);
    } catch (_) {}
    return null;
  }
}
