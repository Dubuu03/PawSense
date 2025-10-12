# Appointment Booking Schedule Validation Implementation

## Overview
Enhanced the mobile appointment booking page to validate dates and times based on clinic schedules. The system now:
1. Disables dates when the clinic is closed
2. Shows only available time slots in hourly blocks (e.g., "9:00 AM - 10:00 AM")
3. Validates against clinic schedule, break times, and existing appointments
4. Caches clinic schedules for 10 minutes to improve performance and reduce Firestore reads

## Features Implemented

### 1. **Date Validation**
- **Clinic Schedule Integration**: Loads weekly schedule when clinic is selected
- **Date Picker Validation**: Uses `selectableDayPredicate` to disable closed days
- **Visual Feedback**: Only allows selection of dates when clinic is open

### 2. **Time Slot Dropdown**
- **Hourly Block Display**: Shows appointments in 1-hour blocks (e.g., "9:00 AM - 10:00 AM")
- **Dynamic Time Slot Generation**: Creates hourly slots based on clinic's operating hours
- **Break Time Handling**: Excludes entire hours that overlap with break times
- **Real-time Availability Check**: Validates if at least one slot is available in each hour block
- **User-friendly Display**: Shows time ranges in 12-hour format with AM/PM
- **Simplified Selection**: Users choose hour blocks instead of specific 20-minute slots

### 3. **Smart Loading**
- **Auto-refresh**: Time slots reload when date or clinic changes
- **Loading States**: Shows loading indicator while fetching slots
- **Empty State**: Clear message when no slots are available
- **Error Handling**: Graceful fallbacks if schedule can't be loaded
- **Schedule Caching**: Caches clinic schedules for 10 minutes to reduce Firestore reads
- **Cache Sharing**: Cache is shared across all booking page instances
- **Auto-validation**: Automatically adjusts selected date to next available if initially closed

## Technical Implementation

### Files Modified
- `lib/pages/mobile/home_services/book_appointment_page.dart`

### Key Changes

#### 1. Added Imports
```dart
import 'package:pawsense/core/services/clinic/clinic_schedule_service.dart';
import 'package:pawsense/core/models/clinic/clinic_schedule_model.dart';
```

#### 2. New State Variables
```dart
WeeklySchedule? _clinicSchedule;
List<String> _availableTimeSlots = [];
bool _loadingTimeSlots = false;
String? _selectedTimeSlot;
static final Map<String, _CachedSchedule> _scheduleCache = {};
```

#### 3. Cache Class
```dart
class _CachedSchedule {
  final WeeklySchedule schedule;
  final DateTime cachedAt;
  
  _CachedSchedule(this.schedule, this.cachedAt);
  
  bool get isExpired {
    final now = DateTime.now();
    return now.difference(cachedAt) > const Duration(minutes: 10);
  }
}
```

#### 4. Schedule Loading Methods

**`_loadClinicSchedule(String clinicId)`**
- Checks cache first before fetching from Firestore
- Loads weekly schedule and stores in cache with timestamp
- Triggered when clinic is selected
- Stores schedule for date validation
- Auto-adjusts selected date if initially closed
- Cache expires after 10 minutes

**`_loadAvailableTimeSlots()`**
- Generates hourly time blocks (1-hour increments)
- Filters out hours that overlap with break times
- Validates if at least one slot is available in each hour
- Updates available slots list with hour ranges (e.g., "09:00 - 10:00")

**`_isDateEnabled(DateTime date)`**
- Checks if clinic is open on the selected day
- Used by date picker's `selectableDayPredicate`

**`_findNextAvailableDate(DateTime startDate)`**
- Finds the next open date starting from a given date
- Searches up to 30 days ahead
- Used to auto-correct invalid initial dates

**`clearScheduleCache([String? clinicId])`**
- Static method to clear cached schedules
- Can clear specific clinic or all clinics
- Useful for forcing fresh data fetch

**`_isHourBlockInBreak(String blockStart, String blockEnd, String breakStart, String breakEnd)`**
- Determines if an hour block overlaps with any break time
- Returns true if there's any overlap

**`_timeToMinutes(String time)`**
- Helper method to convert time string to minutes since midnight
- Used for time range comparisons

**`_formatTimeSlot(String timeRange)`**
- Converts 24-hour format to 12-hour AM/PM format
- Handles hourly blocks: "09:00 - 10:00" → "9:00 AM - 10:00 AM"

**`_formatSingleTime(String time)`**
- Formats individual time values
- Example: "14:00" → "2:00 PM"

#### 4. Updated UI Components

**Date Picker**
```dart
selectableDayPredicate: (DateTime date) {
  return _isDateEnabled(date);
}
```
- Only allows selection of dates when clinic is open
- Visual feedback in calendar

**Time Slot Dropdown**
- Replaced `showTimePicker` with dropdown
- Shows loading state while fetching slots
- Displays warning if no slots available
- Auto-selects first available slot

#### 5. Booking Validation
```dart
if (_selectedTimeSlot == null || _selectedTimeSlot!.isEmpty) {
  // Show error message
  return;
}
final formattedTime = _selectedTimeSlot!;
```
- Uses selected slot directly (already validated)
- No need for additional time validation

## User Experience Flow

### 1. **Select Clinic**
```
User selects clinic → Load clinic schedule → Load available time slots
```

### 2. **Select Date**
```
User opens date picker → Only open days are selectable → Greyed out closed days
```

### 3. **Select Time**
```
User opens time dropdown → Shows only available hour blocks → Displays:
  - 1-hour blocks (e.g., "9:00 AM - 10:00 AM")
  - Only hours with at least one available slot
  - Excludes hours overlapping with breaks
  - Excludes completely booked hours
```

### 4. **Book Appointment**
```
User selects hour block → System extracts start time → Validates availability → Books appointment
```

## Caching Mechanism

### How It Works
1. **First Load**: When a clinic is selected, schedule is fetched from Firestore
2. **Cache Storage**: Schedule is stored in a static map with timestamp
3. **Subsequent Loads**: Before fetching, system checks cache for valid entry
4. **Cache Hit**: If found and not expired, uses cached data (instant load)
5. **Cache Miss**: If not found or expired, fetches fresh data from Firestore
6. **Shared Cache**: All instances of booking page share the same cache

### Cache Lifecycle
```
┌─────────────────────┐
│  Clinic Selected    │
└──────────┬──────────┘
           │
           v
    ┌──────────────┐
    │ Check Cache  │
    └──────┬───────┘
           │
     ┌─────┴─────┐
     │           │
  Found      Not Found
  & Fresh    or Expired
     │           │
     v           v
┌────────┐  ┌─────────────┐
│  Use   │  │ Fetch from  │
│ Cache  │  │  Firestore  │
└────┬───┘  └──────┬──────┘
     │             │
     │             v
     │      ┌─────────────┐
     │      │ Store in    │
     │      │   Cache     │
     │      └──────┬──────┘
     │             │
     └─────────────┘
             │
             v
    ┌────────────────┐
    │ Display Times  │
    └────────────────┘
```

### Cache Benefits
- **Faster Loading**: Instant load on repeated visits
- **Reduced Costs**: Fewer Firestore reads
- **Better UX**: No loading delay for cached data
- **Offline Support**: Works during brief network issues (if cached)
- **Resource Efficient**: Minimal memory usage per cache entry

### When Cache is Used
- ✅ Revisiting same clinic within 10 minutes
- ✅ Switching between dates for same clinic
- ✅ Multiple users booking same clinic simultaneously
- ✅ Page refreshes or back navigation

### When Cache is Bypassed
- ❌ First time selecting a clinic
- ❌ More than 10 minutes since last fetch
- ❌ Manual cache clear (if implemented in UI)
- ❌ Different clinic selected

## Example Scenarios

### Scenario 1: Clinic Closed on Sundays
- **Date Picker**: Sundays are greyed out and cannot be selected
- **User Action**: Must choose Monday-Saturday
- **Result**: Prevents booking errors

### Scenario 2: Lunch Break (12:00 PM - 1:00 PM)
- **Time Dropdown**: "12:00 PM - 1:00 PM" hour block is excluded
- **Available Blocks**: 9:00 AM - 10:00 AM, 10:00 AM - 11:00 AM, 11:00 AM - 12:00 PM, 1:00 PM - 2:00 PM, ...
- **Result**: Users can't book during break times

### Scenario 3: Partially Booked Hour Block
- **Check**: System verifies if ANY slot is available within the hour
- **Time Dropdown**: Shows "9:00 AM - 10:00 AM" if at least one 20-minute slot is free
- **Result**: Users can book in hour blocks with partial availability

### Scenario 4: Fully Booked Hour Block
- **Check**: All slots within the hour are fully booked
- **Time Dropdown**: Hour block is not shown
- **Result**: Prevents booking in completely full hours
### Scenario 5: No Available Slots
- **Display**: Warning message "No available time slots for this date"
- **Action**: User must select different date
- **Result**: Clear feedback to user

## Data Flow

```
┌─────────────────┐
│  Select Clinic  │
└────────┬────────┘
         │
         v
┌─────────────────────┐
│ Load Clinic Schedule│
│  (Weekly hours,     │
│   break times)      │
└─────────┬───────────┘
          │
          v
┌─────────────────────┐
│   Select Date       │
│ (Only open days)    │
└─────────┬───────────┘
          │
          v
┌─────────────────────┐
│ Generate Time Slots │
│  - Hourly blocks    │
│  - Check if hour    │
│    overlaps breaks  │
│  - Verify at least  │
│    one slot free    │
└─────────┬───────────┘
          │
          v
┌─────────────────────┐
│ Display Dropdown    │
│ (Hour block ranges) │
└─────────────────────┘
```

## Benefits

### For Users
- ✅ Can only select valid dates/times
- ✅ See available hours at a glance
- ✅ Simplified selection with hourly blocks
- ✅ No booking errors due to closed hours
- ✅ Better planning with clear availability
- ✅ Reduced decision fatigue with grouped time slots

### For Clinics
- ✅ Respects operating schedule
- ✅ Prevents overbooking
- ✅ Honors break times
- ✅ Reduces manual validation

### For System
- ✅ Reduced invalid bookings
- ✅ Better data integrity
- ✅ Fewer customer support issues
- ✅ Improved user experience

## Error Handling

### No Schedule Found
- **Fallback**: Allow all dates (graceful degradation)
- **User Impact**: Can still book appointments
- **Log**: Error logged for debugging

### Failed to Load Slots
- **Display**: Empty state with retry option
- **Message**: Clear error message to user
- **Action**: User can try different date

### Schedule Changes
- **Auto-refresh**: Slots reload when date changes
- **Real-time**: Always shows current availability
- **Consistency**: Prevents stale data issues

## Testing Checklist

- [x] Date picker disables closed days
- [x] Time dropdown shows only available slots
- [x] Break times are excluded from slots
- [x] Fully booked slots are hidden
- [x] Schedule loads when clinic selected
- [x] Slots reload when date changes
- [x] Loading states display correctly
- [x] Empty states show clear messages
- [x] Booking validates selected slot
- [x] Error handling works gracefully

## Future Enhancements

1. **Holiday Support**
   - Exclude special holidays from date picker
   - Show holiday notification in UI

2. **Waitlist Feature**
   - Allow users to join waitlist for full slots
   - Notify when slot becomes available

3. **Smart Suggestions**
   - Suggest alternative times if selected slot becomes unavailable
   - Show "Next available" slot prominently

4. **Capacity Indicators**
   - Show how many slots remaining
   - Visual indicator for high-demand times

## Performance Considerations

- **Caching**: Clinic schedule cached for 10 minutes to reduce Firestore reads
- **Shared Cache**: Cache is static and shared across all booking page instances
- **Lazy Loading**: Time slots only loaded when needed
- **Debouncing**: Date changes debounced to prevent excessive API calls
- **Optimization**: Availability checks run in parallel when possible
- **Automatic Expiry**: Cached schedules expire after 10 minutes for data freshness
- **Memory Efficient**: Only stores schedule and timestamp, minimal memory footprint

## Maintenance Notes

- Schedule data structure in `clinicSchedules` collection
- Time slots generated client-side for flexibility
- Availability validation server-side for security
- Format: HH:mm (24-hour) for consistency

---

**Last Updated**: October 12, 2025  
**Status**: ✅ Complete and Tested
