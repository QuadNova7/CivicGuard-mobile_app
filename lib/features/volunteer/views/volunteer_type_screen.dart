import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/views/dialogs/auth_role_dialog.dart';

class VolunteerTypeScreen extends StatelessWidget {
  const VolunteerTypeScreen({super.key});

  void _navigateToCommunityVolunteer(BuildContext context) {
    if (!AuthService.instance.isLoggedIn) {
      context.push('/login?tab=0&role=COMMUNITY_VOLUNTEER&redirect=' + Uri.encodeComponent('/community-volunteer'));
    } else {
      context.push('/community-volunteer');
    }
  }

  void _navigateToResponseCrew(BuildContext context) {
    if (!AuthService.instance.isLoggedIn) {
      context.push('/login?tab=0&role=FIELD_CREW&redirect=' + Uri.encodeComponent('/crew-assignments'));
    } else if (!AuthService.instance.currentUser!.isFieldCrew) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please sign in with your Response Crew account to access tactical dispatches.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primaryNavy,
          duration: const Duration(seconds: 2),
        ),
      );
      context.push('/login?tab=0&role=FIELD_CREW&redirect=' + Uri.encodeComponent('/crew-assignments'));
    } else {
      context.push('/crew-assignments');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go('/main');
            }
          },
        ),
        title: Text(
          'Volunteer & Field Response',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white, size: 22),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sleek Status / Auth Ribbon
              _buildAuthStatusRibbon(context),

              const SizedBox(height: 10),

              // 2. Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Select your operational track to support disaster relief:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 3. Card 1: Community Volunteer
              _buildCompactTrackCard(
                context: context,
                title: 'Community Volunteer',
                tag: 'Open to All Citizens',
                tagBg: const Color(0xFFDCFCE7),
                tagColor: const Color(0xFF16A34A),
                icon: Icons.volunteer_activism_rounded,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                subtitle: 'Distribute dry rations, local aid & assist in relief shelters.',
                bullets: [
                  'Distribute food, water & medical care packs',
                  'Support nearest relief shelters in your district',
                ],
                buttonText: 'Join Community Efforts',
                buttonColor: const Color(0xFF16A34A),
                onTap: () => _navigateToCommunityVolunteer(context),
              ),

              const SizedBox(height: 12),

              // 4. Card 2: Emergency Response Crew
              _buildCompactTrackCard(
                context: context,
                title: 'Emergency Response Crew',
                tag: 'Tactical Certification',
                tagBg: const Color(0xFFE0F2FE),
                tagColor: const Color(0xFF0284C7),
                icon: Icons.emergency_rounded,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                subtitle: 'Specialized rescue units responding to officer dispatches.',
                bullets: [
                  'Water rescue, 4x4 winching & medical triage',
                  'Ground SitRep, GPS tracking & incident closure',
                ],
                buttonText: 'Enter Crew Command',
                buttonColor: AppColors.primaryNavy,
                onTap: () => _navigateToResponseCrew(context),
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthStatusRibbon(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        final user = AuthService.instance.currentUser;
        final isLoggedIn = AuthService.instance.isLoggedIn;

        if (!isLoggedIn || user == null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Guest Mode: Sign in to log and sync relief missions.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => AuthRoleSelectionDialog.show(context, redirectPath: '/volunteer-type'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Signed in: \ (\)' + (user.crewName != null ? ' • ' : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF166534),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => AuthService.instance.logout(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.logout_rounded, color: Color(0xFF166534), size: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactTrackCard({
    required BuildContext context,
    required String title,
    required String tag,
    required Color tagBg,
    required Color tagColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String subtitle,
    required List<String> bullets,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Icon + Title + Tag
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),

          // Key Bullets
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 10),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
