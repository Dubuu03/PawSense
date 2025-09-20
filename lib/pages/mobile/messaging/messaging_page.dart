import 'package:flutter/material.dart';
import 'package:pawsense/core/services/messaging/messaging_service.dart';
import 'package:pawsense/core/models/messaging/conversation_model.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToClinicSelection(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(kMobilePaddingMedium,kMobilePaddingMedium,kMobilePaddingMedium,0),
            color: AppColors.background,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Messages',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 16
                    ),
                  ),
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
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: kMobileSizedBoxLarge),
                        Text(
                          'Error loading conversations',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: kMobileSizedBoxSmall),
                        Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: kMobileSizedBoxLarge),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Force rebuild to retry
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          ),
                          child: const Text('Retry', style: TextStyle(fontSize: 12)),
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
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: kMobileSizedBoxLarge),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: kMobileSizedBoxSmall),
                        Text(
                          'Start a conversation with a vet clinic',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: kMobileSizedBoxXLarge),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToClinicSelection(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Message', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final conversations = snapshot.data!;

              return ListView.separated(
                padding: const EdgeInsets.all(kMobilePaddingMedium),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return ConversationListItem(
                      conversation: conversation,
                      onTap: () => _navigateToConversation(conversation),
                      onDelete: () => _deleteConversation(conversation),
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: kMobileSizedBoxMedium),
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

  Future<void> _deleteConversation(Conversation conversation) async {
    try {
      await MessagingService.deleteConversationAndMessages(conversation.id);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversation with ${conversation.clinicName} deleted'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete conversation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateToClinicSelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClinicSelectionPage(),
      ),
    );

    // If a conversation was created (user sent a message), the StreamBuilder should automatically refresh
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation started successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}