import 'package:flutter/material.dart';
import 'package:pawsense/core/models/messaging/conversation_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/services/messaging/messaging_preferences_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'dart:async';

class MobileConversationListItem extends StatefulWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const MobileConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<MobileConversationListItem> createState() => _MobileConversationListItemState();
}

class _MobileConversationListItemState extends State<MobileConversationListItem> {
  final MessagingPreferencesService _preferencesService = MessagingPreferencesService.instance;
  StreamSubscription<Set<String>>? _readConversationsSubscription;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  @override
  void dispose() {
    _readConversationsSubscription?.cancel();
    super.dispose();
  }

  void _initializePreferences() async {
    if (!mounted) return;
    
    // Listen to changes in read conversations
    _readConversationsSubscription = _preferencesService.readConversationsStream.listen(
      (readConversations) {
        if (mounted) {
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
        if (mounted && user != null) {
          await _preferencesService.reinitializeForUser(user.uid);
        } else if (mounted) {
          await _preferencesService.initialize();
        }
      } catch (e) {
        print('Warning: Could not initialize messaging preferences: $e');
      }
    }
  }

  void _onTap() {
    // Mark conversation as read when tapped
    _preferencesService.markConversationAsRead(widget.conversation.id);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    // Check if conversation has been read in persistent storage
    final isReadInStorage = _preferencesService.isConversationRead(widget.conversation.id);
    final hasUnreadMessages = widget.conversation.unreadCount > 0;
    
    // Show as unread if: has unread messages AND not read in storage
    final shouldShowAsUnread = hasUnreadMessages && !isReadInStorage;

    return Container(
      margin: const EdgeInsets.only(bottom: kMobilePaddingSmall),
      child: Material(
        color: shouldShowAsUnread ? AppColors.primary.withValues(alpha: 0.05) : AppColors.white,
        borderRadius: kMobileBorderRadiusSmallPreset,
        elevation: shouldShowAsUnread ? 2 : 1,
        shadowColor: AppColors.textSecondary.withValues(alpha: 0.1),
        child: InkWell(
          onTap: _onTap,
          borderRadius: kMobileBorderRadiusSmallPreset,
          child: Padding(
            padding: const EdgeInsets.all(kMobilePaddingSmall),
            child: Row(
              children: [
                // Clinic avatar with unread indicator
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.local_hospital,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    if (shouldShowAsUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: kMobileSizedBoxLarge),

                // Conversation details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.conversation.clinicName,
                        style: TextStyle(
                          fontWeight: shouldShowAsUnread ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 14,
                          color: shouldShowAsUnread ? AppColors.primary : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.conversation.lastMessage != null &&
                          widget.conversation.lastMessage!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.conversation.lastMessage!,
                          style: TextStyle(
                            color: shouldShowAsUnread ? AppColors.textPrimary : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: shouldShowAsUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Time and unread indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.conversation.lastMessageTime != null)
                      Text(
                        _formatTime(widget.conversation.lastMessageTime!),
                        style: TextStyle(
                          color: shouldShowAsUnread ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: shouldShowAsUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    if (shouldShowAsUnread && widget.conversation.unreadCount > 0) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.conversation.unreadCount.toString(),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Delete action
                if (widget.onDelete != null) ...[
                  const SizedBox(width: kMobilePaddingSmall),
                  GestureDetector(
                    onTap: () => _showDeleteConfirmation(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.more_vert,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Conversation'),
          content: Text(
            'Are you sure you want to delete this conversation with ${widget.conversation.clinicName}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (widget.onDelete != null) {
                  widget.onDelete!();
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}