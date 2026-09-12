import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/request_category_model.dart';

class IssueCategoryCard extends StatelessWidget {
  final RequestCategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const IssueCategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 32,
              color: isSelected ? AppColors.primaryNavy : AppColors.primaryBlue,
            ),
            const SizedBox(height: 12),
            Text(
              category.title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primaryNavy : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
