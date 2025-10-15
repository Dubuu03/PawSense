# Alerts Ghost Notifications Bug Fix

## 🐛 Bug Identified: Ghost Message Notifications

### Problem Description
Users are seeing **ghost message notifications** in their alerts even when:
1. All messages have been read
2. No new messages exist
3. The conversation has already been viewed

### Root Cause Analysis

#### Issue 1: Message Notifications Don't Check Read Status
**Location:** `/lib/core/services/notifications/realtime_notification_service.dart` line 219-250

**Current Logic:**
```dart
Future<List<AlertData>> _getMessageNotifications(String userId) async {
  final recentMessages = await _firestore
      .collection('conversations')
      .where('userId', isEqualTo: userId)
      .where('lastMessageSenderId', isNotEqualTo: userId)  // ❌ PROBLEM: Only checks sender
      .where('updatedAt', isGreaterThan: Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 7))
      ))
      .limit(5)
      .get();

  for (final doc in recentMessages.docs) {
    notifications.add(AlertData(
      id: 'message_${conversationId}',
      title: 'New Message',
      subtitle: 'You have a new message from ${data['clinicName']}',
      isRead: _readStatesCache['message_$conversationId'] ?? false,  // ❌ Cache may not sync with actual read status
    ));
  }
}
```

**Problems:**
1. ❌ Query only checks if `lastMessageSenderId != userId` (means last message wasn't from user)
2. ❌ This shows ALL conversations where clinic sent the last message, regardless of whether user read it
3. ❌ Doesn't check the `unreadCount` field in conversations collection
4. ❌ Doesn't sync with MessagingPreferencesService which tracks actually read conversations
5. ❌ Cache (`_readStatesCache`) may be stale or not properly synchronized

#### Issue 2: No Integration with Read Status
The message notification service doesn't integrate with the messaging preferences service which actually tracks:
- Which conversations have been read
- When conversations were marked as read
- Unread message counts per conversation

#### Issue 3: Notification Service vs Messaging Service Mismatch
There's a disconnect between:
- **NotificationService**: Checks `unreadCount > 0` in conversations ✅ (correct)
- **RealtimeNotificationService**: Only checks `lastMessageSenderId != userId` ❌ (incorrect)

### Example Scenario Where Bug Occurs

```
1. User receives message from clinic → Alert appears ✅
2. User opens conversation and reads all messages → Messages marked as read ✅
3. User goes to alerts page → Alert STILL shows ❌ (GHOST NOTIFICATION)
4. Alert shows because:
   - lastMessageSenderId = clinic (not user)
   - Notification cache doesn't sync with read status
   - No check for unreadCount = 0
```

## 🔧 Solution

### Fix 1: Add Unread Count Check
Update `_getMessageNotifications()` to check `unreadCount`:

```dart
Future<List<AlertData>> _getMessageNotifications(String userId) async {
  try {
    final recentMessages = await _firestore
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .where('lastMessageSenderId', isNotEqualTo: userId)
        .where('unreadCount', isGreaterThan: 0)  // ✅ ADD THIS: Only show if unread
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 7))
        ))
        .limit(5)
        .get();

    final notifications = <AlertData>[];
    
    for (final doc in recentMessages.docs) {
      final data = doc.data();
      final conversationId = doc.id;
      final unreadCount = data['unreadCount'] ?? 0;
      
      // ✅ Double-check unread count before adding
      if (unreadCount > 0) {
        notifications.add(AlertData(
          id: 'message_${conversationId}',
          title: 'New Message',
          subtitle: 'You have a new message from ${data['clinicName']}',
          type: AlertType.message,
          timestamp: (data['updatedAt'] as Timestamp).toDate(),
          isRead: _readStatesCache['message_$conversationId'] ?? false,
          actionUrl: '/messaging',
          actionLabel: 'View Message',
          metadata: {
            'conversationId': conversationId,
            'unreadCount': unreadCount,
          },
        ));
      }
    }
    
    return notifications;
  } catch (e) {
    debugPrint('❌ Error getting message notifications: $e');
    return [];
  }
}
```

### Fix 2: Sync Read Status with Messaging Service
When user marks conversation as read, ensure notification is also marked as read:

```dart
// In MessagingService.markConversationAsRead()
Future<void> markConversationAsRead(String conversationId, String userId) async {
  // Update conversation unread count
  await _firestore.collection('conversations').doc(conversationId).update({
    'unreadCount': 0,
    'lastReadAt': FieldValue.serverTimestamp(),
  });
  
  // ✅ Also mark notification as read
  await RealtimeNotificationService().markAsRead('message_$conversationId', userId);
}
```

### Fix 3: Auto-Clear on Conversation Open
When user opens a conversation, automatically mark the notification as read:

```dart
// In ConversationPage.initState()
@override
void initState() {
  super.initState();
  _loadCurrentUser();
  
  // Mark conversation as read
  if (!widget.conversation.id.startsWith('temp_')) {
    _mobilePreferencesService.markConversationAsRead(widget.conversation.id);
    
    // ✅ ADD THIS: Also mark notification as read
    GlobalNotificationManager().markAsRead('message_${widget.conversation.id}');
  }
}
```

## 📋 Additional Checks Needed

### Check 1: Verify Unread Count Updates
Ensure `unreadCount` in conversations is properly:
- ✅ Incremented when clinic sends message
- ✅ Reset to 0 when user reads messages
- ✅ Persisted correctly in Firestore

### Check 2: Verify Message Status Updates
Ensure individual messages have correct `status` field:
- `sent` → `delivered` → `read`
- When user views message, status changes to `read`
- Conversation `unreadCount` decreases accordingly

### Check 3: Verify Notification Cache
Ensure `_readStatesCache` in RealtimeNotificationService:
- ✅ Syncs with Firestore read states
- ✅ Updates when user marks conversation as read
- ✅ Persists across app restarts

## 🧪 Testing Checklist

### Test Case 1: Normal Message Flow
- [ ] User receives message from clinic
- [ ] Alert appears in alerts page ✅
- [ ] User opens conversation
- [ ] User reads all messages
- [ ] Alert disappears from alerts page ✅
- [ ] No ghost notification remains ✅

### Test Case 2: Multiple Conversations
- [ ] User has 3 unread conversations
- [ ] 3 alerts show in alerts page ✅
- [ ] User reads 1 conversation
- [ ] Only 2 alerts remain ✅
- [ ] User reads remaining 2 conversations
- [ ] All alerts cleared ✅

### Test Case 3: Partial Read
- [ ] User has conversation with 5 unread messages
- [ ] Alert shows in alerts page ✅
- [ ] User reads 3 messages
- [ ] Alert still shows (unreadCount = 2) ✅
- [ ] User reads remaining 2 messages
- [ ] Alert disappears ✅

### Test Case 4: App Restart
- [ ] User has unread message
- [ ] Alert shows ✅
- [ ] User reads message
- [ ] Alert disappears ✅
- [ ] User closes and reopens app
- [ ] Alert does NOT reappear ✅
- [ ] No ghost notification ✅

### Test Case 5: Offline/Online Sync
- [ ] User goes offline
- [ ] Receives message (queued)
- [ ] User comes online
- [ ] Alert appears ✅
- [ ] User reads message
- [ ] Alert disappears ✅
- [ ] No ghost notification on next sync ✅

## 🔍 Debug Logging

Add comprehensive logging to track the issue:

```dart
Future<List<AlertData>> _getMessageNotifications(String userId) async {
  try {
    debugPrint('🔍 Fetching message notifications for user: $userId');
    
    final recentMessages = await _firestore
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .where('lastMessageSenderId', isNotEqualTo: userId)
        .where('unreadCount', isGreaterThan: 0)
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 7))
        ))
        .limit(5)
        .get();

    debugPrint('📊 Found ${recentMessages.docs.length} conversations with unread messages');
    
    final notifications = <AlertData>[];
    
    for (final doc in recentMessages.docs) {
      final data = doc.data();
      final conversationId = doc.id;
      final unreadCount = data['unreadCount'] ?? 0;
      final clinicName = data['clinicName'] ?? 'Unknown';
      
      debugPrint('💬 Conversation: $clinicName (ID: $conversationId)');
      debugPrint('   - Unread count: $unreadCount');
      debugPrint('   - Last sender: ${data['lastMessageSenderId']}');
      debugPrint('   - Updated: ${(data['updatedAt'] as Timestamp).toDate()}');
      
      if (unreadCount > 0) {
        notifications.add(AlertData(
          id: 'message_${conversationId}',
          title: 'New Message',
          subtitle: 'You have a new message from $clinicName',
          type: AlertType.message,
          timestamp: (data['updatedAt'] as Timestamp).toDate(),
          isRead: _readStatesCache['message_$conversationId'] ?? false,
          actionUrl: '/messaging',
          actionLabel: 'View Message',
          metadata: {
            'conversationId': conversationId,
            'unreadCount': unreadCount,
          },
        ));
        
        debugPrint('   ✅ Added to notifications');
      } else {
        debugPrint('   ❌ Skipped (unreadCount = 0)');
      }
    }
    
    debugPrint('✅ Returning ${notifications.length} message notifications');
    return notifications;
  } catch (e) {
    debugPrint('❌ Error getting message notifications: $e');
    return [];
  }
}
```

## 📝 Files to Modify

1. **`/lib/core/services/notifications/realtime_notification_service.dart`**
   - Add `unreadCount > 0` filter in query
   - Add double-check before creating notification
   - Add comprehensive debug logging

2. **`/lib/core/services/messaging/messaging_service.dart`**
   - Ensure `markConversationAsRead()` updates notification service
   - Ensure `unreadCount` is properly reset

3. **`/lib/pages/mobile/messaging/conversation_page.dart`**
   - Auto-mark notification as read when conversation opens

4. **`/lib/core/services/messaging/mobile_messaging_preferences_service.dart`**
   - Ensure sync between preferences and notification service

## 🎯 Expected Outcome

After implementing fixes:
- ✅ No ghost notifications
- ✅ Alerts only show for truly unread messages
- ✅ Alerts disappear when conversation is viewed
- ✅ Alerts sync correctly across app restarts
- ✅ Unread count is always accurate
- ✅ No stale cache issues

## 🚨 Priority: HIGH

This bug directly affects user experience and trust in the notification system. Ghost notifications are confusing and may cause users to:
- Constantly check messages unnecessarily
- Lose trust in the notification system
- Think the app has bugs
- Miss actual new messages (notification fatigue)
