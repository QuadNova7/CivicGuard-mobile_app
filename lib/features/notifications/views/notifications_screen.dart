import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class NotificationItem {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isUnread;

  const NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.isUnread = false,
  });
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const List<NotificationItem> notifications = [
    NotificationItem(
      title: 'High Priority Alert: Flood Response',
      message: 'Operations center deployed response units to Peradeniya sector.',
      time: '10m ago',
      icon: Icons.emergency_rounded,
      iconColor: Color(0xFFEF4444),
      iconBg: Color(0xFFFEE2E2),
      isUnread: true,
    ),
    NotificationItem(
      title: 'Volunteer Activity Confirmed',
      message: 'You have successfully joined the Flood Relief Support event.',
      time: '1h ago',
      icon: Icons.check_circle_rounded,
      iconColor: Color(0xFF16A34A),
      iconBg: Color(0xFFDCFCE7),
      isUnread: true,
    ),
    NotificationItem(
      title: 'Donation Received for Verification',
      message: 'Your contribution of 50 Bottles of water is being verified.',
      time: '3h ago',
      icon: Icons.inventory_2_rounded,
      iconColor: Color(0xFF0284C7),
      iconBg: Color(0xFFE0F2FE),
      isUnread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = notifications[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: item.isUnread ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                width: item.isUnread ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2B48).withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Text(
                            item.time,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
