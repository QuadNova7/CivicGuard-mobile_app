import 'dart:io';
import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';

class CrewApiService {
  static final CrewApiService instance = CrewApiService._();
  CrewApiService._();

  Future<Map<String, dynamic>> fetchMyCrewTasks([String? crewId]) async {
    final activeCrewId = crewId ?? AuthService.instance.currentUser?.crewId;
    if (activeCrewId != null && activeCrewId.isNotEmpty) {
      final response = await ApiClient.instance.get('/api/tickets/crews/$activeCrewId/tasks');
      if (response.success && response.data != null) {
        if (response.data is Map) {
          final map = Map<String, dynamic>.from(response.data as Map);
          if (map.containsKey('tasks')) return map;
          if (map.containsKey('data') && map['data'] is Map) {
            final inner = Map<String, dynamic>.from(map['data'] as Map);
            if (inner.containsKey('tasks')) return inner;
          }
          return map;
        }
        if (response.data is List) {
          return {'tasks': response.data};
        }
      }
    }
    
    final response = await ApiClient.instance.get('/api/tickets/crews/me');
    if (response.success && response.data != null) {
      if (response.data is Map) {
        final map = Map<String, dynamic>.from(response.data as Map);
        if (map.containsKey('tasks')) return map;
        if (map.containsKey('data') && map['data'] is Map) {
          final inner = Map<String, dynamic>.from(map['data'] as Map);
          if (inner.containsKey('tasks')) return inner;
        }
        return map;
      }
      if (response.data is List) {
        return {'tasks': response.data};
      }
    }
    return {'crew': null, 'tasks': []};
  }

  Future<bool> updateTaskStatus(String ticketId, String status) async {
    String backendStatus = 'ASSIGNED';
    if (status == 'En Route' || status == 'On Scene') {
      backendStatus = 'IN_PROGRESS';
    } else if (status == 'Completed') {
      backendStatus = 'COMPLETED';
    }

    final response = await ApiClient.instance.patch(
      '/api/tickets/$ticketId/status',
      body: {
        'status': backendStatus,
        'tactical_status': status,
      },
    );
    return response.success == true;
  }

  Future<bool> updateCrewLeader(String crewId, String userId) async {
    try {
      final response = await ApiClient.instance.patch(
        '/api/tickets/crews/$crewId/leader',
        body: {'user_id': userId},
      );
      return response.success == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitSitRep(String ticketId, String notes, int evacuatedCount, File? photo) async {
    final fields = {
      'notes': 'Field SitRep: $notes',
      'sitrep_notes': notes,
      'evacuated_count': evacuatedCount.toString(),
    };
    
    if (photo == null) {
       fields['photo_url'] = 'https://via.placeholder.com/600x400?text=No+Photo+Evidence';
    }

    final response = await ApiClient.instance.postMultipart(
      '/api/tickets/$ticketId/complete',
      fields: fields,
      file: photo,
      fileField: 'photo',
    );
    
    return response.success == true;
  }
}
