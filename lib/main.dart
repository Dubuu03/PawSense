import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pawsense/pages/mobile/auth/sign_in_page.dart';
import 'package:pawsense/pages/mobile/auth/sign_up_page.dart';
import 'package:pawsense/pages/mobile/home_page.dart';
import 'package:pawsense/pages/web/dashboard_screen.dart';
import 'package:pawsense/pages/web/auth/web_login_page.dart';
import 'package:pawsense/pages/web/auth/admin_signup_page.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/config/firebase_options.dart';
import 'package:pawsense/core/utils/route_guards.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase with proper options
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: kIsWeb
          ? DefaultFirebaseOptions.web
          : DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(const PawSenseApp());
}

class PawSenseApp extends StatelessWidget {
  const PawSenseApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PawSense',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      // Set initial route based on platform
      initialRoute: kIsWeb ? '/web_login' : '/signin',
      routes: {
        // Mobile routes
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),

        // Web routes
        '/web_login': (context) => const WebLoginPage(),
        '/admin_signup': (context) => const AdminSignupPage(),
        '/admin_main': (context) => const AdminMainGuard(),
        '/super_admin': (context) => const SuperAdminPageGuard(),
        '/dashboard': (context) => DashboardScreen(),
      },
    );
  }
}
