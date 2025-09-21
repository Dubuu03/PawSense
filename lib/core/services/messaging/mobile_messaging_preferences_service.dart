import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

/// Mobile-specific messaging preferences service with real-time updates
/// Provides immediate UI updates and persistent storage for mobile messaging
class MobileMessagingPreferencesService {
  static MobileMessagingPreferencesService? _instance;
  static MobileMessagingPreferencesService get instance {
    _instance ??= MobileMessagingPreferencesService._();
    return _instance!;
  }

  MobileMessagingPreferencesService._();

  // In-memory cache for instant access
  Set<String> _readConversations = <String>{};
  Map<String, DateTime> _lastMessageTimestamps = <String, DateTime>{};
  Map<String, int> _conversationUnreadCounts = <String, int>{};
  bool _isInitialized = false;
  String? _currentUserId;

  // Stream controllers for real-time UI updates
  final StreamController<Set<String>> _readConversationsController = 
      StreamController<Set<String>>.broadcast();
  final StreamController<Map<String, int>> _unreadCountsController = 
      StreamController<Map<String, int>>.broadcast();
  final StreamController<bool> _dataChangedController = 
      StreamController<bool>.broadcast();

  // Public getters
  Set<String> get readConversations => Set.from(_readConversations);
  Map<String, DateTime> get lastMessageTimestamps => Map.from(_lastMessageTimestamps);
  Map<String, int> get conversationUnreadCounts => Map.from(_conversationUnreadCounts);
  bool get isInitialized => _isInitialized;
  String? get currentUserId => _currentUserId;

  // Streams for reactive UI updates
  Stream<Set<String>> get readConversationsStream => _readConversationsController.stream;
  Stream<Map<String, int>> get unreadCountsStream => _unreadCountsController.stream;
  Stream<bool> get dataChangedStream => _dataChangedController.stream;

  /// Initialize the service for a specific user
  Future<void> initializeForUser(String userId) async {
    if (_isInitialized && _currentUserId == userId) {
      print('🔄 MobileMessagingPreferences: Already initialized for user $userId');
      return;
    }

    print('🚀 MobileMessagingPreferences: Initializing for user $userId');
    _currentUserId = userId;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load read conversations
      final readConversationsJson = prefs.getString('mobile_read_conversations_$userId');
      if (readConversationsJson != null) {
        final List<dynamic> readList = json.decode(readConversationsJson);
        _readConversations = readList.cast<String>().toSet();
      } else {
        _readConversations = <String>{};
      }

      // Load last message timestamps
      final timestampsJson = prefs.getString('mobile_message_timestamps_$userId');
      if (timestampsJson != null) {
        final Map<String, dynamic> timestampsMap = json.decode(timestampsJson);
        _lastMessageTimestamps = timestampsMap.map(
          (key, value) => MapEntry(key, DateTime.parse(value)),
        );
      } else {
        _lastMessageTimestamps = <String, DateTime>{};
      }

      // Load unread counts
      final unreadCountsJson = prefs.getString('mobile_unread_counts_$userId');
      if (unreadCountsJson != null) {
        final Map<String, dynamic> unreadMap = json.decode(unreadCountsJson);
        _conversationUnreadCounts = unreadMap.map(
          (key, value) => MapEntry(key, value as int),
        );
      } else {
        _conversationUnreadCounts = <String, int>{};
      }

      _isInitialized = true;
      
      // Notify listeners
      _notifyListeners();
      
      print('✅ MobileMessagingPreferences: Loaded ${_readConversations.length} read conversations');
      print('✅ MobileMessagingPreferences: Loaded ${_conversationUnreadCounts.length} unread counts');
      
    } catch (e) {
      print('❌ MobileMessagingPreferences: Initialization failed: $e');
      _isInitialized = false;
    }
  }

  /// Check if a conversation is marked as read
  bool isConversationRead(String conversationId) {
    return _readConversations.contains(conversationId);
  }

  /// Mark a conversation as read and persist immediately
  Future<void> markConversationAsRead(String conversationId) async {
    if (_readConversations.contains(conversationId)) return;
    
    print('✅ MobileMessagingPreferences: Marking conversation $conversationId as read');
    
    _readConversations.add(conversationId);
    
    // Reset unread count for this conversation
    _conversationUnreadCounts[conversationId] = 0;
    
    // Persist changes immediately
    await _saveReadConversations();
    await _saveUnreadCounts();
    
    // Notify UI immediately
    _notifyListeners();
  }

  /// Mark a conversation as unread and persist immediately
  Future<void> markConversationAsUnread(String conversationId) async {
    print('📝 MobileMessagingPreferences: Marking conversation $conversationId as unread');
    
    _readConversations.remove(conversationId);
    
    // Persist changes immediately
    await _saveReadConversations();
    
    // Notify UI immediately
    _notifyListeners();
  }

  /// Update unread count for a conversation and sync with server data
  /// This method is more intelligent for mobile users
  Future<void> syncConversationData(String conversationId, int serverUnreadCount) async {
    final currentCount = _conversationUnreadCounts[conversationId] ?? 0;
    
    // If server shows more unread messages than we have locally, update
    if (serverUnreadCount > currentCount) {
      print('🔄 MobileMessagingPreferences: Syncing conversation $conversationId: $currentCount -> $serverUnreadCount');
      
      // Update the count but DON'T automatically mark as unread
      // Let the UI logic determine if it should show as unread based on lastMessageSenderId
      _conversationUnreadCounts[conversationId] = serverUnreadCount;
      await _saveUnreadCounts();
      _notifyListeners();
    }
  }

  /// Mark a conversation as having new messages from clinic
  /// This should be called when we detect a new message from clinic specifically
  Future<void> markNewMessageFromClinic(String conversationId, int unreadCount) async {
    print('📨 MobileMessagingPreferences: New message from clinic in $conversationId');
    
    // Update unread count
    _conversationUnreadCounts[conversationId] = unreadCount;
    
    // Remove from read conversations since there's a new clinic message
    _readConversations.remove(conversationId);
    
    await _saveUnreadCounts();
    await _saveReadConversations();
    _notifyListeners();
  }

  /// Check if conversation data has changed and needs UI update
  bool hasConversationDataChanged(String conversationId, int serverUnreadCount) {
    final localCount = _conversationUnreadCounts[conversationId] ?? 0;
    final isReadLocally = _readConversations.contains(conversationId);
    
    // Data has changed if:
    // 1. Server unread count is different from local
    // 2. Server shows unread messages but we have it marked as read
    return localCount != serverUnreadCount || (serverUnreadCount > 0 && isReadLocally);
  }

  /// Update unread count for a conversation
  Future<void> updateUnreadCount(String conversationId, int count) async {
    if (_conversationUnreadCounts[conversationId] == count) return;
    
    print('🔢 MobileMessagingPreferences: Updating unread count for $conversationId to $count');
    
    _conversationUnreadCounts[conversationId] = count;
    
    // If count is 0, mark as read
    if (count == 0) {
      _readConversations.add(conversationId);
      await _saveReadConversations();
    } else {
      // If count > 0, remove from read set
      _readConversations.remove(conversationId);
      await _saveReadConversations();
    }
    
    await _saveUnreadCounts();
    
    // Notify UI immediately
    _notifyListeners();
  }

  /// Update last message timestamp for a conversation
  Future<void> updateLastMessageTimestamp(String conversationId, DateTime timestamp) async {
    _lastMessageTimestamps[conversationId] = timestamp;
    await _saveTimestamps();
  }

  /// Get unread count for a conversation
  int getUnreadCount(String conversationId) {
    return _conversationUnreadCounts[conversationId] ?? 0;
  }

  /// Get total unread count across all conversations
  int getTotalUnreadCount() {
    return _conversationUnreadCounts.values.fold(0, (sum, count) => sum + count);
  }

  /// Get total number of unread conversations
  int getUnreadConversationsCount() {
    return _conversationUnreadCounts.entries
        .where((entry) => entry.value > 0 && !_readConversations.contains(entry.key))
        .length;
  }

  /// Clear all data for current user
  Future<void> clearAllData() async {
    if (_currentUserId == null) return;
    
    print('🗑️ MobileMessagingPreferences: Clearing all data for user $_currentUserId');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mobile_read_conversations_$_currentUserId');
    await prefs.remove('mobile_message_timestamps_$_currentUserId');
    await prefs.remove('mobile_unread_counts_$_currentUserId');
    
    _readConversations.clear();
    _lastMessageTimestamps.clear();
    _conversationUnreadCounts.clear();
    
    _notifyListeners();
  }

  /// Private method to save read conversations
  Future<void> _saveReadConversations() async {
    if (_currentUserId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final readList = _readConversations.toList();
      await prefs.setString('mobile_read_conversations_$_currentUserId', json.encode(readList));
    } catch (e) {
      print('❌ Failed to save read conversations: $e');
    }
  }

  /// Private method to save timestamps
  Future<void> _saveTimestamps() async {
    if (_currentUserId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampsMap = _lastMessageTimestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      );
      await prefs.setString('mobile_message_timestamps_$_currentUserId', json.encode(timestampsMap));
    } catch (e) {
      print('❌ Failed to save timestamps: $e');
    }
  }

  /// Private method to save unread counts
  Future<void> _saveUnreadCounts() async {
    if (_currentUserId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mobile_unread_counts_$_currentUserId', json.encode(_conversationUnreadCounts));
    } catch (e) {
      print('❌ Failed to save unread counts: $e');
    }
  }

  /// Notify all listeners of data changes
  void _notifyListeners() {
    _readConversationsController.add(Set.from(_readConversations));
    _unreadCountsController.add(Map.from(_conversationUnreadCounts));
    _dataChangedController.add(true);
  }

  /// Dispose streams
  void dispose() {
    _readConversationsController.close();
    _unreadCountsController.close();
    _dataChangedController.close();
  }

  /// Get statistics for preferences page
  Map<String, dynamic> getStatistics() {
    return {
      'readConversations': _readConversations.length,
      'totalConversationsTracked': _lastMessageTimestamps.length,
      'unreadConversations': getUnreadConversationsCount(),
      'totalUnreadMessages': getTotalUnreadCount(),
      'isInitialized': _isInitialized,
      'currentUserId': _currentUserId,
    };
  }
}