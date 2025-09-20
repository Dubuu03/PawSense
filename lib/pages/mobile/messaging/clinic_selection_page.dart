import 'package:flutter/material.dart';
import 'package:pawsense/core/services/messaging/messaging_service.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'conversation_page.dart';
import 'package:pawsense/core/models/messaging/conversation_model.dart';

class ClinicSelectionPage extends StatefulWidget {
  const ClinicSelectionPage({super.key});

  @override
  State<ClinicSelectionPage> createState() => _ClinicSelectionPageState();
}

class _ClinicSelectionPageState extends State<ClinicSelectionPage> {
  List<Map<String, dynamic>> _clinics = [];
  List<Map<String, dynamic>> _filteredClinics = [];
  List<String> _existingConversationClinicIds = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClinics();
    _searchController.addListener(_filterClinics);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClinics() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get all approved clinics first
      final allClinics = await MessagingService.getApprovedClinics();
      
      // Get existing conversations to filter out clinics
      final conversationsStream = MessagingService.getUserConversations();
      await for (final conversations in conversationsStream.take(1)) {
        _existingConversationClinicIds = conversations.map((conv) => conv.clinicId).toList();
        print('=== Clinic Selection: Found ${conversations.length} existing conversations ===');
        print('=== Existing clinic IDs: $_existingConversationClinicIds ===');
        break;
      }
      
      // Filter out clinics that already have conversations
      final availableClinics = allClinics.where((clinic) {
        final clinicId = clinic['clinicId'] ?? clinic['id']; // Use clinicId first, fallback to id
        final hasConversation = _existingConversationClinicIds.contains(clinicId);
        print('=== Clinic: ${clinic['name']} (ID: $clinicId) - Has conversation: $hasConversation ===');
        return !hasConversation;
      }).toList();

      print('=== Total clinics: ${allClinics.length}, Available: ${availableClinics.length} ===');

      setState(() {
        _clinics = availableClinics;
        _filteredClinics = availableClinics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading clinics: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterClinics() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClinics = _clinics.where((clinic) {
        return clinic['name'].toString().toLowerCase().contains(query) ||
            clinic['address'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  void _startConversation(Map<String, dynamic> clinic) async {
    try {
      // First check if there's already an existing conversation with this clinic
      final conversationsStream = MessagingService.getUserConversations();
      await for (final conversations in conversationsStream.take(1)) {
        // Look for existing conversation with this clinic
        Conversation? existingConversation;
        try {
          final clinicId = clinic['clinicId'] ?? clinic['id']; // Use clinicId first, fallback to id
          existingConversation = conversations.firstWhere(
            (conv) => conv.clinicId == clinicId,
          );
        } catch (e) {
          // No existing conversation found
          existingConversation = null;
        }

        if (existingConversation != null) {
          // Navigate to existing conversation and return to messaging page
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationPage(
                conversation: existingConversation!,
              ),
            ),
          );
          // Always return to messaging page if coming from existing conversation
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          // Create a temporary conversation for new conversation
          final clinicId = clinic['clinicId'] ?? clinic['id']; // Use clinicId first, fallback to id
          final tempConversation = Conversation(
            id: 'temp_${clinicId}_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
            userId: '', // Will be populated when actual conversation is created
            userName: '', // Will be populated when actual conversation is created
            clinicId: clinicId,
            clinicName: clinic['name'],
            lastMessageTime: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Navigate to conversation page with temporary conversation
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationPage(
                conversation: tempConversation,
              ),
            ),
          );

          // If user sent a message, return true to indicate conversation was created
          if (result == true && mounted) {
            Navigator.pop(context, true);
          }
        }
        break; // Exit the stream after first result
      }
    } catch (e) {
      print('Error in _startConversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting conversation: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text(
          'Available Clinics',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.white,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.white,
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(kMobilePaddingMedium),
            color: AppColors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search clinics...',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: kMobileBorderRadiusButtonPreset,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: kMobileBorderRadiusButtonPreset,
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: kMobileBorderRadiusButtonPreset,
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

          // Clinics list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _filteredClinics.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_hospital_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _clinics.isEmpty
                                  ? 'No new clinics available'
                                  : 'No clinics match your search',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_clinics.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'All available clinics already have active conversations',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(kMobilePaddingMedium),
                        itemCount: _filteredClinics.length,
                        itemBuilder: (context, index) {
                          final clinic = _filteredClinics[index];
                          return _buildClinicTile(clinic);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicTile(Map<String, dynamic> clinic) {
    return Container(
      margin: const EdgeInsets.only(bottom: kMobileSizedBoxMedium),
      child: Material(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusSmallPreset,
        elevation: 1,
        shadowColor: AppColors.textSecondary.withValues(alpha: 0.1),
        child: InkWell(
          onTap: () => _startConversation(clinic),
          borderRadius: kMobileBorderRadiusSmallPreset,
          child: Padding(
            padding: const EdgeInsets.all(kMobilePaddingSmall),
            child: Row(
              children: [
                // Clinic avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.local_hospital,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: kMobileSizedBoxLarge),
                
                // Clinic details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinic['name'].toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              clinic['address'].toString(),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (clinic['phone'] != null && clinic['phone'].toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              clinic['phone'].toString(),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (clinic['isVerified'] == true) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.verified,
                              size: 12,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Verified',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Arrow icon
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}