import 'package:flutter/material.dart';

// Font families
const String kFontFamily = 'Poppins';

// Font sizes
const double kFontSizeSmall = 12.0;
const double kFontSizeRegular = 16.0;
const double kFontSizeLarge = 20.0;
const double kFontSizeTitle = 24.0;
const double kFontSizeHeader = 32.0;

// Spacing
const double kSpacingXSmall = 4.0;
const double kSpacingSmall = 8.0;
const double kSpacingMedium = 16.0;
const double kSpacingLarge = 24.0;
const double kSpacingXLarge = 32.0;

// Border radius
const double kBorderRadius = 12.0;
const double kBorderRadiusSmall = 8.0;
const double kBorderRadiusLarge = 16.0;

// Icon sizes
const double kIconSizeSmall = 16.0;
const double kIconSizeMedium = 20.0;
const double kIconSizeLarge = 24.0;
const double kIconSizeHeader = 32.0;

// Button dimensions
const double kButtonHeight = 45.0;
const double kButtonRadius = 12.0;

// Shadow settings
const double kShadowBlurRadius = 10.0;
const double kShadowSpreadRadius = 0.0;
const Offset kShadowOffset = Offset(0, 2);
const double kShadowOpacity = 0.05;

// Text styles
/// This file contains app-wide constants such as colors, text styles, and other reusable values.
const TextStyle kTextStyleSmall = TextStyle(
  fontFamily: kFontFamily,
  fontSize: kFontSizeSmall,
);

const TextStyle kTextStyleRegular = TextStyle(
  fontFamily: kFontFamily,
  fontSize: kFontSizeRegular,
);

const TextStyle kTextStyleLarge = TextStyle(
  fontFamily: kFontFamily,
  fontSize: kFontSizeLarge,
  fontWeight: FontWeight.bold,
);

const TextStyle kTextStyleTitle = TextStyle(
  fontFamily: kFontFamily,
  fontSize: kFontSizeTitle,
  fontWeight: FontWeight.bold,
);

const TextStyle kTextStyleHeader = TextStyle(
  fontFamily: kFontFamily,
  fontSize: kFontSizeHeader,
  fontWeight: FontWeight.bold,
);

// Firebase Collection Names
class FirebaseCollections {
  static const String users = 'users';
  static const String appointments = 'appointments';
  static const String patients = 'patients';
  static const String clinics = 'clinics';
  static const String schedules = 'schedules';
  static const String notifications = 'notifications';
  static const String supportTickets = 'support_tickets';
  static const String faqs = 'faqs';
  static const String diseases = 'diseases';
  static const String vetProfiles = 'vet_profiles';
  static const String settings = 'settings';
}

// Default placeholder data (for development/fallback)
class DefaultData {
  static const String placeholderImage = 'assets/img/logo.png';
  static const String placeholderUserName = 'User';
  static const String placeholderClinicName = 'PawSense Clinic';
  static const String placeholderEmail = 'user@example.com';
  static const String placeholderPhone = '+1234567890';
}

// Light theme
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  fontFamily: kFontFamily,
  textTheme: const TextTheme(
    bodySmall: kTextStyleSmall,
    bodyMedium: kTextStyleRegular,
    bodyLarge: kTextStyleLarge,
    titleLarge: kTextStyleTitle,
  ),
);

// Dark theme
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  fontFamily: kFontFamily,
  textTheme: const TextTheme(
    bodySmall: kTextStyleSmall,
    bodyMedium: kTextStyleRegular,
    bodyLarge: kTextStyleLarge,
    titleLarge: kTextStyleTitle,
  ),
);
