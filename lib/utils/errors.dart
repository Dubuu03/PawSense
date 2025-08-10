/// Centralized error handling for authentication and user flows.
/// Use these helpers to map Firebase and app errors to user-friendly messages and field errors.

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
    if (error.contains('user-not-found')) {
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
