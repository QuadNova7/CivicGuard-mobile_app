import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class AuthRoleSelectionDialog extends StatefulWidget {
  final String? redirectPath;

  const AuthRoleSelectionDialog({
    super.key,
    this.redirectPath,
  });

  static Future<void> show(BuildContext context, {String? redirectPath}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AuthRoleSelectionDialog(redirectPath: redirectPath),
    );
  }

  @override
  State<AuthRoleSelectionDialog> createState() => _AuthRoleSelectionDialogState();
}

class _AuthRoleSelectionDialogState extends State<AuthRoleSelectionDialog> {
  // 0: Role Selection, 1: Community Volunteer Actions
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _step == 1 ? _buildVolunteerView() : _buildRoleSelectionView(),
          ),
        ),
      ),
    );
  }

  // STEP 0: Role Selection (Volunteer vs Response Crew)
  Widget _buildRoleSelectionView() {
    return Column(
      key: const ValueKey(0),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF0284C7), size: 20),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Select Account Role',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your account type to proceed:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),

        // 1. Community Volunteer Card
        _buildRoleChoiceCard(
          title: 'Community Volunteer',
          subtitle: 'Aid distribution & community relief support',
          badgeText: 'Login or Register',
          badgeBg: const Color(0xFFDCFCE7),
          badgeColor: const Color(0xFF16A34A),
          icon: Icons.volunteer_activism_rounded,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFFDCFCE7),
          onTap: () => setState(() => _step = 1),
        ),

        const SizedBox(height: 12),

        // 2. Emergency Response Crew Card (DIRECT LOGIN ONLY)
        _buildRoleChoiceCard(
          title: 'Emergency Response Crew',
          subtitle: 'Tactical squads (Water rescue, 4x4, Medical)',
          badgeText: 'Login Only',
          badgeBg: const Color(0xFFE0F2FE),
          badgeColor: const Color(0xFF0284C7),
          icon: Icons.emergency_rounded,
          iconColor: const Color(0xFF0284C7),
          iconBg: const Color(0xFFE0F2FE),
          onTap: () {
            Navigator.pop(context);
            final redirect = widget.redirectPath ?? '/crew-assignments';
            context.push('/login?tab=0&role=FIELD_CREW&redirect=' + Uri.encodeComponent(redirect));
          },
        ),
      ],
    );
  }

  // STEP 1: Community Volunteer Options (Sign In or Register)
  Widget _buildVolunteerView() {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _step = 0),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.primaryNavy),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Community Volunteer',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Select an option to proceed:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Action 1: Sign In
        _buildActionOptionCard(
          title: 'Sign In to Account',
          subtitle: 'Access your existing volunteer profile',
          icon: Icons.login_rounded,
          iconColor: const Color(0xFF0284C7),
          iconBg: const Color(0xFFE0F2FE),
          onTap: () {
            Navigator.pop(context);
            final redirect = widget.redirectPath ?? '/main';
            context.push('/login?tab=0&role=COMMUNITY_VOLUNTEER&redirect=' + Uri.encodeComponent(redirect));
          },
        ),

        const SizedBox(height: 10),

        // Action 2: Register as Volunteer
        _buildActionOptionCard(
          title: 'Register as Volunteer',
          subtitle: 'Create a new verified volunteer account in your district',
          icon: Icons.person_add_rounded,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFFDCFCE7),
          onTap: () {
            Navigator.pop(context);
            final redirect = widget.redirectPath ?? '/main';
            context.push('/login?tab=1&role=COMMUNITY_VOLUNTEER&redirect=' + Uri.encodeComponent(redirect));
          },
        ),
      ],
    );
  }

  Widget _buildRoleChoiceCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
