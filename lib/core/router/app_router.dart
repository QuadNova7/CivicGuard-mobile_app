import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/views/splash_screen.dart';
import '../../features/onboarding/views/language_selection_screen.dart';
import '../../features/main_navigation/views/main_navigation_screen.dart';
import '../../features/requests/views/report_issue_screen.dart';
import '../../features/requests/views/issue_details_screen.dart';
import '../../features/requests/views/my_reports_screen.dart';
import '../../features/contributions/views/contribute_screen.dart';
import '../../features/donations/views/donation_category_screen.dart';
import '../../features/donations/views/donate_supplies_form_screen.dart';
import '../../features/donations/views/donation_success_screen.dart';
import '../../features/donations/views/my_contributions_screen.dart';
import '../../features/volunteer/views/volunteer_type_screen.dart';
import '../../features/volunteer/views/community_volunteer_screen.dart';
import '../../features/volunteer/views/volunteer_opportunity_details_screen.dart';
import '../../features/volunteer/views/volunteer_joined_screen.dart';
import '../../features/crew/views/crew_assignments_screen.dart';
import '../../features/crew/views/crew_assignment_details_screen.dart';
import '../../features/map/views/nearby_reports_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/auth/views/login_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/language-selection',
      builder: (context, state) => const LanguageSelectionScreen(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        String? redirect;
        int tabIndex = 0;
        if (state.extra is Map<String, dynamic>) {
          final map = state.extra as Map<String, dynamic>;
          redirect = map['redirect'] as String?;
          tabIndex = (map['tab'] as int?) ?? 0;
        } else if (state.extra is String) {
          redirect = state.extra as String;
        } else if (state.uri.queryParameters.containsKey('tab')) {
          tabIndex = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          redirect = state.uri.queryParameters['redirect'];
        }
        return LoginScreen(redirectPath: redirect, initialTabIndex: tabIndex);
      },
    ),
    GoRoute(
      path: '/report-issue',
      builder: (context, state) => const ReportIssueScreen(),
    ),
    GoRoute(
      path: '/issue-details',
      builder: (context, state) {
        final category = state.extra as String? ?? 'Road Hazard';
        return IssueDetailsScreen(category: category);
      },
    ),
    GoRoute(
      path: '/my-reports',
      builder: (context, state) => const MyReportsScreen(),
    ),

    // 1. Contribute Hub (Make a Difference)
    GoRoute(
      path: '/contribute',
      builder: (context, state) => const ContributeScreen(),
    ),

    // 2. Physical Donations Flow
    GoRoute(
      path: '/donate-categories',
      builder: (context, state) => const DonationCategoryScreen(),
    ),
    GoRoute(
      path: '/donations',
      builder: (context, state) => const DonationCategoryScreen(),
    ),
    GoRoute(
      path: '/donate-item-form',
      builder: (context, state) {
        String category = 'Food & Water';
        int? iconCode;
        int? iconColorValue;
        if (state.extra is Map<String, dynamic>) {
          final map = state.extra as Map<String, dynamic>;
          category = map['category'] as String? ?? 'Food & Water';
          iconCode = map['iconCode'] as int?;
          iconColorValue = map['iconColor'] as int?;
        } else if (state.extra is String) {
          category = state.extra as String;
        }
        return DonateSuppliesFormScreen(
          category: category,
          iconCode: iconCode,
          iconColorValue: iconColorValue,
        );
      },
    ),
    GoRoute(
      path: '/donation-success',
      builder: (context, state) {
        final map = (state.extra as Map<String, dynamic>?) ?? {};
        return DonationSuccessScreen(
          category: map['category'] as String? ?? 'Food & Water',
          itemName: map['itemName'] as String? ?? 'Bottled Water',
          quantity: map['quantity'] as String? ?? '50 Bottles',
          location: map['location'] as String? ?? 'Kandy, Sri Lanka',
          description: map['description'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/my-contributions',
      builder: (context, state) => const MyContributionsScreen(),
    ),

    // 3. Volunteer Flow (Community Volunteer vs Response Crew)
    GoRoute(
      path: '/volunteer-type',
      builder: (context, state) => const VolunteerTypeScreen(),
    ),
    GoRoute(
      path: '/volunteer',
      builder: (context, state) => const VolunteerTypeScreen(),
    ),
    GoRoute(
      path: '/community-volunteer',
      builder: (context, state) {
        final initialTab = (state.extra as int?) ?? 0;
        return CommunityVolunteerScreen(initialTabIndex: initialTab);
      },
    ),
    GoRoute(
      path: '/volunteer-opportunity-details',
      builder: (context, state) {
        final opp = state.extra as VolunteerOpportunity? ??
            const VolunteerOpportunity(
              id: 'vol-1',
              title: 'Flood Relief Support',
              status: 'Ongoing',
              statusBg: Color(0xFFDCFCE7),
              statusColor: Color(0xFF16A34A),
              location: 'Kandy',
              date: 'Sat, 20 Aug 2026',
              volunteersNeeded: '12 volunteers needed',
              imagePath: 'assets/images/2.jpg',
              description: 'Help distribute relief items and support affected families in flood-hit areas.',
              requirements: [
                'Age 18+',
                'Physically fit',
                'Bring water and basic gear',
              ],
            );
        return VolunteerOpportunityDetailsScreen(opportunity: opp);
      },
    ),
    GoRoute(
      path: '/volunteer-joined',
      builder: (context, state) {
        final opp = state.extra as VolunteerOpportunity? ??
            const VolunteerOpportunity(
              id: 'vol-1',
              title: 'Flood Relief Support',
              status: 'Ongoing',
              statusBg: Color(0xFFDCFCE7),
              statusColor: Color(0xFF16A34A),
              location: 'Kandy',
              date: 'Sat, 20 Aug 2026',
              volunteersNeeded: '12 volunteers needed',
              imagePath: 'assets/images/2.jpg',
              description: 'Help distribute relief items and support affected families in flood-hit areas.',
              requirements: [
                'Age 18+',
                'Physically fit',
                'Bring water and basic gear',
              ],
            );
        return VolunteerJoinedScreen(opportunity: opp);
      },
    ),

    // 4. Response Crew Operations
    GoRoute(
      path: '/crew-assignments',
      builder: (context, state) => const CrewAssignmentsScreen(),
    ),
    GoRoute(
      path: '/crew-assignment-details',
      builder: (context, state) {
        final assignment = state.extra as CrewAssignment? ??
            const CrewAssignment(
              id: 'crew-001',
              title: 'Flood Response',
              priority: 'High Priority',
              priorityColor: Color(0xFFEF4444),
              priorityBg: Color(0xFFFEE2E2),
              location: 'Peradeniya',
              assignedBy: 'Assigned by Kandy Ops Center',
              status: 'Assigned',
              statusBg: Color(0xFFDBEAFE),
              statusColor: Color(0xFF1E40AF),
              imagePath: 'assets/images/1.jpg',
              description: 'Assess flooded area, assist in evacuations, and report situation with photos.',
              latitude: 7.2600,
              longitude: 80.5975,
            );
        return CrewAssignmentDetailsScreen(assignment: assignment);
      },
    ),

    GoRoute(
      path: '/map',
      builder: (context, state) => const NearbyReportsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
