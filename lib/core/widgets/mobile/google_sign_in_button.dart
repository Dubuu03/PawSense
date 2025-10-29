import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// A custom Google Sign-In button widget with consistent styling
class GoogleSignInButton extends StatelessWidget {
  /// Callback function when the button is pressed
  final VoidCallback onPressed;
  
  /// Whether the button is in a loading state
  final bool isLoading;

  /// Creates a Google Sign-In button
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kButtonRadius),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.1),
          disabledBackgroundColor: Colors.grey.shade100,
        ),
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
                ),
              )
            : Image.asset(
                'assets/img/google_logo.png',
                height: 18,
                width: 18,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to Material icon if image is not found
                  return Icon(
                    Icons.login,
                    size: 18,
                    color: Colors.grey.shade600,
                  );
                },
              ),
        label: Text(
          'Continue with Google',
          style: kTextStyleRegular.copyWith(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}