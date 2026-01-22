
import 'package:flutter/material.dart';

/// common app color class in which all the color used in app are defined
class AppColors {
  static const Color primary = Color(0xFF73ad00);
  static const Color secondary = Color(0xFFE17314);
  static const Color lightGreen = Color(0xFFCAEC89);
  static const Color lightRed = Color(0xFFFF8282);
  static const Color primary10 = Color(0x2D73B000);
  static const Color primary20 = Color(0xFFffeaf1);
  static const Color riderImageBackground = Color(0xFFE4E4E4);
  static const Color redOverlaySliderColor = Color(0x1AFF4200);

  // static const Color accent = Color(0xFFdce4f2);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color scaffoldColor = Color(0xFFffffff);
  static const Color iconColor = grey90TextColor;
  static const textFieldGreyColor = Color(0xffC9C5C4);
  static const sendAgainBtnGrayColor = Color(0xffE6E6E6);
  static const sendAgainBtnGrColor = Color(0xffDFDFDF);
  static const trackOrderGreenBtnGrColor = Color(0xffD0FF76);
  static const tryAgainRedBtnGrColor = Color(0xffFF6666);
  static const changeMethodPinkBtnGrColor = Color(0xffFFC1C1);
  static const orderAgainBtnGrColor = Color(0xffFFD79D);
  static const orderIDTextColor = Color(0xff8E8E8E);

  static const blackColor = Color(0xff171746);
  static const blackTextColor = blackColor;

  static const Color redDeleteSliderColor = Color(0xffF94E34);
  static const Color greyLoginTextColor = Color(0xff7B7D86);
  static const Color whiteColor = Colors.white;
  static const Color statusBarColor = Colors.white;
  static Color? greyTextFormFiledColor = kPrimaryLightColor;

  static const deActiveIndicatorColor = grey40TextColor;

  //text colors
  static const Color redTextStatusColor = Color(0xFFec4d63);
  static const Color whiteTextColor = Color(0xFFFFFFFF);
  static const Color shadowForDeliveryAddsColor = Color(0xFFE2E2E2);

  static const Color primaryTextColor = Color(0xFF73B000);
  static const Color greyTextColor = Color(0xFF656973);
  static const Color circularShadowGrayColor = Color(0xFFD9D9D9);

  // grey colors
  static const Color grey90TextColor = Color(0xFF1d1e21);
  static const Color grey80TextColor = Color(0xFF41444a);
  static const Color grey70TextColor = Color(0xFF656973);
  static const Color grey40TextColor = Color(0xFFbbbdc2);
  static const Color grey30TextColor = Color(0xFFe1e3e8);
  static const Color grey20TextColor = Color(0xFFe8e8e8);
  static const Color greyBorderColor = Color(0xFFBDBDBD);

  // button property
  static const Color btnPrimaryColor = primary;
  static const Color transparent = Colors.transparent;
  static const Color btnGradientStartColor = Color(0xFF256ff7);
  static const Color btnGradientEndColor = Color(0xFF0d56db);
  static const Color btnRippleEffectColor = Colors.white30;

  static const Color selectedTabColor = Color(0xFF2a2c37);

  static const Color textGrayColor = Color(0xFF9D9693);
  static const Color arrowBlackColor = Color(0xFF1A0700);
  static const Color priceContainerColor = Color(0xFF525252);
  static const Color borderColor = Color(0xFFCDCDCD);

  static const Color facebookBtnColor = Color(0xFF4267B2);

  static const Color textFieldBorderColor = Color(0xFFd1d7e3);
  static const Color boxSizeTextColor = Color(0xFF5E5E5E);

  static const Color orderRejectTextColor = Color(0xFFD10707);
  static const Color riderLocationColor = Color(0x34FF4200);
  static const Color ridrLocationColor = Color(0xFFE7E7E7);

  static const cShimmerBaseColor = Colors.black12;
  static const cShimmerHighlightColor = Colors.black26;

  static const shimmerGreyLight = Color(0xffE6E6E6);

  // static const shimmerGreyLight = Color(0xffdce1ea);
  static const shimmerWhiteLight = Color(0xffEEF2F8);
  static const favoriteTileBackgroundColor = Color(0xffFFF4EA);
  static const favoriteChipBackgroundColor = Color(0xffFFDBB9);
  static const starRatingColor = Color(0xffF3C521);

  ///Order Request Response Color
  static const delivered = Color(0xff20AEF3);
  static const delayed = Color(0xfff2a2c5);
  static const paid = Color(0xff8ed490);
  static const readyForPickup = Color(0xff77b58a);
  static const cancelled = Color(0xffC62424);
  static const picked = Color(0xffe8ca9e);

  //store type colors
  static const greenStoreType = Color(0xff315B2D);
  static const orangeStoreType = Color(0xffE05825);
  static const blueStoreType = Color(0xff26558B);
  static const lightGreenStoreType = Color(0xff73B000);
  static const brownStoreType = Color(0xffCF8D29);
  static const kPrimaryColor = Color(0xFF6F35A5);
  static const kPrimaryLightColor = Color(0xFFF1E6FF);
  static const merchantMenuMessageTextColor = Color(0xffdc3545);
  
  static const Color orange = Color(0xFFFFA500);
  static const Color green = Color(0xFF28A745);
  // add more as needed



  // 🎨 Gradient colors (image inspired)
  static const Color purple = kPrimaryColor;
  static const Color pink = kPrimaryLightColor;
  static const Color blue = Color(0xFF8EC5FF);

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, pink, blue],
  );

  // Backgrounds
  static const Color scaffoldBg = Color(0xFFF6F5FB);
  static const Color cardBg = Colors.white;

  // Text
  static const Color titleText = Color(0xFF2B2B2B);
  static const Color subText = Color(0xFF7A7A7A);

  // Drawer
  static const Color drawerBg = Color(0xFF5B3FD8);

  // Charts
  static const Color barColor = purple;
}
