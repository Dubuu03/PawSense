# Real-time Clinic Schedule Caching Implementation

## Overview

This implementation provides real-time synchronization of clinic schedules between admin dashboard and mobile app using Firestore listeners with smart caching. When admins make changes to clinic schedules, mobile users see updates immediately without needing to refresh.

## Architecture

### Components

1. **BookAppointmentPage** - Enhanced with real-time listeners
2. **RealtimeScheduleManager** - Centralized manager for schedule updates
3. **Smart Caching** - Version-aware cache with automatic invalidation

### Key Features

- ✅ **Real-time Updates**: Firestore listeners detect schedule changes instantly
- ✅ **Smart Caching**: Version-aware cache prevents unnecessary updates
- ✅ **Automatic Date Validation**: Selected dates auto-adjust when schedules change
- ✅ **User Notifications**: Visual feedback when schedules update
- ✅ **Memory Management**: Proper cleanup of listeners and cache
- ✅ **Error Handling**: Graceful fallbacks and error recovery

## Implementation Details

### 1. Enhanced Cache Entry

```dart
class _CachedSchedule {
  final WeeklySchedule schedule;
  final DateTime cachedAt;
  final DateTime? lastModified;  // NEW: Version tracking
  
  bool isNewerThan(DateTime? otherModified) {
    // Compare versions to prevent unnecessary updates
  }
}
```

### 2. Real-time Listener Setup

```dart
Future<void> _setupScheduleListener(String clinicId) async {
  _scheduleListeners[clinicId] = FirebaseFirestore.instance
      .collection('clinicSchedules')
      .doc(clinicId)
      .snapshots()
      .listen((snapshot) {
        if (snapshot.exists && mounted) {
          _handleScheduleUpdate(clinicId, snapshot);
        }
      });
}
```

### 3. Smart Update Handling

```dart
void _handleScheduleUpdate(String clinicId, DocumentSnapshot snapshot) {
  // Check document version
  final lastModified = (data['updatedAt'] as Timestamp?)?.toDate();
  
  // Skip if cache is already up to date
  if (cachedEntry != null && cachedEntry.isNewerThan(lastModified)) {
    return;
  }
  
  // Update cache and UI
  // Show notification to user
}
```

## Usage Guide

### Basic Usage in BookAppointmentPage

The real-time caching is automatically enabled when loading clinic schedules:

```dart
// Clinic schedule automatically sets up real-time listener
await _loadClinicSchedule(clinicId);

// User sees immediate updates when admin changes schedule
// Selected dates auto-adjust if they become unavailable
// Time slots refresh automatically
```

### Using the Centralized Manager

For other parts of the app that need real-time schedule updates:

```dart
import '../services/clinic/realtime_schedule_manager.dart';

// Setup listener with callback
RealtimeScheduleManager.setupListener(
  clinicId,
  onUpdate: (WeeklySchedule schedule) {
    // Handle schedule update
    setState(() {
      _clinicSchedule = schedule;
    });
  },
  onError: (String error) {
    // Handle errors
  },
);

// Check for cached data
final cachedSchedule = RealtimeScheduleManager.getCachedSchedule(clinicId);
if (cachedSchedule != null) {
  // Use cached data
}

// Cleanup when done
RealtimeScheduleManager.cleanupListener(clinicId);
```

## Cache Management

### Cache Expiry
- **Default TTL**: 30 minutes (extended since real-time updates handle freshness)
- **Version-based**: Cache invalidated when document `updatedAt` changes
- **Memory-aware**: Automatic cleanup of expired entries

### Cache Invalidation Triggers
1. **Real-time updates** from Firestore listeners
2. **Manual invalidation** via `clearScheduleCache(clinicId)`
3. **Time-based expiry** after 30 minutes
4. **Clinic switching** in UI (cleans up previous clinic listeners)

## Performance Optimizations

### 1. Listener Management
- **One listener per clinic**: Prevents duplicate listeners
- **Automatic cleanup**: Listeners removed when switching clinics
- **Memory management**: All listeners cleaned up on dispose

### 2. Smart Updates
- **Version comparison**: Prevents unnecessary UI updates
- **Differential parsing**: Only parse data when actually changed
- **Debounced notifications**: User sees single notification per update

### 3. Cache Strategy
- **Shared cache**: Static cache shared across all page instances
- **Lazy loading**: Listeners only created when needed
- **Background cleanup**: Expired entries automatically removed

## Error Handling

### Network Issues
```dart
onError: (error) {
  print('❌ Schedule listener error: $error');
  // Fallback to cached data
  // Retry mechanism for critical operations
}
```

### Data Consistency
- **Document existence checks**: Handle deleted documents gracefully
- **Schema validation**: Fallback to defaults for missing fields
- **Type safety**: Proper casting with null safety

### UI Resilience
- **Graceful degradation**: App works even if real-time updates fail
- **User feedback**: Clear error messages and retry options
- **State preservation**: UI state maintained during updates

## Debugging and Monitoring

### Debug Logs
```dart
// Enable detailed logging
print('🎧 Real-time listener setup for clinic schedule: $clinicId');
print('🔄 Schedule updated for clinic $clinicId, refreshing cache...');
print('✅ Schedule cache updated for clinic: $clinicId');
```

### Cache Statistics
```dart
final stats = RealtimeScheduleManager.getStats();
print('Active listeners: ${stats['activeListeners']}');
print('Cached schedules: ${stats['cachedSchedules']}');
```

## Testing Scenarios

### 1. Admin Schedule Changes
1. Admin updates clinic hours on dashboard
2. Mobile app receives real-time update within 1-2 seconds
3. Selected date auto-adjusts if it becomes unavailable
4. User sees notification about schedule update
5. Time slots refresh to show new availability

### 2. Network Connectivity
1. Test with poor network conditions
2. Verify graceful fallback to cached data
3. Ensure listeners reconnect after network recovery
4. Validate cache consistency after reconnection

### 3. Memory Management
1. Switch between multiple clinics rapidly
2. Verify old listeners are cleaned up
3. Check memory usage remains stable
4. Test cache expiry and cleanup

## Integration Points

### Admin Dashboard
- When admins save schedule changes, the `updatedAt` field is automatically set
- Firestore triggers propagate changes to all listening mobile clients
- No additional code needed on admin side

### Mobile App
- BookAppointmentPage automatically handles real-time updates
- Other pages can use RealtimeScheduleManager for custom implementations
- Background listeners continue running during navigation

### Future Enhancements
- **Push notifications**: Notify users about schedule changes even when app is closed
- **Conflict resolution**: Handle concurrent edits by multiple admins
- **Offline support**: Queue schedule updates when offline, sync when online
- **Analytics**: Track schedule change frequency and user impact

## Migration Notes

### From Static Caching
- Existing static cache logic enhanced with version tracking
- Cache TTL extended from 10 minutes to 30 minutes
- Added real-time listener management

### Breaking Changes
- None - backward compatible with existing code
- Optional real-time features can be disabled if needed

### Performance Impact
- **Memory**: Minimal increase due to listener management
- **Network**: Efficient - only updates when data actually changes
- **Battery**: Negligible impact from Firestore listeners
- **User Experience**: Significant improvement in data freshness