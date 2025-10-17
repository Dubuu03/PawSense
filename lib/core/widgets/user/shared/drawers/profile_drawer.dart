import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/widgets/shared/profile_avatar.dart';
import 'package:pawsense/core/utils/user_utils.dart';
import 'package:pawsense/core/services/auth/auth_service_mobile.dart';
import 'package:pawsense/core/services/cloudinary/cloudinary_service.dart';
import 'package:pawsense/core/services/user/user_services.dart';

class ProfileDrawer extends StatefulWidget {
  final UserModel? user;
  final VoidCallback? onClose;
  final Function(UserModel)? onUserUpdated;

  const ProfileDrawer({
    super.key,
    this.user,
    this.onClose,
    this.onUserUpdated,
  });

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  late UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

  @override
  void didUpdateWidget(ProfileDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != oldWidget.user) {
      setState(() {
        currentUser = widget.user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Close button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Profile Avatar
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _pickProfileImage(context, currentUser),
                        child: ProfileAvatar(
                          user: currentUser,
                          size: 80,
                          showBorder: currentUser?.profileImageUrl?.isEmpty ?? true,
                          borderColor: AppColors.primary.withValues(alpha: 0.3),
                          borderWidth: 2,
                        ),
                      ),
                      // Edit button
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: GestureDetector(
                          onTap: () => _pickProfileImage(context, currentUser),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: AppColors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // User Name
                  Text(
                    UserUtils.getDisplayName(currentUser),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  
                  // User Email
                  Text(
                    currentUser?.email ?? 'No email',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                ],
              ),
            ),
            
            // Profile Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildProfileOption(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () async {
                      Navigator.pop(context);
                      // Navigate to edit profile
                      if (currentUser != null) {
                        final updatedUser = await context.push('/edit-profile', extra: {
                          'user': currentUser!,
                        });
                        
                        // If user data was updated, call the callback
                        if (updatedUser != null && updatedUser is UserModel && widget.onUserUpdated != null) {
                          widget.onUserUpdated!(updatedUser);
                        }
                      }
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.pets_outlined,
                    title: 'My Pets',
                    subtitle: 'Manage your pet profiles',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/pets');
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.security_outlined,
                    title: 'Privacy & Security',
                    subtitle: 'Account security settings',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to change password page
                      context.push('/change-password');
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.info_outline,
                    title: 'About PawSense',
                    subtitle: 'App information and version',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/about-pawsense');
                    },
                  ),
                ],
              ),
            ),
            
            // Footer Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        // Handle sign out
                        try {
                          final authService = AuthService();
                          await authService.signOut();
                          if (context.mounted) {
                            context.go('/signin');
                          }
                        } catch (e) {
                          // Handle sign out error - still navigate to signin
                          if (context.mounted) {
                            context.go('/signin');
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.logout_outlined,
                        size: 18,
                        color: AppColors.white,
                      ),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: kFontSizeRegular,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  double _getProfileCompletionPercentage(UserModel? user) {
    if (user == null) return 0.0;
    
    int completedFields = 0;
    const int totalFields = 4;
    
    if (user.firstName?.isNotEmpty == true) completedFields++;
    if (user.lastName?.isNotEmpty == true) completedFields++;
    if (user.email.isNotEmpty) completedFields++;
    if (user.profileImageUrl?.isNotEmpty == true) completedFields++;
    
    return completedFields / totalFields;
  }

  Future<void> _pickProfileImage(BuildContext context, UserModel? user) async {
    if (user == null) return;

    final cloudinaryService = CloudinaryService();
    final userServices = UserServices();
    bool isUploading = false;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Store mounted state before async operations
        if (!context.mounted) return;
        
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        );
        isUploading = true;

        // Upload to Cloudinary
        final cloudinaryUrl = await cloudinaryService.uploadImageFromFile(
          pickedFile.path,
          folder: 'profile_images',
        );

        // Update user with new profile image URL
        final updatedUser = user.copyWith(
          profileImageUrl: cloudinaryUrl,
          updatedAt: DateTime.now(),
        );

        // Update in Firestore
        await userServices.updateUser(updatedUser);

        // Close loading dialog
        if (isUploading && context.mounted) {
          Navigator.pop(context);
          isUploading = false;
        }

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }

        // Call onUserUpdated callback to refresh UI
        if (widget.onUserUpdated != null) {
          widget.onUserUpdated!(updatedUser);
        }

        // Update local state to refresh the drawer immediately
        setState(() {
          currentUser = updatedUser;
        });
      }
    } catch (e) {
      // Close loading dialog if showing
      if (isUploading && context.mounted) {
        Navigator.pop(context);
      }
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}