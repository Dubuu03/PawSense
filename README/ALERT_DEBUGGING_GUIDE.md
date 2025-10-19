# Alert System Debugging Guide

## Current Issue Status

You reported:
1. **Auto-cancelled appointments**: Still showing BOTH notifications ❌
2. **No-show appointments**: Only showing generic "Appointment Cancelled" instead of "Appointment Marked as No Show" ❌

## Latest Changes Made

### 1. Added No-Show Check in Admin Notification Listener
**File:** `admin_appointment_notification_integrator.dart`
- Added `isNoShow` flag check alongside `autoCancelled` check
- Prevents admin listener from creating duplicate notifications

### 2. Enhanced Debug Logging
Added comprehensive logging to track notification creation:

**In `appointment_booking_integration.dart`:**
- Logs notification title and message when created
- Adds `notificationSource` to metadata for tracking

**In `notification_service.dart`:**
- Logs when `updateAppointmentStatusNotification` is called
- Shows which checks are being performed
- Logs final notification title and message

## Testing Steps

### Step 1: Clear Old Notifications
Before testing, **clear all existing notifications** from your database:

```
Firebase Console → Firestore → notifications collection → Delete all documents
```

This ensures you're not seeing old notifications that were created before the fix.

### Step 2: Test Auto-Cancellation

1. **Create a pending appointment** with date = yesterday (or earlier)
2. **Run auto-cancellation** service (or wait for it to trigger)
3. **Check terminal logs** for these messages:

```
Expected logs:
🔄 Marking appointment as auto-cancelled...
✅ Cancellation notification created for user [userId] (auto: true)
   📋 Title: "Appointment Automatically Cancelled"
   📝 Message: "Your appointment for..."
⏰ Skipping generic notification update for auto-cancelled appointment: [appointmentId]
   ✅ Specific auto-cancel notification should handle this
```

4. **Check alerts page** - Should see ONLY:
   - ✅ "Appointment Automatically Cancelled"

**If you see both notifications:**
- Check logs to see if `updateAppointmentStatusNotification` was called
- Check if it found the `autoCancelled` flag
- Check Firestore to confirm `autoCancelled: true` is set

### Step 3: Test No-Show

1. **Create a confirmed appointment**
2. **Mark as no-show** from admin panel
3. **Check terminal logs** for these messages:

```
Expected logs:
🔄 Marking appointment [id] as no-show...
🔔 Creating NO SHOW notification for user: [userId]
✅ No-show notification created for user [userId]
   📋 Title: "Appointment Marked as No Show"
   📝 Message: "Your appointment for..."
🚫 Skipping generic notification update for no-show appointment: [appointmentId]
   ✅ Specific no-show notification should handle this
```

4. **Check alerts page** - Should see ONLY:
   - ✅ "Appointment Marked as No Show"

**If you see generic "Appointment Cancelled":**
- Check if specific no-show notification was created (look for the log)
- Check if `updateAppointmentStatusNotification` was called after
- Check if it skipped due to `isNoShow` flag
- Check Firestore to confirm `isNoShow: true` is set

## Debugging Checklist

### If Still Getting Double Notifications:

**1. Check Firestore Document Flags:**
```
Firebase Console → appointments → [appointmentId]
Should see:
- autoCancelled: true (for auto-cancelled)
- isNoShow: true (for no-show)
- status: "cancelled"
```

**2. Check Notification Creation Order:**
Look at terminal timestamps to see which notification was created first.

**3. Check Notification Metadata:**
```
Firebase Console → notifications → [notificationId] → metadata
Should include:
- notificationSource: "onAppointmentCancelled" or "onAppointmentNoShow" or "updateAppointmentStatusNotification"
```

This tells you WHERE the notification came from.

**4. Check for Multiple Listeners:**
Search logs for:
```
🔔 Initializing appointment notification listener
```
If you see this multiple times, you have duplicate listeners creating duplicate notifications.

### If Getting Wrong Notification Title:

**1. Check if Specific Notification Was Created:**
Search logs for:
```
✅ No-show notification created for user
   📋 Title: "Appointment Marked as No Show"
```

If you DON'T see this, the specific notification wasn't created.

**2. Check if Generic Notification Updated It:**
Search logs for:
```
🔄 updateAppointmentStatusNotification called:
   📊 Status: confirmed → cancelled
```

If this appears AFTER the specific notification, it might be overwriting it.

**3. Check Notification Count:**
```
Firebase Console → notifications collection
Filter by: userId = [your test user]
```
You should see only ONE notification per appointment cancellation.

## Common Issues & Solutions

### Issue 1: Old Notifications Not Cleared
**Symptom:** Seeing notifications from previous tests
**Solution:** Delete all notifications from Firestore before testing

### Issue 2: Race Condition
**Symptom:** Sometimes works, sometimes doesn't
**Solution:** Check if flags are set BEFORE status change in Firestore update

### Issue 3: Multiple Listeners
**Symptom:** Always getting duplicates
**Solution:** Check for multiple calls to `initializeAppointmentListeners()`

### Issue 4: Notification Being Updated After Creation
**Symptom:** Correct notification created but title changes
**Solution:** Check if `updateAppointmentStatusNotification` is being called and not skipping

## Log Pattern Analysis

### Correct Flow for Auto-Cancellation:
```
1. 🔄 Marking appointment as auto-cancelled...
2. ✅ Cancellation notification created (auto: true)
   📋 Title: "Appointment Automatically Cancelled"
3. 🔄 updateAppointmentStatusNotification called (if any)
4. ⏰ Skipping generic notification update for auto-cancelled
```

### Correct Flow for No-Show:
```
1. 🔄 Marking appointment as no-show...
2. 🔔 Creating NO SHOW notification
3. ✅ No-show notification created
   📋 Title: "Appointment Marked as No Show"
4. 🔄 updateAppointmentStatusNotification called (if any)
5. 🚫 Skipping generic notification update for no-show
```

### Incorrect Flow (Double Notification):
```
1. ✅ Specific notification created ✅
2. 🔄 updateAppointmentStatusNotification called
3. ❌ DID NOT SKIP (flag not found or not checked)
4. ℹ️ Creating new generic notification ❌
```

## Next Steps

1. **Run the tests above** with terminal logs visible
2. **Copy and send me the relevant logs** showing:
   - When the appointment is marked as no-show/auto-cancelled
   - What notifications are created
   - What checks are performed
   - What the final notification titles are

3. **Check Firestore directly** and send me screenshots of:
   - The appointment document (showing flags)
   - The notifications created (showing titles and metadata)

4. **If still seeing issues**, we may need to add a **short delay** between setting flags and changing status to avoid race conditions.

## Emergency Fix (If All Else Fails)

If the issue persists, we can implement a **notification deduplication** system:

1. Before creating any cancellation notification, check if one already exists
2. Delete any generic "Appointment Cancelled" notification if a specific one exists
3. Prevent creation of generic notification if specific notification was created in last 5 seconds

Let me know what you see in the logs!

---
**Date:** October 18, 2025
**Status:** 🔍 Debugging In Progress
