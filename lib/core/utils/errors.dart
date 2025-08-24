/// Centralized error handling for authentication and user flows.
/// Use these helpers to map Firebase and app errors to user-friendly messages and field errors.
library;

class AuthErrorMapper {
  /// Returns a tuple: (field, message, generalMessage)
  /// field: the field to show error on (or null for general)
  /// message: the error message for the field
  /// generalMessage: the error message for the banner (or null)
  static ({String? field, String? message, String? generalMessage}) mapSignUpError(String error) {
    if (error.contains('email-already-in-use')) {
      return (field: 'email', message: 'This email is already registered.', generalMessage: 'This email is already registered but not yet verified. Please check your inbox or spam folder for the verification email, or try signing in and requesting a new verification email.');
    } else if (error.contains('invalid-email')) {
      return (field: 'email', message: 'The email address is invalid.', generalMessage: null);
    } else if (error.contains('weak-password')) {
      return (field: 'password', message: 'The password is too weak. Please use a stronger password.', generalMessage: null);
    } else if (error.contains('operation-not-allowed')) {
      return (field: null, message: null, generalMessage: 'Email/password accounts are not enabled.');
    } else if (error.contains('network-request-failed')) {
      return (field: null, message: null, generalMessage: 'Network error. Please check your connection.');
    }
    return (field: null, message: null, generalMessage: 'Sign up failed. Please try again.');
  }

  static ({String? field, String? message, String? generalMessage}) mapSignInError(String error) {
    // Custom approval-related errors
    if (error.contains('account-pending-approval')) {
      return (field: null, message: null, generalMessage: 'Your registration has been submitted. Please wait for admin approval before logging in.');
    } else if (error.contains('account-suspended')) {
      return (field: null, message: null, generalMessage: 'Your clinic has been suspended. Please contact support for assistance.');
    } else if (error.contains('account-rejected')) {
      return (field: null, message: null, generalMessage: 'Your clinic registration has been rejected. Please contact support for more information.');
    } else if (error.contains('account-not-verified')) {
      return (field: null, message: null, generalMessage: 'Your account is not yet verified. Please wait for admin approval.');
    }
    // Firebase authentication errors
    else if (error.contains('user-not-found')) {
      return (field: 'email', message: 'Account not found.', generalMessage: null);
    } else if (error.contains('wrong-password')) {
      return (field: 'password', message: 'Incorrect password. Please try again.', generalMessage: null);
    } else if (error.contains('invalid-email')) {
      return (field: 'email', message: 'Please enter a valid email address.', generalMessage: null);
    } else if (error.contains('user-disabled')) {
      return (field: null, message: null, generalMessage: 'This account has been temporarily disabled.');
    } else if (error.contains('invalid-credential')) {
      return (field: null, message: null, generalMessage: 'Invalid email or password.');
    } else if (error.contains('too-many-requests')) {
      return (field: null, message: null, generalMessage: 'Too many failed attempts. Please try again later.');
    } else if (error.contains('network-request-failed')) {
      return (field: null, message: null, generalMessage: 'Network error. Please check your connection.');
    }
    return (field: null, message: null, generalMessage: 'Sign in failed. Please try again.');
  }

}
