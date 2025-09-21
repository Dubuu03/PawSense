import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/services/messaging/messaging_preferences_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import '../../../models/messaging/conversation_model.dart';
import 'user_avatar.dart';
import 'dart:async';

class ConversationList extends StatefulWidget {
  final List<Conversation> conversations;
  final Conversation? selectedConversation;
  final Function(Conversation) onConversationSelected;
  final bool isLoading;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const ConversationList({
    super.key,
    required this.conversations,
    this.selectedConversation,
    required this.onConversationSelected,
    this.isLoading = false,
    this.searchQuery = '',
    required this.onSearchChanged,
  });

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  final MessagingPreferencesService _preferencesService = MessagingPreferencesService.instance;
  StreamSubscription<Set<String>>? _readConversationsSubscription;
  Map<String, int> _previousUnreadCounts = {}; // Track previous unread counts

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  @override
  void didUpdateWidget(ConversationList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check for new messages when conversations update
    _checkForNewMessages(oldWidget.conversations, widget.conversations);
  }

  @override
  void dispose() {
    _readConversationsSubscription?.cancel();
    super.dispose();
  }

  void _initializePreferences() async {
    if (!mounted) return; // Check if widget is still mounted
    
    // Listen to changes in read conversations
    _readConversationsSubscription = _preferencesService.readConversationsStream.listen(
      (readConversations) {
        if (mounted) { // Always check mounted before setState
          setState(() {
            // Trigger rebuild when read status changes
          });
        }
      },
      onError: (error) {
        print('Error in read conversations stream: $error');
      },
    );

    // If not initialized, try to initialize with current user
    if (!_preferencesService.isInitialized && !_preferencesService.isLoading) {
      try {
        final user = await AuthGuard.getCurrentUser();
        if (mounted && user != null) { // Check mounted after async call
          await _preferencesService.reinitializeForUser(user.uid);
        } else if (mounted) {
          await _preferencesService.initialize();
        }
      } catch (e) {
        print('Warning: Could not initialize messaging preferences: $e');
      }
    }
  }

  void _markAsRead(String conversationId) {
    if (!mounted) return; // Ensure widget is still mounted
    
    _preferencesService.markConversationAsRead(conversationId);
    print('✅ Marked conversation $conversationId as read via centralized service');
  }

  void _checkForNewMessages(List<Conversation> oldConversations, List<Conversation> newConversations) {
    // Create map for easier comparison
    final oldConversationMap = {for (var conv in oldConversations) conv.id: conv};

    // Check each conversation for increased unread count
    for (final newConv in newConversations) {
      final oldConv = oldConversationMap[newConv.id];
      
      // If this conversation had fewer unread messages before, or didn't exist, 
      // it means there are new messages - clear read status
      if (oldConv == null || newConv.unreadCount > oldConv.unreadCount) {
        // Only clear read status if conversation is not currently selected
        final isCurrentlySelected = widget.selectedConversation?.id == newConv.id;
        if (!isCurrentlySelected && newConv.unreadCount > 0) {
          _preferencesService.markConversationAsUnread(newConv.id);
          print('🆕 New messages detected in conversation ${newConv.id}, marked as unread');
        }
      }
    }

    // Update the previous unread counts for next comparison
    _previousUnreadCounts = {for (var conv in newConversations) conv.id: conv.unreadCount};
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while preferences are being loaded
    if (_preferencesService.isLoading) {
      return Container(
        width: 360,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            right: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filteredConversations = widget.conversations.where((conv) {
      return conv.userName.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
             conv.clinicName.toLowerCase().contains(widget.searchQuery.toLowerCase());
    }).toList();

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chats',
                      style: kTextStyleHeader.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${widget.conversations.length}',
                      style: kTextStyleSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kSpacingSmall),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    onChanged: widget.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search Messenger',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: kSpacingMedium,
                        vertical: kSpacingSmall,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Conversations list
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredConversations.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: filteredConversations.length,
                        itemBuilder: (context, index) {
                          final conversation = filteredConversations[index];
                          return _buildConversationTile(conversation);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: kSpacingMedium),
          Text(
            'No conversations found',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kSpacingSmall),
          Text(
            'Patient conversations for your clinic will appear here',
            style: kTextStyleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final isSelected = widget.selectedConversation?.id == conversation.id;
    // Check if conversation has been read in persistent storage or is currently selected
    final isReadInStorage = _preferencesService.isConversationRead(conversation.id);
    final hasUnreadMessages = conversation.unreadCount > 0;
    
    // Show as unread if: has unread messages AND not read in storage AND not currently selected
    final shouldShowAsUnread = hasUnreadMessages && !isReadInStorage && !isSelected;
    
    return Material(
      key: ValueKey('conversation_${conversation.id}'),
      color: isSelected 
          ? AppColors.primary.withOpacity(0.1) 
          : shouldShowAsUnread 
              ? AppColors.primary.withOpacity(0.02)
              : Colors.transparent,
      child: InkWell(
        onTap: () {
          // Mark as read when tapped
          _markAsRead(conversation.id);
          // Call the parent callback
          widget.onConversationSelected(conversation);
        },
        child: Container(
          decoration: BoxDecoration(
            border: shouldShowAsUnread 
                ? Border(
                    left: BorderSide(
                      color: AppColors.primary,
                      width: 4,
                    ),
                  )
                : null,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: shouldShowAsUnread ? kSpacingMedium - 4 : kSpacingMedium,
            vertical: kSpacingSmall,
          ),
          child: Row(
            children: [
              // Avatar
              UserAvatar(
                userId: conversation.userId,
                userName: conversation.userName,
                radius: 24,
                showUnreadIndicator: shouldShowAsUnread,
              ),
              const SizedBox(width: kSpacingSmall),
              
              // Conversation details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.userName.isNotEmpty 
                          ? conversation.userName 
                          : 'Unknown User',
                      style: kTextStyleRegular.copyWith(
                        fontWeight: shouldShowAsUnread ? FontWeight.w700 : FontWeight.w600,
                        color: shouldShowAsUnread ? AppColors.textPrimary : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (conversation.lastMessage != null && conversation.lastMessage!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessage!,
                        style: kTextStyleSmall.copyWith(
                          color: shouldShowAsUnread ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: shouldShowAsUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Time and indicators
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(conversation.lastMessageTime ?? conversation.updatedAt),
                    style: kTextStyleSmall.copyWith(
                      color: shouldShowAsUnread ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: shouldShowAsUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Unread count indicator - only show if conversation should show as unread
                      if (shouldShowAsUnread && conversation.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: kTextStyleSmall.copyWith(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      // Show date format for messages older than a day
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inHours >= 1) {
      // Show hour:minute format for messages older than 1 hour
      final hour = dateTime.hour;
      final minute = dateTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
    } else if (difference.inMinutes > 0) {
      // Show "X mins ago" for messages within the last hour
      return '${difference.inMinutes} mins ago';
    } else {
      // Show "Just now" for very recent messages
      return 'Just now';
    }
  }
}