import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import '../../../models/messaging/conversation_model.dart';
import 'user_avatar.dart';

class ChatHeader extends StatelessWidget {
  final Conversation? conversation;
  final VoidCallback? onInfoPressed;

  const ChatHeader({
    super.key,
    this.conversation,
    this.onInfoPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (conversation == null) {
      return Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Center(
          child: Text(
            'Select a conversation to start chatting',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // User avatar and info
          UserAvatar(
            userId: conversation!.userId,
            userName: conversation!.userName,
            radius: 20,
            showUnreadIndicator: false,
          ),
          const SizedBox(width: kSpacingSmall),
          
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation!.userName.isNotEmpty 
                      ? conversation!.userName 
                      : 'Unknown User',
                  style: kTextStyleRegular.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          // Action buttons
          IconButton(
            onPressed: onInfoPressed,
            icon: Icon(
              Icons.info_outline,
              color: AppColors.primary,
              size: 20,
            ),
            tooltip: 'Conversation info',
          ),
        ],
      ),
    );
  }
}