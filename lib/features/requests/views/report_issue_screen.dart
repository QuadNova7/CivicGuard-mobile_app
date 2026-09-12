import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../models/request_category_model.dart';
import 'widgets/issue_category_card.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  String _selectedCategory = 'Road Hazard';

  final List<RequestCategoryModel> _categories = const [
    RequestCategoryModel(
      id: 'road',
      title: 'Road Hazard',
      icon: Icons.warning_amber_rounded,
      iconColor: Color(0xFFEA580C),
      iconBgColor: Color(0xFFFFEDD5),
      activeBorderColor: Color(0xFFF97316),
    ),
    RequestCategoryModel(
      id: 'flood',
      title: 'Flooding',
      icon: Icons.water_drop_rounded,
      iconColor: Color(0xFF0284C7),
      iconBgColor: Color(0xFFE0F2FE),
      activeBorderColor: Color(0xFF0284C7),
    ),
    RequestCategoryModel(
      id: 'power',
      title: 'Power Outage',
      icon: Icons.bolt_rounded,
      iconColor: Color(0xFFD97706),
      iconBgColor: Color(0xFFFEF3C7),
      activeBorderColor: Color(0xFFF59E0B),
    ),
    RequestCategoryModel(
      id: 'landslide',
      title: 'Landslide',
      icon: Icons.landscape_rounded,
      iconColor: Color(0xFFDC2626),
      iconBgColor: Color(0xFFFEE2E2),
      activeBorderColor: Color(0xFFEF4444),
    ),
    RequestCategoryModel(
      id: 'safety',
      title: 'Public Safety',
      icon: Icons.shield_rounded,
      iconColor: Color(0xFF16A34A),
      iconBgColor: Color(0xFFDCFCE7),
      activeBorderColor: Color(0xFF22C55E),
    ),
    RequestCategoryModel(
      id: 'other',
      title: 'Other',
      icon: Icons.more_horiz_rounded,
      iconColor: Color(0xFF6366F1),
      iconBgColor: Color(0xFFEEF2FF),
      activeBorderColor: Color(0xFF6366F1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Report an Issue',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF0F2B48),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Progress Bar (Step 1 of 3)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                'What would you like to report?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F2B48),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a category to begin verification',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 18),

              // 6 Colorful Category Cards
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return IssueCategoryCard(
                      category: cat,
                      isSelected: _selectedCategory == cat.title,
                      onTap: () => setState(() => _selectedCategory = cat.title),
                    );
                  },
                ),
              ),

              // Next Button
              AppButton(
                text: 'Next',
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                onPressed: () {
                  context.push('/issue-details', extra: _selectedCategory);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
