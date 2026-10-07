import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? category.iconBgColor.withValues(alpha: 0.35) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? category.activeBorderColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2.2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? category.iconColor.withValues(alpha: 0.18)
                  : const Color(0xFF0F2B48).withValues(alpha: 0.04),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Selected Checkmark Badge (Top-Right)
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: category.iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),

            // Card Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Colorful Icon Container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: category.iconBgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: category.iconColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      category.icon,
                      size: 26,
                      color: category.iconColor,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Category Title
                  Text(
                    category.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                      color: isSelected ? const Color(0xFF0F2B48) : const Color(0xFF334155),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
