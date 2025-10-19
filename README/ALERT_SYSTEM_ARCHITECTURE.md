# Alert System Architecture

## Overview

The PawSense alert system manages notifications for users and admins regarding appointments, messages, and other important events. This document provides a comprehensive understanding of how alerts work.

## Key Components

### 1. Notification Models
**File:** `lib/core/models/notifications/notification_model.dart`

Defines the structure of notifications:
- `NotificationModel`: Core notification data structure
- `NotificationCategory`: appointment, message, task, system, etc.
- `NotificationPriority`: low, medium, high, urgent

### 2. Notification Service
**File:** `lib/core/services/notifications/notification_service.dart`

Central service managing all notifications:
- Creates and stores notifications in Firestore
- Provides streams for real-time notification updates
- Manages read/unread states
- Handles virtual notifications (appointment status changes)
- Implements notification cache to reduce database queries

### 3. Appointment Notification Integration
**File:** `lib/core/services/notifications/appointment_booking_integration.dart`

Bridges appointment events to notification creation:
- `onAppointmentBooked()`: New appointment submitted
- `onAppointmentStatusChanged()`: Status updates (confirmed, cancelled, etc.)
- `onAppointmentCancelled()`: Specific cancellation notifications
- `onAppointmentNoShow()`: No-show notifications

### 4. Admin Notification Integrator
**File:** `lib/core/services/admin/admin_appointment_notification_integrator.dart`

Manages admin-side notifications:
- New appointment requests
- Appointment confirmations
- Cancellations by users
- Auto-cancellations
- No-show markings

## Notification Flow

### Scenario 1: User Books Appointment

```
User submits booking
    ↓
AppointmentBookingService.bookAppointment()
    ↓
AppointmentBookingIntegration.onAppointmentBooked()
    ↓
NotificationService.createPendingAppointmentNotification()
    ↓
User sees: "Appointment Request Sent"
Admin sees: "New Appointment Request"
```

### Scenario 2: Admin Confirms Appointment

```
Admin confirms appointment
    ↓
AppointmentService.updateAppointmentStatus(status: confirmed)
    ↓
Checks: isAutoCancelled? isNoShow? (both false)
    ↓
AppointmentBookingIntegration.onAppointmentStatusChanged()
    ↓
NotificationService.updateAppointmentStatusNotification()
    ↓
User sees: "Appointment Confirmed"
```

### Scenario 3: Auto-Cancelled Appointment (FIXED)

```
Appointment date passes without confirmation
    ↓
AppointmentAutoCancellationService.processExpiredAppointments()
    ↓
Sets autoCancelled: true in Firestore FIRST
    ↓
Sets status: cancelled
    ↓
AppointmentBookingIntegration.onAppointmentCancelled(isAutoCancelled: true)
    ↓
NotificationService.createNotification()
    ↓
User sees: "Appointment Automatically Cancelled" (1 notification only) ✅
    ↓
[SKIPPED] Generic "Appointment Cancelled" due to autoCancelled flag ✅
```

### Scenario 4: No-Show Appointment (FIXED)

```
Admin marks appointment as no-show
    ↓
AppointmentService.markAsNoShow()
    ↓
Sets isNoShow: true in Firestore
    ↓
Sets status: cancelled
    ↓
AppointmentBookingIntegration.onAppointmentNoShow()
    ↓
NotificationService.createNotification()
    ↓
User sees: "Appointment Marked as No Show" (1 notification only) ✅
    ↓
[SKIPPED] Generic "Appointment Cancelled" due to isNoShow flag ✅
```

### Scenario 5: Regular Cancellation

```
Admin/User cancels appointment
    ↓
AppointmentService.updateAppointmentStatus(status: cancelled)
    ↓
Checks: isAutoCancelled? (false), isNoShow? (false)
    ↓
AppointmentBookingIntegration.onAppointmentStatusChanged()
    ↓
NotificationService.updateAppointmentStatusNotification()
    ↓
User sees: "Appointment Cancelled" + reason (1 notification) ✅
```

## Alert Display

### Alert Page
**File:** `lib/pages/mobile/alerts_page.dart`

Features:
- Displays all user notifications in chronological order
- Shows unread count badge
- Pull-to-refresh functionality
- Infinite scroll pagination
- Marks alerts as read on tap
- Navigates to relevant pages (appointment details, etc.)

### Alert Components
**Files:**
- `lib/core/widgets/user/alerts/alerts.dart` - Main alert widget
- `lib/core/widgets/user/alerts/alert_item.dart` - Individual alert card
- `lib/core/widgets/user/alerts/optimized_alert_list.dart` - Performance-optimized list

## Notification Types

### Real Notifications
Stored in Firestore `notifications` collection:
- Appointment booked
- Appointment confirmed
- **Appointment cancelled (regular)**
- **Appointment auto-cancelled** ✅
- **Appointment marked as no-show** ✅
- Appointment completed
- Messages from clinic
- System announcements

### Virtual Notifications
Generated on-the-fly from other data:
- Appointment status changes (pending → confirmed)
- Appointment reminders (7 days before)
- Message unread counts

**Note:** The system avoids creating virtual notifications when real notifications exist for the same event to prevent duplicates.

## Deduplication Strategy

### Problem Solved
Previously, users received duplicate notifications for:
1. Auto-cancelled appointments (specific + generic)
2. No-show appointments (specific + generic)

### Solution
1. **Flag-Based Detection:**
   - `autoCancelled: true` flag set BEFORE status change
   - `isNoShow: true` flag set BEFORE status change

2. **Skip Generic Notifications:**
   - Check flags before creating generic "Appointment Cancelled"
   - Only create specific notifications for special cases
   - Allow generic notification for regular cancellations

3. **Implemented in Multiple Services:**
   - `AppointmentService.updateAppointmentStatus()` (admin)
   - `AppointmentBookingService.updateAppointmentStatus()` (mobile)
   - Both check for special flags and skip generic notifications

## Cache Management

The notification service implements caching to reduce database queries:

1. **Local Read Cache:**
   - Stores notification IDs marked as read
   - Provides instant UI updates
   - Syncs with Firestore in background

2. **Appointment Notification Cache:**
   - Tracks which appointments have real notifications
   - Prevents duplicate virtual notification generation
   - Cleared when real notifications are created/updated

## Performance Optimizations

1. **Reduced Polling Frequency:**
   - Unread count updates every 60 seconds (was more frequent)
   - Prevents excessive database queries

2. **Pagination:**
   - Loads 50 notifications initially
   - Infinite scroll for older notifications
   - Improves initial load time

3. **Firestore Query Limits:**
   - Appointment notifications: 20 most recent
   - Message notifications: All unread
   - Task notifications: 20 most recent

4. **Virtual Notification Check:**
   - Caches results to avoid repeated database queries
   - Only checks database if not in cache

## Best Practices

### Creating New Notifications

1. **Always use appropriate integration method:**
   ```dart
   // For appointment events
   await AppointmentBookingIntegration.onAppointmentBooked(...);
   
   // For status changes
   await AppointmentBookingIntegration.onAppointmentStatusChanged(...);
   ```

2. **Set special flags BEFORE status changes:**
   ```dart
   // For auto-cancellation
   await _firestore.collection('appointments').doc(id).update({
     'autoCancelled': true,  // Set flag FIRST
     'status': 'cancelled',  // Then change status
   });
   ```

3. **Check for existing notifications:**
   ```dart
   // Avoid duplicates by checking first
   final existing = await _firestore
     .collection('notifications')
     .where('userId', isEqualTo: userId)
     .where('metadata.appointmentId', isEqualTo: appointmentId)
     .get();
   ```

### Testing Notifications

1. Test all notification scenarios:
   - Create, confirm, cancel appointments
   - Trigger auto-cancellation (set old dates)
   - Mark as no-show
   - Check for duplicates

2. Verify notification counts:
   - Each event should produce exactly ONE user notification
   - Check both alerts page and unread count badge

3. Test across services:
   - Mobile app cancellations
   - Admin panel cancellations
   - Auto-cancellation service

## Troubleshooting

### Double Notifications
- Check if special flags (`autoCancelled`, `isNoShow`) are set
- Verify flags are set BEFORE status changes
- Ensure `onAppointmentStatusChanged` checks flags

### Missing Notifications
- Check Firestore `notifications` collection
- Verify userId matches
- Check notification expiration dates
- Clear local cache: `NotificationService.clearReadCache()`

### Incorrect Unread Count
- Trigger immediate update: `NotificationService.triggerUpdate()`
- Check virtual notification read states
- Verify read state storage in `user_preferences` collection

## Related Documentation

- [Alerts Page Implementation](./ALERTS_PAGE_IMPLEMENTATION.md)
- [Alerts Performance Optimization](./ALERTS_PERFORMANCE_OPTIMIZATION.md)
- [Admin Notification Complete](./ADMIN_NOTIFICATION_COMPLETE.md)
- [Alerts Bug Fix Summary](./ALERTS_BUG_FIX_SUMMARY.md)
- **[Alerts Double Notification Fix](./ALERTS_DOUBLE_NOTIFICATION_FIX.md)** (This fix)

## Date
October 18, 2025
