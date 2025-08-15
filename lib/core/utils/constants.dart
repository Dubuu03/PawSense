import 'package:flutter/material.dart';

// Font families
const String kFontFamily = 'Poppins';

// Font sizes
const double kFontSizeSmall = 12.0;
const double kFontSizeRegular = 16.0;
const double kFontSizeLarge = 20.0;
const double kFontSizeTitle = 24.0;

// Spacing
const double kSpacingSmall = 8.0;
const double kSpacingMedium = 16.0;
const double kSpacingLarge = 24.0;
const double kSpacingXLarge = 32.0;

// Border radius
const double kBorderRadius = 12.0;
const double kBorderRadiusSmall = 8.0;

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
