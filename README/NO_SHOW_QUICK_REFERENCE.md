# 🎯 No Show Feature - Quick Reference

## What It Does
Allows admin to mark confirmed appointments as "No Show" when patients don't arrive, with automatic notifications to both parties.

## How to Use (Admin)

### Step 1: Find Confirmed Appointment
- Open **Appointments** screen in admin dashboard
- Look for appointments with **blue "Confirmed"** badge
- Locate the appointment where patient didn't show up

### Step 2: Mark as No Show
- Click the **person-off icon** button (👤⃠)
- Button appears between "Mark as Completed" and "Edit"
- Review appointment details in confirmation dialog

### Step 3: Confirm Action
- Check pet name, owner, date/time
- Note: "Both you and the pet owner will be notified"
- Click **"Mark as No Show"** to confirm

### Step 4: Verify
- Status badge changes to **orange "No Show"**
- Success message appears at bottom
- Notification sent to user immediately

## Button Location

```
Confirmed Appointment Actions:
[✓ Complete] [👤⃠ No Show] [✏️ Edit]
     ↑            ↑            ↑
  Mark Done   No Show      Edit
```

## Color Codes

| Status | Badge Color | Meaning |
|--------|-------------|---------|
| 🟡 Pending | Yellow | Waiting for approval |
| 🔵 Confirmed | Blue | Approved & scheduled |
| 🟢 Completed | Green | Successfully done |
| 🔴 Cancelled | Red | Cancelled by someone |
| 🟠 **No Show** | **Orange** | **Patient didn't arrive** |

## Notifications Sent

### To User (Pet Owner)
```
📱 Appointment Marked as No Show

Your appointment for Luna on October 24, 2025 at 2:00 PM 
has been marked as a no-show because you did not arrive 
for your scheduled appointment.
```

### To Admin
```
🔔 👤 Appointment Marked as No Show

Confirmed appointment for Luna (owner: John Doe) scheduled 
for October 24, 2025 at 2:00 PM has been marked as a 
no-show - General Checkup
```

## When to Use

✅ **Mark as No Show When:**
- Patient confirmed but didn't arrive
- No call/message from patient about cancellation
- Appointment time has passed (15+ minutes recommended)
- You want to track no-show patterns

❌ **Don't Mark as No Show When:**
- Patient called to cancel (use Cancel instead)
- Patient arrived late but was seen (use Complete)
- Appointment still pending (can't mark pending as no-show)
- Clinic cancelled the appointment

## Quick Facts

- **Only works for:** CONFIRMED appointments
- **Button icon:** Person with slash (👤⃠)
- **Button color:** Orange/Warning
- **Status color:** Orange (#FF9800)
- **Notifications:** Sent to BOTH user and admin
- **Can undo?** No, status change is permanent (reschedule instead)

## Common Scenarios

### Scenario 1: Patient No-Show
```
Problem: Luna's 2 PM appointment - owner never showed up
Solution: Click No Show button → Both parties notified
Result: Orange "No Show" badge, owner gets notification
```

### Scenario 2: Patient Called to Cancel
```
Problem: Owner called 1 hour before to cancel
Solution: Don't use No Show - use regular Cancel instead
Result: Red "Cancelled" badge with reason
```

### Scenario 3: Patient Arrived Late
```
Problem: Arrived 20 minutes late but was still seen
Solution: Don't mark as No Show - mark as Completed
Result: Green "Completed" badge
```

## Troubleshooting

### Button Not Showing?
- Check appointment status is CONFIRMED (blue badge)
- Pending appointments: Accept first, then can mark no-show
- Completed/Cancelled: Can't mark as no-show

### No Success Message?
- Check internet connection
- Refresh page and try again
- Check browser console for errors

### User Didn't Get Notification?
- Check user has notification permissions enabled
- Notification sent to database (check Firestore)
- User may need to refresh alerts page

## API Reference

### Service Method
```dart
AppointmentService.markAsNoShow(String appointmentId)
```

### Returns
```dart
Future<bool> // true = success, false = failed
```

### Usage Example
```dart
final success = await AppointmentService.markAsNoShow(appointment.id);
if (success) {
  // Show success message
} else {
  // Show error message
}
```

## Status
✅ **LIVE** - Feature fully implemented and ready to use!

**Last Updated:** October 18, 2025
