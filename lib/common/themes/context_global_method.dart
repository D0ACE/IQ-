import 'package:flutter/material.dart';

/// global context used for hide keyboard
class ContextGlobalMethod {
  static void hideGlobalKb(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }
}
