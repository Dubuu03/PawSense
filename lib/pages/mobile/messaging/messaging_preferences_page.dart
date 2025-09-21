import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/services/messaging/messaging_preferences_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'dart:async';

class MobileMessagingPreferencesPage extends StatefulWidget {
  const MobileMessagingPreferencesPage({super.key});

  @override
  State<MobileMessagingPreferencesPage> createState() => _MobileMessagingPreferencesPageState();
}

class _MobileMessagingPreferencesPageState extends State<MobileMessagingPreferencesPage> {
  final MessagingPreferencesService _preferencesService = MessagingPreferencesService.instance;
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _markAsReadOnOpen = true;
  bool _showUnreadIndicators = true;
  int _totalReadConversations = 0;
  int _totalConversationsTracked = 0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      // Initialize preferences if not already done
      if (!_preferencesService.isInitialized) {
        final user = await AuthGuard.getCurrentUser();
        if (user != null) {
          await _preferencesService.reinitializeForUser(user.uid);
        }
      }

      // Load current stats
      setState(() {
        _totalReadConversations = _preferencesService.readConversations.length;
        _totalConversationsTracked = _preferencesService.lastMessageTimestamps.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading messaging preferences: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllReadStatus() async {
    final confirmed = await _showConfirmationDialog(
      'Clear Read Status',
      'This will mark all conversations as unread. Are you sure?',
    );

    if (confirmed) {
      try {
        // Clear all read conversations
        final readConversations = List.from(_preferencesService.readConversations);
        for (final conversationId in readConversations) {
          await _preferencesService.markConversationAsUnread(conversationId);
        }

        await _loadPreferences();
        _showSuccessSnackBar('All conversations marked as unread');
      } catch (e) {
        _showErrorSnackBar('Failed to clear read status: $e');
      }
    }
  }

  Future<void> _clearAllPreferences() async {
    final confirmed = await _showConfirmationDialog(
      'Clear All Data',
      'This will clear all messaging preferences and history. This action cannot be undone. Are you sure?',
    );

    if (confirmed) {
      try {
        final user = await AuthGuard.getCurrentUser();
        await _preferencesService.clearAllData(userId: user?.uid);
        await _loadPreferences();
        _showSuccessSnackBar('All messaging preferences cleared');
      } catch (e) {
        _showErrorSnackBar('Failed to clear preferences: $e');
      }
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
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
        title: const Text('Messaging Settings'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(kMobilePaddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Section
                  _buildSectionHeader('Statistics'),
                  _buildStatisticsCard(),
                  const SizedBox(height: kMobileSizedBoxLarge),

                  // Preferences Section
                  _buildSectionHeader('Preferences'),
                  _buildPreferencesCard(),
                  const SizedBox(height: kMobileSizedBoxLarge),

                  // Actions Section
                  _buildSectionHeader('Actions'),
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kMobilePaddingSmall),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusSmallPreset,
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow('Read Conversations', _totalReadConversations.toString()),
          const SizedBox(height: kMobileSizedBoxSmall),
          _buildStatRow('Total Conversations Tracked', _totalConversationsTracked.toString()),
          const SizedBox(height: kMobileSizedBoxSmall),
          _buildStatRow('Service Status', _preferencesService.isInitialized ? 'Initialized' : 'Not Initialized'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusSmallPreset,
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Push Notifications',
            'Receive notifications for new messages',
            _notificationsEnabled,
            (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              // Here you could save to SharedPreferences or implement actual notification logic
            },
          ),
          const Divider(),
          _buildSwitchTile(
            'Mark as Read on Open',
            'Automatically mark conversations as read when opened',
            _markAsReadOnOpen,
            (value) {
              setState(() {
                _markAsReadOnOpen = value;
              });
              // Here you could save to SharedPreferences
            },
          ),
          const Divider(),
          _buildSwitchTile(
            'Show Unread Indicators',
            'Display visual indicators for unread messages',
            _showUnreadIndicators,
            (value) {
              setState(() {
                _showUnreadIndicators = value;
              });
              // Here you could save to SharedPreferences
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusSmallPreset,
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionButton(
            'Clear Read Status',
            'Mark all conversations as unread',
            Icons.mark_email_unread,
            AppColors.warning,
            _clearAllReadStatus,
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          _buildActionButton(
            'Clear All Data',
            'Remove all messaging preferences',
            Icons.delete_forever,
            AppColors.error,
            _clearAllPreferences,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppColors.textSecondary,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}