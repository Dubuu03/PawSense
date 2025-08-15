import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pawsense/pages/mobile/auth/sign_in_page.dart';
import 'package:pawsense/pages/mobile/auth/sign_up_page.dart';
import 'package:pawsense/pages/mobile/home_page.dart';
import 'package:pawsense/pages/web/admin_main.dart';
import 'package:pawsense/pages/web/dashboard_screen.dart';
import 'package:pawsense/pages/web/web_login_page.dart';
import 'package:pawsense/pages/web/superadmin_page.dart';
import 'package:pawsense/core/services/auth/auth_service_web.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/config/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with proper options
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCYC9kIBdnqyrslDW18MGpvnjr7_lz7_wI',
        appId: '1:1040108127502:web:417570b3f365ed24e7835f',
        messagingSenderId: '1040108127502',
        projectId: 'pawsense-134fc',
        authDomain: 'pawsense-134fc.firebaseapp.com',
        storageBucket: 'pawsense-134fc.firebasestorage.app',
        measurementId: 'G-E2RR862KHY',
      ),
    );
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const PawSenseApp());
}

class PawSenseApp extends StatelessWidget {
  const PawSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        '/admin_main': (context) => const AdminMainGuard(),
        '/super_admin': (context) => const SuperAdminPageGuard(),
        '/dashboard': (context) => DashboardScreen(),
      },
    );
  }
}

// Guard wrapper for AdminMain to ensure user has admin privileges
class AdminMainGuard extends StatelessWidget {
  const AdminMainGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthServiceWeb().hasAdminPrivileges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return AdminMain();
        } else {
          // Redirect to login if not authorized
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/web_login');
          });
          return const Scaffold(body: Center(child: Text('Redirecting...')));
        }
      },
    );
  }
}

// Guard wrapper for SuperAdminPage to ensure user has super admin privileges
class SuperAdminPageGuard extends StatelessWidget {
  const SuperAdminPageGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthServiceWeb().isSuperAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const SuperAdminPage();
        } else {
          // Redirect to login if not authorized
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/web_login');
          });
          return const Scaffold(body: Center(child: Text('Redirecting...')));
        }
      },
    );
  }
}

// Placeholder for your existing mobile home page
class MobileHomePage extends StatelessWidget {
  const MobileHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Mobile App Home\n(Your existing mobile app goes here)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
