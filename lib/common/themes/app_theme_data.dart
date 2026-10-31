import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_const.dart';
import 'app_strings.dart';

/// Central theme configuration for IQ +.
///
/// Everything visual that is shared between screens lives here:
/// colour scheme, typography scale and the component themes that Material
/// widgets pick up automatically (app bar, cards, buttons, inputs, dialogs,
/// sheets, snack bars, ...).
///
/// Screen level code should prefer these definitions (or the semantic text
/// styles exposed at the bottom of this class) over locally declared
/// [TextStyle]s and hard-coded colours.
class AppThemeData {
  // ───────────────────────────────────────────────────────────────────────────
  // TYPOGRAPHY SCALE
  // Font family: OpenSans (bundled, see pubspec.yaml).
  // ───────────────────────────────────────────────────────────────────────────

  /// Display – hero headlines (login, empty states, marketing surfaces).
  static const TextStyle displayLarge = TextStyle(
    fontFamily: AppFonts.fontOpenSansExtraBold,
    fontSize: 32,
    height: 1.15,
    letterSpacing: -0.6,
    color: AppColors.neutralTextPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: AppFonts.fontOpenSansExtraBold,
    fontSize: 28,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.neutralTextPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: AppFonts.fontOpenSansExtraBold,
    fontSize: 24,
    height: 1.25,
    letterSpacing: -0.4,
    color: AppColors.neutralTextPrimary,
  );

  /// Headline – screen and section titles.
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: AppFonts.fontOpenSansBold,
    fontSize: 24,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.neutralTextPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: AppFonts.fontOpenSansBold,
    fontSize: 20,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.neutralTextPrimary,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: AppFonts.fontOpenSansBold,
    fontSize: 18,
    height: 1.3,
    color: AppColors.neutralTextPrimary,
  );

  /// Title – card titles, dialog titles, list item titles.
  static const TextStyle titleLarge = TextStyle(
    fontFamily: AppFonts.fontOpenSansSemiBold,
    fontSize: 20,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.neutralTextPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: AppFonts.fontOpenSansSemiBold,
    fontSize: 16,
    height: 1.3,
    color: AppColors.neutralTextPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: AppFonts.fontOpenSansSemiBold,
    fontSize: 14,
    height: 1.3,
    color: AppColors.neutralTextPrimary,
  );

  /// Body – paragraphs and data values.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: AppFonts.fontOpenSansRegular,
    fontSize: 16,
    height: 1.5,
    color: AppColors.neutralTextPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: AppFonts.fontOpenSansRegular,
    fontSize: 14,
    height: 1.45,
    color: AppColors.neutralTextPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: AppFonts.fontOpenSansRegular,
    fontSize: 12,
    height: 1.4,
    color: AppColors.neutralTextSecondary,
  );

  /// Labels – buttons, form labels, chips, navigation items, table headers.
  static const TextStyle labelLarge = TextStyle(
    fontFamily: AppFonts.fontOpenSansSemiBold,
    fontSize: 15,
    height: 1.2,
    color: AppColors.neutralTextPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: AppFonts.fontOpenSansSemiBold,
    fontSize: 13,
    height: 1.2,
    color: AppColors.neutralTextSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: AppFonts.fontOpenSansSemiBold,
    fontSize: 11,
    height: 1.2,
    letterSpacing: 0.4,
    color: AppColors.neutralTextSecondary,
  );

  /// Text rendered on top of the brand colour (app bars, primary buttons).
  static const TextStyle labelOnPrimary = TextStyle(
    fontFamily: AppFonts.fontOpenSansSemiBold,
    fontSize: 15,
    height: 1.2,
    color: AppColors.neutralOnPrimary,
  );

  static const TextTheme _textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );

  // ───────────────────────────────────────────────────────────────────────────
  // THEME
  // ───────────────────────────────────────────────────────────────────────────

  static ThemeData appThemeData() => ThemeData(
    useMaterial3: false,
    primarySwatch: buildMaterialColor(AppColors.brandPrimary),
    scaffoldBackgroundColor: AppColors.neutralBackground,
    canvasColor: AppColors.neutralBackground,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: const ColorScheme.light(
      primary: AppColors.brandPrimary,
      onPrimary: AppColors.neutralOnPrimary,
      primaryContainer: AppColors.brandPrimarySurface,
      onPrimaryContainer: AppColors.brandPrimaryDark,
      secondary: AppColors.brandSecondary,
      onSecondary: AppColors.neutralOnPrimary,
      secondaryContainer: AppColors.brandSecondarySurface,
      onSecondaryContainer: AppColors.brandPrimaryDark,
      tertiary: AppColors.brandAccent,
      onTertiary: AppColors.neutralOnPrimary,
      error: AppColors.semanticError,
      onError: AppColors.neutralOnPrimary,
      errorContainer: AppColors.semanticErrorSurface,
      onErrorContainer: AppColors.semanticErrorDark,
      surface: AppColors.neutralSurface,
      onSurface: AppColors.neutralTextPrimary,
      outline: AppColors.neutralBorder,
      shadow: AppColors.shadowColor,
    ),
    textTheme: _textTheme,
    primaryTextTheme: _textTheme,

    /// Text selection / caret
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.brandPrimary,
      selectionColor: AppColors.brandSecondarySurface,
      selectionHandleColor: AppColors.brandPrimary,
    ),

    /// Page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.iOS: CupertinoPageTransitionsBuilder()},
    ),

    /// AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.neutralSurface,
      foregroundColor: AppColors.brandPrimary,
      surfaceTintColor: AppColors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.neutralTextPrimary,
        fontFamily: AppFonts.fontOpenSansSemiBold,
      ),
      iconTheme: IconThemeData(color: AppColors.brandPrimary),
      actionsIconTheme: IconThemeData(color: AppColors.brandPrimary),
      elevation: 0.0,
      scrolledUnderElevation: 0.0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    /// Bottom tab bar / bottom app bar
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: AppColors.neutralSurface,
      surfaceTintColor: AppColors.transparent,
      elevation: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.neutralSurface,
      selectedItemColor: AppColors.brandPrimary,
      unselectedItemColor: AppColors.neutralTextDisabled,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontFamily: AppFonts.fontOpenSansSemiBold,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontFamily: AppFonts.fontOpenSansRegular,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    /// Global icon colour
    iconTheme: const IconThemeData(color: AppColors.neutralTextSecondary),
    primaryIconTheme: const IconThemeData(color: AppColors.neutralOnPrimary),

    /// Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonDarkGreen,
        foregroundColor: AppColors.buttonYellow,
        disabledBackgroundColor: AppColors.neutralBorder,
        disabledForegroundColor: AppColors.neutralTextDisabled,
        elevation: 0,
        minimumSize: const Size(64, AppConst.buttonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConst.spaceXl,
          vertical: AppConst.spaceMd,
        ),
        textStyle: labelLarge.copyWith(
          color: AppColors.buttonYellow,
          fontFamily: AppFonts.fontOpenSansBold,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConst.radiusMd),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.buttonDarkGreen,
        foregroundColor: AppColors.buttonYellow,
        disabledForegroundColor: AppColors.neutralTextDisabled,
        minimumSize: const Size(64, AppConst.buttonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConst.spaceXl,
          vertical: AppConst.spaceMd,
        ),
        textStyle: labelLarge.copyWith(
          color: AppColors.buttonYellow,
          fontFamily: AppFonts.fontOpenSansBold,
          fontWeight: FontWeight.w700,
        ),
        side: const BorderSide(color: AppColors.neutralBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConst.radiusMd),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        backgroundColor: AppColors.buttonDarkGreen,
        foregroundColor: AppColors.buttonYellow,
        disabledForegroundColor: AppColors.neutralTextDisabled,
        minimumSize: const Size(0, AppConst.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppConst.spaceMd),
        textStyle: labelLarge.copyWith(
          color: AppColors.buttonYellow,
          fontFamily: AppFonts.fontOpenSansBold,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConst.radiusSm),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.buttonDarkGreen,
        foregroundColor: AppColors.buttonYellow,
        minimumSize: const Size(64, AppConst.buttonHeight),
        textStyle: labelLarge.copyWith(
          color: AppColors.buttonYellow,
          fontFamily: AppFonts.fontOpenSansBold,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConst.radiusMd),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.brandPrimary,
        minimumSize: const Size(
          AppConst.minTouchTarget,
          AppConst.minTouchTarget,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.buttonDarkGreen,
      foregroundColor: AppColors.buttonYellow,
      elevation: AppConst.elevationRaised,
      focusElevation: AppConst.elevationRaised,
      hoverElevation: AppConst.elevationRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppConst.radiusLg)),
      ),
    ),

    /// Cards
    cardTheme: CardThemeData(
      color: AppColors.neutralSurface,
      surfaceTintColor: AppColors.neutralSurface,
      shadowColor: AppColors.shadowColor,
      elevation: AppConst.elevationFlat,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConst.radiusLg),
        side: const BorderSide(color: AppColors.neutralDivider),
      ),
    ),

    /// Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.neutralSurface,
      isDense: true,
      hintStyle: bodyMedium.copyWith(color: AppColors.neutralTextDisabled),
      labelStyle: bodyMedium.copyWith(color: AppColors.neutralTextSecondary),
      floatingLabelStyle: labelMedium.copyWith(color: AppColors.brandPrimary),
      errorStyle: bodySmall.copyWith(color: AppColors.semanticErrorDark),
      helperStyle: bodySmall,
      prefixIconColor: AppColors.neutralTextDisabled,
      suffixIconColor: AppColors.neutralTextSecondary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConst.spaceLg,
        vertical: AppConst.spaceMd,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConst.radiusMd),
        borderSide: const BorderSide(color: AppColors.neutralBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConst.radiusMd),
        borderSide: const BorderSide(color: AppColors.neutralBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConst.radiusMd),
        borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConst.radiusMd),
        borderSide: const BorderSide(color: AppColors.semanticError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConst.radiusMd),
        borderSide: const BorderSide(
          color: AppColors.semanticError,
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConst.radiusMd),
        borderSide: const BorderSide(color: AppColors.neutralDivider),
      ),
    ),

    /// Selection controls
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.brandPrimary
            : AppColors.transparent,
      ),
      checkColor: WidgetStateProperty.all(AppColors.neutralOnPrimary),
      side: const BorderSide(color: AppColors.neutralBorder, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConst.spaceXs),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.brandPrimary
            : AppColors.neutralBorder,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.neutralSurface
            : AppColors.neutralSurface,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.brandPrimary
            : AppColors.neutralBorder,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.brandPrimary
            : AppColors.neutralBorder,
      ),
    ),

    /// Chips
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.neutralSurfaceMuted,
      selectedColor: AppColors.brandPrimarySurface,
      disabledColor: AppColors.neutralSurfaceSunken,
      labelStyle: labelMedium.copyWith(color: AppColors.neutralTextSecondary),
      secondaryLabelStyle: labelMedium.copyWith(color: AppColors.brandPrimary),
      side: const BorderSide(color: AppColors.neutralDivider),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppConst.radiusPill)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConst.spaceMd,
        vertical: AppConst.spaceSm,
      ),
    ),

    /// Tabs
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.brandPrimary,
      unselectedLabelColor: AppColors.neutralTextSecondary,
      indicatorColor: AppColors.brandPrimary,
      labelStyle: titleSmall.copyWith(color: AppColors.brandPrimary),
      unselectedLabelStyle: titleSmall.copyWith(
        color: AppColors.neutralTextSecondary,
      ),
      dividerColor: AppColors.neutralDivider,
    ),

    /// Dialogs / sheets
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.neutralSurface,
      surfaceTintColor: AppColors.neutralSurface,
      elevation: AppConst.elevationFloating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConst.radiusLg),
      ),
      titleTextStyle: headlineSmall.copyWith(fontSize: 18),
      contentTextStyle: bodyMedium,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.neutralSurface,
      surfaceTintColor: AppColors.transparent,
      modalBackgroundColor: AppColors.neutralSurface,
      elevation: AppConst.elevationFloating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConst.radiusXl),
        ),
      ),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.neutralSurface,
      surfaceTintColor: AppColors.transparent,
      elevation: 1,
    ),

    /// Menus and overlays
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.neutralSurface,
      surfaceTintColor: AppColors.neutralSurface,
      elevation: AppConst.elevationRaised,
      textStyle: bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConst.radiusMd),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.neutralTextPrimary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppConst.radiusSm),
      ),
      textStyle: bodySmall.copyWith(color: AppColors.neutralSurface),
      waitDuration: const Duration(milliseconds: 400),
    ),

    /// Lists
    listTileTheme: ListTileThemeData(
      iconColor: AppColors.neutralTextSecondary,
      textColor: AppColors.neutralTextPrimary,
      titleTextStyle: titleSmall,
      subtitleTextStyle: bodySmall,
      selectedColor: AppColors.brandPrimary,
      selectedTileColor: AppColors.brandPrimarySurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConst.radiusMd),
      ),
    ),

    /// Feedback
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.brandPrimary,
      linearTrackColor: AppColors.neutralSurfaceSunken,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.neutralDivider,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.neutralTextPrimary,
      contentTextStyle: bodyMedium.copyWith(color: AppColors.neutralSurface),
      actionTextColor: AppColors.brandSecondary,
      behavior: SnackBarBehavior.floating,
      elevation: AppConst.elevationFloating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConst.radiusMd),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.neutralBorder),
      thickness: WidgetStateProperty.all(6),
      radius: const Radius.circular(AppConst.radiusSm),
    ),
  );

  // ───────────────────────────────────────────────────────────────────────────
  // SHARED TEXT STYLES
  // Retained for screens that reference AppThemeData.* directly.
  // ───────────────────────────────────────────────────────────────────────────

  static TextStyle normal16 = bodyLarge;

  static TextStyle bold16 = bodyLarge.copyWith(
    fontFamily: AppFonts.fontOpenSansBold,
  );

  /// @Deprecated – use [labelMedium] / [brandPrimary].
  static TextStyle primary14TextStyle = labelMedium.copyWith(
    color: AppColors.brandPrimary,
  );

  /// @Deprecated – use [titleMedium].
  static TextStyle primary16TextStyle = titleMedium.copyWith(
    color: AppColors.brandPrimary,
  );

  static TextStyle black12TextStyle = bodySmall.copyWith(
    color: AppColors.neutralTextPrimary,
  );

  static TextStyle black14TextStyle = bodyMedium;

  static TextStyle black16TextStyle = bodyLarge;

  static TextStyle black18TextStyle = headlineSmall;

  static TextStyle grey14TextStyle = bodyMedium.copyWith(
    color: AppColors.neutralTextSecondary,
  );

  static TextStyle grey16TextStyle = bodyLarge.copyWith(
    color: AppColors.neutralTextSecondary,
  );

  static TextStyle grey18TextStyle = headlineSmall.copyWith(
    color: AppColors.neutralTextSecondary,
  );

  static TextStyle primaryButtonTextStyle = labelLarge.copyWith(
    color: AppColors.buttonYellow,
    fontFamily: AppFonts.fontOpenSansBold,
    fontWeight: FontWeight.w700,
  );

  static TextStyle appBarTitleTextStyle = titleSmall.copyWith(
    fontSize: 18,
    color: AppColors.neutralTextPrimary,
  );

  static TextStyle appBarSecondaryTitleTextStyle = headlineLarge.copyWith(
    fontSize: 31,
    letterSpacing: -0.2,
  );

  /// Form field input text.
  static TextStyle textFieldTextStyle = bodyMedium;

  /// Form field label.
  static TextStyle textFieldLabelTextStyle = titleSmall;

  /// Inline form validation message.
  static TextStyle errorTextFieldStyle = bodySmall.copyWith(
    color: AppColors.semanticErrorDark,
  );

  /// Dialog action label.
  static TextStyle dialogueBtnTextStyle = labelLarge.copyWith(
    color: AppColors.buttonYellow,
    fontFamily: AppFonts.fontOpenSansBold,
    fontWeight: FontWeight.w700,
  );

  /// Section heading used inside cards / pages.
  static TextStyle sectionTitleTextStyle = titleMedium;

  /// Muted helper / caption text.
  static TextStyle captionTextStyle = bodySmall;

  /// Builds a [MaterialColor] swatch from a single [color].
  static MaterialColor buildMaterialColor(Color color) {
    List<double> strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = (color.r * 255).round().clamp(0, 255);
    final int g = (color.g * 255).round().clamp(0, 255);
    final int b = (color.b * 255).round().clamp(0, 255);

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.toARGB32(), swatch);
  }
}
