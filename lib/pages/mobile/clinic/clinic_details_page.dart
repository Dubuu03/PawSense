import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/models/clinic/clinic_details_model.dart';
import 'package:pawsense/core/services/clinic/clinic_details_service.dart';
import 'package:pawsense/core/widgets/user/clinic_details/clinic_header.dart';
import 'package:pawsense/core/widgets/user/clinic_details/clinic_contact_info.dart';
import 'package:pawsense/core/widgets/user/clinic_details/clinic_services_list.dart';
import 'package:pawsense/core/widgets/user/clinic_details/clinic_credentials.dart';
import 'package:pawsense/core/widgets/user/clinic_details/clinic_action_buttons.dart';
import 'package:pawsense/pages/mobile/messaging/conversation_page.dart';
import 'package:pawsense/core/models/messaging/conversation_model.dart';
import 'package:pawsense/core/services/messaging/messaging_service.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

class ClinicDetailsPage extends StatefulWidget {
  final String clinicId;

  const ClinicDetailsPage({
    Key? key,
    required this.clinicId,
  }) : super(key: key);

  @override
  State<ClinicDetailsPage> createState() => _ClinicDetailsPageState();
}

class _ClinicDetailsPageState extends State<ClinicDetailsPage> {
  ClinicDetails? _clinicDetails;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClinicDetails();
  }

  Future<void> _loadClinicDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final clinicDetails = await ClinicDetailsService.getClinicDetails(widget.clinicId);
      
      setState(() {
        _clinicDetails = clinicDetails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _clinicDetails?.clinicName ?? 'Clinic Details',
          style: kMobileTextStyleTitle.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_clinicDetails == null) {
      return _buildNotFoundState();
    }

    return RefreshIndicator(
      onRefresh: _loadClinicDetails,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(kMobilePaddingMedium),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clinic Header
            ClinicHeader(clinic: _clinicDetails!),
            
            const SizedBox(height: kMobileSizedBoxMedium),
            
            // Contact Information
            ClinicContactInfo(clinic: _clinicDetails!),
            
            const SizedBox(height: kMobileSizedBoxMedium),
            
            // Services List
            ClinicServicesList(clinic: _clinicDetails!),
            
            const SizedBox(height: kMobileSizedBoxMedium),
            
            // Credentials & Licenses
            ClinicCredentials(clinic: _clinicDetails!),
            
            const SizedBox(height: kMobileSizedBoxMedium),
            
            // Action Buttons - moved to last
            ClinicActionButtons(
              clinic: _clinicDetails!,
              onBookAppointment: _bookAppointment,
              onMessageClinic: _messageClinic,
            ),
            
            const SizedBox(height: kMobileSizedBoxLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: kMobileSizedBoxLarge),
          Text(
            'Loading clinic details...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kMobileMarginAll),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: kMobileSizedBoxLarge),
            Text(
              'Failed to load clinic details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kMobileSizedBoxMedium),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kMobileSizedBoxLarge),
            ElevatedButton.icon(
              onPressed: _loadClinicDetails,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: kMobilePaddingLarge,
                  vertical: kMobilePaddingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kMobileMarginAll),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: kMobileSizedBoxLarge),
            Text(
              'Clinic Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: kMobileSizedBoxMedium),
            Text(
              'The clinic you\'re looking for doesn\'t exist or has been removed.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kMobileSizedBoxLarge),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: kMobilePaddingLarge,
                  vertical: kMobilePaddingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bookAppointment() {
    // Navigate to appointment booking page with pre-filled clinic data
    context.push(
      '/book-appointment',
      extra: {
        'clinicId': _clinicDetails!.clinicId,
        'clinicName': _clinicDetails!.clinicName,
      },
    );
  }

  void _messageClinic() async {
    try {
      // Get current user
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) {
        _showSnackBar('Please log in to send messages');
        return;
      }

      // Check if conversation already exists with this clinic
      final conversationsStream = MessagingService.getUserConversations();
      await for (final conversations in conversationsStream.take(1)) {
        // Look for existing conversation with this clinic
        Conversation? existingConversation;
        try {
          existingConversation = conversations.firstWhere(
            (conv) => conv.clinicId == _clinicDetails!.clinicId,
          );
        } catch (e) {
          // No existing conversation found
          existingConversation = null;
        }

        if (existingConversation != null) {
          // Navigate to existing conversation (like clicking from messages menu)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationPage(
                conversation: existingConversation!,
              ),
            ),
          );
        } else {
          // Create a temporary conversation for new conversation
          final tempConversation = Conversation(
            id: 'temp_${_clinicDetails!.clinicId}_${DateTime.now().millisecondsSinceEpoch}',
            userId: currentUser.uid,
            userName: '${currentUser.firstName ?? ''} ${currentUser.lastName ?? ''}'.trim(),
            clinicId: _clinicDetails!.clinicId,
            clinicName: _clinicDetails!.clinicName,
            lastMessageTime: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Navigate to conversation page with temporary conversation
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationPage(
                conversation: tempConversation,
              ),
            ),
          );
        }
        break; // Exit the stream after first result
      }
    } catch (e) {
      print('Error in _messageClinic: $e');
      _showSnackBar('Error loading conversation');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
        ),
      ),
    );
  }
}