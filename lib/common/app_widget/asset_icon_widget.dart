import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'custom_gesture_detector.dart';

/// common svg icon widget with on tap functionality
class AssetIconWidget extends StatelessWidget {
  final String icon;
  final Function? onTap;
  final Color? color;
  final double? height;
  final double? width;
  final EdgeInsets margin;

  const AssetIconWidget({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.height = 20,
    this.width = 20,
    this.margin = const EdgeInsets.all(0.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: onTap != null
          ? CustomGestureDetector(
              onTap: onTap != null ? onTap! : () {},
              child: mainContentWidget(),
            )
          : mainContentWidget(),
    );
  }

  Widget mainContentWidget() {
    return icon.contains(".svg")
        ? SvgPicture.asset(
            icon,
            colorFilter: color != null
                ? ColorFilter.mode(color!, BlendMode.srcIn)
                : null,
            width: width,
            height: height,
          )
        : Image.asset(
            icon,
            color: color,
            width: width,
            height: height,
          );
  }
}
