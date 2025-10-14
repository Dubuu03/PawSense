import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pawsense/core/utils/app_theme.dart';
import 'package:pawsense/core/config/firebase_options.dart';
import 'package:pawsense/core/config/app_router.dart';
import 'package:pawsense/core/services/shared/data_service.dart';
import 'package:pawsense/core/services/notifications/appointment_reminder_service.dart';
import 'package:pawsense/core/widgets/shared/global_notification_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase with proper options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize DataService and enable Firebase
  DataService().enableFirebase(true);

  // Start appointment reminder service
  AppointmentReminderService.startReminderService();

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