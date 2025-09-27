import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Centralized service for managing messaging-related SharedPreferences
/// Loads data once during login and maintains it in memory for the session
class MessagingPreferencesService {
  static MessagingPreferencesService? _instance;
  static MessagingPreferencesService get instance {
    _instance ??= MessagingPreferencesService._();
    return _instance!;
  }

  MessagingPreferencesService._();

  // In-memory cache for messaging preferences
  Set<String> _readConversations = <String>{};
  final Map<String, DateTime> _lastMessageTimestamps = <String, DateTime>{};
  final Map<String, int> _unreadCounts = <String, int>{};
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _currentUserId; // Track which user's data we have loaded

  // Stream controllers for real-time updates
  final StreamController<Set<String>> _readConversationsController = 
      StreamController<Set<String>>.broadcast();
  final StreamController<Map<String, int>> _unreadCountsController = 
      StreamController<Map<String, int>>.broadcast();

  // Getters for cached data
  Set<String> get readConversations => Set.from(_readConversations);
  Map<String, DateTime> get lastMessageTimestamps => Map.from(_lastMessageTimestamps);
  Map<String, int> get unreadCounts => Map.from(_unreadCounts);
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  // Streams for reactive updates
  Stream<Set<String>> get readConversationsStream => _readConversationsController.stream;
  Stream<Map<String, int>> get unreadCountsStream => _unreadCountsController.stream;

  /// Initialize and load all messaging preferences from SharedPreferences
  /// Should be called once during login/app initialization
  Future<void> initialize({String? userId}) async {
    if (_isInitialized || _isLoading) return;
    
    _isLoading = true;
    _currentUserId = userId;
    print('🚀 MessagingPreferencesService: Initializing for user: $userId');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Create user-specific keys
      final userPrefix = userId != null ? '${userId}_' : '';
      
      // Load read conversations
      final readConversationsJson = prefs.getStringList('${userPrefix}read_conversations') ?? [];
      _readConversations = Set.from(readConversationsJson);
      
      // Load last message timestamps
      final timestampsJson = prefs.getStringList('${userPrefix}last_message_timestamps') ?? [];
      _lastMessageTimestamps.clear();
      for (String timestampEntry in timestampsJson) {
        final parts = timestampEntry.split(':::');
        if (parts.length == 2) {
          final conversationId = parts[0];
          final timestamp = DateTime.tryParse(parts[1]);
          if (timestamp != null) {
            _lastMessageTimestamps[conversationId] = timestamp;
          }
        }
      }
      
      // Load unread counts
      final unreadCountsJson = prefs.getStringList('${userPrefix}unread_counts') ?? [];
      _unreadCounts.clear();
      for (String countEntry in unreadCountsJson) {
        final parts = countEntry.split(':::');
        if (parts.length == 2) {
          final conversationId = parts[0];
          final count = int.tryParse(parts[1]);
          if (count != null) {
            _unreadCounts[conversationId] = count;
          }
        }
      }
      
      _isInitialized = true;
      _isLoading = false;
      
      // Notify listeners
      if (!_areStreamsDisposed) {
        _readConversationsController.add(_readConversations);
        _unreadCountsController.add(_unreadCounts);
      }
      
      print('✅ MessagingPreferencesService: Initialized successfully for user: $userId');
      print('   - Read conversations: ${_readConversations.length}');
      print('   - Last message timestamps: ${_lastMessageTimestamps.length}');
      print('   - Unread counts: ${_unreadCounts.length}');
      
    } catch (e) {
      print('❌ MessagingPreferencesService: Initialization failed: $e');
      _isLoading = false;
      _isInitialized = false;
    }
  }

  /// Check if a conversation has been marked as read
  bool isConversationRead(String conversationId) {
    return _readConversations.contains(conversationId);
  }

  /// Mark a conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    if (_readConversations.contains(conversationId)) return;
    
    _readConversations.add(conversationId);
    await _saveReadConversations();
    
    // Reset unread count
    if (_unreadCounts.containsKey(conversationId)) {
      _unreadCounts[conversationId] = 0;
      await _saveUnreadCounts();
    }
    
    print('✅ Marked conversation $conversationId as read');
  }

  /// Mark a conversation as unread
  Future<void> markConversationAsUnread(String conversationId) async {
    _readConversations.remove(conversationId);
    await _saveReadConversations();
    print('📝 Marked conversation $conversationId as unread');
  }

  /// Update the last message timestamp for a conversation
  Future<void> updateLastMessageTimestamp(String conversationId, DateTime timestamp) async {
    _lastMessageTimestamps[conversationId] = timestamp;
    await _saveTimestamps();
  }

  /// Record when user leaves a conversation (for unread separator logic)
  Future<void> recordConversationExit(String conversationId, DateTime lastSeenMessageTime) async {
    _lastMessageTimestamps[conversationId] = lastSeenMessageTime;
    await _saveTimestamps();
    print('📤 Recorded conversation exit: $conversationId at ${lastSeenMessageTime.toIso8601String()}');
  }

  /// Get the last seen message timestamp for a conversation
  DateTime? getLastSeenMessageTime(String conversationId) {
    return _lastMessageTimestamps[conversationId];
  }

  /// Update unread count for a conversation
  Future<void> updateUnreadCount(String conversationId, int count) async {
    if (count <= 0) {
      _unreadCounts.remove(conversationId);
    } else {
      _unreadCounts[conversationId] = count;
    }
    await _saveUnreadCounts();
    if (!_areStreamsDisposed) {
      _unreadCountsController.add(_unreadCounts);
    }
  }

  /// Get unread count for a conversation
  int getUnreadCount(String conversationId) {
    return _unreadCounts[conversationId] ?? 0;
  }

  /// Get last message timestamp for a conversation
  DateTime? getLastMessageTimestamp(String conversationId) {
    return _lastMessageTimestamps[conversationId];
  }

  /// Reinitialize for a different user (when switching accounts)
  Future<void> reinitializeForUser(String userId) async {
    if (_currentUserId == userId && _isInitialized) {
      print('MessagingPreferencesService: Already initialized for user $userId');
      return;
    }
    
    // Clear current session
    await clearSessionData();
    
    // Initialize for new user
    await initialize(userId: userId);
  }
  Future<void> clearSessionData() async {
    _readConversations.clear();
    _lastMessageTimestamps.clear();
    _unreadCounts.clear();
    _isInitialized = false;
    _currentUserId = null;
    
    // Notify listeners
    if (!_areStreamsDisposed) {
      _readConversationsController.add(_readConversations);
      _unreadCountsController.add(_unreadCounts);
    }
    
    print('🗑️ MessagingPreferencesService: Session data cleared (user data preserved)');
  }

  /// Clear all data including stored preferences (for complete reset or account deletion)
  Future<void> clearAllData({String? userId}) async {
    _readConversations.clear();
    _lastMessageTimestamps.clear();
    _unreadCounts.clear();
    
    final prefs = await SharedPreferences.getInstance();
    final userPrefix = userId ?? _currentUserId ?? '';
    final keyPrefix = userPrefix.isNotEmpty ? '${userPrefix}_' : '';
    
    await prefs.remove('${keyPrefix}read_conversations');
    await prefs.remove('${keyPrefix}last_message_timestamps');
    await prefs.remove('${keyPrefix}unread_counts');
    
    _isInitialized = false;
    _currentUserId = null;
    
    // Notify listeners
    if (!_areStreamsDisposed) {
      _readConversationsController.add(_readConversations);
      _unreadCountsController.add(_unreadCounts);
    }
    
    print('🗑️ MessagingPreferencesService: All data cleared for user: ${userId ?? userPrefix}');
  }

  /// Save read conversations to SharedPreferences
  Future<void> _saveReadConversations() async {
    try {
      if (_areStreamsDisposed) {
        print('Warning: Attempting to save after disposal');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final userPrefix = _currentUserId != null ? '${_currentUserId}_' : '';
      await prefs.setStringList('${userPrefix}read_conversations', _readConversations.toList());
      
      if (!_areStreamsDisposed) {
        _readConversationsController.add(_readConversations);
      }
      
      print('💾 Saved ${_readConversations.length} read conversations for user: $_currentUserId');
    } catch (e) {
      print('❌ Error saving read conversations: $e');
    }
  }

  /// Save timestamps to SharedPreferences
  Future<void> _saveTimestamps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPrefix = _currentUserId != null ? '${_currentUserId}_' : '';
      final timestampsList = _lastMessageTimestamps.entries
          .map((entry) => '${entry.key}:::${entry.value.toIso8601String()}')
          .toList();
      await prefs.setStringList('${userPrefix}last_message_timestamps', timestampsList);
      print('💾 Saved ${_lastMessageTimestamps.length} message timestamps for user: $_currentUserId');
    } catch (e) {
      print('❌ Error saving timestamps: $e');
    }
  }

  /// Save unread counts to SharedPreferences
  Future<void> _saveUnreadCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userPrefix = _currentUserId != null ? '${_currentUserId}_' : '';
      final countsList = _unreadCounts.entries
          .map((entry) => '${entry.key}:::${entry.value}')
          .toList();
      await prefs.setStringList('${userPrefix}unread_counts', countsList);
      print('💾 Saved ${_unreadCounts.length} unread counts for user: $_currentUserId');
    } catch (e) {
      print('❌ Error saving unread counts: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    try {
      _readConversationsController.close();
      _unreadCountsController.close();
      print('🗑️ MessagingPreferencesService: Disposed');
    } catch (e) {
      print('Warning: Error disposing MessagingPreferencesService: $e');
    }
  }

  /// Check if streams are closed to prevent usage after disposal
  bool get _areStreamsDisposed {
    return _readConversationsController.isClosed || _unreadCountsController.isClosed;
  }
}