
import 'package:iq_plus/common/themes/context_global_method.dart';
import 'package:flutter/material.dart';

/// common gesture detector used in all place which remove focus first on button tap
class CustomGestureDetector extends StatelessWidget {
  final Widget child;
  final Function? onTap;

  const CustomGestureDetector({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: child,
      onTap: () {
        ContextGlobalMethod.hideGlobalKb(context);
        if (onTap != null) {
          onTap!();
        }
      },
    );
  }
}
