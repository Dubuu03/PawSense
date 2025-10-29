import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isEnabled;

  const MessageInput({
    super.key,
    required this.onSendMessage,
    this.isEnabled = true,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _messageController = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _messageController.text.trim().isNotEmpty;
    });
  }

  void _sendMessage() {
    if (_hasText && widget.isEnabled) {
      final message = _messageController.text.trim();
      widget.onSendMessage(message);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Message input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                enabled: widget.isEnabled,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: widget.isEnabled ? 'Type a message...' : 'Select a conversation to reply',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: kSpacingMedium,
                    vertical: kSpacingSmall,
                  ),
                ),
                style: kTextStyleRegular.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: kSpacingSmall),
          
          // Send button
          Container(
            decoration: BoxDecoration(
              color: _hasText && widget.isEnabled ? AppColors.primary : AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _hasText && widget.isEnabled ? _sendMessage : null,
              icon: Icon(
                Icons.send,
                color: AppColors.white,
                size: 18,
              ),
              tooltip: 'Send message',
            ),
          ),
        ],
      ),
    );
  }
}