import 'package:budget/functions.dart';
import 'package:flutter/material.dart';

class AndroidOnly extends StatelessWidget {
  const AndroidOnly({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (getPlatform(ignoreEmulation: true) != PlatformOS.isAndroid)
      return SizedBox.shrink();
    return child;
  }
}

// Budgie is web-only, so there are no Android home screen widgets to refresh.
Future updateWidgetColorsAndText(BuildContext context) async {}
