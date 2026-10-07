import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/services/auth_service.dart';

class GreetingHeader extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const GreetingHeader({
    super.key,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        final user = AuthService.instance.currentUser;
        final isLoggedIn = AuthService.instance.isLoggedIn;
        final name = isLoggedIn && user != null
            ? (user.name.split(' ').first)
            : 'Citizen';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Bar: Logo + Brand Name on Left, Notification + Modern Profile Icon on Right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Brand: Logo Badge + "CivicGuard" + LIVE Indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F2B48), Color(0xFF1E40AF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F2B48).withValues(alpha: 0.22),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CivicGuard',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F2B48),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF16A34A),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Notification Bell + Clean Modern Profile Icon
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_outlined,
                            size: 23,
                            color: Color(0xFF0F2B48),
                          ),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          onPressed: onNotificationTap ?? () => context.push('/notifications'),
                        ),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Clean Profile Avatar Icon Button (No photo image)
                    GestureDetector(
                      onTap: onProfileTap ?? () => context.push('/profile'),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF1F5F9),
                          border: Border.all(
                            color: isLoggedIn ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                            width: 1.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F2B48).withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isLoggedIn ? Icons.person_rounded : Icons.person_outline_rounded,
                            size: 20,
                            color: isLoggedIn ? const Color(0xFF0F2B48) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 2. Welcoming Headline (Replaced 'Good evening')
            Row(
              children: [
                Text(
                  isLoggedIn ? 'Welcome back, $name' : 'Welcome, $name',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F2B48),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(width: 5),
                const Text('👋', style: TextStyle(fontSize: 19)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              "Let's make your community safe & resilient.",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        );
      },
    );
  }
}
