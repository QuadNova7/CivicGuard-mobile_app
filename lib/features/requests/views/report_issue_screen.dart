import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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
    RequestCategoryModel(id: 'road', title: 'Road Hazard', icon: Icons.warning_amber_rounded),
    RequestCategoryModel(id: 'flood', title: 'Flooding', icon: Icons.water_drop_outlined),
    RequestCategoryModel(id: 'power', title: 'Power Outage', icon: Icons.bolt_outlined),
    RequestCategoryModel(id: 'landslide', title: 'Landslide', icon: Icons.landscape_outlined),
    RequestCategoryModel(id: 'safety', title: 'Public Safety', icon: Icons.shield_outlined),
    RequestCategoryModel(id: 'other', title: 'Other', icon: Icons.more_horiz_rounded),
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
        title: const Text('Report an Issue'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Progress Dots (Step 1 of 3)
              Row(
                children: [
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.primaryNavy, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 6),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 6),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                ],
              ),

              const SizedBox(height: 24),

              Text('What would you like to report?', style: AppTextStyles.headingMedium),
              const SizedBox(height: 4),
              Text('Select a category', style: AppTextStyles.bodyMedium),

              const SizedBox(height: 20),

              // 6 Category Grid
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
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
