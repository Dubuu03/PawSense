import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_theme.dart';
import 'package:pawsense/core/config/firebase_options.dart';
import 'package:pawsense/core/config/app_router.dart';
import 'package:pawsense/core/services/shared/data_service.dart';

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
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'PawSense - Your Pet Care Companion',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
