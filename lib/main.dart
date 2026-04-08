import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pawsense/core/utils/app_theme.dart';
import 'package:pawsense/core/config/firebase_options.dart';
import 'package:pawsense/core/config/app_router.dart';
import 'package:pawsense/core/services/shared/data_service.dart';
import 'package:pawsense/core/services/shared/server_time_service.dart';
import 'package:pawsense/core/services/auth/auth_time_enhancement.dart';
import 'package:pawsense/core/services/notifications/appointment_reminder_service.dart';
import 'package:pawsense/core/services/clinic/appointment_auto_cancellation_service.dart';
import 'package:pawsense/core/services/auth/auth_recovery_service.dart';
import 'package:pawsense/core/widgets/shared/global_notification_wrapper.dart';
import 'package:pawsense/core/services/ai/groq_orchestration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Validate AI configuration early so the app can safely use deterministic fallbacks.
  GroqOrchestrationService.instance.validateConfiguration();

  // Initialize Firebase with proper options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Enable Firestore offline persistence for better offline experience
  // This allows data to be cached locally and accessed even without network
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    print('✅ Firestore offline persistence enabled');
  } catch (e) {
    print('⚠️ Failed to enable Firestore persistence: $e');
  }

  // Initialize DataService and enable Firebase
  DataService().enableFirebase(true);

  // Initialize ServerTimeService for time synchronization
  // This prevents issues when device time is incorrect
  // CRITICAL: This must complete to ensure auth works with incorrect device time
  try {
    await ServerTimeService.initialize();
    print('⏰ Server time synchronized successfully');
    
    // Validate device time and warn if off
    final diagnostics = ServerTimeService.getDiagnostics();
    final isAccurate = diagnostics['isAccurate'] as bool?;
    if (isAccurate == false) {
      final offsetMinutes = diagnostics['offsetMinutes'] as int?;
      print('⚠️ WARNING: Device time is off by ${offsetMinutes ?? '?'} minutes');
      print('   Authentication may fail if time skew is severe');
    }
  } catch (e) {
    print('⚠️ Server time sync failed (app will use device time): $e');
    print('   This may cause authentication issues if device time is incorrect');
  }

  // Initialize auth monitoring if user is already signed in
  // This ensures token refresh continues working after app restart
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    print('🔐 Found existing user session: ${currentUser.uid}');
    print('   Email verified: ${currentUser.emailVerified}');
    print('   Restoring auth monitoring...');
    
    AuthTimeEnhancement.initializeAuthMonitoring(FirebaseAuth.instance).then((_) {
      print('✅ Auth monitoring restored for existing session');
    }).catchError((e) {
      print('⚠️ Failed to restore auth monitoring: $e');
    });
  } else {
    print('ℹ️  No existing user session found');
  }

  // Check for authentication recovery scenarios
  // This helps users who verified email outside the app
  AuthRecoveryService().checkForRecovery().then((result) {
    print('🔄 Auth recovery check: ${result.message}');
  }).catchError((e) {
    print('⚠️ Error during auth recovery check: $e');
  });

  // Start appointment reminder service
  AppointmentReminderService.startReminderService();

  // Process expired appointments on app startup
  // This ensures any pending appointments that have passed are auto-cancelled
  AppointmentAutoCancellationService.processExpiredAppointments().then((stats) {
    print('📊 Auto-cancellation on startup: ${stats['cancelled']} cancelled, ${stats['failed']} failed');
  }).catchError((e) {
    print('⚠️ Error processing expired appointments on startup: $e');
  });

  runApp(const PawSenseApp());
}

class PawSenseApp extends StatelessWidget {
  const PawSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalNotificationWrapper(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'PawSense - Your Pet Care Companion',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Always use light mode
        routerConfig: AppRouter.router,
      ),
    );
  }
} 

  // runApp(const MaterialApp(
  //   debugShowCheckedModeBanner: false,
  //   home: ImageDisplayPage(),
  // ));