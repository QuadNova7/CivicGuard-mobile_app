import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/volunteer_activity_model.dart';

class VolunteerScreen extends StatefulWidget {
  const VolunteerScreen({super.key});

  @override
  State<VolunteerScreen> createState() => _VolunteerScreenState();
}

class _VolunteerScreenState extends State<VolunteerScreen> {
  bool _isOngoing = true;

  final List<VolunteerActivityModel> _activities = const [
    VolunteerActivityModel(
      title: 'Flood Relief Support',
      location: 'Colombo',
      date: 'Sat, 12 Aug 2026',
      neededCount: 12,
    ),
    VolunteerActivityModel(
      title: 'Community Clean-up',
      location: 'Nugegoda',
      date: 'Sun, 20 Aug 2026',
      neededCount: 8,
    ),
    VolunteerActivityModel(
      title: 'Awareness Campaign',
      location: 'Gampaha',
      date: 'Sat, 26 Aug 2026',
      neededCount: 15,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Volunteer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Photo Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2B48), Color(0xFF1E5BB0)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Make a Difference', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Join hands for a safer tomorrow.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tabs: Ongoing | Past
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isOngoing = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isOngoing ? AppColors.primaryNavy : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Ongoing',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _isOngoing ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() => _isOngoing = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isOngoing ? AppColors.primaryNavy : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Past',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: !_isOngoing ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Volunteer Cards List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _activities[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.accentGreen, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: AppTextStyles.bodyLarge.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(item.location, style: AppTextStyles.bodySmall),
                            Text('${item.date} • ${item.neededCount} needed', style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(64, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Join', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
