import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/services/auth_service.dart';

class VolunteerTypeScreen extends StatelessWidget {
  const VolunteerTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF0F2B48)),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'Volunteer & Response',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F2B48),
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.account_circle_outlined, size: 20, color: Color(0xFF0F2B48)),
            ),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sleek Modern Status Ribbon
              _buildModernStatusRibbon(context),

              const SizedBox(height: 12),

              // 2. Section Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  'Select your operational track to support disaster relief:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. Track 1: Community Volunteer (Ultra-Modern Emerald Glassmorphic Card)
              _buildUltraModernTrackCard(
                context: context,
                title: 'Community Volunteer',
                tag: '🌿 Open Volunteer Network',
                tagBg: const Color(0xFFDCFCE7),
                tagColor: const Color(0xFF15803D),
                tagBorder: const Color(0xFF86EFAC),
                icon: Icons.volunteer_activism_rounded,
                iconGradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                cardGradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF0FDF4)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderColor: const Color(0xFF10B981).withValues(alpha: 0.35),
                glowShadowColor: const Color(0xFF10B981).withValues(alpha: 0.10),
                subtitle: 'Distribute food rations, emergency shelter aid & assist displaced families.',
                featureChips: [
                  '📦 Food & Rations',
                  '🏥 Shelter Ops',
                  '🤝 On-Site Check-In',
                  '📜 Service Hours',
                ],
                buttonText: 'Join Community Efforts',
                buttonGradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                ),
                buttonShadowColor: const Color(0xFF10B981),
                onTap: () {
                  final isLoggedIn = AuthService.instance.isLoggedIn;
                  if (!isLoggedIn) {
                    _showVolunteerAuthModal(context);
                  } else {
                    context.push('/community-volunteer');
                  }
                },
              ),

              const SizedBox(height: 14),

              // 4. Track 2: Emergency Response Crew (Ultra-Modern Sapphire Tactical Card)
              _buildUltraModernTrackCard(
                context: context,
                title: 'Emergency Response Crew',
                tag: '🛡️ Tactical Certification',
                tagBg: const Color(0xFFDBEAFE),
                tagColor: const Color(0xFF1E40AF),
                tagBorder: const Color(0xFF93C5FD),
                icon: Icons.medical_services_rounded,
                iconGradient: const LinearGradient(
                  colors: [Color(0xFF0F2B48), Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                cardGradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF0F9FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderColor: const Color(0xFF2563EB).withValues(alpha: 0.35),
                glowShadowColor: const Color(0xFF1E40AF).withValues(alpha: 0.10),
                subtitle: 'Authorized municipal rescue squads executing real-time council dispatch orders.',
                featureChips: [
                  '🌊 Water Rescue',
                  '🚜 4x4 Heavy Winch',
                  '🚑 Medical Triage',
                  '📡 GPS Field SitRep',
                ],
                buttonText: 'Enter Crew Command',
                buttonGradient: const LinearGradient(
                  colors: [Color(0xFF0F2B48), Color(0xFF1E40AF)],
                ),
                buttonShadowColor: const Color(0xFF0F2B48),
                onTap: () {
                  final user = AuthService.instance.currentUser;
                  if (user != null && user.isFieldCrew) {
                    context.push('/crew-assignments');
                  } else {
                    _showCrewLockDialog(context);
                  }
                },
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatusRibbon(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        final user = AuthService.instance.currentUser;
        final isLoggedIn = AuthService.instance.isLoggedIn;

        if (!isLoggedIn || user == null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCD34D), width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE68A),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.lock_person_rounded, color: Color(0xFFB45309), size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volunteer Account Required',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                      Text(
                        'Sign in or register to join active squads.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showVolunteerAuthModal(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      'Sign In',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF86EFAC), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFBBF7D0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Signed In: ${user.name}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF166534),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Role: ${user.role}  •  District: ${user.district}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUltraModernTrackCard({
    required BuildContext context,
    required String title,
    required String tag,
    required Color tagBg,
    required Color tagColor,
    required Color tagBorder,
    required IconData icon,
    required LinearGradient iconGradient,
    required LinearGradient cardGradient,
    required Color borderColor,
    required Color glowShadowColor,
    required String subtitle,
    required List<String> featureChips,
    required String buttonText,
    required LinearGradient buttonGradient,
    required Color buttonShadowColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: glowShadowColor,
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFF0F2B48).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: 3D Squircle Icon + Title + Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: iconGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: buttonShadowColor.withValues(alpha: 0.32),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F2B48),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: tagBorder, width: 0.8),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
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

            const SizedBox(height: 10),

            // Subtitle Description
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // Modern Feature Chips Grid (2x2 Wrap)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: featureChips.map((chip) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    chip,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Modern Call-To-Action Button
            Container(
              width: double.infinity,
              height: 42,
              decoration: BoxDecoration(
                gradient: buttonGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: buttonShadowColor.withValues(alpha: 0.32),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // POPUP MODAL: Community Volunteer Auth Modal (Sign In / Register)
  void _showVolunteerAuthModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            // Emerald Beacon Icon
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 30),
            ),

            const SizedBox(height: 14),

            Text(
              'Community Volunteer Access',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F2B48),
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Sign in or register your account to join active relief squads, log field hours, and receive real-time operation briefings.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            // Option 1: Sign In
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2B48), Color(0xFF1E40AF)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2B48).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/login?tab=0&role=COMMUNITY_VOLUNTEER&redirect=/community-volunteer');
                },
                icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Sign In to Volunteer Account',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Option 2: Register
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981), width: 1.3),
              ),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/login?tab=1&role=COMMUNITY_VOLUNTEER&redirect=/community-volunteer');
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF059669), size: 18),
                label: Text(
                  'Register as New Volunteer',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCrewLockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF1E40AF), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Field Crew Access',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Emergency Response Crew Console requires official Municipal Council credentials. If you are an active crew member, please sign in.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/login?tab=0&role=FIELD_CREW&redirect=/crew-assignments');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2B48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Crew Login', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
