# 🔄 No Show Restructure: Using Cancelled Status

## Overview

**No Show appointments are now cancelled appointments with visual indicators**, similar to how follow-up appointments work.

### What Changed:

✅ **Before:** `status = noShow` (separate status)  
✅ **After:** `status = cancelled` + `isNoShow = true` (visual flag)

---

## Why This Change?

### 1. **Simplifies Status Management**
- Only 4 core statuses: `pending`, `confirmed`, `completed`, `cancelled`
- No-show is a TYPE of cancellation, not a separate status

### 2. **Consistent with Follow-Up Pattern**
- Follow-ups: `isFollowUp = true` flag with blue badge
- No-shows: `isNoShow = true` flag with orange badge  
- Auto-cancelled: `autoCancelled = true` flag with red badge

### 3. **Better Reason Tracking**
- `cancelReason`: Explains WHY it was cancelled
- Examples:
  - "No Show - Patient did not arrive for scheduled appointment"
  - "Auto-cancelled - scheduled time passed without confirmation"
  - "Cancelled by clinic"
  - "Cancelled by user"

---

## Data Structure

### Appointment Fields

```dart
class Appointment {
  // Core fields
  final AppointmentStatus status; // pending, confirmed, completed, cancelled
  final String? cancelReason;     // Why was it cancelled?
  final DateTime? cancelledAt;    // When was it cancelled?
  
  // Visual flags (like isFollowUp)
  final bool? isNoShow;          // 🟠 Shows orange "No Show" badge
  final bool? autoCancelled;     // 🔴 Shows red "Auto-Cancelled" badge
  final bool? isFollowUp;        // 🔵 Shows blue "Follow-up" badge
}
```

### Firestore Document

**When marking as No Show:**
```javascript
{
  "status": "cancelled",
  "cancelReason": "No Show - Patient did not arrive for scheduled appointment",
  "isNoShow": true,              // ✅ Visual flag
  "noShowMarkedAt": Timestamp,
  "cancelledAt": Timestamp,
  "updatedAt": Timestamp
}
```

**When auto-cancelled by time:**
```javascript
{
  "status": "cancelled",
  "cancelReason": "Appointment automatically cancelled - scheduled time passed without clinic confirmation",
  "autoCancelled": true,         // ✅ Visual flag
  "cancelledAt": Timestamp,
  "updatedAt": Timestamp
}
```

**When manually cancelled:**
```javascript
{
  "status": "cancelled",
  "cancelReason": "Cancelled by clinic - patient request",
  "isNoShow": false,             // No special flags
  "autoCancelled": false,
  "cancelledAt": Timestamp,
  "updatedAt": Timestamp
}
```

---

## Visual Indicators

### Appointment Table Row

All three types of special appointments show badges in the Disease/Reason column:

```
┌─────────────────────────────────────────────────────────┐
│ Pet Name  │ [🔵 Follow-up] Vaccination checkup          │
│ Pet Name  │ [🟠 No Show] Skin condition treatment       │
│ Pet Name  │ [🔴 Auto-Cancelled] General consultation    │
│ Pet Name  │ [🔵 Follow-up][🟠 No Show] Follow-up visit  │
└─────────────────────────────────────────────────────────┘
```

### Badge Styles

#### 🔵 Follow-up Badge
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.info.withOpacity(0.1),
    border: Border.all(color: AppColors.info),
  ),
  child: Row(
    children: [
      Icon(Icons.sync, color: AppColors.info),
      Text('Follow-up', color: AppColors.info),
    ],
  ),
)
```

#### 🟠 No Show Badge
```dart
Container(
  decoration: BoxDecoration(
    color: Color(0xFFFF9800).withOpacity(0.1), // Orange
    border: Border.all(color: Color(0xFFFF9800)),
  ),
  child: Row(
    children: [
      Icon(Icons.person_off_outlined, color: Color(0xFFFF9800)),
      Text('No Show', color: Color(0xFFFF9800)),
    ],
  ),
)
```

#### 🔴 Auto-Cancelled Badge  
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.error.withOpacity(0.1),
    border: Border.all(color: AppColors.error),
  ),
  child: Row(
    children: [
      Icon(Icons.schedule_outlined, color: AppColors.error),
      Text('Auto-Cancelled', color: AppColors.error),
    ],
  ),
)
```

### Status Badge

The main status badge shows "Cancelled" for all cancelled appointments:

```dart
case AppointmentStatus.cancelled:
  backgroundColor = AppColors.error.withOpacity(0.1);
  textColor = AppColors.error;
  text = 'Cancelled';  // Same for all cancelled types
```

---

## Code Changes

### 1. Enum Updated

**File:** `appointment_models.dart`

```dart
// Before
enum AppointmentStatus { pending, confirmed, completed, cancelled, noShow }

// After  
enum AppointmentStatus { pending, confirmed, completed, cancelled }
```

### 2. Model Fields Added

**File:** `appointment_models.dart`

```dart
class Appointment {
  // ... existing fields ...
  final bool? isNoShow;       // ✅ NEW
  final bool? autoCancelled;  // ✅ NEW
}
```

### 3. Service Method Updated

**File:** `appointment_service.dart` - `markAsNoShow()`

```dart
// Before
await _firestore.collection(_collection).doc(appointmentId).update({
  'status': 'noShow',
  'noShowMarkedAt': Timestamp.fromDate(DateTime.now()),
});

// After
await _firestore.collection(_collection).doc(appointmentId).update({
  'status': 'cancelled',
  'cancelReason': 'No Show - Patient did not arrive for scheduled appointment',
  'isNoShow': true,           // ✅ Visual flag
  'noShowMarkedAt': Timestamp.fromDate(DateTime.now()),
  'cancelledAt': Timestamp.fromDate(DateTime.now()),
});
```

### 4. Table Row Updated

**File:** `appointment_table_row.dart`

```dart
// Disease/Reason column now shows badges
Wrap(
  spacing: 4,
  children: [
    // Follow-up badge
    if (appointment.isFollowUp == true) _buildFollowUpBadge(),
    
    // No Show badge ✅ NEW
    if (appointment.isNoShow == true) _buildNoShowBadge(),
    
    // Auto-Cancelled badge ✅ NEW
    if (appointment.autoCancelled == true) _buildAutoCancelledBadge(),
  ],
)
```

### 5. Status Counts Updated

**File:** `appointment_models.dart` - `calculateStatusCounts()`

```dart
// Before
final noShowCount = appointments.where((a) => a.status == AppointmentStatus.noShow).length;

// After
final noShowCount = appointments.where((a) => a.isNoShow == true).length;
```

---

## Migration Guide

### For Existing Data

If you have existing appointments with `status = noShow`, you need to migrate them:

**Firestore Migration Script:**
```dart
Future<void> migrateNoShowAppointments() async {
  final firestore = FirebaseFirestore.instance;
  
  // Find all no-show appointments
  final query = await firestore
      .collection('appointments')
      .where('status', isEqualTo: 'noShow')
      .get();
  
  print('📊 Found ${query.docs.length} no-show appointments to migrate');
  
  // Update each one
  for (final doc in query.docs) {
    await doc.reference.update({
      'status': 'cancelled',
      'cancelReason': 'No Show - Patient did not arrive for scheduled appointment',
      'isNoShow': true,
      'cancelledAt': doc.data()['noShowMarkedAt'] ?? FieldValue.serverTimestamp(),
    });
    
    print('✅ Migrated appointment ${doc.id}');
  }
  
  print('🎉 Migration complete!');
}
```

### For New Appointments

All new no-show markings automatically use the new structure - no changes needed!

---

## Filtering & Queries

### Get All Cancelled Appointments (including no-shows)

```dart
final query = await FirebaseFirestore.instance
    .collection('appointments')
    .where('clinicId', isEqualTo: clinicId)
    .where('status', isEqualTo: 'cancelled')
    .get();
```

### Get Only No-Show Appointments

```dart
final query = await FirebaseFirestore.instance
    .collection('appointments')
    .where('clinicId', isEqualTo: clinicId)
    .where('status', isEqualTo: 'cancelled')
    .where('isNoShow', isEqualTo: true)  // ✅ Filter by flag
    .get();
```

### Get Only Auto-Cancelled Appointments

```dart
final query = await FirebaseFirestore.instance
    .collection('appointments')
    .where('clinicId', isEqualTo: clinicId)
    .where('status', isEqualTo: 'cancelled')
    .where('autoCancelled', isEqualTo: true)  // ✅ Filter by flag
    .get();
```

### Get Regular Cancelled Appointments (not no-show, not auto)

```dart
final query = await FirebaseFirestore.instance
    .collection('appointments')
    .where('clinicId', isEqualTo: clinicId)
    .where('status', isEqualTo: 'cancelled')
    .where('isNoShow', isEqualTo: false)
    .where('autoCancelled', isEqualTo: false)
    .get();
```

---

## UI Behavior

### Appointment List

**"All Status" Filter:**
- Shows all appointments
- No-show appointments appear with:
  - ❌ RED "Cancelled" status badge
  - 🟠 ORANGE "No Show" inline badge
  - Cancel reason visible in details

**"Cancelled" Filter:**
- Shows all cancelled appointments (including no-shows and auto-cancelled)
- Use badges to distinguish types:
  - 🟠 Orange badge = No Show
  - 🔴 Red badge = Auto-Cancelled  
  - No badge = Regular cancellation

### Appointment Details Modal

Shows cancel reason clearly:
```
Status: Cancelled
Reason: No Show - Patient did not arrive for scheduled appointment
Cancelled At: Oct 18, 2025 10:30 AM
```

### Cancel Reason Examples

```
✅ "No Show - Patient did not arrive for scheduled appointment"
✅ "Appointment automatically cancelled - scheduled time passed without clinic confirmation"  
✅ "Cancelled by clinic - patient request"
✅ "Cancelled by user - schedule conflict"
✅ "Cancelled by clinic - emergency closure"
```

---

## Benefits of This Approach

### 1. ✅ Cleaner Status Management
- 4 core statuses instead of 5
- Easier to manage in dropdowns
- Less complexity in queries

### 2. ✅ Better Cancel Tracking
- Every cancellation has a reason
- Easy to distinguish types
- Better analytics and reporting

### 3. ✅ Consistent Visual Pattern
- Follow the same pattern as follow-ups
- Users understand badge system
- Easy to add more flags in future

### 4. ✅ Flexible Filtering
- Can filter by status alone
- Can filter by specific type (no-show, auto-cancelled)
- Can combine filters

### 5. ✅ Future-Proof
- Easy to add new cancellation types
- Easy to add new visual indicators
- Maintainable and scalable

---

## Examples

### Example 1: Follow-up No-Show

```javascript
{
  "status": "cancelled",
  "cancelReason": "No Show - Patient did not arrive for follow-up appointment",
  "isNoShow": true,
  "isFollowUp": true,
  "previousAppointmentId": "abc123"
}
```

**UI Display:**
```
[🔵 Follow-up] [🟠 No Show] Follow-up checkup for vaccination
Status: Cancelled
Reason: No Show - Patient did not arrive for follow-up appointment
```

### Example 2: Auto-Cancelled Appointment

```javascript
{
  "status": "cancelled",
  "cancelReason": "Appointment automatically cancelled - scheduled time passed without clinic confirmation",
  "autoCancelled": true,
  "isNoShow": false
}
```

**UI Display:**
```
[🔴 Auto-Cancelled] General consultation
Status: Cancelled
Reason: Appointment automatically cancelled - scheduled time passed without clinic confirmation
```

### Example 3: Regular Cancellation

```javascript
{
  "status": "cancelled",
  "cancelReason": "Cancelled by user - schedule conflict",
  "isNoShow": false,
  "autoCancelled": false
}
```

**UI Display:**
```
Vaccination appointment
Status: Cancelled
Reason: Cancelled by user - schedule conflict
```

---

## Testing Checklist

### ✅ Mark as No Show
- [ ] Confirmed appointment can be marked as no-show
- [ ] Status changes to "cancelled"
- [ ] `isNoShow` flag is set to `true`
- [ ] Cancel reason is set correctly
- [ ] 🟠 Orange "No Show" badge appears in table
- [ ] ❌ Red "Cancelled" status badge appears
- [ ] Both admin and user receive notifications

### ✅ Auto-Cancellation
- [ ] Pending appointments auto-cancel when time expires
- [ ] Status changes to "cancelled"  
- [ ] `autoCancelled` flag is set to `true`
- [ ] Cancel reason includes "automatically cancelled"
- [ ] 🔴 Red "Auto-Cancelled" badge appears in table
- [ ] Both admin and user receive notifications

### ✅ Follow-up + No Show Combination
- [ ] Follow-up appointment can be marked no-show
- [ ] Both badges appear: [🔵 Follow-up] [🟠 No Show]
- [ ] Status is "cancelled"
- [ ] Both flags: `isFollowUp = true`, `isNoShow = true`

### ✅ Filtering
- [ ] "All Status" shows all appointments
- [ ] "Cancelled" shows all cancelled types
- [ ] No-show appointments don't appear in "Confirmed"
- [ ] Badge indicators work in all views

### ✅ Cancel Reasons Display
- [ ] Cancel reason visible in appointment details
- [ ] Reason text is clear and descriptive
- [ ] Different types have different reasons

---

## Related Files

**Core Model:**
- `/lib/core/models/clinic/appointment_models.dart` - Lines 80, 109-111, 143-145, 211-212, 355

**Service Layer:**
- `/lib/core/services/clinic/appointment_service.dart` - Lines 854-880 (markAsNoShow method)

**UI Components:**
- `/lib/core/widgets/admin/appointments/appointment_table_row.dart` - Lines 210-299 (badge display)
- `/lib/core/widgets/admin/appointments/status_badge.dart` - Lines 30-43 (status badge)

**Other UI Files:**
- `/lib/core/widgets/admin/patient_records/patient_details_modal.dart`
- `/lib/core/widgets/admin/clinic_schedule/appointment_details_modal.dart`
- `/lib/core/widgets/admin/appointments/appointment_edit_modal.dart`
- `/lib/core/services/clinic/appointment_pdf_service.dart`

---

## Summary

✅ **No-show is now a type of cancellation, not a separate status**

✅ **Visual indicators (badges) show the type at a glance**

✅ **Cancel reasons provide context for every cancellation**

✅ **Consistent with follow-up pattern - easier to understand**

✅ **Flexible and future-proof architecture**

