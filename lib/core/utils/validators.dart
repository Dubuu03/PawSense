// validators.dart

String? emailValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Enter email';
  }
  
  // Check if email starts with @
  if (value.startsWith('@')) {
    return 'Email cannot start with @';
  }
  
  // Comprehensive email validation
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  if (!emailRegex.hasMatch(value)) {
    return 'Enter valid email';
  }
  
  // Additional checks
  if (value.contains('..')) {
    return 'Email contains consecutive dots';
  }
  
  if (value.startsWith('.') || value.endsWith('.')) {
    return 'Email cannot start or end with dot';
  }
  
  return null;
}

String? passwordValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Enter password';
  }
  
  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  
  if (value.length > 128) {
    return 'Password too long (max 128 characters)';
  }
  
  // Check for at least one uppercase letter
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'Password must contain uppercase letter';
  }
  
  // Check for at least one lowercase letter
  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return 'Password must contain lowercase letter';
  }
  
  // Check for at least one digit
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return 'Password must contain a number';
  }
  
  return null;
}

String? nameValidator(String? value, String fieldName) {
  if (value == null || value.isEmpty) {
    return 'Enter $fieldName';
  }
  
  // Remove extra spaces and check length
  final trimmedValue = value.trim();
  
  if (trimmedValue.length < 2) {
    return '$fieldName must be at least 2 characters';
  }
  
  if (trimmedValue.length > 30) {
    return '$fieldName too long (max 30 characters)';
  }
  
  // Check for valid characters (letters, spaces, hyphens, apostrophes)
  if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(trimmedValue)) {
    return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
  }
  
  // Check for consecutive spaces
  if (trimmedValue.contains(RegExp(r'\s{2,}'))) {
    return '$fieldName cannot have consecutive spaces';
  }
  
  return null;
}

String? addressValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Enter address';
  }
  
  final trimmedValue = value.trim();
  
  if (trimmedValue.length > 200) {
    return 'Address too long (max 200 characters)';
  }
  
  // Check for valid characters (letters, numbers, spaces, common punctuation)
  if (!RegExp(r"^[a-zA-Z0-9\s\-'.,#/]+$").hasMatch(trimmedValue)) {
    return 'Address contains invalid characters';
  }
  
  return null;
}

String? requiredValidator(String? value, [String field = 'This field']) {
  if (value == null || value.isEmpty) {
    return 'Enter $field';
  }
  
  if (value.trim().isEmpty) {
    return '$field cannot be empty or just spaces';
  }
  
  return null;
}

String? confirmPasswordValidator(String? value, String? original) {
  if (value == null || value.isEmpty) {
    return 'Confirm your password';
  }
  if (value != original) {
    return 'Passwords do not match';
  }
  return null;
}

String? phoneValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Enter contact number';
  }
  
  // Remove any non-digit characters for validation
  final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
  
  if (digitsOnly.length != 11) {
    return 'Phone number must be exactly 11 digits';
  }
  
  return null;
}
