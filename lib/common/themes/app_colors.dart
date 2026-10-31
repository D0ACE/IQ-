import 'package:flutter/material.dart';

/// Central colour system for IQ +.
///
/// The palette below is the single source of truth for colour in the app.
/// Screens and widgets must reference these tokens instead of hard-coding
/// hex literals.
///
/// Structure:
///  1. [Brand] tokens      – the IQ + identity colours.
///  2. [Semantic] tokens   – status / feedback colours used by workflows.
///  3. [Neutral] tokens    – backgrounds, surfaces, text and borders.
///  4. [Data] tokens       – chart / data-visualisation ramp.
///  5. Legacy aliases      – historic names kept so the ~60 existing screens
///                           that import this file keep compiling. Each one is
///                           mapped onto a semantic token above.
class AppColors {
  // Login palette – matches the navy, green, yellow and warm-neutral tones
  // used by the login experience.
  static const Color loginBackground = Color(0xFF032B45);
  static const Color loginPrimary = Color(0xFF086B0A);
  static const Color loginPrimaryDark = Color(0xFF064D08);
  static const Color loginAccent = Color(0xFFD6C42A);
  static const Color loginSurface = Color(0xFFFFFFFF);
  static const Color loginInputSurface = Color(0xFFF0ECEC);
  static const Color loginTextPrimary = Color(0xFF2C292C);
  static const Color loginTextSecondary = Color(0xFF686368);
  static const Color loginTextMuted = Color(0xFF8A858A);
  static const Color loginBorder = Color(0xFFD8D3D3);
  static const Color loginError = Color(0xFFC9362C);

  /// Button surface – dark green used by every button in the app.
  static const Color buttonDarkGreen = Color(0xFF006400);

  /// Button label colour – yellow text rendered on [buttonDarkGreen].
  static const Color buttonYellow = Color(0xFFFFD700);

  // ───────────────────────────────────────────────────────────────────────────
  // 1. BRAND
  // ───────────────────────────────────────────────────────────────────────────

  /// Primary brand colour – IQ + navy. Used for primary actions, active
  /// navigation and brand surfaces.
  static const Color brandPrimary = Color(0xFF053459);

  /// Pressed / high-emphasis variant of [brandPrimary].
  static const Color brandPrimaryDark = Color(0xFF032338);

  /// Lighter navy used for gradients and hover states.
  static const Color brandPrimaryLight = Color(0xFF1B4E7D);

  /// Subtle navy tint used as a fill behind primary content.
  static const Color brandPrimarySurface = Color(0xFFE8EFF5);

  /// Steel blue – secondary brand colour, used for supporting actions,
  /// links and informational accents.
  static const Color brandSecondary = Color(0xFF5899CC);

  /// Pressed / high-emphasis variant of [brandSecondary].
  static const Color brandSecondaryDark = Color(0xFF3F7EAF);

  /// Subtle steel-blue tint.
  static const Color brandSecondarySurface = Color(0xFFE7F1F9);

  /// Teal accent – used sparingly for emphasis (badges, highlights).
  static const Color brandAccent = Color(0xFF39A28F);

  /// Subtle teal tint.
  static const Color brandAccentSurface = Color(0xFFE4F2EF);

  // ───────────────────────────────────────────────────────────────────────────
  // 2. SEMANTIC
  // ───────────────────────────────────────────────────────────────────────────

  /// Positive outcome – completed tasks, approved items. Brand green.
  static const Color semanticSuccess = Color(0xFF76A751);

  /// Accessible green for success *text* on light surfaces.
  static const Color semanticSuccessDark = Color(0xFF47711F);

  /// Subtle green tint for success chips / banners.
  static const Color semanticSuccessSurface = Color(0xFFEDF5E5);

  /// Caution – pending, due soon, awaiting action.
  static const Color semanticWarning = Color(0xFFE08A00);

  /// Accessible amber for warning *text* on light surfaces.
  static const Color semanticWarningDark = Color(0xFF8A5400);

  /// Subtle amber tint for warning chips / banners.
  static const Color semanticWarningSurface = Color(0xFFFFF4E0);

  /// Failure – errors, overdue items, destructive actions.
  static const Color semanticError = Color(0xFFC62828);

  /// Accessible red for error *text* on light surfaces.
  static const Color semanticErrorDark = Color(0xFF9F1C1C);

  /// Subtle red tint for error chips / banners.
  static const Color semanticErrorSurface = Color(0xFFFDECEC);

  /// Informational / neutral status (in progress, shared, synced).
  static const Color semanticInfo = brandSecondary;

  /// Subtle informational tint.
  static const Color semanticInfoSurface = brandSecondarySurface;

  /// Focus ring / hover outline colour for interactive controls.
  static const Color semanticFocus = brandSecondary;

  /// Translucent overlay applied on hover of interactive surfaces.
  static const Color semanticHoverOverlay = Color(0x14053459);

  // ───────────────────────────────────────────────────────────────────────────
  // 3. NEUTRALS
  // ───────────────────────────────────────────────────────────────────────────

  /// App background (page canvas).
  static const Color neutralBackground = Color(0xFFF2F2F2);

  /// Elevated surfaces – cards, sheets, bars.
  static const Color neutralSurface = Color(0xFFFFFFFF);

  /// Secondary surface used for grouped/inset content and table stripes.
  static const Color neutralSurfaceMuted = Color(0xFFF7F9FB);

  /// Sunken surface used behind inputs and secondary panels.
  static const Color neutralSurfaceSunken = Color(0xFFEEF2F6);

  /// Primary body / heading text.
  static const Color neutralTextPrimary = Color(0xFF0E2A3D);

  /// Supporting text, captions, labels and icons.
  static const Color neutralTextSecondary = Color(0xFF54697B);

  /// Disabled text and inactive icons.
  static const Color neutralTextDisabled = Color(0xFF9BAAB6);

  /// Hairline borders (inputs, cards, dividers that need to be visible).
  static const Color neutralBorder = Color(0xFFD5DDE4);

  /// Dividers and separators (lighter than [neutralBorder]).
  static const Color neutralDivider = Color(0xFFE8EDF1);

  /// Text / icons rendered on top of [brandPrimary].
  static const Color neutralOnPrimary = Color(0xFFFFFFFF);

  // ───────────────────────────────────────────────────────────────────────────
  // 4. DATA / CHARTS
  // ───────────────────────────────────────────────────────────────────────────

  static const Color dataSeries1 = brandPrimary;
  static const Color dataSeries2 = brandSecondary;
  static const Color dataSeries3 = brandAccent;
  static const Color dataSeries4 = semanticSuccess;
  static const Color dataSeries5 = semanticWarning;

  // ───────────────────────────────────────────────────────────────────────────
  // 5. LEGACY ALIASES
  //    Kept for backwards compatibility. New code should use the semantic
  //    tokens above. Values are re-pointed onto the new palette so existing
  //    screens adopt the design system automatically.
  // ───────────────────────────────────────────────────────────────────────────

  /// @Deprecated alias of [brandPrimary].
  static const Color primaryPink = brandPrimary;

  /// @Deprecated alias of [brandPrimaryDark].
  static const Color darkPink = brandPrimaryDark;

  /// @Deprecated alias of [brandSecondary].
  static const Color mediumPink = brandSecondary;

  /// @Deprecated alias of [brandPrimarySurface].
  static const Color lightPink = brandPrimarySurface;

  /// @Deprecated alias of [neutralBackground].
  static const Color background = neutralBackground;

  /// @Deprecated alias of [neutralSurface].
  static const Color surface = neutralSurface;

  /// @Deprecated alias of [neutralTextPrimary].
  static const Color primaryText = neutralTextPrimary;

  /// @Deprecated alias of [neutralTextSecondary].
  static const Color secondaryText = neutralTextSecondary;

  /// @Deprecated alias of [neutralBorder].
  static const Color border = neutralBorder;

  /// @Deprecated alias of [neutralTextDisabled].
  static const Color disabled = neutralTextDisabled;

  /// @Deprecated alias of [semanticError].
  static const Color error = semanticError;

  /// @Deprecated alias of [semanticSuccess].
  static const Color success = semanticSuccess;

  /// @Deprecated alias of [brandPrimary].
  static const Color primary = brandPrimary;

  /// @Deprecated alias of [brandSecondary].
  static const Color secondary = brandSecondary;

  /// @Deprecated alias of [semanticSuccessSurface].
  static const Color lightGreen = Color(0xFFDCEBC9);

  /// @Deprecated – use [semanticErrorSurface].
  static const Color lightRed = Color(0xFFF19A9A);

  /// @Deprecated alias of [brandPrimarySurface].
  static const Color primary10 = Color(0x1F053459);

  /// @Deprecated alias of [brandPrimarySurface].
  static const Color primary20 = brandPrimarySurface;

  /// @Deprecated – template leftover.
  static const Color riderImageBackground = Color(0xFFE4E4E4);

  /// @Deprecated – template leftover.
  static const Color redOverlaySliderColor = Color(0x1AFF4200);

  /// @Deprecated alias of [neutralBackground].
  static const Color backgroundColor = neutralBackground;

  /// @Deprecated alias of [neutralSurface].
  static const Color scaffoldColor = neutralSurface;

  /// @Deprecated alias of [neutralTextSecondary].
  static const Color iconColor = neutralTextSecondary;

  /// @Deprecated alias of [neutralTextSecondary].
  static const textFieldGreyColor = neutralTextSecondary;

  /// @Deprecated – template leftover.
  static const sendAgainBtnGrayColor = Color(0xffE6E6E6);

  /// @Deprecated – template leftover.
  static const sendAgainBtnGrColor = Color(0xffDFDFDF);

  /// @Deprecated – template leftover.
  static const trackOrderGreenBtnGrColor = Color(0xffD0FF76);

  /// @Deprecated – template leftover.
  static const tryAgainRedBtnGrColor = Color(0xffFF6666);

  /// @Deprecated – template leftover.
  static const changeMethodPinkBtnGrColor = Color(0xffFFC1C1);

  /// @Deprecated – template leftover.
  static const orderAgainBtnGrColor = Color(0xffFFD79D);

  /// @Deprecated – template leftover.
  static const orderIDTextColor = Color(0xff8E8E8E);

  /// @Deprecated alias of [neutralTextPrimary].
  static const blackColor = neutralTextPrimary;

  /// @Deprecated alias of [neutralTextPrimary].
  static const blackTextColor = neutralTextPrimary;

  /// @Deprecated alias of [semanticError].
  static const Color redDeleteSliderColor = Color(0xffF94E34);

  /// @Deprecated alias of [neutralTextSecondary].
  static const Color greyLoginTextColor = Color(0xff7B7D86);

  /// @Deprecated alias of [neutralSurface].
  static const Color whiteColor = Colors.white;

  /// @Deprecated – status bar is driven by the platform theme.
  static const Color statusBarColor = Colors.white;

  /// @Deprecated alias of [brandPrimarySurface].
  static Color? greyTextFormFiledColor = brandPrimarySurface;

  /// @Deprecated alias of [neutralTextDisabled].
  static const deActiveIndicatorColor = grey40TextColor;

  /// @Deprecated alias of [semanticError].
  static const Color redTextStatusColor = semanticError;

  /// @Deprecated alias of [neutralOnPrimary].
  static const Color whiteTextColor = Colors.white;

  /// @Deprecated – template leftover.
  static const Color shadowForDeliveryAddsColor = Color(0xFFE2E2E2);

  /// @Deprecated alias of [brandPrimary].
  static const Color primaryTextColor = brandPrimary;

  /// @Deprecated alias of [neutralTextSecondary].
  static const Color greyTextColor = neutralTextSecondary;

  /// @Deprecated – template leftover (shadow tint).
  static const Color circularShadowGrayColor = Color(0xFFD9D9D9);

  // Neutral ramp – retained for icon / metadata greys.
  static const Color grey90TextColor = Color(0xFF1d1e21);
  static const Color grey80TextColor = Color(0xFF41444a);

  /// @Deprecated alias of [neutralTextSecondary].
  static const Color grey70TextColor = neutralTextSecondary;

  /// @Deprecated alias of [neutralTextDisabled].
  static const Color grey40TextColor = neutralTextDisabled;

  static const Color grey30TextColor = Color(0xFFe1e3e8);
  static const Color grey20TextColor = Color(0xFFe8e8e8);

  /// @Deprecated alias of [neutralBorder].
  static const Color greyBorderColor = neutralBorder;

  /// @Deprecated alias of [brandPrimary].
  static const Color btnPrimaryColor = brandPrimary;
  static const Color transparent = Colors.transparent;

  /// @Deprecated alias of the brand gradient (steel blue → navy).
  static const Color btnGradientStartColor = brandSecondary;

  /// @Deprecated alias of the brand gradient (steel blue → navy).
  static const Color btnGradientEndColor = brandPrimary;

  static const Color btnRippleEffectColor = Colors.white30;

  /// @Deprecated alias of [brandPrimary].
  static const Color selectedTabColor = brandPrimary;

  /// @Deprecated alias of [neutralTextDisabled].
  static const Color textGrayColor = neutralTextDisabled;

  /// @Deprecated alias of [neutralTextPrimary].
  static const Color arrowBlackColor = neutralTextPrimary;

  /// @Deprecated alias of [neutralTextSecondary].
  static const Color priceContainerColor = neutralTextSecondary;

  /// @Deprecated alias of [neutralBorder].
  static const Color borderColor = neutralBorder;

  static const Color facebookBtnColor = Color(0xFF4267B2);

  /// @Deprecated alias of [neutralBorder].
  static const Color textFieldBorderColor = neutralBorder;

  /// @Deprecated alias of [neutralTextSecondary].
  static const Color boxSizeTextColor = neutralTextSecondary;

  /// @Deprecated alias of [semanticError].
  static const Color orderRejectTextColor = semanticError;

  /// @Deprecated – template leftover.
  static const Color riderLocationColor = Color(0x34FF4200);

  /// @Deprecated – template leftover.
  static const Color ridrLocationColor = Color(0xFFE7E7E7);

  static const cShimmerBaseColor = Color(0x140E2A3D);
  static const cShimmerHighlightColor = Color(0x240E2A3D);
  static const shimmerGreyLight = Color(0xffE6E6E6);

  /// @Deprecated – use [neutralSurfaceMuted].
  static const shimmerWhiteLight = Color(0xffEEF2F8);

  /// @Deprecated – template leftover.
  static const favoriteTileBackgroundColor = Color(0xffFFF4EA);

  /// @Deprecated – template leftover.
  static const favoriteChipBackgroundColor = Color(0xffFFDBB9);

  /// Rating stars.
  static const starRatingColor = Color(0xffF3C521);

  // ── Workflow status colours (task / visit / order states) ──────────────────

  /// @Deprecated alias of [semanticInfo].
  static const delivered = semanticInfo;

  /// @Deprecated alias of [semanticWarning].
  static const delayed = semanticWarning;

  /// @Deprecated alias of [semanticSuccess].
  static const paid = semanticSuccess;

  /// @Deprecated alias of [semanticSuccess].
  static const readyForPickup = semanticSuccess;

  /// @Deprecated alias of [semanticError].
  static const cancelled = semanticError;

  /// @Deprecated alias of [semanticWarning].
  static const picked = semanticWarning;

  // ── Legacy categorisation colours (retained for data-viz parity) ───────────
  static const greenStoreType = Color(0xff315B2D);
  static const orangeStoreType = Color(0xffE05825);
  static const blueStoreType = Color(0xff26558B);
  static const lightGreenStoreType = Color(0xff73B000);
  static const brownStoreType = Color(0xffCF8D29);

  /// @Deprecated alias of [brandPrimary].
  static const kPrimaryColor = brandPrimary;

  /// @Deprecated alias of [brandPrimarySurface].
  static const kPrimaryLightColor = brandPrimarySurface;

  /// @Deprecated alias of [semanticError].
  static const merchantMenuMessageTextColor = semanticError;

  /// @Deprecated alias of [semanticWarning].
  static const Color orange = semanticWarning;

  /// @Deprecated alias of [semanticSuccess].
  static const Color green = semanticSuccess;

  /// @Deprecated alias of [brandPrimary].
  static const Color purple = brandPrimary;

  /// @Deprecated alias of [brandPrimarySurface].
  static const Color pink = brandPrimarySurface;

  /// @Deprecated alias of [brandSecondary].
  static const Color blue = Color(0xFF8EC5FF);

  /// Brand gradient: navy → steel blue → teal.
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandPrimary, brandSecondary, brandAccent],
  );

  /// Primary-action button background: solid dark green.
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [buttonDarkGreen, buttonDarkGreen],
  );

  /// @Deprecated alias of [neutralBackground].
  static const Color scaffoldBg = neutralBackground;

  /// @Deprecated alias of [neutralSurface].
  static const Color cardBg = neutralSurface;

  /// @Deprecated alias of [neutralTextPrimary].
  static const Color titleText = neutralTextPrimary;

  /// @Deprecated alias of [neutralTextSecondary].
  static const Color subText = neutralTextSecondary;

  /// @Deprecated alias of [brandPrimaryDark].
  static const Color drawerBg = brandPrimaryDark;

  /// @Deprecated alias of [dataSeries1].
  static const Color barColor = dataSeries1;

  // ── Shadows / elevation tints ─────────────────────────────────────────────

  /// Card shadow tint.
  static const Color shadowColor = Color(0x140E2A3D);

  /// Strong shadow tint for floating elements (dialogs, FABs).
  static const Color shadowColorStrong = Color(0x240E2A3D);

  /// Shadow tint derived from the brand colour (used by accent cards).
  static const Color shadowColorBrand = Color(0x1F053459);
}
