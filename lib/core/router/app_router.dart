import 'package:latlong2/latlong.dart';
import '../../features/auth/services/auth_service.dart';
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
        String? redirect = state.uri.queryParameters['redirect'];
        String? role = state.uri.queryParameters['role'];
        int tabIndex = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;

        final extra = state.extra;
        if (extra is Map) {
          if (extra['redirect'] != null) redirect = extra['redirect'].toString();
          if (extra['role'] != null) role = extra['role'].toString();
          if (extra['tab'] != null && extra['tab'] is num) {
            tabIndex = (extra['tab'] as num).toInt();
          }
        } else if (extra is String && extra.isNotEmpty) {
          redirect = extra;
        }

        return LoginScreen(
          redirectPath: redirect,
          initialTabIndex: tabIndex,
          initialRole: role,
        );
      },
    ),
    GoRoute(
      path: '/report-issue',
      builder: (context, state) => const ReportIssueScreen(),
    ),
    GoRoute(
      path: '/issue-details',
      builder: (context, state) {
        final category = state.extra is String ? state.extra as String : 'Road Hazard';
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
      path: '/donate-supplies-form',
      builder: (context, state) {
        String category = 'Food & Water';
        int? iconCode;
        int? iconColorValue;
        if (state.extra is Map) {
          final map = state.extra as Map;
          category = map['category']?.toString() ?? 'Food & Water';
          if (map['iconCode'] is int) iconCode = map['iconCode'] as int;
          if (map['iconColor'] is int) iconColorValue = map['iconColor'] as int;
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
      path: '/donate',
      builder: (context, state) => const DonationCategoryScreen(),
    ),
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
        if (state.extra is Map) {
          final map = state.extra as Map;
          category = map['category']?.toString() ?? 'Food & Water';
          if (map['iconCode'] is int) iconCode = map['iconCode'] as int;
          if (map['iconColor'] is int) iconColorValue = map['iconColor'] as int;
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
        final map = state.extra is Map ? state.extra as Map : {};
        return DonationSuccessScreen(
          category: map['category']?.toString() ?? 'Food & Water',
          itemName: map['itemName']?.toString() ?? 'Bottled Water',
          quantity: map['quantity']?.toString() ?? '50 Bottles',
          location: map['location']?.toString() ?? 'Kandy, Sri Lanka',
          description: map['description']?.toString() ?? '',
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
      redirect: (context, state) {
        final isLoggedIn = AuthService.instance.isLoggedIn;
        if (!isLoggedIn) {
          return '/login?tab=0&role=COMMUNITY_VOLUNTEER&redirect=${Uri.encodeComponent('/community-volunteer')}';
        }
        return null;
      },
      builder: (context, state) {
        final initialTab = (state.extra is num) ? (state.extra as num).toInt() : 0;
        return CommunityVolunteerScreen(initialTabIndex: initialTab);
      },
    ),
    GoRoute(
      path: '/volunteer-opportunity-details',
      builder: (context, state) {
        final opp = (state.extra is VolunteerOpportunity)
            ? state.extra as VolunteerOpportunity
            : const VolunteerOpportunity(
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
        final opp = (state.extra is VolunteerOpportunity)
            ? state.extra as VolunteerOpportunity
            : const VolunteerOpportunity(
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

    // 4. Response Crew Operations (Strict Role Protected Guard)
    GoRoute(
      path: '/crew-assignments',
      redirect: (context, state) {
        final user = AuthService.instance.currentUser;
        if (user == null || !user.isFieldCrew) {
          return '/volunteer-type';
        }
        return null;
      },
      builder: (context, state) => const CrewAssignmentsScreen(),
    ),
    GoRoute(
      path: '/crew-assignment-details',
      redirect: (context, state) {
        final user = AuthService.instance.currentUser;
        if (user == null || !user.isFieldCrew) {
          return '/volunteer-type';
        }
        return null;
      },
      builder: (context, state) {
        final assignment = (state.extra is CrewAssignment)
            ? state.extra as CrewAssignment
            : const CrewAssignment(
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
      builder: (context, state) {
        final target = state.extra as LatLng?;
        return NearbyReportsScreen(targetDestination: target);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
