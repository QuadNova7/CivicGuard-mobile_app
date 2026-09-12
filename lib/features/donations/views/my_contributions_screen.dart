import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class ContributionItem {
  final String title;
  final String category;
  final String quantity;
  final String location;
  final String date;
  final String status;
  final Color statusColor;
  final Color statusBg;

  const ContributionItem({
    required this.title,
    required this.category,
    required this.quantity,
    required this.location,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.statusBg,
  });
}

class MyContributionsScreen extends StatelessWidget {
  const MyContributionsScreen({super.key});

  static const List<ContributionItem> contributions = [
    ContributionItem(
      title: 'Bottled Water (500ml)',
      category: 'Food & Water',
      quantity: '50 Bottles',
      location: 'Kandy, Sri Lanka',
      date: 'Today, 11:25 AM',
      status: 'Pending Verification',
      statusColor: Color(0xFFD97706),
      statusBg: Color(0xFFFEF3C7),
    ),
    ContributionItem(
      title: 'Warm Blankets & Towels',
      category: 'Clothing & Blankets',
      quantity: '20 Packs',
      location: 'Peradeniya',
      date: 'Yesterday',
      status: 'Verified',
      statusColor: Color(0xFF0284C7),
      statusBg: Color(0xFFE0F2FE),
    ),
    ContributionItem(
      title: 'First Aid Medical Kits',
      category: 'Medical Supplies',
      quantity: '15 Boxes',
      location: 'Colombo 07',
      date: '10 Aug 2026',
      status: 'Allocated',
      statusColor: Color(0xFF16A34A),
      statusBg: Color(0xFFDCFCE7),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
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
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: contributions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final item = contributions[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2B48).withOpacity(0.025),
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
                    Text(
                      item.category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0284C7),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
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
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.layers_outlined, size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      item.quantity,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Submitted: ${item.date}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
