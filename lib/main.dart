import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pawsense/pages/mobile/auth/sign_in_page.dart';
import 'package:pawsense/pages/mobile/auth/sign_up_page.dart';
import 'package:pawsense/pages/mobile/home_page.dart';
import 'package:pawsense/pages/web/admin/dashboard_screen.dart';
import 'package:pawsense/pages/web/auth/web_login_page.dart';
import 'package:pawsense/pages/web/auth/admin_signup_page.dart';
import 'package:pawsense/core/utils/app_theme.dart';
import 'package:pawsense/core/config/firebase_options.dart';
import 'package:pawsense/core/utils/route_guards.dart';
import 'package:pawsense/core/services/data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with proper options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize DataService and enable Firebase
  DataService().enableFirebase(true);

  runApp(const PawSenseApp());
}

class PawSenseApp extends StatelessWidget {
  const PawSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PawSense - Your Pet Care Companion',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // Set initial route based on platform
      initialRoute: kIsWeb ? '/web_login' : '/signin',
      routes: {
        // Mobile routes
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),

        // Web routes - Both admin and super admin use the same guard
        '/web_login': (context) => const WebLoginPage(),
        '/admin_signup': (context) => const AdminSignupPage(),
        '/admin_main': (context) => const AdminMainGuard(),
        '/dashboard': (context) => DashboardScreen(),
      },
    );
  }
}
