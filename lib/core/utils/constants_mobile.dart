import 'package:flutter/material.dart';

// Mobile-specific constants used in home widgets and mobile UI components

// ====================
// SPACING CONSTANTS
// ====================

// Container margins
const double kMobileMarginHorizontal = 20.0;
const double kMobileMarginAll = 20.0;
const double kMobileMarginSymmetric = 20.0;

// Container padding
const double kMobilePaddingAll = 16.0;
const double kMobilePaddingLarge = 24.0;
const double kMobilePaddingSmall = 14.0;
const double kMobilePaddingMedium = 16.0;

// Widget spacing
const double kMobileSizedBoxSmall = 4.0;
const double kMobileSizedBoxMedium = 8.0;
const double kMobileSizedBoxLarge = 12.0;
const double kMobileSizedBoxXLarge = 16.0;
const double kMobileSizedBoxXXLarge = 20.0;
const double kMobileSizedBoxHuge = 24.0;

// Grid spacing (for services grid)
const double kMobileGridCrossAxisSpacing = 12.0;
const double kMobileGridMainAxisSpacing = 12.0;
const double kMobileGridChildAspectRatio = 1.2;

// ====================
// BORDER RADIUS CONSTANTS
// ====================

const double kMobileBorderRadiusCard = 16.0;
const double kMobileBorderRadiusSmall = 12.0;
const double kMobileBorderRadiusIcon = 10.0;
const double kMobileBorderRadiusButton = 8.0;
const double kMobileBorderRadiusLegend = 8.0;

// ====================
// SIZE CONSTANTS
// ====================

// Chart sizes
const double kMobileDonutChartSize = 90.0;

// Icon container sizes
const double kMobileIconContainerSize = 40.0;
const double kMobileIconContainerMedium = 32.0;
const double kMobileIconContainerSmall = 24.0;

// Legend item sizes
const double kMobileLegendDotSize = 8.0;
const double kMobileLegendSpacing = 8.0;
const double kMobileLegendBottomPadding = 6.0;

// Pet icon sizes
const double kMobilePetIconSize = 28.0;
const double kMobilePetIconContainerSize = 48.0;

// ====================
// FONT SIZES (MOBILE-SPECIFIC)
// ====================

const double kMobileFontSizeTitle = 16.0;
const double kMobileFontSizeSubtitle = 13.0;
const double kMobileFontSizeChartTotal = 18.0;
const double kMobileFontSizeChartLabel = 10.0;
const double kMobileFontSizeViewAll = 12.0;
const double kMobileFontSizeLegend = 11.0;
const double kMobileFontSizePetName = 12.0;
const double kMobileFontSizePetType = 10.0;
const double kMobileFontSizeServiceTitle = 14.0;
const double kMobileFontSizeServiceSubtitle = 11.0;

// ====================
// FONT WEIGHTS
// ====================

const FontWeight kMobileFontWeightTitle = FontWeight.w600;
const FontWeight kMobileFontWeightSubtitle = FontWeight.w400;
const FontWeight kMobileFontWeightChartTotal = FontWeight.w700;
const FontWeight kMobileFontWeightViewAll = FontWeight.w600;
const FontWeight kMobileFontWeightServiceTitle = FontWeight.w600;

// ====================
// SHADOW CONSTANTS
// ====================

const double kMobileShadowBlurRadius = 10.0;
const double kMobileShadowBlurRadiusSmall = 8.0;
const Offset kMobileShadowOffset = Offset(0, 2);
const double kMobileShadowSpreadRadius = 0.0;
const double kMobileShadowOpacity = 0.06;

// ====================
// LINE HEIGHT CONSTANTS
// ====================

const double kMobileLineHeightTitle = 1.3;
const double kMobileLineHeightSubtitle = 1.2;
const double kMobileLineHeightChartLabel = 1.0;

// ====================
// EDGE INSETS PRESETS
// ====================

// Container margins
const EdgeInsets kMobileMarginCard = EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal);
const EdgeInsets kMobileMarginCardAll = EdgeInsets.all(kMobileMarginAll);
const EdgeInsets kMobileMarginContainer = EdgeInsets.all(kMobileMarginAll);

// Container padding
const EdgeInsets kMobilePaddingCard = EdgeInsets.all(kMobilePaddingAll);
const EdgeInsets kMobilePaddingService = EdgeInsets.all(kMobilePaddingSmall);
const EdgeInsets kMobilePaddingIcon = EdgeInsets.all(kMobilePaddingSmall);

// Button padding
const EdgeInsets kMobileButtonPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 4);

// Legend padding
const EdgeInsets kMobileLegendPadding = EdgeInsets.only(bottom: kMobileLegendBottomPadding);

// ====================
// GRID DELEGATE PRESET
// ====================

const SliverGridDelegateWithFixedCrossAxisCount kMobileServicesGridDelegate = 
    SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: kMobileGridCrossAxisSpacing,
      mainAxisSpacing: kMobileGridMainAxisSpacing,
      childAspectRatio: kMobileGridChildAspectRatio,
    );

// ====================
// BOX SHADOW PRESETS
// ====================

const List<BoxShadow> kMobileCardShadow = [
  BoxShadow(
    color: Color(0x0F000000), // Colors.black.withValues(alpha: 0.06)
    blurRadius: kMobileShadowBlurRadius,
    offset: kMobileShadowOffset,
    spreadRadius: kMobileShadowSpreadRadius,
  ),
];

const List<BoxShadow> kMobileCardShadowSmall = [
  BoxShadow(
    color: Color(0x0F000000), // Colors.black.withValues(alpha: 0.06)
    blurRadius: kMobileShadowBlurRadiusSmall,
    offset: kMobileShadowOffset,
    spreadRadius: kMobileShadowSpreadRadius,
  ),
];

// ====================
// TEXT STYLE PRESETS (MOBILE)
// ====================

const TextStyle kMobileTextStyleTitle = TextStyle(
  fontSize: kMobileFontSizeTitle,
  fontWeight: kMobileFontWeightTitle,
  height: kMobileLineHeightTitle,
);

const TextStyle kMobileTextStyleSubtitle = TextStyle(
  fontSize: kMobileFontSizeSubtitle,
  fontWeight: kMobileFontWeightSubtitle,
  height: kMobileLineHeightSubtitle,
);

const TextStyle kMobileTextStyleChartTotal = TextStyle(
  fontSize: kMobileFontSizeChartTotal,
  fontWeight: kMobileFontWeightChartTotal,
  height: kMobileLineHeightChartLabel,
);

const TextStyle kMobileTextStyleChartLabel = TextStyle(
  fontSize: kMobileFontSizeChartLabel,
  fontWeight: kMobileFontWeightSubtitle,
  height: kMobileLineHeightChartLabel,
);

const TextStyle kMobileTextStyleViewAll = TextStyle(
  fontSize: kMobileFontSizeViewAll,
  fontWeight: kMobileFontWeightViewAll,
  height: kMobileLineHeightSubtitle,
);

const TextStyle kMobileTextStyleLegend = TextStyle(
  fontSize: kMobileFontSizeLegend,
  fontWeight: kMobileFontWeightSubtitle,
  height: kMobileLineHeightSubtitle,
);

const TextStyle kMobileTextStylePetName = TextStyle(
  fontSize: kMobileFontSizePetName,
  fontWeight: kMobileFontWeightTitle,
  height: kMobileLineHeightSubtitle,
);

const TextStyle kMobileTextStylePetType = TextStyle(
  fontSize: kMobileFontSizePetType,
  fontWeight: kMobileFontWeightSubtitle,
  height: kMobileLineHeightSubtitle,
);

const TextStyle kMobileTextStyleServiceTitle = TextStyle(
  fontSize: kMobileFontSizeServiceTitle,
  fontWeight: kMobileFontWeightServiceTitle,
  height: kMobileLineHeightTitle,
);

const TextStyle kMobileTextStyleServiceSubtitle = TextStyle(
  fontSize: kMobileFontSizeServiceSubtitle,
  fontWeight: kMobileFontWeightSubtitle,
  height: kMobileLineHeightSubtitle,
);

// ====================
// BORDER RADIUS PRESETS
// ====================

const BorderRadius kMobileBorderRadiusCardPreset = BorderRadius.all(
  Radius.circular(kMobileBorderRadiusCard),
);

const BorderRadius kMobileBorderRadiusSmallPreset = BorderRadius.all(
  Radius.circular(kMobileBorderRadiusSmall),
);

const BorderRadius kMobileBorderRadiusIconPreset = BorderRadius.all(
  Radius.circular(kMobileBorderRadiusIcon),
);

const BorderRadius kMobileBorderRadiusButtonPreset = BorderRadius.all(
  Radius.circular(kMobileBorderRadiusButton),
);
