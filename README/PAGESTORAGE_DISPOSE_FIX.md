# PageStorage Dispose Error Fix

## Error Description
```
Looking up a deactivated widget's ancestor is unsafe.
At this point the state of the widget's element tree is no longer stable.
To safely refer to a widget's ancestor in its dispose() method, save a reference to the ancestor by
calling dependOnInheritedWidgetOfExactType() in the widget's didChangeDependencies() method.
```

**Location:** `dashboard_screen.dart` line 82, 137  
**Trigger:** Signing out while on the dashboard screen  
**Root Cause:** `_saveState()` called in `dispose()` trying to access `PageStorage.of(context)` when context is already deactivated

## Problem Analysis

### The Issue
When signing out, the widget tree is rapidly torn down. The `DashboardScreen` tries to save its state to `PageStorage` in the `dispose()` method, but by that time:
1. The context is already deactivated
2. The PageStorage ancestor may no longer be accessible
3. Calling `PageStorage.of(context)` throws an assertion error

### Why It Happens
During sign out → navigation to login:
```
User clicks Sign Out
    ↓
authService.signOut() completes
    ↓
context.go('/web_login') triggers navigation
    ↓
Widget tree begins unmounting (deactivation)
    ↓
DashboardScreen.dispose() called
    ↓
_saveState() tries PageStorage.of(context)
    ↓
❌ ERROR: Context already deactivated
```

## Solution Implemented

### 1. Guard dispose() Method
**File:** `lib/pages/web/admin/dashboard_screen.dart`

```dart
@override
void dispose() {
  // Try to save state, but don't fail if context is already deactivated
  try {
    if (mounted) {
      _saveState();
    }
  } catch (e) {
    // Context might be deactivated during sign out - safe to ignore
    AppLogger.debug('Could not save state on dispose (widget deactivated): $e');
  }
  
  // Cancel listener and debounce timer when widget is disposed
  _appointmentsListener?.cancel();
  _refreshDebounceTimer?.cancel();
  super.dispose();
}
```

### 2. Safe _saveState() Implementation

**Before:**
```dart
void _saveState() {
  final storage = PageStorage.of(context);
  storage.writeState(context, selectedPeriod, identifier: 'selectedPeriod');
  print('💾 Saved dashboard state: period="$selectedPeriod"');
}
```

**After:**
```dart
void _saveState() {
  // Guard against accessing deactivated context (e.g., during sign out)
  if (!mounted) {
    AppLogger.debug('Cannot save state - widget not mounted');
    return;
  }
  
  try {
    final storage = PageStorage.maybeOf(context);
    if (storage != null) {
      storage.writeState(context, selectedPeriod, identifier: 'selectedPeriod');
      print('💾 Saved dashboard state: period="$selectedPeriod"');
    } else {
      AppLogger.debug('PageStorage not available - skipping state save');
    }
  } catch (e) {
    AppLogger.debug('Error saving state: $e');
  }
}
```

**Key Changes:**
- ✅ Check `mounted` before proceeding
- ✅ Use `PageStorage.maybeOf()` instead of `PageStorage.of()` (returns null if not found instead of throwing)
- ✅ Wrap in try-catch for additional safety
- ✅ Log debug messages instead of crashing

### 3. Safe _restoreState() Implementation

**Before:**
```dart
void _restoreState() {
  final storage = PageStorage.of(context);
  final savedPeriod = storage.readState(context, identifier: 'selectedPeriod');
  if (savedPeriod != null && savedPeriod is String) {
    _safeSetState(() {
      selectedPeriod = savedPeriod;
    });
    print('🔄 Restored dashboard state: period="$selectedPeriod"');
  }
}
```

**After:**
```dart
void _restoreState() {
  if (!mounted) return;
  
  try {
    final storage = PageStorage.maybeOf(context);
    if (storage == null) {
      AppLogger.debug('PageStorage not available - skipping state restore');
      return;
    }
    
    final savedPeriod = storage.readState(context, identifier: 'selectedPeriod');
    if (savedPeriod != null && savedPeriod is String) {
      _safeSetState(() {
        selectedPeriod = savedPeriod;
      });
      print('🔄 Restored dashboard state: period="$selectedPeriod"');
    }
  } catch (e) {
    AppLogger.debug('Error restoring state: $e');
  }
}
```

## Best Practices Applied

### ✅ 1. Use maybeOf() Instead of of()
```dart
// ❌ BAD: Throws if not found
final storage = PageStorage.of(context);

// ✅ GOOD: Returns null if not found
final storage = PageStorage.maybeOf(context);
```

### ✅ 2. Always Check mounted Before Context Access
```dart
if (!mounted) return;
```

### ✅ 3. Wrap Context Lookups in Try-Catch
```dart
try {
  // Context access
} catch (e) {
  // Log and continue gracefully
}
```

### ✅ 4. Guard dispose() Context Access
```dart
@override
void dispose() {
  try {
    if (mounted) {
      // Safe to access context
    }
  } catch (e) {
    // Handle gracefully
  }
  super.dispose();
}
```

## Expected Behavior After Fix

### Sign-Out Flow (Console Output)
```
🔒 Starting sign out process...
  ✓ Cleared token manager
  ✓ Cleared messaging session data
  ✓ Cleared AuthGuard cache
  ✓ Cleared screen state service
  ✓ Cleared notification cache
  ✓ Signed out from Firebase Auth
✅ Sign out complete - all caches and state cleared
Cannot save state - widget not mounted  ← Safe debug log, no crash
AuthGuard.validateRouteAccess() called for: /web_login
✅ Successfully navigated to login
```

### No More Errors
- ✅ No "Looking up deactivated widget's ancestor" error
- ✅ No red error screen
- ✅ Smooth sign-out → login transition
- ✅ State saved when possible, gracefully skipped when not

## Testing Verification

### Test Case 1: Normal Sign Out
1. Sign in as admin
2. Use dashboard normally
3. Click Sign Out
4. **Expected:** Smooth transition to login, no errors ✅

### Test Case 2: Rapid Navigation + Sign Out
1. Sign in
2. Rapidly switch between screens
3. Click Sign Out while dashboard is loading
4. **Expected:** No crash, graceful degradation ✅

### Test Case 3: State Preservation
1. Change dashboard period to "Weekly"
2. Navigate away
3. Come back to dashboard
4. **Expected:** Period still "Weekly" (state saved) ✅

## Related Fixes

This fix complements the comprehensive sign-out cleanup:
- **Sign-Out Cleanup:** Clears all caches and state (see `COMPREHENSIVE_SIGNOUT_CLEANUP.md`)
- **PageStorage Safety:** Prevents crashes when saving state during rapid widget disposal

## File Changes Summary

### Modified Files
1. **`lib/pages/web/admin/dashboard_screen.dart`**
   - `dispose()` - Added mounted check and try-catch
   - `_saveState()` - Use `maybeOf()`, added guards
   - `_restoreState()` - Use `maybeOf()`, added guards

### No Breaking Changes
- ✅ Existing functionality preserved
- ✅ State still saved/restored when possible
- ✅ Graceful degradation when not possible

---

**Date:** October 22, 2025  
**Issue:** PageStorage disposal error during sign out  
**Status:** ✅ Fixed  
**Impact:** Prevents red error screen on sign out
