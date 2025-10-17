import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/pages/mobile/auth/sign_in_page.dart';
import 'package:pawsense/pages/mobile/auth/sign_up_page.dart';
import 'package:pawsense/pages/mobile/auth/verify_email_page.dart';
import 'package:pawsense/pages/mobile/auth/change_password_page.dart';
import 'package:pawsense/pages/mobile/home_page.dart';
import 'package:pawsense/pages/mobile/assessment_page.dart';
import 'package:pawsense/pages/mobile/optimized_alerts_page.dart';
import 'package:pawsense/pages/mobile/notification_detail_page.dart';
import 'package:pawsense/core/widgets/user/alerts/alert_item.dart';
import 'package:pawsense/pages/mobile/appointments/appointment_details_page.dart';
import 'package:pawsense/pages/mobile/edit_profile_page.dart';
import 'package:pawsense/pages/mobile/about_pawsense_page.dart';
import 'package:pawsense/pages/mobile/history/ai_history_detail_page.dart';
import 'package:pawsense/pages/mobile/history/appointment_history_detail_page.dart';
import 'package:pawsense/pages/mobile/messaging/messaging_page.dart';
import 'package:pawsense/pages/mobile/messaging/messaging_test_page.dart';
import 'package:pawsense/pages/mobile/pets/view_all_pets_page.dart';
import 'package:pawsense/pages/mobile/pets/add_edit_pet_page.dart';
import 'package:pawsense/pages/mobile/home_services/book_appointment_page.dart';
import 'package:pawsense/pages/mobile/home_services/emergency_hotline_page.dart';
import 'package:pawsense/pages/mobile/home_services/first_aid_guide_page.dart';
import 'package:pawsense/pages/mobile/home_services/pet_care_tips_page.dart';
import 'package:pawsense/pages/mobile/home_services/faqs_page.dart';
import 'package:pawsense/pages/mobile/home_services/clinic_faqs_page.dart';
import 'package:pawsense/pages/mobile/clinic/clinic_list_page.dart';
import 'package:pawsense/pages/mobile/clinic/clinic_details_page.dart';
import 'package:pawsense/pages/mobile/skin_disease_library_page.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/pages/web/auth/web_login_page.dart';
import 'package:pawsense/pages/web/auth/admin_signup_page.dart';
import 'package:pawsense/pages/web/auth/forgot_password_page.dart';
import 'package:pawsense/pages/web/admin/dashboard_screen.dart';
import 'package:pawsense/pages/web/admin/appointment_screen.dart';
import 'package:pawsense/pages/web/admin/patient_record_screen.dart';
import 'package:pawsense/pages/web/admin/clinic_schedule_screen.dart';
import 'package:pawsense/pages/web/admin/vet_profile_screen.dart';
import 'package:pawsense/pages/web/admin/clinic_ratings_page.dart';
import 'package:pawsense/pages/web/admin/messaging_screen.dart';

import 'package:pawsense/pages/web/admin/support_screen.dart';
import 'package:pawsense/pages/web/admin/settings_screen.dart';
import 'package:pawsense/core/widgets/admin/notifications/admin_notification_dropdown.dart';
import 'package:pawsense/pages/web/superadmin/clinic_management_screen.dart';
import 'package:pawsense/pages/web/superadmin/system_analytics_screen.dart';
import 'package:pawsense/pages/web/superadmin/user_management_screen.dart';
import 'package:pawsense/pages/web/superadmin/breed_management_screen.dart';
import 'package:pawsense/pages/web/superadmin/diseases_management_screen.dart';
import 'package:pawsense/pages/web/superadmin/system_settings_screen.dart';
import 'package:flutter/foundation.dart';
import '../widgets/shared/navigation/admin_shell.dart';
import '../guards/auth_guard.dart';
import '../services/optimization/role_manager.dart';

class AppRouter {
  static final _router = GoRouter(
    initialLocation: kIsWeb ? '/web_login' : '/signin',
    redirect: _handleRedirect,
    errorBuilder: (context, state) => const SignInPage(), // Add error handler
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
        builder: (context, state) => const OptimizedAlertsPage(),
      ),
      GoRoute(
        path: '/alerts/details/:notificationId',
        builder: (context, state) {
          final notificationId = state.pathParameters['notificationId']!;
          final alertData = state.extra as AlertData?;
          return NotificationDetailPage(
            notificationId: notificationId,
            alertData: alertData,
          );
        },
      ),
      GoRoute(
        path: '/appointments/details/:appointmentId',
        builder: (context, state) {
          final appointmentId = state.pathParameters['appointmentId']!;
          return AppointmentDetailsPage(appointmentId: appointmentId);
        },
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
        path: '/about-pawsense',
        builder: (context, state) => const AboutPawSensePage(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/messaging',
        builder: (context, state) => const MessagingPage(),
      ),
      GoRoute(
        path: '/messaging-test',
        builder: (context, state) => const MessagingTestPage(),
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

      // Pet management routes
      GoRoute(
        path: '/pets',
        builder: (context, state) => const ViewAllPetsPage(),
      ),
      GoRoute(
        path: '/add-pet',
        builder: (context, state) => const AddEditPetPage(),
      ),
      GoRoute(
        path: '/edit-pet',
        builder: (context, state) {
          final pet = state.extra as Pet?;
          return AddEditPetPage(pet: pet);
        },
      ),

      // Service routes
      GoRoute(
        path: '/book-appointment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final assessmentResultId = state.uri.queryParameters['assessment_result_id'];
          final skipService = state.uri.queryParameters['skip_service'] == 'true';
          
          return BookAppointmentPage(
            preselectedClinicId: extra?['clinicId'] as String?,
            preselectedClinicName: extra?['clinicName'] as String?,
            assessmentResultId: assessmentResultId,
            skipServiceSelection: skipService,
          );
        },
      ),
      GoRoute(
        path: '/emergency-hotline',
        builder: (context, state) => const EmergencyHotlinePage(),
      ),
      GoRoute(
        path: '/first-aid-guide',
        builder: (context, state) => const FirstAidGuidePage(),
      ),
      GoRoute(
        path: '/pet-care-tips',
        builder: (context, state) => const PetCareTipsPage(),
      ),
      GoRoute(
        path: '/faqs',
        builder: (context, state) => const FAQsPage(),
      ),
      GoRoute(
        path: '/clinic-faqs',
        builder: (context, state) {
          final clinicId = state.uri.queryParameters['clinicId'] ?? '';
          final clinicName = state.uri.queryParameters['clinicName'] ?? 'Clinic';
          return ClinicFAQsPage(
            clinicId: clinicId,
            clinicName: clinicName,
          );
        },
      ),

      // Clinic routes
      GoRoute(
        path: '/clinics',
        builder: (context, state) => const ClinicListPage(),
      ),
      GoRoute(
        path: '/clinic-details',
        builder: (context, state) {
          final clinicId = state.uri.queryParameters['id'];
          return ClinicDetailsPage(clinicId: clinicId ?? '');
        },
      ),

      // Skin Disease Library routes
      GoRoute(
        path: '/skin-disease-library',
        builder: (context, state) => const SkinDiseaseLibraryPage(),
      ),

      // Web auth routes
      GoRoute(
        path: '/web_login',
        builder: (context, state) => const WebLoginPage(),
      ),
      GoRoute(
        path: '/login', // Alias for web_login
        builder: (context, state) => const WebLoginPage(),
      ),
      GoRoute(
        path: '/admin_signup',
        builder: (context, state) => const AdminSignupPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const WebForgotPasswordPage(),
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
            builder: (context, state) {
              final appointmentId = state.uri.queryParameters['appointmentId'];
              print('📍 ROUTER DEBUG: /admin/appointments route');
              print('   Query parameters: ${state.uri.queryParameters}');
              print('   Extracted appointmentId: $appointmentId');
              return OptimizedAppointmentManagementScreen(
                highlightAppointmentId: appointmentId,
              );
            },
            pageBuilder: (context, state) {
              final appointmentId = state.uri.queryParameters['appointmentId'];
              print('📍 ROUTER PAGE BUILDER: appointmentId = $appointmentId');
              return NoTransitionPage(
                child: OptimizedAppointmentManagementScreen(
                  highlightAppointmentId: appointmentId,
                ),
              );
            },
          ),
          GoRoute(
            path: '/admin/patient-records',
            builder: (context, state) => ImprovedPatientRecordsScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: ImprovedPatientRecordsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/clinic-schedule',
            builder: (context, state) => ClinicSchedulePage(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: ClinicSchedulePage(),
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
            path: '/admin/ratings',
            builder: (context, state) => const ClinicRatingsPage(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: const ClinicRatingsPage(),
            ),
          ),
          GoRoute(
            path: '/admin/messaging',
            builder: (context, state) => const MessagingScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: const MessagingScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/messaging/:conversationId',
            builder: (context, state) {
              final conversationId = state.pathParameters['conversationId']!;
              return MessagingScreen(conversationId: conversationId);
            },
            pageBuilder: (context, state) {
              final conversationId = state.pathParameters['conversationId']!;
              return NoTransitionPage(
                child: MessagingScreen(conversationId: conversationId),
              );
            },
          ),

          GoRoute(
            path: '/admin/notifications',
            builder: (context, state) => const AdminNotificationScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: const AdminNotificationScreen(),
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
            path: '/super-admin/pet-breeds',
            builder: (context, state) => const BreedManagementScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: const BreedManagementScreen(),
            ),
          ),
          GoRoute(
            path: '/super-admin/skin-diseases',
            builder: (context, state) => const DiseasesManagementScreen(),
            pageBuilder: (context, state) => NoTransitionPage(
              child: const DiseasesManagementScreen(),
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
      
      // Fallback route for unmatched paths
      GoRoute(
        path: '/',
        redirect: (context, state) => kIsWeb ? '/web_login' : '/signin',
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
    
    try {
      // Use AuthGuard to validate route access
      final redirectPath = await AuthGuard.validateRouteAccess(location);
      
      // Prevent infinite redirects by checking if we're already on the redirect target
      if (redirectPath != null && redirectPath != location) {
        print('AppRouter: Redirecting from $location to $redirectPath');
        return redirectPath;
      }
      
      return null; // No redirect needed
    } catch (e) {
      print('AppRouter: Error during redirect validation: $e');
      // On error, redirect to appropriate login page
      return kIsWeb ? '/web_login' : '/signin';
    }
  }
}

