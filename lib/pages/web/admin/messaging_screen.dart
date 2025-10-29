import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/widgets/admin/messages/conversation_list.dart';
import 'package:pawsense/core/widgets/admin/messages/chat_header.dart';
import 'package:pawsense/core/widgets/admin/messages/message_list.dart';
import 'package:pawsense/core/widgets/admin/messages/message_input.dart';
import 'package:pawsense/core/services/messaging/messaging_web_service.dart';
import 'package:pawsense/core/models/messaging/conversation_model.dart';
import 'package:pawsense/core/models/messaging/message_model.dart';

class MessagingScreen extends StatefulWidget {
  final String? conversationId;
  
  const MessagingScreen({super.key, this.conversationId});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final MessagingWebService _messagingService = MessagingWebService();
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  Conversation? _selectedConversation;
  bool _isLoadingConversations = true;
  bool _isLoadingMessages = false;
  String _searchQuery = '';
  
  final ScrollController _messageScrollController = ScrollController();
  
  // Stream subscriptions for proper disposal
  StreamSubscription<List<Conversation>>? _conversationsSubscription;
  StreamSubscription<List<Message>>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    print('🚀 MessagingScreen initState - conversationId: ${widget.conversationId}');
    _loadConversations();
  }

  @override
  void dispose() {
    print('🗑️ MessagingScreen disposing...');
    
    // Cancel all stream subscriptions
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    
    // Dispose scroll controller
    _messageScrollController.dispose();
    
    print('🗑️ MessagingScreen disposed successfully');
    super.dispose();
  }

  void _loadConversations() {
    if (!mounted) return;
    
    setState(() {
      _isLoadingConversations = true;
    });

    // Cancel previous subscription to prevent multiple listeners
    _conversationsSubscription?.cancel();
    
    _conversationsSubscription = _messagingService.getConversationsStream().listen(
      (conversations) {
        if (!mounted) return;
        
        setState(() {
          _conversations = conversations;
          _isLoadingConversations = false;
        });
        
        // If a conversation ID was provided and we haven't selected one yet, select it now
        if (widget.conversationId != null && _selectedConversation == null && conversations.isNotEmpty) {
          _selectConversationById(widget.conversationId!);
        }
      },
      onError: (error) {
        if (!mounted) return;
        
        setState(() {
          _isLoadingConversations = false;
        });
        _showErrorSnackBar('Failed to load conversations: $error');
      },
    );
  }

  void _loadMessages(String conversationId) {
    if (!mounted) return;
    
    print('📱 MessagingScreen: Loading messages for conversation: $conversationId');
    setState(() {
      _isLoadingMessages = true;
      _messages = [];
    });

    // Cancel previous subscription to prevent multiple listeners
    _messagesSubscription?.cancel();
    
    _messagesSubscription = _messagingService.getMessagesStream(conversationId).listen(
      (messages) {
        if (!mounted) return;
        
        print('📱 MessagingScreen: Received ${messages.length} messages');
        setState(() {
          _messages = messages;
          _isLoadingMessages = false;
        });
        _scrollToBottom();
        // Mark messages as read
        _messagingService.markConversationAsRead(conversationId, 'admin');
      },
      onError: (error) {
        if (!mounted) return;
        
        print('❌ MessagingScreen: Error loading messages: $error');
        setState(() {
          _isLoadingMessages = false;
        });
        _showErrorSnackBar('Failed to load messages: $error');
      },
    );
  }

  void _selectConversation(Conversation conversation) {
    if (!mounted) return;
    
    // Just update the state without changing the URL
    // This avoids route matching conflicts
    setState(() {
      _selectedConversation = conversation;
    });
    _loadMessages(conversation.id);
  }

  void _selectConversationById(String conversationId) {
    if (!mounted) return;
    
    print('📱 MessagingScreen: Selecting conversation by ID: $conversationId');
    try {
      final conversation = _conversations.firstWhere(
        (conv) => conv.id == conversationId,
      );
      
      print('📱 MessagingScreen: Found conversation: ${conversation.userName}');
      setState(() {
        _selectedConversation = conversation;
      });
      _loadMessages(conversation.id);
    } catch (e) {
      // Conversation not found, handle gracefully
      print('❌ MessagingScreen: Conversation with ID $conversationId not found');
      if (_conversations.isNotEmpty) {
        print('📱 MessagingScreen: Selecting first available conversation');
        _selectConversation(_conversations.first);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (!mounted) return;
    
    setState(() {
      _searchQuery = query;
    });
    _loadConversations();
  }

  void _sendMessage(String content) async {
    if (_selectedConversation == null || content.trim().isEmpty) return;

    try {
      await _messagingService.sendAdminMessage(
        _selectedConversation!.id,
        content.trim(),
      );
      
      // Mark conversation as read when admin replies (clears unread indicators)
      await _messagingService.markConversationAsRead(_selectedConversation!.id, 'admin');
      
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackBar('Failed to send message: $e');
    }
  }

  void _scrollToBottom() {
    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      if (_messageScrollController.hasClients) {
        _messageScrollController.animateTo(
          _messageScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _onInfoPressed() {
    if (_selectedConversation != null) {
      _showConversationInfo();
    }
  }

  void _showConversationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conversation Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${_selectedConversation!.userName}'),
            const SizedBox(height: kSpacingSmall),
            Text('Clinic: ${_selectedConversation!.clinicName}'),
            const SizedBox(height: kSpacingSmall),
            Text('Created: ${_formatDate(_selectedConversation!.createdAt)}'),
            const SizedBox(height: kSpacingSmall),
            Text('Last Updated: ${_formatDate(_selectedConversation!.updatedAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _archiveConversation();
            },
            child: Text('Archive', style: TextStyle(color: AppColors.warning)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteConversation();
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _archiveConversation() async {
    if (_selectedConversation == null || !mounted) return;

    try {
      await _messagingService.updateConversationStatus(_selectedConversation!.id, false);
      if (!mounted) return;
      
      setState(() {
        _selectedConversation = null;
        _messages = [];
      });
      _showSuccessSnackBar('Conversation archived successfully');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to archive conversation: $e');
    }
  }

  void _deleteConversation() async {
    if (_selectedConversation == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Conversation'),
        content: Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _messagingService.deleteConversation(_selectedConversation!.id);
        if (!mounted) return;
        
        setState(() {
          _selectedConversation = null;
          _messages = [];
        });
        _showSuccessSnackBar('Conversation deleted successfully');
      } catch (e) {
        if (!mounted) return;
        _showErrorSnackBar('Failed to delete conversation: $e');
      }
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Conversations sidebar
          ConversationList(
            key: const ValueKey('conversation_list'),
            conversations: _conversations,
            selectedConversation: _selectedConversation,
            onConversationSelected: _selectConversation,
            isLoading: _isLoadingConversations,
            searchQuery: _searchQuery,
            onSearchChanged: _onSearchChanged,
          ),
          
          // Chat area
          Expanded(
            child: Container(
              key: const ValueKey('chat_area'),
              decoration: BoxDecoration(
                color: AppColors.white,
              ),
              child: Column(
                children: [
                  // Chat header
                  ChatHeader(
                    conversation: _selectedConversation,
                    onInfoPressed: _onInfoPressed,
                  ),
                  
                  // Messages
                  Expanded(
                    child: _selectedConversation == null
                        ? _buildEmptyState()
                        : MessageList(
                            messages: _messages,
                            isLoading: _isLoadingMessages,
                            scrollController: _messageScrollController,
                          ),
                  ),
                  
                  // Message input
                  MessageInput(
                    onSendMessage: _sendMessage,
                    isEnabled: _selectedConversation != null,
                  ),
                ],
              ),
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
            size: 120,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: kSpacingLarge),
          Text(
            'No conversation selected',
            style: kTextStyleLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kSpacingSmall),
          Text(
            'Choose a conversation from the sidebar to start messaging',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}