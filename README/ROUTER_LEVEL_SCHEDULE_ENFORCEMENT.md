# Router-Level Schedule Setup Enforcement

## Overview

Implemented router-level navigation guard to prevent admins from accessing any admin pages until they complete their clinic schedule setup. This ensures a mandatory, unbypassable setup flow.

## Problem Solved

**Issue**: Admins could bypass schedule setup by:
- Navigating to other pages via the navigation menu
- Using direct URLs (e.g., `/admin/appointments`)
- Using browser back/forward buttons
- Using bookmarked links

**Solution**: Added schedule setup checking at the router level in `AuthGuard.validateRouteAccess()`, intercepting ALL navigation attempts before pages load.

## Implementation

### Router Guard (`lib/core/guards/auth_guard.dart`)

Added schedule setup validation in the `_performRouteValidation` method:

```dart
// For admin users on web, check schedule setup status before allowing route access
if (kIsWeb && user.role == 'admin' && !_isScheduleSetupRoute(routePath) && !_isPublicRoute(routePath)) {
  print('AuthGuard: Checking schedule setup status for admin user');
  final setupStatus = await ScheduleSetupGuard.checkScheduleSetupStatus();
  
  if (setupStatus.needsSetup) {
    print('AuthGuard: Admin needs to complete schedule setup, allowing access to dashboard only');
    // Allow access only to dashboard - the dashboard will show the setup prompt
    if (routePath != '/admin/dashboard') {
      print('AuthGuard: Redirecting to dashboard for schedule setup');
      return '/admin/dashboard';
    }
  }
}
```

### Helper Method

Added `_isScheduleSetupRoute()` to allow access to setup-related routes:

```dart
/// Check if route is related to schedule setup (should not block these routes)
static bool _isScheduleSetupRoute(String routePath) {
  // Routes that are part of the schedule setup process should not be blocked
  return routePath == '/admin/clinic-schedule' || 
         routePath == '/admin/vet-profile';
}
```

## How It Works

### Flow Diagram

```
User attempts navigation
    ↓
AuthGuard.validateRouteAccess(route)
    ↓
Is user authenticated? → No → Redirect to login
    ↓ Yes
Is user an admin on web? → No → Continue to role validation
    ↓ Yes
Is route setup-related? → Yes → Allow access
    ↓ No
Check schedule setup status
    ↓
Needs setup? → No → Allow access to route
    ↓ Yes
Is route /admin/dashboard? → Yes → Allow (dashboard shows setup UI)
    ↓ No
Redirect to /admin/dashboard
    ↓
Dashboard displays setup prompt
```

### Allowed Routes During Setup

1. **`/admin/dashboard`** - Shows the setup prompt/banner
2. **`/admin/clinic-schedule`** - Needed to configure clinic hours
3. **`/admin/vet-profile`** - Needed to complete vet profile

All other admin routes are blocked and redirect to the dashboard.

## Multi-Layer Defense Strategy

### Layer 1: Router-Level Guard (Primary)
- **File**: `lib/core/guards/auth_guard.dart`
- **Trigger**: Every route change via `go_router`
- **Action**: Redirects to dashboard if setup incomplete
- **Prevents**: URL manipulation, direct navigation, menu clicks

### Layer 2: Dashboard UI (Secondary)
- **File**: `lib/pages/web/admin/dashboard_screen.dart`
- **Component**: `AdminDashboardWithSetupCheck`
- **Action**: Shows full-screen prompt or banner
- **Provides**: User-friendly interface

### Layer 3: Database Enforcement (Foundation)
- **File**: `lib/core/services/super_admin/super_admin_service.dart`
- **Trigger**: Super admin approval
- **Action**: Sets `scheduleStatus: 'pending'`, `isVisible: false`
- **Ensures**: Data integrity

### Layer 4: User Feedback
- **Files**: `schedule_setup_components.dart`, `schedule_setup_modal.dart`
- **Action**: Shows visibility warnings in 3 places
- **Provides**: Clear expectations

## Benefits

### Security
✅ No bypass via navigation menu
✅ No bypass via direct URL entry
✅ No bypass via browser navigation
✅ No bypass via bookmarks

### User Experience
✅ Clear, consistent messaging
✅ Guides admin through setup
✅ Cannot accidentally skip setup
✅ Dashboard provides setup interface

### Data Integrity
✅ Clinic always has schedule before going live
✅ Database state matches UI state
✅ Visibility flag accurately reflects readiness

### Maintainability
✅ Single point of enforcement (AuthGuard)
✅ Reusable service (ScheduleSetupGuard)
✅ Clear separation of concerns
✅ Easy to modify allowed routes

## Testing

### Test Cases

#### 1. Fresh Admin (Just Approved)
```bash
# Setup: Super admin just approved clinic
# Expected: All routes redirect to dashboard except setup routes

Navigate to /admin/appointments → Redirects to /admin/dashboard ✓
Navigate to /admin/patient-records → Redirects to /admin/dashboard ✓
Navigate to /admin/messaging → Redirects to /admin/dashboard ✓
Navigate to /admin/clinic-schedule → Allowed ✓
Navigate to /admin/vet-profile → Allowed ✓
Navigate to /admin/dashboard → Shows setup prompt ✓
```

#### 2. Setup In Progress
```bash
# Setup: Admin started setup (scheduleStatus: 'in_progress')
# Expected: All routes accessible, dashboard shows banner

Navigate to /admin/appointments → Allowed ✓
Navigate to /admin/patient-records → Allowed ✓
Navigate to /admin/dashboard → Shows banner ✓
```

#### 3. Setup Completed
```bash
# Setup: Admin completed setup (scheduleStatus: 'completed')
# Expected: All routes accessible, no prompts

Navigate to /admin/appointments → Allowed ✓
Navigate to /admin/dashboard → Normal dashboard ✓
No prompts or banners shown ✓
```

### Manual Testing Steps

1. **Create a test admin account**
   - Sign up as clinic admin
   - Wait for super admin approval

2. **Verify enforcement**
   - Try clicking navigation menu items → Should redirect to dashboard
   - Try entering URLs directly → Should redirect to dashboard
   - Try using browser back button → Should redirect to dashboard
   - Verify dashboard shows setup prompt

3. **Start setup**
   - Click "Start Setup" button
   - Verify modal opens
   - Verify warning message is displayed

4. **Complete setup**
   - Configure clinic schedule
   - Complete vet profile
   - Verify status updates to 'completed'
   - Verify prompts/banners disappear

5. **Post-setup verification**
   - Navigate to all admin pages → Should work normally
   - Verify clinic is visible to users
   - Check database: `isVisible: true`, `scheduleStatus: 'completed'`

## Troubleshooting

### Admin can still access other pages

**Cause**: Router guard may not be running
**Check**:
1. Open browser DevTools console (F12)
2. Look for AuthGuard logs when navigating
3. Expected logs:
   ```
   AuthGuard: User authenticated - UID: xxx, Role: admin
   AuthGuard: Checking schedule setup status for admin user
   AuthGuard: Admin needs to complete schedule setup
   AuthGuard: Redirecting to dashboard for schedule setup
   ```

**Fix**: Ensure `go_router` is configured with `redirect: _handleRedirect`

### Setup prompt not showing

**Cause**: Dashboard not wrapped with `AdminDashboardWithSetupCheck`
**Check**: `lib/pages/web/admin/dashboard_screen.dart` should use FutureBuilder with setup check
**Fix**: Verify dashboard implementation matches documentation

### Infinite redirect loop

**Cause**: Dashboard itself might be redirecting
**Check**: Console logs for repeated redirects
**Fix**: Ensure dashboard route (`/admin/dashboard`) is allowed when setup needed

### Schedule setup routes blocked

**Cause**: Routes not in `_isScheduleSetupRoute()` whitelist
**Fix**: Add route to `_isScheduleSetupRoute()` method in `auth_guard.dart`:
```dart
static bool _isScheduleSetupRoute(String routePath) {
  return routePath == '/admin/clinic-schedule' || 
         routePath == '/admin/vet-profile' ||
         routePath == '/admin/your-new-route'; // Add here
}
```

## Migration Notes

### Before (Page-Level Wrapping)
- Needed to wrap every admin page with `ScheduleSetupNavigationGuard`
- Easy to miss pages
- Inconsistent enforcement
- Maintenance burden

### After (Router-Level)
- Single enforcement point in `AuthGuard`
- Automatic for all routes
- Consistent behavior
- Easier to maintain

### Removing Old Page-Level Guards

If you previously wrapped pages with `ScheduleSetupNavigationGuard`, you can now remove those wrappers:

```dart
// OLD (can be removed):
@override
Widget build(BuildContext context) {
  return ScheduleSetupNavigationGuard(
    child: Scaffold(...),
  );
}

// NEW (router handles it):
@override
Widget build(BuildContext context) {
  return Scaffold(...);
}
```

## Future Enhancements

### Disable Navigation Menu Items
- Grey out menu items when setup incomplete
- Show tooltip: "Complete clinic schedule setup first"
- Visual indication of restricted access

### Progress Indicator
- Show setup completion percentage in banner
- Highlight next required step
- Celebrate completion with animation

### Email Reminder
- Send reminder email if setup not completed within 24 hours
- Include direct link to schedule setup
- Tips for completing setup quickly

## Related Files

### Core Implementation
- `lib/core/guards/auth_guard.dart` - Router-level enforcement
- `lib/core/services/admin/schedule_setup_guard.dart` - Status checking service
- `lib/pages/web/admin/dashboard_screen.dart` - UI layer enforcement

### UI Components
- `lib/core/widgets/admin/schedule/schedule_setup_components.dart` - Prompt & banner
- `lib/core/widgets/admin/schedule/schedule_setup_modal.dart` - Setup wizard
- `lib/core/widgets/admin/schedule/schedule_settings_modal.dart` - Schedule config

### Super Admin Integration
- `lib/core/services/super_admin/super_admin_service.dart` - Approval process
- Database initialization on approval

## Summary

The router-level schedule setup enforcement provides:
- **Complete Protection**: No bypasses possible
- **Single Point of Control**: Easier to maintain
- **Better UX**: Consistent behavior across all routes
- **Data Integrity**: Ensures setup before clinic goes live
- **Visibility**: Clear warnings and guidance

This implementation follows best practices for route guarding in Flutter/go_router applications and ensures data integrity through multi-layer enforcement.
