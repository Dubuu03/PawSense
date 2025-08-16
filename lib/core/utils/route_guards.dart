import 'package:flutter/material.dart';
import 'package:pawsense/pages/web/admin_main.dart';
import 'package:pawsense/pages/web/superadmin_page.dart';
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
          return AdminMain();
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/web_login');
          });
          return const Scaffold(body: Center(child: Text('Redirecting...')));
        }
      },
    );
  }
}
