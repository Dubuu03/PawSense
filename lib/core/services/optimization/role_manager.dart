import 'package:flutter/material.dart';

/// Manages role-based routing and permissions
class RoleManager {
  // Role definitions with their associated routes and permissions
  static const Map<String, RoleDefinition> _roleDefinitions = {
    'super_admin': RoleDefinition(
      name: 'Super Admin',
      displayName: 'Super Administrator',
      routes: [
        RouteInfo('/super-admin/dashboard', 'Dashboard', Icons.dashboard),
        RouteInfo('/super-admin/admin-management', 'Admin Management', Icons.admin_panel_settings),
        RouteInfo('/super-admin/clinic-management', 'Clinic Management', Icons.business),
        RouteInfo('/super-admin/system-analytics', 'System Analytics', Icons.analytics),
        RouteInfo('/super-admin/user-management', 'User Management', Icons.people_outline),
        RouteInfo('/super-admin/notifications', 'Notifications', Icons.notifications_outlined),
        RouteInfo('/super-admin/support', 'Support Center', Icons.help_outline),
        RouteInfo('/super-admin/system-settings', 'System Settings', Icons.settings_outlined),
      ],
      permissions: [
        'manage_all_clinics',
        'manage_all_users',
        'manage_certifications',
        'system_analytics',
        'system_settings',
        'approve_clinics',
        'view_all_data',
      ],
      canAccessAdminRoutes: false, // Super admin should use super-admin routes
      canAccessSuperAdminRoutes: true,
    ),
    'admin': RoleDefinition(
      name: 'Admin',
      displayName: 'Clinic Administrator',
      routes: [
        RouteInfo('/admin/dashboard', 'Dashboard', Icons.dashboard),
        RouteInfo('/admin/appointments', 'Appointment\nManagement', Icons.calendar_today),
        RouteInfo('/admin/patient-records', 'Patient Records', Icons.folder_open),
        RouteInfo('/admin/clinic-schedule', 'Clinic Schedule', Icons.schedule),
        RouteInfo('/admin/vet-profile', 'Vet Profile & Services', Icons.person_outline),
        RouteInfo('/admin/notifications', 'Notifications', Icons.notifications_outlined),
        RouteInfo('/admin/support', 'Support', Icons.help_outline),
        RouteInfo('/admin/settings', 'Settings', Icons.settings_outlined),
      ],
      permissions: [
        'manage_own_clinic',
        'manage_own_services',
        'manage_patients',
        'manage_appointments',
        'view_analytics',
        'manage_staff',
        'view_clinic_data',
      ],
      canAccessAdminRoutes: true,
      canAccessSuperAdminRoutes: false,
    ),
    'vet': RoleDefinition(
      name: 'Vet',
      displayName: 'Veterinarian',
      routes: [
        RouteInfo('/vet/dashboard', 'Dashboard', Icons.dashboard),
        RouteInfo('/vet/appointments', 'My Appointments', Icons.calendar_today),
        RouteInfo('/vet/patients', 'My Patients', Icons.folder_open),
        RouteInfo('/vet/schedule', 'My Schedule', Icons.schedule),
        RouteInfo('/vet/profile', 'My Profile', Icons.person_outline),
      ],
      permissions: [
        'view_patients',
        'manage_appointments',
        'view_clinic_info',
        'update_patient_records',
        'view_own_schedule',
      ],
      canAccessAdminRoutes: false,
      canAccessSuperAdminRoutes: false,
    ),
    'staff': RoleDefinition(
      name: 'Staff',
      displayName: 'Clinic Staff',
      routes: [
        RouteInfo('/staff/dashboard', 'Dashboard', Icons.dashboard),
        RouteInfo('/staff/appointments', 'Appointments', Icons.calendar_today),
        RouteInfo('/staff/patients', 'Patient Records', Icons.folder_open),
        RouteInfo('/staff/schedule', 'Schedule', Icons.schedule),
      ],
      permissions: [
        'view_patients',
        'schedule_appointments',
        'view_clinic_info',
        'update_appointments',
        'view_schedule',
      ],
      canAccessAdminRoutes: false,
      canAccessSuperAdminRoutes: false,
    ),
    'pet_owner': RoleDefinition(
      name: 'Pet Owner',
      displayName: 'Pet Owner',
      routes: [
        RouteInfo('/pet-owner/dashboard', 'Dashboard', Icons.dashboard),
        RouteInfo('/pet-owner/pets', 'My Pets', Icons.pets),
        RouteInfo('/pet-owner/appointments', 'Appointments', Icons.calendar_today),
        RouteInfo('/pet-owner/profile', 'Profile', Icons.person_outline),
      ],
      permissions: [
        'view_own_pets',
        'book_appointments',
        'view_own_appointments',
        'update_profile',
      ],
      canAccessAdminRoutes: false,
      canAccessSuperAdminRoutes: false,
    ),
  };

  /// Get routes for a specific role
  static List<RouteInfo> getRoutesForRole(String role) {
    final roleDef = _roleDefinitions[role];
    if (roleDef != null) {
      return roleDef.routes;
    }
    
    // Fallback to admin routes for unknown roles
    return _roleDefinitions['admin']!.routes;
  }

  /// Get all available roles
  static List<String> getAvailableRoles() {
    return _roleDefinitions.keys.toList();
  }

  /// Get role definition
  static RoleDefinition? getRoleDefinition(String role) {
    return _roleDefinitions[role];
  }

  /// Get role display name
  static String getRoleDisplayName(String role) {
    final roleDef = _roleDefinitions[role];
    return roleDef?.displayName ?? role;
  }

  /// Check if role can access admin routes
  static bool canAccessAdminRoutes(String role) {
    final roleDef = _roleDefinitions[role];
    return roleDef?.canAccessAdminRoutes ?? false;
  }

  /// Check if role can access super admin routes
  static bool canAccessSuperAdminRoutes(String role) {
    final roleDef = _roleDefinitions[role];
    return roleDef?.canAccessSuperAdminRoutes ?? false;
  }

  /// Get permissions for a role
  static List<String> getPermissionsForRole(String role) {
    final roleDef = _roleDefinitions[role];
    return roleDef?.permissions ?? [];
  }

  /// Check if role has specific permission
  static bool roleHasPermission(String role, String permission) {
    final permissions = getPermissionsForRole(role);
    return permissions.contains(permission);
  }

  /// Get default dashboard route for a role
  static String getDefaultDashboardRoute(String role) {
    final routes = getRoutesForRole(role);
    if (routes.isNotEmpty) {
      return routes.first.path;
    }
    return '/web_login';
  }

  /// Validate if a route is accessible by a role
  static bool isRouteAccessibleByRole(String routePath, String role) {
    final routes = getRoutesForRole(role);
    return routes.any((route) => route.path == routePath);
  }

  /// Get all routes for all roles
  static Map<String, List<RouteInfo>> getAllRoleRoutes() {
    final Map<String, List<RouteInfo>> allRoutes = {};
    for (final entry in _roleDefinitions.entries) {
      allRoutes[entry.key] = entry.value.routes;
    }
    return allRoutes;
  }

  /// Add a new role (for future extensibility)
  static void addRole(String roleName, RoleDefinition definition) {
    // This would be used when adding new roles dynamically
    // For now, we'll keep it static but provide the structure
    throw UnimplementedError('Dynamic role addition not implemented yet');
  }
}

/// Definition of a role with its routes and permissions
class RoleDefinition {
  final String name;
  final String displayName;
  final List<RouteInfo> routes;
  final List<String> permissions;
  final bool canAccessAdminRoutes;
  final bool canAccessSuperAdminRoutes;

  const RoleDefinition({
    required this.name,
    required this.displayName,
    required this.routes,
    required this.permissions,
    required this.canAccessAdminRoutes,
    required this.canAccessSuperAdminRoutes,
  });
}

/// Information about a route
class RouteInfo {
  final String path;
  final String title;
  final IconData icon;

  const RouteInfo(this.path, this.title, this.icon);
}
