# Appointment Auto-Cancellation System - Implementation Guide

## Overview

Implemented an intelligent auto-cancellation system that automatically cancels pending appointments when their scheduled time has passed without clinic confirmation. This follows industry best practices for appointment management systems.

**Implementation Date**: October 18, 2025  
**Status**: ✅ Complete and Integrated

---

## 📋 Best Practices Analysis

### ✅ Should Auto-Cancel Be Implemented?

**YES** - Auto-cancelling expired pending appointments is an industry best practice for the following reasons:

#### Benefits for Users:
- **Clarity**: Users know their appointment wasn't accepted
- **Next Steps**: Can book alternative appointments
- **No Limbo**: Reduces uncertainty about appointment status
- **Better Experience**: Clear communication about appointment outcome

#### Benefits for Clinics:
- **Data Hygiene**: Keeps appointment list clean and accurate
- **Accurate Metrics**: Better reporting and analytics
- **Reduced Manual Work**: Less time spent managing old pending requests
- **Slot Availability**: Expired slots become visible again

#### Benefits for System:
- **Resource Management**: Prevents database bloat
- **Better UX**: Shows only relevant appointments
- **Reliability**: Automatic cleanup without manual intervention
- **Data Integrity**: Maintains accurate appointment state

### ⚙️ Auto-Cancellation Policy

**What Gets Auto-Cancelled:**
- ✅ **PENDING appointments only** - Appointments awaiting clinic confirmation
- ❌ **CONFIRMED appointments** - Never auto-cancelled (clinic has committed)
- ❌ **COMPLETED appointments** - Already done
- ❌ **CANCELLED appointments** - Already cancelled

**Grace Period:**
- **Default**: 2 hours after scheduled appointment time
- **Configurable**: Can be adjusted per clinic requirements
- **Rationale**: Gives clinic reasonable time to respond, but not so long that users are left waiting

**Timing:**
- Runs on app startup
- Runs when users view their appointments
- Runs when admins view clinic appointments
- Can be scheduled via Cloud Functions for hourly checks (recommended for production)

### 📊 Confirmed vs No-Show Policy

**CONFIRMED Appointments That Pass:**
- Should NOT be auto-cancelled
- Should be marked as "no-show" status (recommended future enhancement)
- Requires manual clinic action to mark as completed or no-show
- Rationale: Clinic has committed the slot; user accountability matters

---

## 🏗️ Architecture

### Components Created

#### 1. **AppointmentAutoCancellationService**
**File**: `/lib/core/services/clinic/appointment_auto_cancellation_service.dart`

**Purpose**: Core service that handles auto-cancellation logic

**Key Features:**
- Configurable grace period (default: 2 hours)
- Only cancels PENDING appointments
- Sends notifications to both user and admin
- Batch processing for efficiency
- Error handling and logging

**Main Methods:**
```dart
// Process all expired appointments system-wide
Future<Map<String, int>> processExpiredAppointments()

// Check and cancel expired appointments for specific user
Future<List<String>> checkUserExpiredAppointments(String userId)

// Check and cancel expired appointments for specific clinic
Future<List<String>> checkClinicExpiredAppointments(String clinicId)

// Get grace period in hours
int getGracePeriodHours()
```

#### 2. **Notification Integrations**

**User Notifications** (`appointment_booking_integration.dart`):
```dart
// New method added
Future<void> onAppointmentCancelled({
  required String userId,
  required String petName,
  required String clinicName,
  required DateTime appointmentDate,
  required String appointmentTime,
  String? appointmentId,
  String? cancelReason,
  bool cancelledByClinic = false,
  bool isAutoCancelled = false,
})
```

**Admin Notifications** (`admin_appointment_notification_integrator.dart`):
```dart
// New method added
Future<void> notifyAppointmentAutoCancelled({
  required String appointmentId,
  required String petName,
  required String ownerName,
  required DateTime appointmentDate,
  required String appointmentTime,
  required String serviceName,
})
```

#### 3. **Service Integrations**

**Mobile Appointment Service** (`appointment_booking_service.dart`):
- Integrated auto-cancellation check in `getUserAppointments()`
- Integrated auto-cancellation check in `getUpcomingAppointments()`

**Admin Appointment Service** (`appointment_service.dart`):
- Integrated auto-cancellation check in `getClinicAppointments()`

**App Initialization** (`main.dart`):
- Runs auto-cancellation on app startup
- Ensures clean state when app launches

---

## 🔄 How It Works

### Auto-Cancellation Flow

```
┌─────────────────────────────────────┐
│  User Books Appointment (PENDING)  │
└──────────────┬──────────────────────┘
               │
               v
┌─────────────────────────────────────┐
│   Appointment Time: Oct 18, 2PM    │
│   Grace Period: 2 hours             │
│   Expiry: Oct 18, 4PM               │
└──────────────┬──────────────────────┘
               │
               v
        ┌──────┴───────┐
        │   Oct 18     │
        │   4:01 PM    │
        │  (Expired)   │
        └──────┬───────┘
               │
               v
┌─────────────────────────────────────┐
│   Auto-Cancellation Service         │
│   Detects Expired Appointment       │
└──────────────┬──────────────────────┘
               │
               v
┌─────────────────────────────────────┐
│   Update Appointment Status:        │
│   - status = cancelled              │
│   - cancelReason = "auto-cancelled" │
│   - autoCancelled = true            │
│   - cancelledAt = now               │
└──────────────┬──────────────────────┘
               │
               v
        ┌──────┴───────┐
        │              │
        v              v
┌──────────────┐  ┌──────────────┐
│ User Notif   │  │ Admin Notif  │
│ "Your appt   │  │ "Appt auto-  │
│  expired"    │  │  cancelled"  │
└──────────────┘  └──────────────┘
```

### Trigger Points

1. **App Startup**: `main.dart`
   - Processes all expired appointments
   - Ensures clean state

2. **User Views Appointments**: `appointment_booking_service.dart`
   - Checks user's expired appointments
   - Updates before displaying

3. **Admin Views Dashboard**: `appointment_service.dart`
   - Checks clinic's expired appointments
   - Updates before displaying

4. **Scheduled (Recommended)**: Cloud Functions
   - Run hourly via Cloud Scheduler
   - Production-ready automation

---

## 📱 User Experience

### User Notifications

**Auto-Cancellation Notification:**
```
Title: ⏰ Appointment Automatically Cancelled

Message: Your appointment for Max at Happy Paws Clinic on 
October 18, 2025 at 2:00 PM was automatically cancelled 
because the scheduled time has passed without clinic 
confirmation.

Priority: Medium
Category: Appointment
```

**Notification Details:**
- Clear icon (⏰) to indicate automatic action
- Explains WHY it was cancelled
- Provides all relevant details (pet, clinic, date, time)
- Medium priority (not urgent, but important to know)
- Linked to appointment for reference

### Admin Notifications

**Admin Dashboard Notification:**
```
Title: ⏰ Appointment Auto-Cancelled (Expired)

Message: Pending appointment for Max (owner: John Doe) 
scheduled for October 18, 2025 at 2:00 PM was automatically 
cancelled because the scheduled time passed without 
confirmation - General Checkup

Priority: Medium
```

**Notification Metadata:**
- Marked as "auto_cancelled" type
- Action attributed to "system" (not admin)
- Includes full appointment context
- Allows admin to track system actions

---

## 🔧 Configuration

### Grace Period

**Default**: 2 hours after scheduled time

**To Change**: Edit in `appointment_auto_cancellation_service.dart`
```dart
static const Duration _gracePeriod = Duration(hours: 2);
```

**Recommended Values:**
- **Standard Clinics**: 2-4 hours (balances responsiveness with fairness)
- **Emergency Clinics**: 1 hour (faster turnover needed)
- **Specialty Clinics**: 6-24 hours (may need more time to review)

### Lookback Window

**Default**: 7 days

**Purpose**: How far back to check for expired appointments

```dart
static const Duration _lookbackWindow = Duration(days: 7);
```

### Cancellation Reason

**Default Message**:
```dart
static const String _autoCancelReason = 
  'Appointment automatically cancelled - scheduled time has passed without clinic confirmation';
```

**Customization**: Can be overridden per appointment with detailed time info

---

## 📊 Database Schema

### Appointment Document Updates

When auto-cancelled, the following fields are updated:

```dart
{
  'status': 'cancelled',
  'cancelReason': 'Appointment automatically cancelled - scheduled time has passed without clinic confirmation',
  'cancelledAt': Timestamp.fromDate(DateTime.now()),
  'updatedAt': Timestamp.fromDate(DateTime.now()),
  'autoCancelled': true, // NEW FIELD - flags system auto-cancellation
}
```

**New Field**: `autoCancelled` (boolean)
- `true`: Cancelled by system (expired)
- `false` or null: Cancelled manually by user/admin

---

## 🚀 Production Deployment

### Cloud Functions Setup (Recommended)

For production, set up a Cloud Function to run auto-cancellation hourly:

**File**: `functions/src/index.ts`

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Run every hour
export const processExpiredAppointments = functions.pubsub
  .schedule('0 * * * *') // Every hour at minute 0
  .timeZone('America/New_York') // Adjust to your timezone
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const gracePeriod = 2 * 60 * 60 * 1000; // 2 hours in ms
    const cutoffTime = new Date(now.toMillis() - gracePeriod);
    
    const expiredAppointments = await db
      .collection('appointments')
      .where('status', '==', 'pending')
      .where('appointmentDate', '<', admin.firestore.Timestamp.fromDate(cutoffTime))
      .get();
    
    const batch = db.batch();
    let cancelledCount = 0;
    
    expiredAppointments.docs.forEach(doc => {
      batch.update(doc.ref, {
        status: 'cancelled',
        cancelReason: 'Appointment automatically cancelled - scheduled time has passed without clinic confirmation',
        cancelledAt: now,
        updatedAt: now,
        autoCancelled: true,
      });
      cancelledCount++;
    });
    
    if (cancelledCount > 0) {
      await batch.commit();
      console.log(`✅ Auto-cancelled ${cancelledCount} expired appointments`);
    }
    
    return null;
  });
```

**Deploy**:
```bash
cd functions
npm install
firebase deploy --only functions:processExpiredAppointments
```

---

## 📈 Analytics & Monitoring

### Metrics to Track

1. **Auto-Cancellation Rate**: % of pending appointments that expire
2. **Time to Confirmation**: How long clinics take to confirm
3. **Expired Appointments by Clinic**: Identify slow-responding clinics
4. **User Impact**: How many users affected by auto-cancellations

### Logging

All auto-cancellation actions are logged:

```
🔍 Checking for expired pending appointments...
⏰ Found 3 potentially expired appointments
❌ Auto-cancelled appointment appt_123
✅ Auto-cancellation complete: 3 cancelled, 0 failed
```

### Query for Auto-Cancelled Appointments

```dart
// Get all auto-cancelled appointments
final autoCancelledAppointments = await FirebaseFirestore.instance
  .collection('appointments')
  .where('autoCancelled', isEqualTo: true)
  .orderBy('cancelledAt', descending: true)
  .get();

// Get auto-cancellation stats by clinic
final clinicStats = await FirebaseFirestore.instance
  .collection('appointments')
  .where('clinicId', isEqualTo: clinicId)
  .where('autoCancelled', isEqualTo: true)
  .get();
```

---

## 🧪 Testing

### Test Scenarios

1. **Expired Pending Appointment**
   - Create appointment for yesterday
   - Status: pending
   - Run `processExpiredAppointments()`
   - Verify: Status changed to cancelled, notifications sent

2. **Confirmed Appointment (Should NOT Cancel)**
   - Create appointment for yesterday
   - Status: confirmed
   - Run `processExpiredAppointments()`
   - Verify: Status remains confirmed

3. **Recent Pending (Within Grace Period)**
   - Create appointment for 1 hour ago
   - Status: pending
   - Run `processExpiredAppointments()`
   - Verify: Status remains pending (grace period)

4. **User Experience**
   - Have an expired pending appointment
   - Open appointments page
   - Verify: Appointment auto-cancelled, notification shown

5. **Admin Experience**
   - Have clinic with expired pending appointment
   - Open admin dashboard
   - Verify: Appointment auto-cancelled, admin notification shown

### Manual Testing Commands

```dart
// Test auto-cancellation for specific user
final cancelledIds = await AppointmentAutoCancellationService
  .checkUserExpiredAppointments('user_123');
print('Cancelled: $cancelledIds');

// Test auto-cancellation for specific clinic
final cancelledIds = await AppointmentAutoCancellationService
  .checkClinicExpiredAppointments('clinic_456');
print('Cancelled: $cancelledIds');

// Test system-wide auto-cancellation
final stats = await AppointmentAutoCancellationService
  .processExpiredAppointments();
print('Stats: $stats');
```

---

## ⚠️ Important Considerations

### What NOT to Auto-Cancel

**❌ Confirmed Appointments**
- Clinic has committed the time slot
- Should be marked as "no-show" instead
- Requires manual clinic action

**❌ Completed Appointments**
- Already finished
- Historical record

**❌ Already Cancelled**
- Avoid double-processing
- Maintain clean state

### Edge Cases Handled

1. **Firestore Query Limits**: Batches large result sets
2. **Missing Pet/User Data**: Graceful fallback to generic names
3. **Notification Failures**: Don't prevent cancellation
4. **Time Zone Issues**: Uses server time consistently
5. **Invalid Time Formats**: Validates before parsing

### Error Handling

- **Graceful Degradation**: Notification failures don't block cancellation
- **Logging**: All errors logged for debugging
- **Stats**: Returns counts of success/failure
- **Retry**: Idempotent - safe to run multiple times

---

## 📚 Future Enhancements

### Recommended Additions

1. **No-Show Status**
   - Add `noShow` to AppointmentStatus enum
   - Mark confirmed appointments that weren't completed
   - Track user reliability metrics

2. **Configurable Grace Periods**
   - Per-clinic grace period settings
   - Store in clinic configuration
   - Allow admins to customize

3. **Pre-Expiration Warnings**
   - Notify users 30 minutes before auto-cancel
   - "Your appointment hasn't been confirmed yet"
   - Give chance to contact clinic

4. **Auto-Cancellation Dashboard**
   - Admin view of all auto-cancelled appointments
   - Analytics on clinic response times
   - Identify improvement opportunities

5. **Smart Rescheduling**
   - Offer to rebook when auto-cancelled
   - Suggest alternative times
   - One-click rebooking

6. **Clinic Performance Metrics**
   - Track confirmation response time
   - Alert clinics with high auto-cancel rates
   - Gamification to improve response times

---

## 📞 Support & Troubleshooting

### Common Issues

**Issue**: Appointments not auto-cancelling
- Check grace period configuration
- Verify appointment is PENDING status
- Ensure scheduled time + grace period has passed
- Check Firestore indexes are deployed

**Issue**: Too many appointments being cancelled
- Review grace period (may be too short)
- Check system time vs appointment time zones
- Verify appointment data format

**Issue**: Notifications not sending
- Check user ID exists
- Verify notification service initialized
- Review Firestore permissions

### Debug Mode

Add logging to track auto-cancellation:

```dart
// In appointment_auto_cancellation_service.dart
static bool _debugMode = true;

if (_debugMode) {
  print('🔍 Checking appointment ${appointment.id}');
  print('   Scheduled: ${appointment.appointmentDate} ${appointment.appointmentTime}');
  print('   Grace period: $_gracePeriod');
  print('   Is expired: ${_isAppointmentExpired(appointment)}');
}
```

---

## ✅ Checklist for Implementation

- [x] Create `AppointmentAutoCancellationService`
- [x] Add user notification method
- [x] Add admin notification method
- [x] Integrate into mobile appointment service
- [x] Integrate into admin appointment service
- [x] Initialize on app startup
- [x] Add comprehensive documentation
- [ ] Deploy Cloud Function for hourly checks (production)
- [ ] Set up monitoring and alerts
- [ ] Create admin dashboard for auto-cancel stats
- [ ] Add pre-expiration warning notifications

---

## 🎯 Summary

This implementation provides a robust, production-ready auto-cancellation system that:

✅ Follows industry best practices  
✅ Maintains data integrity  
✅ Provides clear user communication  
✅ Reduces admin workload  
✅ Improves overall system reliability  

The system is **configurable**, **scalable**, and **well-documented** for easy maintenance and future enhancements.

---

**Maintained By**: PawSense Development Team  
**Last Updated**: October 18, 2025  
**Version**: 1.0.0
