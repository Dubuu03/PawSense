import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/pages/mobile/auth/sign_in_page.dart';
import 'package:pawsense/pages/mobile/auth/sign_up_page.dart';
import 'package:pawsense/pages/mobile/auth/verify_email_page.dart';
import 'package:pawsense/pages/mobile/home_page.dart';
import 'package:pawsense/pages/mobile/assessment_page.dart';
import 'package:pawsense/pages/mobile/alerts_page.dart';
import 'package:pawsense/pages/mobile/edit_profile_page.dart';
import 'package:pawsense/pages/mobile/history/ai_history_detail_page.dart';
import 'package:pawsense/pages/mobile/history/appointment_history_detail_page.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/pages/web/auth/web_login_page.dart';
import 'package:pawsense/pages/web/auth/admin_signup_page.dart';
import 'package:pawsense/pages/web/admin/dashboard_screen.dart';
import 'package:pawsense/pages/web/admin/appointment_screen.dart';
import 'package:pawsense/pages/web/admin/patient_record_screen.dart';
import 'package:pawsense/pages/web/admin/clinic_schedule_screen.dart';
import 'package:pawsense/pages/web/admin/vet_profile_screen.dart';
import 'package:pawsense/pages/web/admin/notifications_screen.dart';
import 'package:pawsense/pages/web/admin/support_screen.dart';
import 'package:pawsense/pages/web/admin/settings_screen.dart';
import 'package:pawsense/pages/web/superadmin/clinic_management_screen.dart';
import 'package:pawsense/pages/web/superadmin/system_analytics_screen.dart';
import 'package:pawsense/pages/web/superadmin/user_management_screen.dart';
import 'package:pawsense/pages/web/superadmin/system_settings_screen.dart';
import 'package:flutter/foundation.dart';

import '../widgets/shared/navigation/admin_shell.dart';
import '../guards/auth_guard.dart';
import '../services/optimization/role_manager.dart';

class AppRouter {
  static final _router = GoRouter(
    initialLocation: kIsWeb ? '/web_login' : '/signin',
    redirect: _handleRedirect,
    routes: [
      // Mobile routes
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const SignUpPage(); // Redirect back to signup if no data
          }
          return VerifyEmailPage(
            firstName: extra['firstName'] as String,
            lastName: extra['lastName'] as String,
            email: extra['email'] as String,
            uid: extra['uid'] as String,
            contactNumber: extra['contactNumber'] as String,
            dateOfBirth: extra['dateOfBirth'] as DateTime?,
            agreedToTerms: extra['agreedToTerms'] as bool,
            address: extra['address'] as String,
          );
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const UserHomePage(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsPage(),
      ),
      GoRoute(
        path: '/assessment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AssessmentPage(
            selectedPetType: extra?['selectedPetType'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null || extra['user'] == null) {
            return const SignInPage(); // Redirect if no user data
          }
          return EditProfilePage(
            user: extra['user'] as UserModel,
          );
        },
      ),
      GoRoute(
        path: '/ai-history/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AIHistoryDetailPage(aiHistoryId: id);
        },
      ),
      GoRoute(
        path: '/appointment-history/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AppointmentHistoryDetailPage(appointmentId: id);
        },
      ),

      // Web auth routes
      GoRoute(
        path: '/web_login',
        builder: (context, state) => const WebLoginPage(),
      ),
      GoRoute(
        path: '/admin_signup',
        builder: (context, state) => const AdminSignupPage(),
      ),

      // Admin shell with nested routes
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          // Admin routes
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => DashboardScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/appointments',
            builder: (context, state) => AppointmentManagementScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: AppointmentManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/patient-records',
            builder: (context, state) => PatientRecordsScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: PatientRecordsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/clinic-schedule',
            builder: (context, state) => ClinicScheduleScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: ClinicScheduleScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/vet-profile',
            builder: (context, state) => VetProfileScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: VetProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/notifications',
            builder: (context, state) => NotificationsScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/support',
            builder: (context, state) => SupportCenterScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: SupportCenterScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => SettingsScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),

          // Super admin routes
          GoRoute(
            path: '/super-admin/dashboard',
            builder: (context, state) => DashboardScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/super-admin/clinic-management',
            builder: (context, state) => const ClinicManagementScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: const ClinicManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/super-admin/system-analytics',
            builder: (context, state) => const SystemAnalyticsScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: const SystemAnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/super-admin/user-management',
            builder: (context, state) => const UserManagementScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: const UserManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/super-admin/notifications',
            builder: (context, state) => NotificationsScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: NotificationsScreen(),
            ),
          ),
          GoRoute(
            path: '/super-admin/support',
            builder: (context, state) => SupportCenterScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: SupportCenterScreen(),
            ),
          ),
          GoRoute(
            path: '/super-admin/system-settings',
            builder: (context, state) => const SystemSettingsScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: const SystemSettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );

  static GoRouter get router => _router;

  // Role-based route mappings - now using RoleManager
  static Map<String, List<RouteInfo>> get roleRoutes => RoleManager.getAllRoleRoutes();

  // Get routes for a specific role, fallback to admin if role not found
  static List<RouteInfo> getRoutesForRole(String role) {
    return RoleManager.getRoutesForRole(role);
  }

  // Redirect logic for authentication and role-based access
  static Future<String?> _handleRedirect(BuildContext context, GoRouterState state) async {
    final location = state.uri.path;
    
    // Use AuthGuard to validate route access
    return await AuthGuard.validateRouteAccess(location);
  }
}

