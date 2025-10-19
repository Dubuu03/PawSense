# Auto-Cancellation: Next Day Logic Update

## Change Summary
Updated auto-cancellation logic to cancel appointments **the day AFTER** their scheduled date, not on the same day with a time-based grace period.

## Previous Behavior ❌
- **Grace Period:** 2 hours after appointment TIME
- **Example:** Appointment on Oct 24 at 2:00 PM → Auto-cancel on Oct 24 at 4:00 PM
- **Problem:** Cancels on the same day, doesn't give clinic full day to respond

## New Behavior ✅
- **Grace Period:** Until end of appointment day (midnight)
- **Example:** Appointment on Oct 24 (any time) → Auto-cancel on Oct 25 (next day)
- **Benefit:** Clinic has the ENTIRE day to confirm appointment

## Updated Logic

### Grace Period Change
```dart
// BEFORE:
static const Duration _gracePeriod = Duration(hours: 2);

// AFTER:
static const Duration _gracePeriod = Duration(days: 1);
```

### Date Comparison Logic
```dart
// BEFORE (checked time):
final appointmentDateTime = DateTime(
  appointment.appointmentDate.year,
  appointment.appointmentDate.month,
  appointment.appointmentDate.day,
  int.parse(timeParts[0]),  // Hour
  int.parse(timeParts[1]),  // Minute
);
final expiryTime = appointmentDateTime.add(_gracePeriod);
final isExpired = DateTime.now().isAfter(expiryTime);

// AFTER (checks date only):
final appointmentDate = DateTime(
  appointment.appointmentDate.year,
  appointment.appointmentDate.month,
  appointment.appointmentDate.day,
  // NO TIME - just the date!
);
final todayMidnight = DateTime(today.year, today.month, today.day);
final isExpired = todayMidnight.isAfter(appointmentDate);
```

## Examples

### Scenario 1: Appointment on Oct 24
- **Scheduled:** Oct 24 (any time: 9:00 AM, 2:00 PM, 5:00 PM)
- **Status:** PENDING
- **Auto-Cancel Date:** Oct 25 00:00 (midnight)
- **Reason:** "Appointment automatically cancelled - scheduled date has passed without clinic confirmation"

### Scenario 2: Appointment Confirmed on Same Day
- **Scheduled:** Oct 24, 2:00 PM
- **Confirmed:** Oct 24, 3:00 PM (status changed to CONFIRMED)
- **Auto-Cancel:** ❌ WILL NOT auto-cancel (only cancels PENDING)

### Scenario 3: Multiple Appointments
- **Appointment A:** Oct 24, 9:00 AM (PENDING)
- **Appointment B:** Oct 24, 3:00 PM (PENDING)
- **Appointment C:** Oct 24, 5:00 PM (PENDING)
- **Result on Oct 25:** All 3 will be auto-cancelled if still PENDING

### Scenario 4: Late Booking
- **Booked:** Oct 24, 11:00 PM (1 hour before midnight)
- **Scheduled:** Oct 25
- **Auto-Cancel:** Oct 26 (clinic still has full Oct 25 to confirm)

## Technical Details

### Query Range
The system checks appointments within a 7-day lookback window:
```dart
static const Duration _lookbackWindow = Duration(days: 7);
```

This means it will check appointments from:
- Oct 18 to Oct 24 (if running on Oct 25)

### Processing Frequency
Currently runs on **app startup**. For production, recommend:
- Cloud Functions scheduled every 6-12 hours
- Runs at: 12:00 AM (midnight) and 12:00 PM (noon)

### Date Comparison
```dart
// Compare DATES only, ignore time
final appointmentDate = DateTime(year, month, day); // No hour/minute
final todayMidnight = DateTime(year, month, day);   // No hour/minute

// If today > appointment date → EXPIRED
if (todayMidnight.isAfter(appointmentDate)) {
  // Cancel appointment
}
```

## Benefits

### 1. Fair to Clinic ✅
- Clinic has full day to review and confirm
- No rush to respond within hours
- Can handle end-of-day bookings

### 2. Clear User Expectations ✅
- "Appointment on Oct 24" means clinic has until end of Oct 24
- Next day (Oct 25) = appointment expired
- Simple, intuitive logic

### 3. Reduced Edge Cases ✅
- No timezone issues with specific times
- No parsing time strings
- Simpler date comparison

## Updated Cancellation Reason
```
Before: "Appointment automatically cancelled - scheduled time has passed without clinic confirmation"
After:  "Appointment automatically cancelled - scheduled date has passed without clinic confirmation"
```

Changed "time" to "date" for clarity.

## Testing Checklist

### Test 1: Basic Next-Day Cancellation
- [ ] Create appointment for Oct 24
- [ ] Keep status as PENDING
- [ ] Run auto-cancellation on Oct 25
- [ ] Verify appointment is cancelled
- [ ] Check notification received

### Test 2: Same-Day Confirmation
- [ ] Create appointment for Oct 24
- [ ] Confirm on Oct 24
- [ ] Run auto-cancellation on Oct 25
- [ ] Verify appointment is NOT cancelled

### Test 3: Multiple Appointments
- [ ] Create 3 appointments for Oct 24 (different times)
- [ ] Keep all PENDING
- [ ] Run auto-cancellation on Oct 25
- [ ] Verify all 3 are cancelled

### Test 4: Late Booking
- [ ] Create appointment for Oct 25 at 11:00 PM on Oct 24
- [ ] Run auto-cancellation on Oct 26
- [ ] Verify appointment is cancelled (had full Oct 25 to confirm)

## Files Modified
- `/lib/core/services/clinic/appointment_auto_cancellation_service.dart`
  - Changed `_gracePeriod` from `Duration(hours: 2)` to `Duration(days: 1)`
  - Updated `_isAppointmentExpired()` to compare dates only (ignore time)
  - Updated `_autoCancelReason` to say "date" instead of "time"
  - Added debug logging for clearer tracking

## Production Recommendations

### Cloud Function Schedule
```javascript
// Recommended: Run twice daily
exports.autoCancelExpiredAppointments = functions.pubsub
  .schedule('0 0,12 * * *') // At 00:00 and 12:00
  .timeZone('Asia/Manila')
  .onRun(async (context) => {
    // Call auto-cancellation service
  });
```

### Monitoring
Track these metrics:
- Number of appointments auto-cancelled daily
- Percentage of appointments that get confirmed vs auto-cancelled
- Time of day when most confirmations happen

### Potential Enhancements
1. **Configurable grace period per clinic**
   - Some clinics may want 2 days grace period
   - Store in clinic settings

2. **Reminder notifications**
   - Send reminder to clinic at 5:00 PM if still pending
   - "Appointment for tomorrow is still pending confirmation"

3. **Auto-confirm policy**
   - Some clinics may want auto-CONFIRM instead of auto-CANCEL
   - Configurable per clinic

## Related Documentation
- [APPOINTMENT_AUTO_CANCELLATION_IMPLEMENTATION.md](./APPOINTMENT_AUTO_CANCELLATION_IMPLEMENTATION.md) - Original implementation
- [AUTO_CANCEL_DUPLICATE_FIX.md](./AUTO_CANCEL_DUPLICATE_FIX.md) - Duplicate notification fix
- [AUTO_CANCEL_COMPLETE_SUMMARY.md](./AUTO_CANCEL_COMPLETE_SUMMARY.md) - Complete overview

## Status
✅ **UPDATED** - Auto-cancellation now happens the day AFTER scheduled date.

Last Updated: October 18, 2025
