# Alert Double Notification Fix

## Problem Analysis

Users were receiving **double notifications** for automatically cancelled and no-show appointments:

### Example Issues:
1. **Auto-Cancelled Appointments:**
   - User receives: "Appointment Automatically Cancelled" ✅ (Specific)
   - User also receives: "Appointment Cancelled" ❌ (Generic duplicate)

2. **No-Show Appointments:**
   - User receives: "Appointment Marked as No Show" ✅ (Specific)
   - User also receives: "Appointment Cancelled" ❌ (Generic duplicate)

## Root Cause

The notification system had two pathways creating notifications:

1. **Specific Notification Path** (Correct):
   - `AppointmentAutoCancellationService` → Creates "Appointment Automatically Cancelled"
   - `AppointmentService.markAsNoShow()` → Creates "Appointment Marked as No Show"

2. **Generic Notification Path** (Duplicate):
   - When appointment status changes to `cancelled`, the system also triggered generic "Appointment Cancelled" notifications through:
     - `AppointmentService.updateAppointmentStatus()`
     - `AppointmentBookingService.updateAppointmentStatus()`
   - These methods call `AppointmentBookingIntegration.onAppointmentStatusChanged()`
   - Which creates a generic cancellation notification

## Solution Implemented

### 1. Added No-Show Detection in Status Change Handlers

**File: `lib/core/services/clinic/appointment_service.dart`**

Added check for `isNoShow` flag alongside existing `autoCancelled` check:

```dart
// Check if this is an auto-cancelled or no-show appointment
final updatedDoc = await _firestore.collection(_collection).doc(appointmentId).get();
final isAutoCancelled = updatedDoc.data()?['autoCancelled'] == true;
final isNoShow = updatedDoc.data()?['isNoShow'] == true;

if (isAutoCancelled) {
  print('⏰ Skipping onAppointmentStatusChanged for auto-cancelled appointment: $appointmentId');
} else if (isNoShow) {
  print('🚫 Skipping onAppointmentStatusChanged for no-show appointment: $appointmentId');
} else {
  // Only create generic notification for regular cancellations
  await AppointmentBookingIntegration.onAppointmentStatusChanged(...);
}
```

**File: `lib/core/services/mobile/appointment_booking_service.dart`**

Applied the same fix to the mobile service to ensure consistency.

### 2. Added Early Return for No-Show in Cancellation Handler

**File: `lib/core/services/notifications/appointment_booking_integration.dart`**

Added `isNoShow` parameter and early return to skip generic notification:

```dart
static Future<void> onAppointmentCancelled({
  required String userId,
  required String petName,
  required String clinicName,
  required DateTime appointmentDate,
  required String appointmentTime,
  String? appointmentId,
  String? cancelReason,
  bool cancelledByClinic = false,
  bool isAutoCancelled = false,
  bool isNoShow = false,  // NEW PARAMETER
}) async {
  try {
    // Skip notification if this is a no-show (has its own specific notification)
    if (isNoShow) {
      print('⏭️ Skipping generic cancellation notification for no-show appointment');
      return;
    }
    
    // ... rest of notification creation
  }
}
```

### 3. Added Protection in Notification Update Method

**File: `lib/core/services/notifications/notification_service.dart`**

Added defensive check in `updateAppointmentStatusNotification` to prevent updating existing notifications with generic "Appointment Cancelled" when the appointment is no-show or auto-cancelled:

```dart
static Future<void> updateAppointmentStatusNotification({
  ...
}) async {
  try {
    // IMPORTANT: Check if this is a no-show or auto-cancelled appointment
    // These have their own specific notifications and should not be updated here
    if (newStatus == 'cancelled') {
      try {
        final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
        if (appointmentDoc.exists) {
          final appointmentData = appointmentDoc.data();
          final isNoShow = appointmentData?['isNoShow'] == true;
          final isAutoCancelled = appointmentData?['autoCancelled'] == true;
          
          if (isNoShow) {
            print('🚫 Skipping generic notification update for no-show appointment');
            return; // Don't update - specific no-show notification already created
          }
          
          if (isAutoCancelled) {
            print('⏰ Skipping generic notification update for auto-cancelled appointment');
            return; // Don't update - specific auto-cancel notification already created
          }
        }
      } catch (e) {
        print('⚠️ Could not check appointment flags: $e');
        // Continue with generic notification if check fails
      }
    }
    
    // ... rest of notification update logic
  }
}
```

This third layer of protection ensures that even if an existing notification is found in the database, it won't be updated with the generic "Appointment Cancelled" title when the cancellation is due to no-show or auto-cancellation.

## How It Works Now

### Auto-Cancelled Appointments Flow:
1. `AppointmentAutoCancellationService._cancelExpiredAppointment()`
2. Sets `autoCancelled: true` in Firestore **BEFORE** setting status to cancelled
3. Creates specific notification: "Appointment Automatically Cancelled"
4. When `updateAppointmentStatus` is triggered, it checks `autoCancelled` flag
5. **Skips generic "Appointment Cancelled" notification** ✅

### No-Show Appointments Flow:
1. Admin marks appointment as no-show via `AppointmentService.markAsNoShow()`
2. Sets `isNoShow: true` in Firestore along with status = cancelled
3. Creates specific notification: "Appointment Marked as No Show"
4. When `updateAppointmentStatus` is triggered, it checks `isNoShow` flag
5. **Skips generic "Appointment Cancelled" notification** ✅

### Regular Cancellations (Admin or User):
1. Admin/User cancels appointment normally
2. NO special flags set (`autoCancelled` = false, `isNoShow` = false)
3. Creates generic notification: "Appointment Cancelled" with reason ✅
4. This is the **only notification** the user receives ✅

## Files Modified

1. **`lib/core/services/clinic/appointment_service.dart`**
   - Added `isNoShow` check in `updateAppointmentStatus()`
   - Skips generic notification for no-show appointments

2. **`lib/core/services/mobile/appointment_booking_service.dart`**
   - Added `isNoShow` check in `updateAppointmentStatus()`
   - Ensures consistency across mobile and admin services

3. **`lib/core/services/notifications/appointment_booking_integration.dart`**
   - Added `isNoShow` parameter to `onAppointmentCancelled()`
   - Early return to skip generic notification for no-show

4. **`lib/core/services/notifications/notification_service.dart`** ⭐ NEW
   - Added defensive check in `updateAppointmentStatusNotification()`
   - Prevents updating existing notifications with generic "Appointment Cancelled"
   - Reads appointment flags before updating notification
   - Third layer of protection against wrong notification titles

## Testing Checklist

- [ ] **Auto-Cancelled Appointment:**
  - Create a pending appointment in the past
  - Trigger auto-cancellation service
  - Verify only ONE notification: "Appointment Automatically Cancelled"
  - No generic "Appointment Cancelled" notification

- [ ] **No-Show Appointment:**
  - Create a confirmed appointment
  - Mark as no-show from admin panel
  - Verify only ONE notification: "Appointment Marked as No Show"
  - No generic "Appointment Cancelled" notification

- [ ] **Regular Cancellation by Admin:**
  - Create any appointment
  - Cancel from admin panel
  - Verify only ONE notification: "Appointment Cancelled" with reason
  - Correct and expected behavior

- [ ] **Regular Cancellation by User:**
  - Create any appointment
  - Cancel from mobile app
  - Verify only ONE notification: "Appointment Cancelled"
  - Correct and expected behavior

## Expected Behavior

| Cancellation Type | Notifications User Receives | Count |
|------------------|------------------------------|-------|
| **Auto-Cancelled** | "Appointment Automatically Cancelled" | 1 |
| **Marked as No Show** | "Appointment Marked as No Show" | 1 |
| **Admin Cancels (Regular)** | "Appointment Cancelled" + reason | 1 |
| **User Cancels** | "Appointment Cancelled" | 1 |

## Impact

✅ **Eliminates duplicate notifications** for auto-cancelled and no-show appointments

✅ **Maintains clear, specific messaging** for each cancellation scenario

✅ **No breaking changes** - regular cancellations still work as before

✅ **Consistent behavior** across mobile and admin services

## Related Files

- Auto-cancellation logic: `lib/core/services/clinic/appointment_auto_cancellation_service.dart`
- No-show marking: `lib/core/services/clinic/appointment_service.dart` (line 856)
- Notification models: `lib/core/models/notifications/notification_model.dart`
- Alert display: `lib/pages/mobile/alerts_page.dart`

## Date
October 18, 2025
