import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/home_update_model.dart';
import 'widgets/greeting_header.dart';
import 'widgets/home_banner.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/recent_update_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Clean Light Surface (#F9FBFC)
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // 1. Top Bar: Location & Header Greeting
              const GreetingHeader(),

              const SizedBox(height: 18),

              // 2. Top Two Big Primary Action Cards (Red & Green)
              Row(
                children: [
                  // Left Card: Report an Issue (Solid Coral Red)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/report-issue'),
                      child: Container(
                        height: 170,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.reportCardRed,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.reportCardRed.withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Report an Issue',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'See something\nReport it',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.90),
                                fontSize: 11.5,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Right Card: Volunteer / Contribute (Solid Emerald Green)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/contribute'),
                      child: Container(
                        height: 170,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.volunteerCardGreen,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.volunteerCardGreen.withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_alt_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Volunteer',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the change',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.90),
                                fontSize: 11.5,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. Three White Quick Action Cards
              Row(
                children: [
                  QuickActionCard(
                    icon: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 24),
                    title: 'Donate',
                    subtitle: 'Support relief\nefforts',
                    onTap: () => context.push('/donate-categories'),
                  ),
                  const SizedBox(width: 10),
                  QuickActionCard(
                    icon: const Icon(Icons.assignment_outlined, color: Color(0xFF0F3E68), size: 24),
                    title: 'Track Reports',
                    subtitle: 'Check status',
                    onTap: () => context.push('/my-reports'),
                  ),
                  const SizedBox(width: 10),
                  QuickActionCard(
                    icon: const Icon(Icons.location_on_rounded, color: Color(0xFF0284C7), size: 24),
                    title: 'Nearby',
                    subtitle: 'View on map',
                    onTap: () => context.push('/map'),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 4. Hero Rotating Photo Banner
              const HomeBanner(),

              const SizedBox(height: 20),

              // 5. Recent Updates Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Updates',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F2B48),
                      letterSpacing: -0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/map'),
                    child: Text(
                      'View All',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF1E5BB0),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const RecentUpdateCard(
                update: HomeUpdateModel(
                  title: 'Road blockage cleared',
                  location: 'Galle Road, Colombo',
                  status: 'Resolved',
                  timeAgo: '2 hours ago',
                  imageUrl: 'assets/images/1.jpg',
                ),
              ),

              // Extra scroll margin
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }
}
