import 'package:flutter/material.dart';
import 'package:pawsense/core/models/user_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'user_card.dart';

class UsersList extends StatelessWidget {
  final List<Map<String, dynamic>> users; // Changed to support user with status
  final bool isLoading;
  final int totalUsers; // Add total users count
  final Function(UserModel) onEditUser;
  final Function(UserModel) onDeleteUser;
  final Function(UserModel, bool) onStatusToggle;

  const UsersList({
    Key? key,
    required this.users,
    required this.isLoading,
    required this.totalUsers,
    required this.onEditUser,
    required this.onDeleteUser,
    required this.onStatusToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: EdgeInsets.all(kSpacingXLarge),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kBorderRadius),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(kShadowOpacity),
              spreadRadius: kShadowSpreadRadius,
              blurRadius: kShadowBlurRadius,
              offset: kShadowOffset,
            ),
          ],
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (users.isEmpty) {
      return Container(
        padding: EdgeInsets.all(kSpacingXLarge),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kBorderRadius),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(kShadowOpacity),
              spreadRadius: kShadowSpreadRadius,
              blurRadius: kShadowBlurRadius,
              offset: kShadowOffset,
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: AppColors.textTertiary,
              ),
              SizedBox(height: kSpacingMedium),
              Text(
                'No users found',
                style: kTextStyleLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: kSpacingSmall),
              Text(
                'Try adjusting your search criteria',
                style: kTextStyleRegular.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(kShadowOpacity),
            spreadRadius: kShadowSpreadRadius,
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Users ($totalUsers)',
            style: kTextStyleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: kSpacingMedium),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userWithStatus = users[index];
              final user = userWithStatus['user'] as UserModel;
              
              return UserCard(
                user: user,
                onEdit: () => onEditUser(user),
                onDelete: () => onDeleteUser(user),
                onStatusToggle: (newStatus) => onStatusToggle(user, newStatus),
              );
            },
          ),
        ],
      ),
    );
  }
}
