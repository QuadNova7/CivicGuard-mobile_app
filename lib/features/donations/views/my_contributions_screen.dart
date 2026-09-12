import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/services/local_cache_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/services/auth_service.dart';

class ContributionItem {
  final String title;
  final String category;
  final String quantity;
  final String location;
  final String? helpRequestDesc;
  final String date;
  final String status;
  final Color statusColor;
  final Color statusBg;

  const ContributionItem({
    required this.title,
    required this.category,
    required this.quantity,
    required this.location,
    this.helpRequestDesc,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.statusBg,
  });

  factory ContributionItem.fromJson(Map<String, dynamic> json) {
    final type = json['resource_type']?.toString().toUpperCase() ?? 'FOOD';
    final statusStr = json['status']?.toString().toUpperCase() ?? 'AVAILABLE';
    final shelterName = json['shelter_name']?.toString() ?? 'Central Relief Shelter';
    final helpDesc = json['help_request_desc']?.toString();

    String cat = 'Food & Water';
    if (type.contains('MEDIC')) {
      cat = 'Medical Supplies';
    } else if (type.contains('BED') || type.contains('CLOTH')) {
      cat = 'Clothing & Blankets';
    }

    String displayStatus = 'Received & Available';
    Color sColor = const Color(0xFF0284C7);
    Color sBg = const Color(0xFFE0F2FE);

    if (statusStr == 'ASSIGNED') {
      displayStatus = 'Allocated to Emergency Shelters';
      sColor = const Color(0xFF16A34A);
      sBg = const Color(0xFFDCFCE7);
    } else if (statusStr == 'DEPLETED') {
      displayStatus = 'Distributed to Displaced Victims';
      sColor = const Color(0xFF64748B);
      sBg = const Color(0xFFF1F5F9);
    }

    String dateStr = 'Recent';
    if (json['created_at'] != null) {
      try {
        final dt = DateTime.parse(json['created_at'].toString()).toLocal();
        dateStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return ContributionItem(
      title: json['resource_name']?.toString() ?? 'Relief Supply Item',
      category: cat,
      quantity: '${json['quantity'] ?? 1} ${json['unit'] ?? 'Units'}',
      location: shelterName,
      helpRequestDesc: helpDesc,
      date: dateStr,
      status: displayStatus,
      statusColor: sColor,
      statusBg: sBg,
    );
  }
}

class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({super.key});

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen> {
  bool _isLoading = true;
  List<ContributionItem> _contributions = [];

  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_onAuthChanged);
    _loadLocalFirstThenFetch();
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      _loadLocalFirstThenFetch();
    }
  }

  Future<void> _loadLocalFirstThenFetch() async {
    // 1. Instant Offline-First Cache Load
    final cached = await LocalCacheService.instance.getCachedDonations();
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _contributions = cached.map((e) => ContributionItem.fromJson(e)).toList();
        _isLoading = false;
      });
    }

    // 2. Network Fetch from Supabase via Relief Microservice
    await _fetchContributions();
  }

  Future<void> _fetchContributions() async {
    final user = AuthService.instance.currentUser;
    final queryParams = <String, String>{};
    if (user != null && user.id.isNotEmpty) {
      queryParams['user_id'] = user.id;
    }

    final res = await ApiClient.instance.get(
      ApiConfig.reliefResources,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (!mounted) return;

    if (res.success && res.data is Map) {
      final list = res.data['resources'];
      if (list is List) {
        final mapped = list.map((i) => ContributionItem.fromJson(i as Map<String, dynamic>)).toList();
        setState(() {
          _contributions = mapped;
          _isLoading = false;
        });

        // Update local cache
        await LocalCacheService.instance.saveDonations(
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
        return;
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Contributions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Donor Account Header Ribbon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Icon(Icons.volunteer_activism_rounded, color: Color(0xFF16A34A), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user != null ? '${user.name} (${user.district})' : 'Verified Relief Contributor',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Live Supabase records of your emergency donation pledges',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_contributions.length} Pledged',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy))
                : RefreshIndicator(
                    onRefresh: _fetchContributions,
                    color: AppColors.primaryNavy,
                    child: _contributions.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 100),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.6)),
                                    const SizedBox(height: 14),
                                    Text(
                                      'No donation pledges recorded yet',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32),
                                      child: Text(
                                        'Your submitted relief donations will be recorded directly into the central database and shown here.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: () => context.push('/donate-categories'),
                                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                      label: const Text('Donate Supplies Now'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryNavy,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            itemCount: _contributions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _contributions[index];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: item.statusBg,
                                          child: Icon(
                                            Icons.inventory_2_rounded,
                                            color: item.statusColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      item.category,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: const Color(0xFF475569),
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    item.date,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 11,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: item.statusBg,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            item.status,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: item.statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),
                                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                    const SizedBox(height: 10),

                                    // Quantity & Target Shelter Info
                                    Row(
                                      children: [
                                        const Icon(Icons.tag_rounded, size: 16, color: Color(0xFF64748B)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Quantity: ',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                        Text(
                                          item.quantity,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.domain_rounded, size: 16, color: Color(0xFF0284C7)),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            item.location,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF0284C7),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Linked SOS Request If Any
                                    if (item.helpRequestDesc != null && item.helpRequestDesc!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF1F2),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFFECDD3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.emergency_rounded, size: 14, color: Color(0xFFE11D48)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Fulfilling SOS Request: ${item.helpRequestDesc}',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF9F1239),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
}
