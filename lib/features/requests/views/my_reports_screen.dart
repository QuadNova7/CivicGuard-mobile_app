import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/local_cache_service.dart';

class IncidentReportItem {
  final String id;
  final String? ticketId;
  final String title;
  final String category;
  final String location;
  final String date;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final IconData icon;

  const IncidentReportItem({
    required this.id,
    this.ticketId,
    required this.title,
    required this.category,
    required this.location,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.icon,
  });

  factory IncidentReportItem.fromJson(Map<String, dynamic> json) {
    final type = json['incident_type']?.toString().toUpperCase() ?? 'HAZARD';
    final statusStr = json['status']?.toString().toUpperCase() ?? 'REPORTED';
    final roadName = json['roads'] is Map ? json['roads']['name']?.toString() : null;
    final wardName = json['wards'] is Map ? json['wards']['name']?.toString() : null;
    final locationName = roadName ?? wardName ?? 'Moratuwa Galle Road';

    String cat = 'Public Safety';
    IconData ic = Icons.shield_outlined;
    if (type.contains('FLOOD')) {
      cat = 'Flooding';
      ic = Icons.water_drop_outlined;
    } else if (type.contains('ROAD') || type.contains('BLOCK') || type.contains('DAMAGE')) {
      cat = 'Road Hazard';
      ic = Icons.alt_route_rounded;
    } else if (type.contains('TREE') || type.contains('FALLEN')) {
      cat = 'Fallen Tree';
      ic = Icons.park_outlined;
    } else if (type.contains('LANDSLIDE')) {
      cat = 'Landslide';
      ic = Icons.landscape_outlined;
    } else if (type.contains('POWER')) {
      cat = 'Power Outage';
      ic = Icons.bolt_rounded;
    }

    String displayStatus = 'Under AI Analysis';
    Color sColor = const Color(0xFFD97706);
    Color sBg = const Color(0xFFFEF3C7);

    if (statusStr == 'CONFIRMED') {
      displayStatus = 'Confirmed Hazard';
      sColor = const Color(0xFFDC2626);
      sBg = const Color(0xFFFEE2E2);
    } else if (statusStr == 'IN_PROGRESS' || statusStr == 'DISPATCHED') {
      displayStatus = 'Crew Dispatched';
      sColor = const Color(0xFF0284C7);
      sBg = const Color(0xFFE0F2FE);
    } else if (statusStr == 'RESOLVED') {
      displayStatus = 'Resolved & Safe';
      sColor = const Color(0xFF16A34A);
      sBg = const Color(0xFFDCFCE7);
    }

    String dateStr = 'Just Now';
    if (json['created_at'] != null) {
      try {
        final dt = DateTime.parse(json['created_at'].toString()).toLocal();
        dateStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    final rawId = json['id']?.toString() ?? '00000000';
    final shortId = rawId.length > 8 ? rawId.substring(0, 8) : rawId;
    final ticket = json['ticket_id']?.toString() ?? 'TKT-$shortId';

    return IncidentReportItem(
      id: shortId,
      ticketId: ticket,
      title: json['description']?.toString().isNotEmpty == true
          ? json['description'].toString()
          : (json['title']?.toString().isNotEmpty == true
              ? json['title'].toString()
              : 'Citizen reported $cat with photo verification.'),
      category: cat,
      location: locationName,
      date: dateStr,
      status: displayStatus,
      statusColor: sColor,
      statusBg: sBg,
      icon: ic,
    );
  }
}

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  int _selectedFilter = 0; // 0 = All, 1 = Active/Verified, 2 = Resolved
  bool _isLoading = true;
  List<IncidentReportItem> _reports = [];

  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_onAuthChanged);
    _loadLocalThenFetch();
  }

  Future<void> _loadLocalThenFetch() async {
    // 1. Instant load from local user-submitted reports
    final localReports = await LocalCacheService.instance.getSubmittedReports();
    if (mounted) {
      setState(() {
        _reports = localReports.map((item) => IncidentReportItem.fromJson(item)).toList();
        _isLoading = false;
      });
    }

    // 2. If user is signed in, fetch user-specific reports from backend
    await _fetchReports();
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      _loadLocalThenFetch();
    }
  }

  Future<void> _fetchReports() async {
    final currentUser = AuthService.instance.currentUser;
    
    // Only query backend if user is logged in with valid ID
    if (currentUser != null && currentUser.id.isNotEmpty) {
      try {
        final res = await ApiClient.instance.get(
          ApiConfig.incidentsList,
          queryParams: {'reported_by': currentUser.id},
        );

        if (res.success && res.data is Map && res.data['incidents'] is List && mounted) {
          final list = res.data['incidents'] as List;
          final remoteItems = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          
          // Merge with local submissions
          final localReports = await LocalCacheService.instance.getSubmittedReports();
          final mergedMap = <String, Map<String, dynamic>>{};
          
          for (final item in localReports) {
            final key = item['id']?.toString() ?? '';
            if (key.isNotEmpty) mergedMap[key] = item;
          }
          for (final item in remoteItems) {
            final key = item['id']?.toString() ?? '';
            if (key.isNotEmpty) mergedMap[key] = item;
          }

          final mergedList = mergedMap.values.toList();
          await LocalCacheService.instance.saveSubmittedReports(mergedList);

          setState(() {
            _reports = mergedList.map((item) => IncidentReportItem.fromJson(item)).toList();
            _isLoading = false;
          });
          return;
        }
      } catch (_) {}
    }

    // For guest users: retain strictly local submitted reports
    final localReports = await LocalCacheService.instance.getSubmittedReports();
    if (mounted) {
      setState(() {
        _reports = localReports.map((item) => IncidentReportItem.fromJson(item)).toList();
        _isLoading = false;
      });
    }
  }

  List<IncidentReportItem> get _filteredReports {
    if (_selectedFilter == 1) {
      return _reports.where((r) => r.status != 'Resolved & Safe').toList();
    } else if (_selectedFilter == 2) {
      return _reports.where((r) => r.status == 'Resolved & Safe').toList();
    }
    return _reports;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false, // Prevents leading back button on bottom navigation tab
        title: Text(
          'My Reports',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF0F2B48),
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22, color: Color(0xFF0F2B48)),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchReports();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip(0, 'All Reports (${_reports.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    1,
                    'Active / Verified (${_reports.where((r) => r.status != 'Resolved & Safe').length})',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    2,
                    'Resolved (${_reports.where((r) => r.status == 'Resolved & Safe').length})',
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Reports List or Empty State
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F2B48)),
                      strokeWidth: 2.5,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchReports,
                    color: const Color(0xFF0F2B48),
                    child: _filteredReports.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 60),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                                      ),
                                      child: const Icon(
                                        Icons.assignment_turned_in_outlined,
                                        size: 40,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'No Reports Submitted Yet',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F2B48),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Reports you submit on this device will appear here with live AI verification and dispatch status.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: const Color(0xFF64748B),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () => context.push('/report-issue'),
                                      icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                                      label: Text(
                                        'Report an Issue',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0F2B48),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            itemCount: _filteredReports.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _filteredReports[index];
                              return Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F2B48).withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
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
                                            Icon(item.icon, size: 16, color: const Color(0xFF0284C7)),
                                            const SizedBox(width: 6),
                                            Text(
                                              item.category,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0284C7),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: item.statusBg,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            item.status,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: item.statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.title,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F2B48),
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            item.location,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: const Color(0xFF64748B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Ticket #${item.ticketId ?? item.id}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        Text(
                                          item.date,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F2B48) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F2B48) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
