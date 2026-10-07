import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Blues
  static const Color primaryNavy = Color(0xFF0F2B48);     // Main Navy Blue for buttons, FAB & headers
  static const Color primaryBlue = Color(0xFF1E5BB0);     // Secondary brand blue
  static const Color primaryGreen = Color(0xFF16A34A);    // Primary emerald green
  
  // Action Card Colors (Red & Green)
  static const Color reportCardRed = Color(0xFFE84C4C);   // Coral Red for Report an Issue
  static const Color alertCoral = Color(0xFFE84C4C);      // Alias for alertCoral
  static const Color alertCoralDark = Color(0xFFDC2626);
  
  static const Color volunteerCardGreen = Color(0xFF1EA855); // Rich Green for Volunteer
  static const Color accentGreen = Color(0xFF1EA855);        // Alias for accentGreen
  static const Color accentGreenDark = Color(0xFF16A34A);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF9FBFC);      // Ultra-clean light background
  static const Color surfaceWhite = Color(0xFFFFFFFF);    // White card background
  static const Color cardBackground = Color(0xFFFFFFFF);  // Card white alias
  static const Color surfaceMuted = Color(0xFFF1F5F9);    // Subtle grey background
  static const Color cardShadow = Color(0x0A0F2B48);

  // Borders & Dividers
  static const Color border = Color(0xFFEDF2F7);
  static const Color borderFocus = Color(0xFF0F2B48);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);      // Primary dark heading text
  static const Color textDark = Color(0xFF1E293B);        // Heading text
  static const Color textSecondary = Color(0xFF64748B);   // Body text
  static const Color textMuted = Color(0xFF94A3B8);       // Subtitle / helper text
  static const Color textLight = Color(0xFF94A3B8);       // Muted subtext alias

  // Category Icons & Badges
  static const Color hazardRoad = Color(0xFF0284C7);
  static const Color hazardFlood = Color(0xFF0284C7);
  static const Color hazardPower = Color(0xFFF59E0B);
  static const Color hazardLandslide = Color(0xFF0F172A);
  static const Color hazardSafety = Color(0xFF0F2B48);

  // Badges & Status Indicators
  static const Color statusResolvedBg = Color(0xFFDCFCE7);
  static const Color statusResolvedText = Color(0xFF16A34A);
  static const Color statusInProgressBg = Color(0xFFFEF3C7);
  static const Color statusInProgressText = Color(0xFFD97706);
}
