import 'package:flutter/material.dart';

import '../../core/services/auth/auth_service_mobile.dart';
import '../../core/models/user_model.dart';
import '../../core/guards/auth_guard.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    // Use AuthGuard to get current user to leverage caching and deduplication
    final userModel = await AuthGuard.getCurrentUser();
    if (userModel != null) {
      setState(() {
        _userModel = userModel;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Home',
          style: kTextStyleTitle.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: AppColors.textSecondary,
              size: kIconSizeLarge,
            ),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: _loading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              )
            : Container(
                margin: EdgeInsets.all(kSpacingLarge),
                padding: EdgeInsets.all(kSpacingLarge),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(kBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(kShadowOpacity),
                      blurRadius: kShadowBlurRadius,
                      offset: kShadowOffset,
                    ),
                  ],
                ),
                child: _userModel != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: kSpacingMedium),
                          Text(
                            'Welcome to PawSense!',
                            style: kTextStyleTitle.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: kSpacingSmall),
                          Text(
                            _userModel!.username,
                            style: kTextStyleLarge.copyWith(
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: kSpacingSmall),
                          Text(
                            'Your pet care companion',
                            style: kTextStyleRegular.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Icon(
                              Icons.pets,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: kSpacingMedium),
                          Text(
                            'Welcome to PawSense!',
                            style: kTextStyleTitle.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: kSpacingSmall),
                          Text(
                            'Your pet care companion',
                            style: kTextStyleRegular.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),
      ),
    );
  }
}
