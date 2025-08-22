# PawSense Authentication & Authorization System

## Overview

This document describes the comprehensive authentication and authorization system implemented in PawSense, which provides secure, role-based access control using Firebase Authentication and Firestore.

## Architecture

### Core Components

1. **AuthGuard** (`lib/core/guards/auth_guard.dart`)

   - Central authentication and authorization logic
   - Firebase token validation
   - Route access control
   - Permission checking

2. **AuthService** (`lib/core/services/auth/auth_service.dart`)

   - User authentication operations
   - User profile management
   - Clinic data management
   - Integration with all models

3. **RoleManager** (`lib/core/services/role_manager.dart`)

   - Role-based routing configuration
   - Permission definitions
   - Extensible role system

4. **Models** (`lib/core/models/`)
   - `UserModel` - User profiles and roles
   - `ClinicModel` - Basic clinic information
   - `ClinicDetails` - Comprehensive clinic data
   - `ClinicService` - Clinic services with permissions
   - `ClinicCertification` - Clinic certifications with approval workflow

## Authentication Flow

### 1. User Login

```
User enters credentials → Firebase Auth → Token validation → Role check → Route access
```

### 2. Route Protection

```
Route request → AuthGuard.validateRouteAccess() → Token check → Role validation → Access granted/denied
```

### 3. Token Management

- Firebase automatically handles token refresh
- Tokens are validated on each route access
- Expired tokens trigger re-authentication

## Role-Based Access Control

### Available Roles

#### Super Admin

- **Routes**: `/super-admin/*`
- **Permissions**:
  - Manage all clinics
  - Manage all users
  - Approve/reject certifications
  - System analytics
  - System settings
- **Access**: Can access all system data

#### Admin (Clinic Administrator)

- **Routes**: `/admin/*`
- **Permissions**:
  - Manage own clinic
  - Manage own services
  - Manage patients and appointments
  - View analytics
  - Manage staff
- **Access**: Limited to own clinic data

#### Veterinarian

- **Routes**: `/vet/*`
- **Permissions**:
  - View patients
  - Manage appointments
  - View clinic info
  - Update patient records
- **Access**: Limited to assigned patients and schedule

#### Staff

- **Routes**: `/staff/*`
- **Permissions**:
  - View patients
  - Schedule appointments
  - View clinic info
  - Update appointments
- **Access**: Limited to appointment management

#### Pet Owner

- **Routes**: `/pet-owner/*`
- **Permissions**:
  - View own pets
  - Book appointments
  - View own appointments
  - Update profile
- **Access**: Limited to own data

## Model Integration

### UserModel

- Always loaded to check user's role and profile
- Contains role, permissions, and basic profile data
- Used for authentication decisions

### ClinicModel

- Basic clinic information (name, address, contact)
- Loaded when accessing clinic-related routes
- Used for basic clinic identification

### ClinicDetails

- Comprehensive clinic information
- Attached for detailed clinic profile screens
- Contains services, certifications, and additional data

### ClinicService

- Clinic services with category and pricing
- Only authorized users can manage services
- Integrated with permission system

### ClinicCertification

- Clinic certifications with approval workflow
- Only super admins can approve/verify
- Status tracking (pending, approved, rejected, expired)

## Security Features

### 1. Firebase Token Validation

- Automatic token refresh
- Secure session management
- Protection against token tampering

### 2. Role-Based Route Protection

- Routes are protected at the router level
- Unauthorized access is automatically redirected
- Role validation on every route change

### 3. Data Access Control

- Users can only access data they're authorized for
- Clinic admins can only manage their own clinic
- Super admins have system-wide access

### 4. Permission-Based Operations

- Fine-grained permission checking
- Operations are validated before execution
- Audit trail for sensitive operations

## Usage Examples

### Checking User Permissions

```dart
final authService = AuthService();

// Check if user has specific permission
if (await authService.hasPermission('manage_own_clinic')) {
  // Allow clinic management
}

// Check if user can access specific clinic
if (await authService.canAccessClinic(clinicId)) {
  // Allow access to clinic data
}
```

### Route Protection

```dart
// In go_router configuration
redirect: (context, state) async {
  return await AuthGuard.validateRouteAccess(state.uri.path);
}
```

### Role-Based Navigation

```dart
// Get routes for user's role
final routes = RoleManager.getRoutesForRole(userRole);

// Check if route is accessible
if (RoleManager.isRouteAccessibleByRole(routePath, userRole)) {
  // Navigate to route
}
```

## Adding New Roles

### 1. Define Role in RoleManager

```dart
'new_role': RoleDefinition(
  name: 'New Role',
  displayName: 'New Role Display Name',
  routes: [
    RouteInfo('/new-role/dashboard', 'Dashboard', Icons.dashboard),
    // ... more routes
  ],
  permissions: [
    'permission1',
    'permission2',
    // ... more permissions
  ],
  canAccessAdminRoutes: false,
  canAccessSuperAdminRoutes: false,
),
```

### 2. Add Routes to AppRouter

```dart
// Add new role routes to the ShellRoute
GoRoute(
  path: '/new-role/dashboard',
  builder: (context, state) => NewRoleDashboard(),
  pageBuilder: (context, state) => NoTransitionPage(
    child: NewRoleDashboard(),
  ),
),
```

### 3. Update AuthGuard (if needed)

- Add role-specific logic to `_validateRoleBasedAccess`
- Update permission checking methods
- Add new permission constants

## Best Practices

### 1. Always Check Permissions

```dart
// Good: Check permission before operation
if (await authService.hasPermission('manage_patients')) {
  await updatePatientRecord(patientId, data);
}

// Bad: Assume user has permission
await updatePatientRecord(patientId, data);
```

### 2. Use RoleManager for Route Access

```dart
// Good: Use RoleManager for route validation
final routes = RoleManager.getRoutesForRole(userRole);

// Bad: Hardcode route access
if (userRole == 'admin') {
  // admin routes
}
```

### 3. Validate Data Access

```dart
// Good: Check if user can access specific data
if (await authService.canAccessClinic(clinicId)) {
  final clinicData = await getClinicData(clinicId);
}

// Bad: Assume user can access any data
final clinicData = await getClinicData(clinicId);
```

## Troubleshooting

### Common Issues

1. **"Access denied" errors**

   - Check user's role and permissions
   - Verify Firebase token is valid
   - Ensure user has access to requested data

2. **Route redirects to login**

   - Check if user is authenticated
   - Verify Firebase token hasn't expired
   - Check if route requires authentication

3. **Permission denied errors**
   - Verify user's role has required permission
   - Check if permission is correctly defined in RoleManager
   - Ensure permission checking is implemented

### Debug Mode

Enable debug logging in AuthGuard:

```dart
// Add debug prints to track authentication flow
print('AuthGuard: Checking route access for $routePath');
print('AuthGuard: User role: $userRole');
print('AuthGuard: Permission check: $permission');
```

## Security Considerations

1. **Token Security**

   - Firebase handles token security automatically
   - Tokens are validated on every request
   - Expired tokens trigger re-authentication

2. **Data Access**

   - All data access is validated against user permissions
   - Users can only access authorized data
   - Audit trail for sensitive operations

3. **Route Protection**
   - Routes are protected at multiple levels
   - Unauthorized access is automatically prevented
   - Role-based routing ensures proper access control

## Performance Considerations

1. **Token Validation**

   - Firebase caches tokens locally
   - Validation happens only when needed
   - Automatic token refresh minimizes API calls

2. **Data Loading**

   - Models are loaded on-demand
   - Permission checking is cached where possible
   - Efficient Firestore queries for data access

3. **Route Validation**
   - Route access is validated once per navigation
   - Cached permission results where appropriate
   - Minimal overhead for authentication checks
