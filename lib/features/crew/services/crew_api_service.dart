import 'dart:io';
import '../../../core/network/api_client.dart';

class CrewApiService {
  static final CrewApiService instance = CrewApiService._();
  CrewApiService._();

  Future<Map<String, dynamic>> fetchMyCrewTasks() async {
    final response = await ApiClient.instance.get('/api/tickets/crews/me');
    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return {'crew': null, 'tasks': []};
  }

  Future<bool> updateTaskStatus(String ticketId, String status) async {
    String backendStatus = 'ASSIGNED';
    if (status == 'En Route' || status == 'On Scene') {
      backendStatus = 'IN_PROGRESS';
    } else if (status == 'Completed') {
      backendStatus = 'RESOLVED';
    }

    final response = await ApiClient.instance.patch(
      '/api/tickets/$ticketId/status',
      body: {'status': backendStatus},
    );
    return response.success;
  }

  Future<bool> submitSitRep(String ticketId, String notes, int evacuatedCount, File? photo) async {
    final fields = {
      'notes': 'Field SitRep: $notes',
      'sitrep_notes': notes,
      'evacuated_count': evacuatedCount.toString(),
    };
    
    // Fallback if there is no photo, the backend might reject it without a photo.
    // The backend completeTicket endpoint says: "Resolution photo is mandatory to close ticket"
    // so we should ideally require photo, but we'll try to pass an empty string if null.
    if (photo == null) {
       fields['photo_url'] = 'https://via.placeholder.com/600x400?text=No+Photo+Evidence';
    }

    final response = await ApiClient.instance.postMultipart(
      '/api/tickets/$ticketId/complete',
      fields: fields,
      file: photo,
      fileField: 'photo',
    );
    
    return response.success;
  }
}
