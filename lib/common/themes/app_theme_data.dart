import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_strings.dart';

/// common app theme data class which contain all the data related to theme like text style
class AppThemeData {
  static ThemeData appThemeData() => ThemeData(
    useMaterial3: false,
    primarySwatch: buildMaterialColor(AppColors.primary),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: AppColors.primary,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.whiteColor,
      surfaceTintColor: AppColors.transparent,
    ),

    ///Page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        // TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      },
    ),

    ///Text theme
    // textTheme: GoogleFonts.latoTextTheme(),
    ///AppBar common.theme
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.whiteColor,
      iconTheme: IconThemeData(color: AppColors.blackTextColor),
      elevation: 0.0,
      // centerTitle: true,
    ),

    ///Bottom tab bar
    bottomAppBarTheme: const BottomAppBarThemeData(color: AppColors.iconColor),

    ///Icon common.theme
    iconTheme: const IconThemeData(color: AppColors.iconColor),

    primaryTextTheme: const TextTheme(),
  );

  static TextStyle normal16 = const TextStyle(
    fontSize: 16,
    color: AppColors.blackTextColor,
    fontFamily: AppFonts.fontOpenSansRegular,
  );

  static TextStyle bold16 = const TextStyle(
    fontSize: 16,
    color: AppColors.blackTextColor,
    fontFamily: AppFonts.fontOpenSansBold,
  );

  static TextStyle primary14TextStyle = const TextStyle(
    fontSize: 14.0,
    color: AppColors.primaryTextColor,
    fontFamily: AppFonts.fontOpenSansRegular,
  );

  static TextStyle primary16TextStyle = const TextStyle(
    fontSize: 16.0,
    color: AppColors.primaryTextColor,
    fontFamily: AppFonts.fontOpenSansRegular,
  );

  static TextStyle black12TextStyle = const TextStyle(
    fontSize: 12,
    color: AppColors.blackTextColor,
    fontFamily: AppFonts.fontOpenSansRegular,
  );
  static TextStyle black14TextStyle = const TextStyle(
    fontSize: 14,
    color: AppColors.blackTextColor,
    fontFamily: AppFonts.fontOpenSansRegular,
  );

  static TextStyle black16TextStyle = const TextStyle(
    fontSize: 16,
    color: AppColors.blackTextColor,
    fontFamily: AppFonts.fontOpenSansRegular,
  );

  static TextStyle black18TextStyle = const TextStyle(
    fontSize: 18,
    color: AppColors.blackTextColor,
    fontFamily: AppFonts.fontOpenSansRegular,
  );

  static TextStyle grey14TextStyle = const TextStyle(
    fontSize: 14,
    color: AppColors.greyTextColor,
    fontFamily: AppFonts.fontOpenSansRegular,
  );

  static TextStyle grey16TextStyle = const TextStyle(
    fontSize: 16,
    color: AppColors.greyTextColor,
    fontFamily: AppFonts.fontOpenSansRegular,
  );

  static TextStyle grey18TextStyle = const TextStyle(
    fontSize: 18,
    color: AppColors.greyTextColor,
    fontFamily: AppFonts.fontOpenSansRegular,
  );

  static TextStyle primaryButtonTextStyle = const TextStyle(
    fontSize: 16,
    color: AppColors.whiteTextColor,
    fontFamily: AppFonts.fontOpenSansRegular,
  );

  static TextStyle appBarTitleTextStyle = const TextStyle(
    fontSize: 18,
    color: AppColors.blackTextColor,
    fontFamily: AppFonts.fontOpenSansSemiBold,
  );

  static TextStyle appBarSecondaryTitleTextStyle = const TextStyle(
    fontSize: 31,
    fontFamily: AppFonts.fontOpenSansBold,
    letterSpacing: -0.2,
    color: AppColors.blackTextColor,
  );

  static TextStyle textFieldTextStyle = const TextStyle(
    fontSize: 14,
    color: AppColors.textFieldGreyColor,
    fontFamily: AppFonts.fontOpenSansRegular,
  );

  static TextStyle errorTextFieldStyle = const TextStyle(
    fontSize: 12,
    wordSpacing: 1,
    fontFamily: AppFonts.fontOpenSansRegular,
    color: AppColors.redTextStatusColor,
  );

  static TextStyle dialogueBtnTextStyle = const TextStyle(
    fontSize: 14,
    fontFamily: AppFonts.fontOpenSansSemiBold,
    color: AppColors.primaryTextColor,
  );

  static MaterialColor buildMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

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
