class ApiConfig {
  ApiConfig._();

  /// Gateway Base URL (Laptop LAN IP on Wi-Fi router: 192.168.8.100)
  static String baseUrl = 'http://192.168.8.100:8000';

  /// Socket.IO URL for live notifications & alerts
  static String socketUrl = 'http://192.168.8.100:4003';

  static void setBaseIp(String ip) {
    if (ip.isNotEmpty) {
      baseUrl = 'http://$ip:8000';
      socketUrl = 'http://$ip:4003';
    }
  }

  // --- Service Endpoint Paths ---
  
  // Auth
  static const String authRegister = '/api/incidents/auth/register';
  static const String authLogin = '/api/incidents/auth/login';
  static const String authMe = '/api/incidents/auth/me';

  // Incidents
  static const String incidentsList = '/api/incidents';
  static const String incidentsMapHazards = '/api/incidents/map/hazards';
  static const String incidentsReport = '/api/incidents/reports';
  static const String incidentsSafePath = '/api/incidents/routes/safe-path';
  static String incidentCorroborate(String id) => '/api/incidents/' + id + '/corroborate';

  // Relief, SOS & Shelters
  static const String reliefShelters = '/api/relief/shelters';
  static const String reliefHelpRequests = '/api/relief/help-requests';
  static const String reliefMatchShelter = '/api/relief/match-shelter';
  static const String reliefResources = '/api/relief/resources';
  static const String reliefSimulateSos = '/api/relief/simulate-sos';

  // Community Volunteer Hub
  static const String volunteerOpportunities = '/api/relief/volunteers/opportunities';
  static const String volunteerJoin = '/api/relief/volunteers/join';
  static const String volunteerMyActivities = '/api/relief/volunteers/my-activities';

  // Tickets & Crew Dispatches
  static const String ticketsList = '/api/tickets';
  static String ticketComplete(String id) => '/api/tickets/' + id + '/complete';
  static String crewLocation(String crewId) => '/api/tickets/crews/' + crewId + '/location';
  static String crewSos(String crewId) => '/api/tickets/crews/' + crewId + '/sos';

  // Notifications
  static String userNotifications(String userId) => '/api/notifications/user/' + userId;

  /// Helper to get full URL
  static String url(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return baseUrl + path;
  }
}
