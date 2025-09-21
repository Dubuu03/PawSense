import 'package:flutter/material.dart';
import 'package:pawsense/core/services/messaging/messaging_service.dart';
import 'package:pawsense/core/models/messaging/conversation_model.dart';
import 'package:pawsense/core/models/messaging/message_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/widgets/user/messaging/mobile_message_list.dart';
import 'package:pawsense/core/widgets/user/messaging/message_input.dart';
import 'package:pawsense/core/services/messaging/messaging_preferences_service.dart';

class ConversationPage extends StatefulWidget {
  final Conversation conversation;

  const ConversationPage({
    super.key,
    required this.conversation,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessagingPreferencesService _preferencesService = MessagingPreferencesService.instance;
  bool _isSending = false;
  String? _currentUserId;
  String? _realConversationId; // Track the real conversation ID
  bool _hassentMessage = false; // Track if user has sent a message
  
  @override
  void initState() {
    super.initState();
    print('=== ConversationPage initState ===');
    print('Conversation ID: ${widget.conversation.id}');
    print('Clinic Name: ${widget.conversation.clinicName}');
    _loadCurrentUser();
    
    // Set initial conversation ID
    _realConversationId = widget.conversation.id.startsWith('temp_') ? null : widget.conversation.id;
    
    // Mark conversation as read when entering
    if (!widget.conversation.id.startsWith('temp_')) {
      _preferencesService.markConversationAsRead(widget.conversation.id);
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthGuard.getCurrentUser();
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  Stream<List<Message>> _getMessagesStream() {
    // Use real conversation ID if available, otherwise check if temp conversation
    final conversationId = _realConversationId ?? widget.conversation.id;
    
    if (conversationId.startsWith('temp_')) {
      return Stream.value(<Message>[]);
    }
    
    return MessagingService.getMessagesStream(conversationId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      String conversationId = widget.conversation.id;
      
      // Check if this is a temporary conversation (new conversation)
      if (conversationId.startsWith('temp_')) {
        // Create or get existing conversation
        final realConversationId = await MessagingService.createOrGetConversation(
          widget.conversation.clinicId,
          widget.conversation.clinicName,
        );
        
        if (realConversationId == null) {
          _showError('Failed to create conversation');
          return;
        }
        
        conversationId = realConversationId;
        _realConversationId = conversationId; // Update the real conversation ID
        print('=== Created/Retrieved real conversation: $conversationId ===');
        
        // Trigger a rebuild to update the stream
        setState(() {});
      }
      
      final success = await MessagingService.sendMessage(
        conversationId: conversationId,
        receiverId: widget.conversation.clinicId,
        receiverName: widget.conversation.clinicName,
        content: content,
      );

      if (success) {
        print('=== Message sent successfully ===');
        _messageController.clear();
        _hassentMessage = true; // Mark that user has sent a message
        
        // Mark conversation as read when user sends a message
        _preferencesService.markConversationAsRead(conversationId);
        
        // The StreamBuilder will automatically update with the new message
      } else {
        _showError('Failed to send message');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context, _hassentMessage),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.white.withValues(alpha: 0.2),
              child: const Icon(
                Icons.local_hospital,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.clinicName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Vet Clinic',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.white),
            onPressed: () {
              // TODO: Add menu options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list - Using StreamBuilder for real-time updates
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _getMessagesStream(),
              builder: (context, snapshot) {
                print('=== StreamBuilder update ===');
                print('Connection state: ${snapshot.connectionState}');
                print('Has data: ${snapshot.hasData}');
                print('Has error: ${snapshot.hasError}');
                
                if (snapshot.hasData) {
                  print('Messages count: ${snapshot.data!.length}');
                }
                
                if (snapshot.hasError) {
                  print('StreamBuilder error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                // Auto-scroll to bottom when messages update
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return MobileMessageList(
                  messages: messages,
                  scrollController: _scrollController,
                  currentUserId: _currentUserId,
                );
              },
            ),
          ),

          // Message input area
          MessageInput(
            controller: _messageController,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}