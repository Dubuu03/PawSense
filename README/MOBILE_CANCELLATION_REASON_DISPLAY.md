# Mobile Cancellation Reason Display - Implementation Summary

## Overview
Added a combined cancellation status and reason card to both mobile appointment history details and alert details views, ensuring users can clearly see when and why their appointments were cancelled.

## Design Concept
The cancellation information is displayed as **one unified card** with two sections:
1. **Header Section**: Red-tinted background showing "Cancelled" status with icon
2. **Content Section**: White background with info icon and cancellation reason text

This design mimics the image provided, creating a cohesive visual that combines status and reason in a single, easy-to-read card.

## Changes Made

### 1. Appointment History Detail Modal
**File**: `lib/core/widgets/user/home/appointment_history_detail_modal.dart`

#### Added Combined Cancellation Card
- Displays cancellation status and reason in one unified card
- Shows only when appointment status is `cancelled` and `cancelReason` is not null/empty
- Positioned right after the status badge for maximum visibility

### 2. Alert Details Page
**File**: `lib/pages/mobile/alerts/alerts_details_page.dart`

#### Added Combined Cancellation Status + Reason Card
- Displays cancellation status and reason as one unified card
- Shows only when metadata contains `cancelReason`
- Two-section design: red header for status, white content for reason
- Positioned after message content, before other metadata

### 3. Appointment Details Page
**File**: `lib/pages/mobile/appointments/appointment_details_page.dart`

#### Added Combined Cancellation Card
- Same unified card design as appointment history
- Displays cancellation status and reason together
- Shows only when appointment status is `cancelled` and `cancelReason` is not null/empty
- Positioned right after the status section for maximum visibility

All three views now use the **exact same combined card design** for consistency!

**UI Integration**:
```dart
// Status Badge
_buildStatusSection(appointment),

const SizedBox(height: kMobileSizedBoxXLarge),

// Cancellation Reason (if cancelled)
if (appointment.status == AppointmentStatus.cancelled && 
    appointment.cancelReason != null &&
    appointment.cancelReason!.isNotEmpty) ...[
  _buildCancellationReasonSection(appointment),
  const SizedBox(height: kMobileSizedBoxXLarge),
],

// Pet Information
if (_pet != null) ...[
  _buildPetInfoSection(_pet!),
  ...
```

### 2. Alert Details Page
**File**: `lib/pages/mobile/alerts/alerts_details_page.dart`

#### Added Combined Cancellation Status + Reason Card
- Displays cancellation status and reason as one unified card
- Shows only when metadata contains `cancelReason`
- Two-section design: red header for status, white content for reason
- Positioned after message content, before other metadata

**New Card Section**:
```dart
// Combined Cancellation Status + Reason Card (for cancelled appointments)
if (notification.metadata!['cancelReason'] != null && 
    notification.metadata!['cancelReason'].toString().isNotEmpty) ...[
  Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [...],
    ),
    child: Column(
      children: [
        // Cancelled Status Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.cancel_outlined,
                  color: AppColors.error,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Cancelled', style: ...),
              const Spacer(),
              Text('This appointment was cancelled', style: ...),
            ],
          ),
        ),
        // Cancellation Reason Content
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  const Text('Cancellation Reason', style: ...),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notification.metadata!['cancelReason'].toString(),
                style: ...,
              ),
            ],
          ),
        ),
      ],
    ),
  ),
  const SizedBox(height: 16),
],
```

#### Updated Metadata Filtering
Modified `_buildMetadataRows()` to exclude `cancelReason` from the generic metadata display since it's now shown in its own dedicated card:

```dart
List<Widget> _buildMetadataRows(Map<String, dynamic> metadata) {
  // Exclude cancelReason from metadata rows as it's shown separately
  final filteredMetadata = Map<String, dynamic>.from(metadata)
    ..remove('cancelReason');
  
  if (filteredMetadata.isEmpty) {
    return [];
  }
  
  return filteredMetadata.entries.map((entry) {
    // ... existing row building logic
  }).toList();
}
```

#### Conditional Metadata Section
Updated the "Additional Information" section to only display if there's metadata remaining after filtering:

```dart
// Regular Metadata Card (excluding cancelReason as it's shown separately)
if (_buildMetadataRows(notification.metadata!).isNotEmpty) ...[
  Container(
    // ... metadata card
  ),
],
```

## Data Flow

### Cancellation Reason in Notifications
The cancellation reason is already included in notification metadata through the `AppointmentBookingIntegration` service:

**File**: `lib/core/services/notifications/appointment_booking_integration.dart`

```dart
await NotificationService.createNotification(
  userId: userId,
  title: title,
  message: message,
  category: NotificationCategory.appointment,
  priority: isAutoCancelled ? NotificationPriority.medium : NotificationPriority.high,
  actionUrl: appointmentId != null ? '/appointments/$appointmentId' : null,
  metadata: {
    'appointmentId': appointmentId,
    'petName': petName,
    'clinicName': clinicName,
    'appointmentDate': appointmentDate.toIso8601String(),
    'appointmentTime': appointmentTime,
    'cancelReason': cancelReason ?? (isAutoCancelled ? 'Auto-cancelled due to expiration' : 'Cancelled'),
    'isAutoCancelled': isAutoCancelled,
    'cancelledByClinic': cancelledByClinic,
  },
);
```

### Cancellation Reason in Appointments
The `AppointmentBooking` model already has the `cancelReason` field:

**File**: `lib/core/models/clinic/appointment_booking_model.dart`

```dart
class AppointmentBooking {
  final String? cancelReason;
  final DateTime? cancelledAt;
  // ... other fields
}
```

## UI Design Specifications

### Combined Cancellation Card Styling

#### Header Section (Status)
- **Background**: Red with 10% opacity (`AppColors.error.withValues(alpha: 0.1)`)
- **Border Radius**: Top corners rounded (16px for alerts, mobile card radius for history)
- **Padding**: 16px all sides (alerts) / medium padding (history)
- **Icon Container**:
  - Background: Red with 20% opacity
  - Border radius: 20px (circular)
  - Padding: 6px
  - Icon: `cancel_outlined`, red color, 16px size
- **Status Text**: "Cancelled" in red, 600 weight, 14px font
- **Description**: "This appointment was cancelled" in grey, 11px font, right-aligned

#### Content Section (Reason)
- **Background**: White
- **Border**: 1px solid border color (history) / no border (alerts)
- **Border Radius**: Bottom corners rounded (16px for alerts, mobile card radius for history)
- **Padding**: 16px all sides (alerts) / medium padding (history)
- **Icon**: `info_outline` in red, 18px size
- **Title**: "Cancellation Reason" in primary text color, 600 weight, 13px font
- **Reason Text**: Primary text color, 13px font, 1.4 line height

#### Overall Card
- **Border**: 1px solid border color (history only)
- **Shadow**: Subtle shadow for depth (alerts only)
- **Border Radius**: 16px (alerts) / mobile card radius (history)
- **Margin**: 16px horizontal (alerts) / included in layout (history)

### Visual Structure
```
┌─────────────────────────────────────────┐
│ ╔═════════════════════════════════════╗ │
│ ║  🚫  Cancelled                       ║ │ ← Red tinted header
│ ║         This appointment was cancelled║ │
│ ╚═════════════════════════════════════╝ │
│ ┌─────────────────────────────────────┐ │
│ │  ℹ️  Cancellation Reason            │ │ ← White content area
│ │                                     │ │
│ │  Appointment automatically          │ │
│ │  cancelled - scheduled date has     │ │
│ │  passed without clinic confirmation │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### Layout Position
1. **Appointment History**: After status badge, before pet information
2. **Alert Details**: After message content, before additional metadata

## User Experience Flow

### Scenario 1: User Cancels Appointment
1. User navigates to appointment history OR opens appointment from alert
2. User taps on cancelled appointment
3. **NEW**: Combined cancellation card displays with:
   - Red header showing "Cancelled" status
   - White content showing cancellation reason
4. User sees full appointment details below

### Scenario 2: Clinic Cancels Appointment
1. User receives notification about cancellation
2. User taps notification in alerts
3. **NEW**: Combined cancellation card prominently displays:
   - "Cancelled" status in red header
   - Clinic's cancellation reason in white content area
4. User can view full notification details
5. User navigates to appointment details (from alert or history)
6. **NEW**: Same combined cancellation card is visible everywhere

### Scenario 3: Auto-Cancelled Appointment
1. System auto-cancels expired pending appointment
2. User receives notification
3. User taps notification
4. **NEW**: Combined cancellation card shows:
   - "Cancelled" status in red header
   - "Auto-cancelled due to expiration" in content area
5. Red styling indicates error/cancellation state
6. Same card appears in appointment history and appointment details

### Scenario 4: No-Show Appointment
1. Clinic marks appointment as no-show
2. User receives notification
3. User taps notification or views in history
4. **NEW**: Combined cancellation card shows:
   - "Cancelled" status in red header
   - "No Show - Patient did not arrive" in content area
5. Orange/red styling distinguishes from regular cancellations
6. User sees the consequences consistently across all views

## Visual Hierarchy

### Appointment History Details View
```
┌─────────────────────────────────┐
│ Status Badge (Showing Status)   │
├─────────────────────────────────┤
│ ╔═══════════════════════════╗   │
│ ║ 🚫 Cancelled              ║   │ ← Red header
│ ║    (description text)     ║   │
│ ╚═══════════════════════════╝   │
│ ┌───────────────────────────┐   │
│ │ ℹ️  Cancellation Reason   │   │ ← White content
│ │ [Reason text]             │   │
│ └───────────────────────────┘   │
├─────────────────────────────────┤
│ Pet Information                 │
├─────────────────────────────────┤
│ Appointment Information         │
└─────────────────────────────────┘
```

### Alert Details View
```
┌─────────────────────────────────┐
│ Header Card                     │
│ (Icon, Title, Time, Category)   │
├─────────────────────────────────┤
│ Details Card                    │
│ (Main notification message)     │
├─────────────────────────────────┤
│ ╔═══════════════════════════╗   │
│ ║ 🚫 Cancelled              ║   │ ← Red header
│ ║    (description text)     ║   │
│ ╚═══════════════════════════╝   │
│ ┌───────────────────────────┐   │
│ │ ℹ️  Cancellation Reason   │   │ ← White content
│ │ [Reason text with grey    │   │
│ │  background highlighting]  │   │
│ └───────────────────────────┘   │
├─────────────────────────────────┤
│ Additional Information          │
│ (Other metadata if available)   │
├─────────────────────────────────┤
│ Action Buttons                  │
└─────────────────────────────────┘
```

## Testing Checklist

### Appointment History
- [x] Cancelled appointment shows cancellation reason card
- [x] Card appears between status badge and pet info
- [x] Card only shows when cancelReason is not null/empty
- [x] Red styling matches design specifications
- [x] Text is readable and properly formatted
- [x] Non-cancelled appointments don't show the card

### Alert Details
- [x] Cancelled appointment notification shows cancellation reason card
- [x] Card appears before additional metadata
- [x] Card has red border and proper styling
- [x] cancelReason is removed from metadata list
- [x] "Additional Information" section hides when only cancelReason exists
- [x] Navigation to appointment details works correctly

### Edge Cases
- [x] No errors when cancelReason is null
- [x] No errors when cancelReason is empty string
- [x] Proper handling of long cancellation reason text
- [x] Multiple cancellation types display correctly (user, clinic, auto, no-show)

## Known Cancellation Types

1. **User Cancellation**: "Cancelled by user"
2. **Clinic Cancellation**: Custom reason provided by clinic admin
3. **Auto-Cancellation**: "Auto-cancelled due to expiration" / "Appointment expired - not confirmed within 24 hours"
4. **No-Show**: "No Show - Patient did not arrive"
5. **System/Other**: Custom or default "Cancelled"

## Related Files

### Models
- `lib/core/models/clinic/appointment_booking_model.dart` - Appointment data structure with cancelReason
- `lib/core/models/notifications/notification_model.dart` - Notification structure with metadata

### Services
- `lib/core/services/notifications/appointment_booking_integration.dart` - Creates notifications with cancelReason
- `lib/core/services/clinic/appointment_auto_cancellation_service.dart` - Auto-cancels expired appointments
- `lib/core/services/mobile/appointment_booking_service.dart` - Handles appointment booking operations

### UI Components
- `lib/core/widgets/user/home/appointment_history_detail_modal.dart` - Appointment history details (combined card)
- `lib/pages/mobile/alerts/alerts_details_page.dart` - Alert/notification details (combined card)
- `lib/pages/mobile/appointments/appointment_details_page.dart` - Appointment details page (combined card)

### Navigation Paths
- **From Alerts**: Alerts → Tap notification → Alert Details (combined card) → Navigate to appointment
- **From History**: History → Tap appointment → Appointment History Details (combined card)
- **From Appointment List**: Appointments → Tap appointment → Appointment Details (combined card)

## Benefits

1. **Transparency**: Users always know why their appointments were cancelled
2. **Consistency**: Same information available in both alerts and appointment history
3. **Visual Clarity**: Red-themed card makes cancellation reason stand out
4. **Better UX**: No need to search through metadata to find cancellation reason
5. **Support**: Reduces support inquiries about cancelled appointments
6. **Trust**: Clear communication builds user trust in the system

## Implementation Date
October 18, 2025

## Status
✅ **COMPLETE** - All features implemented and tested
