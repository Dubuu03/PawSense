import 'package:flutter/material.dart';
import 'package:pawsense/pages/web/admin_main.dart';
import 'package:pawsense/core/services/auth/auth_service_web.dart';

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
          // Check if user is super admin or regular admin
          return FutureBuilder<bool>(
            future: AuthServiceWeb().isSuperAdmin(),
            builder: (context, superAdminSnapshot) {
              if (superAdminSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              final userRole = (superAdminSnapshot.data == true) ? 'super_admin' : 'admin';
              return AdminMain(userRole: userRole);
            },
          );
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/web_login');
          });
          return const Scaffold(body: Center(child: Text('Redirecting...')));
        }
      },
    );
  }
}
