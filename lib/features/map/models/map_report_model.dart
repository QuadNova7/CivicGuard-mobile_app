class MapReportModel {
  final String id;
  final String title;
  final String location;
  final String status;
  final String timeAgo;
  final double latitude;
  final double longitude;

  const MapReportModel({
    required this.id,
    required this.title,
    required this.location,
    required this.status,
    required this.timeAgo,
    required this.latitude,
    required this.longitude,
  });
}
