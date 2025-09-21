import 'package:flutter/material.dart';
import 'package:pawsense/core/models/messaging/conversation_model.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/services/messaging/mobile_messaging_preferences_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'dart:async';

class MobileConversationListItem extends StatefulWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isCurrentlySelected; // Add this to track if conversation is currently open

  const MobileConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onDelete,
    this.isCurrentlySelected = false, // Default to false
  });

  @override
  State<MobileConversationListItem> createState() => _MobileConversationListItemState();
}

class _MobileConversationListItemState extends State<MobileConversationListItem>
    with TickerProviderStateMixin {
  final MobileMessagingPreferencesService _mobilePreferencesService = 
      MobileMessagingPreferencesService.instance;
  
  StreamSubscription<Set<String>>? _readConversationsSubscription;
  StreamSubscription<bool>? _dataChangedSubscription;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
    
    // Setup pulse animation for unread indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _readConversationsSubscription?.cancel();
    _dataChangedSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _initializePreferences() async {
    if (!mounted) return;
    
    // Listen to real-time data changes
    _dataChangedSubscription = _mobilePreferencesService.dataChangedStream.listen(
      (changed) {
        if (mounted && changed) {
          setState(() {
            // Trigger rebuild when data changes
          });
        }
      },
      onError: (error) {
        print('Error in data changed stream: $error');
      },
    );
    
    // Listen to changes in read conversations
    _readConversationsSubscription = _mobilePreferencesService.readConversationsStream.listen(
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

    // Initialize if needed
    if (!_mobilePreferencesService.isInitialized) {
      try {
        final user = await AuthGuard.getCurrentUser();
        if (mounted && user != null) {
          await _mobilePreferencesService.initializeForUser(user.uid);
        } else {
          print('Warning: Could not initialize mobile messaging preferences - no user');
        }
      } catch (e) {
        print('Warning: Could not initialize mobile messaging preferences: $e');
      }
    }
  }

  /// Mark conversation as read when tapped (following admin logic)
  void _markAsRead(String conversationId) {
    if (!mounted) return; // Ensure widget is still mounted
    
    _mobilePreferencesService.markConversationAsRead(conversationId);
    print('✅ Marked conversation $conversationId as read via mobile service');
  }

  void _onTap() {
    // Mark conversation as read when tapped (admin pattern)
    _markAsRead(widget.conversation.id);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: AuthGuard.getCurrentUser(),
      builder: (context, userSnapshot) {
        // Get current user to determine if last message was from clinic
        final isReadInStorage = _mobilePreferencesService.isConversationRead(widget.conversation.id);
        
        bool hasUnreadFromClinic = false;
        if (userSnapshot.hasData && userSnapshot.data != null) {
          final currentUser = userSnapshot.data!;
          
          // Mobile user logic: Only show as unread if the last message was from clinic
          // Ignore server unread count since it's designed for admin perspective
          hasUnreadFromClinic = widget.conversation.lastMessageSenderId != currentUser.uid &&
                                widget.conversation.lastMessageSenderId != null &&
                                !isReadInStorage;
          
          // Fix-up logic: If last message is from clinic but marked as read, 
          // this might be an old state that needs correction
          if (widget.conversation.lastMessageSenderId != currentUser.uid &&
              widget.conversation.lastMessageSenderId != null &&
              isReadInStorage) {
            print('🔧 Fix-up: Clinic message but marked as read - clearing read status for ${widget.conversation.clinicName} (ID: ${widget.conversation.id})');
            // Clear the read status since there's a clinic message
            _mobilePreferencesService.markConversationAsUnread(widget.conversation.id);
            hasUnreadFromClinic = true; // Override for this render
          }
                                
          // Debug logging only for conversations that should potentially show as unread
          if (widget.conversation.lastMessageSenderId != currentUser.uid && widget.conversation.lastMessageSenderId != null) {
            print('🔍 Debug conversation ${widget.conversation.clinicName}: lastSender=${widget.conversation.lastMessageSenderId}, currentUser=${currentUser.uid}, showAsUnread=$hasUnreadFromClinic, isRead=$isReadInStorage');
          }
        }
        
        final shouldShowAsUnread = hasUnreadFromClinic && !widget.isCurrentlySelected;

        // Control pulse animation based on unread status
        if (shouldShowAsUnread && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        } else if (!shouldShowAsUnread && _pulseController.isAnimating) {
          _pulseController.stop();
          _pulseController.reset();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: kMobilePaddingSmall),
          child: Material(
            color: shouldShowAsUnread ? AppColors.primary.withValues(alpha: 0.08) : AppColors.white,
            borderRadius: kMobileBorderRadiusSmallPreset,
            elevation: shouldShowAsUnread ? 3 : 1,
            shadowColor: shouldShowAsUnread 
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.textSecondary.withValues(alpha: 0.1),
            child: InkWell(
              onTap: _onTap,
              borderRadius: kMobileBorderRadiusSmallPreset,
              child: Container(
                decoration: shouldShowAsUnread
                    ? BoxDecoration(
                        borderRadius: kMobileBorderRadiusSmallPreset,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      )
                    : null,
                padding: const EdgeInsets.all(kMobilePaddingSmall),
                child: Row(
                  children: [
                    // Clinic avatar with animated unread indicator
                    Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: shouldShowAsUnread 
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.1),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.transparent,
                            child: Icon(
                              Icons.local_hospital,
                              color: shouldShowAsUnread ? AppColors.primary : AppColors.primary.withValues(alpha: 0.8),
                              size: 18,
                            ),
                          ),
                        ),
                        if (shouldShowAsUnread)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.4),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.conversation.lastMessage ?? 'No messages yet',
                            style: TextStyle(
                              fontSize: 12,
                              color: shouldShowAsUnread 
                                  ? AppColors.textPrimary.withValues(alpha: 0.8)
                                  : AppColors.textSecondary,
                              fontWeight: shouldShowAsUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                              fontSize: 11,
                              color: shouldShowAsUnread ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: shouldShowAsUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (shouldShowAsUnread)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            if (widget.onDelete != null) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _showDeleteConfirmation(context),
                                child: Icon(
                                  Icons.more_vert,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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