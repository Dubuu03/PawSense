import 'package:flutter/material.dart';
import 'package:pawsense/core/services/messaging/messaging_service.dart';
import 'package:pawsense/core/models/messaging/conversation_model.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/widgets/user/shared/navigation/user_app_bar.dart';
import 'package:pawsense/core/widgets/user/messaging/conversation_list_item.dart';
import 'clinic_selection_page.dart';
import 'conversation_page.dart';

class MessagingPage extends StatefulWidget {
  const MessagingPage({super.key});

  @override
  State<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  UserModel? _userModel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (mounted) {
        setState(() {
          _userModel = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _onUserUpdated(UserModel updatedUser) {
    setState(() {
      _userModel = updatedUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: UserAppBar(
        user: _userModel,
        onUserUpdated: _onUserUpdated,
      ),
      body: Column(
        children: [
          // Header with new message button
          Container(
            padding: const EdgeInsets.all(kSpacingMedium),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Your Conversations',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                FloatingActionButton.small(
                  onPressed: () => _navigateToClinicSelection(),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          
          // Conversations list
          Expanded(
            child: StreamBuilder<List<Conversation>>(
              stream: MessagingService.getUserConversations(),
              builder: (context, snapshot) {
                print('MessagingPage StreamBuilder state: ${snapshot.connectionState}');
                if (snapshot.hasError) {
                  print('MessagingPage StreamBuilder error: ${snapshot.error}');
                }
                if (snapshot.hasData) {
                  print('MessagingPage StreamBuilder data: ${snapshot.data!.length} conversations');
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
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
                          'Error loading conversations',
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
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Force rebuild to retry
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a conversation with a vet clinic',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToClinicSelection(),
                          icon: const Icon(Icons.add),
                          label: const Text('New Message'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final conversations = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(kSpacingMedium),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return ConversationListItem(
                      conversation: conversation,
                      onTap: () => _navigateToConversation(conversation),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToConversation(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationPage(conversation: conversation),
      ),
    );
  }

  void _navigateToClinicSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClinicSelectionPage(),
      ),
    );
  }
}