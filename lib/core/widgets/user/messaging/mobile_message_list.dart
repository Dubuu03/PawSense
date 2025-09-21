import 'package:flutter/material.dart';
import 'package:pawsense/core/models/messaging/message_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/user/messaging/message_bubble.dart';

class MobileMessageList extends StatelessWidget {
  final List<Message> messages;
  final bool isLoading;
  final ScrollController? scrollController;
  final String? currentUserId;

  const MobileMessageList({
    super.key,
    required this.messages,
    this.isLoading = false,
    this.scrollController,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (messages.isEmpty) {
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
              'No messages yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation by sending a message',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      itemCount: _calculateItemCount(),
      itemBuilder: (context, index) {
        return _buildMessageItems()[index];
      },
    );
  }

  List<Widget> _buildMessageItems() {
    final items = <Widget>[];
    String? lastDateStr;

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );
      final dateStr = _formatDate(messageDate);

      // Add date separator if this is a new day
      if (lastDateStr != dateStr) {
        items.add(_buildDateSeparator(dateStr));
        lastDateStr = dateStr;
      }

      // Add message bubble with proper key
      items.add(
        MessageBubble(
          key: ValueKey('message_${message.id}_${message.timestamp.millisecondsSinceEpoch}'),
          message: message,
          currentUserId: currentUserId,
        ),
      );
    }

    return items;
  }

  Widget _buildDateSeparator(String dateStr) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: kMobilePaddingSmall),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kMobilePaddingSmall),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: kMobilePaddingSmall,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateItemCount() {
    if (messages.isEmpty) return 0;
    
    int itemCount = messages.length;
    String? lastDateStr;

    for (final message in messages) {
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );
      final dateStr = _formatDate(messageDate);

      if (lastDateStr != dateStr) {
        itemCount++; // Add count for date separator
        lastDateStr = dateStr;
      }
    }

    return itemCount;
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}